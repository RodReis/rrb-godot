# Roteiro F20 — monstros, baús e boss replicados para 2 clientes reais (SPEC-020, #60)

O Code executa tudo (`CLAUDE.md`); o PI só olha as janelas. Protocolo dos cenários: ADR-0001.

## Como rodar

```powershell
.\tools\net-measure.ps1 -OutDir <pasta> -DelayMs 100 -LossPct 2 -Minutes 10               # B
.\tools\net-measure.ps1 -OutDir <pasta> -DelayMs 200 -JitterMs 30 -LossPct 5 -Minutes 10  # C
```

O script sobe o servidor em Docker com `tc netem` e `--probe`, abre 2 clientes com a sonda (`NetProbe`), espera, grava `server.log`, `client1.log`, `client2.log` e `bandwidth.txt`, derruba tudo e roda `tools\net-probe-report.ps1`.

- **Cliente 1** é jogado pelo `BotInput` (`--autopilot=bot`): farma, abre baús, enfrenta monstros e o herói adversário. Gera morte e respawn de monstros, baús abertos e o boss.
- **Cliente 2** anda em círculo (`--autopilot`), sempre em movimento: é o remoto que o cliente 1 mede.
- Os dois clientes jogam sozinhos, sem o PI; a medição é repetível.

O que a sonda mede:

| Linha | Onde | O que é |
|---|---|---|
| `[probe] remoto parado X%` | clientes, a cada 10 s | quadros em que o herói remoto ficou no lugar enquanto a velocidade replicada dizia que ele andava (estado atrasado ou perdido) |
| `[probe] check <tick> ...` | servidor e clientes, a cada 300 ticks | monstros (HP; `x` = fora do mapa) e baús abertos no tick `<tick>` do servidor, lidos do histórico do `StateSynchronizer`; o relatório compara cliente × servidor |
| `[probe] throttle minimo` | servidor e clientes | menor throttle do ENet na janela (32 = nada descartado) |

## Verificação visual (PI)

1. As duas janelas mostram o mesmo contador "Baús abertos X/24 · Monstros N" e o mesmo HP no monstro em combate.
2. 3:00: banner "O REI ESQUELETO DESPERTA EM 30 s" nas duas. 3:30: boss no centro.
3. 5:00: portões abertos; o boss vivo some sem deixar baú, e o painel mostra "SAIU DO MAPA".
4. O herói remoto anda sem travar visivelmente.

## Execução — 2026-10-10 (servidor no Docker Desktop/WSL2, clientes locais, 10 min por cenário)

| Cenário | Remoto parado (c1 / c2) | Checkpoints iguais ao servidor | `Node not found` | `Reference tick missing` (c1 / c2) | Banda do servidor (envio / recepção) |
|---|---|---|---|---|---|
| B (100 ms, 2 %) | **6,2 % / 2,7 %** | **60/60 e 60/60** | **0** | 6 / 2 | 1.336 / 219 kbit/s |
| C (200 ms, jitter 30 ms, 5 %) | 31,4 % / 42,7 % | 0/60 e 0/60 | **0** | 454 / 540 | 1.517 / 208 kbit/s |

Logs do B (aceite): `f20-logs/b-*.log`. Servidor sem `ERROR`/`WARNING` nas duas rodadas.

Verificação visual do PI no B: **ok** (2026-10-10). Captura no roadmap: `docs/roadmap/img/mvp2-f20-dois-clientes-sob-latencia.webp`.

### Antes

- `Node not found` (roteiro F5, M0): numa rodada de 100 ms/2 %, 7 ocorrências de `Main/Players/<peer>/RollbackSynchronizer/Node` logo depois do sync; em outra, 0. Causa: o estado do netfox vai no canal não confiável e o spawn do `MultiplayerSpawner` no confiável; sob perda o estado chegava antes do spawn retransmitido.
- Remoto parado (ADR-0001, 1 cápsula, instrumento temporário do M0): A 2,2 %, B 19,6 %, C 79,1 %. A sonda do F20 é outro instrumento — não desconta pausa legítima do mesmo jeito —, então os números não são comparáveis um a um. Na mesma régua, o primeiro B do F20 deu 2,6 % / 3,7 %.

### O que mudou

- **Spawn confiável antes do estado** (`SpawnAck`): o servidor começa sem mandar estado do herói a ninguém; cada cliente confirma por RPC confiável quando o node já existe nele, e só então entra no filtro de visibilidade do `RollbackSynchronizer`.
- **Nenhum monstro nasce ou some da árvore no meio da partida.** Monstros e baús já nasciam iguais nos dois lados no load; o Rei Esqueleto agora também existe desde o load, fora do mapa (`Monster.present`), entra às 3:30 e, vivo às 5:00, sai sem drop nem XP (R-PEND-06). Respawn (F36) e saída são estado replicado do mesmo node.

## Cenário C — fora da meta (decisão do PI, 2026-10-10)

Meta do card: ≤ 30 % de remoto parado **ou** decisão do PI de que C está fora da meta. Nenhum ajuste de configuração do netfox levou o C à meta; o PI decidiu: **C fora da meta**, netfox no padrão, C volta a ser medido no teste com duas máquinas reais (MVP3).

Investigação (C, 4 min por variante salvo indicado):

| Variante | Remoto parado (c1 / c2) | Checkpoints iguais | Observação |
|---|---|---|---|
| netfox padrão (10 min) | 41,4 % / 23,0 % | 0/60, 1/60 | ~600 `Reference tick missing` por cliente |
| sem `StateSynchronizer` de monstro | 19,0 % / — | — | só os heróis já perdem; o tráfego de monstros dobra o problema |
| `netem` sem reordenar (`pfifo` filho) | 52,6 % / 22,6 % | 0/24 | piorou: reordenação não é a causa |
| `full_state_interval` 24 → 6 | 21,8 % / 58,4 % | 1/24 | a referência continua expirando |
| `enable_diff_states` desligado | 28,7 % / 50,7 % | 13/24 | 0 `Reference tick missing`, mas o servidor manda 2,5 Mbit/s |
| throttle do ENet | mín. 28–32 de 32 | — | não é a causa |

Leitura:
- Em todo `Reference tick missing` a referência tem ~65 ticks: o servidor ainda a tem (histórico de 64) e manda a diferença; o cliente acabou de descartá-la. O snapshot fica sem HP (`?` nos checkpoints) ou com HP velho. A referência só avança quando o cliente confirma um estado completo pelo canal confiável, que sob 5 % de perda e 200 ms atrasa em cadeia.
- O netfox mostra o remoto no último estado recebido, sem buffer de exibição; com jitter e perda os estados chegam aos saltos e o remoto para e pula. Resolver exige buffer de exibição (`display_offset`, recusado no ADR-0001 porque atrasa o movimento próprio) ou outra replicação — fora do F20.
