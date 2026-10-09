# Roteiro #41 — herói encostado no muro e cruzando o portão A sem correção

O Code executa todos os comandos (`CLAUDE.md`). O PI só olha a janela 1 (time A).

1. **RTT local.** `.\tools\run-server.ps1` e `.\tools\run-clients.ps1 -Autopilot`.
   - Na janela 1, saia da base A pelo portão. Ande encostado no muro de fora e no de dentro. Entre e saia pelo portão 3 a 5 vezes, raspando nas laterais (faixas de ±1,8 u).
   - Esperado: o herói não volta para trás nem dá tranco.
2. **+100 ms.** Rode `$env:NETEM_DELAY_MS=100; docker compose -f infra/docker-compose.yml up --build -d` e depois `.\tools\run-clients.ps1 -Address 127.0.0.1:7000 -Autopilot`. Repita o movimento do passo 1.
   - Esperado: o mesmo, sem correção visível. O HUD mostra RTT ≈ 100 ms mais a base local.
3. **Ao terminar:** `docker compose -f infra/docker-compose.yml down` e `Remove-Item Env:NETEM_DELAY_MS`.

## Medição objetiva (Code)

Para medir, o Code usa uma sonda temporária no `Hero`, que não vai para o commit. No cliente dono do herói, ela guarda a posição prevista na primeira simulação de cada tick. Quando a ressimulação começa no último tick confirmado pelo servidor, ela compara as duas posições. Diferença acima de 0,01 u conta como correção.

Para o roteiro ficar repetível sem o PI, um andarilho temporário (`--autopilot` com `RRB_WALK=1`) circula entre o pátio da base A, as duas laterais do portão e o lado de fora do muro.

## Execução — 2026-10-09

| Passo | Variante | Resultado |
|---|---|---|
| 1. RTT local, PI jogando (~12 min) | `main` | Sem puxão (PI). Sonda: 0 correções em 2473 comparações; 1 travada de frame de 81 ms; servidor sem `ERROR` |
| 1. RTT local, andarilho | `main` | 0 correções nos 5 cenários (1 cliente, 2 clientes headless, 2 com janela, andarilho no portão, 2º herói encostado no 1º dentro do portão) |
| 2. 100 ms, andarilho, 3 rodadas | `main` (GROUNDED) | **4 correções em 14.613 comparações**, todas de ~0,071 u, no canto entre portão A e muro (s ≈ 20,9, l ≈ ±3,4). O servidor tinha o herói em y = −0,012 e o cliente em y = +0,0007 |
| 2. 100 ms, andarilho, 2 rodadas | FLOATING + y travado (descartado) | 5 correções em 12.666, todas de ~0,200 u (um passo), na dobra do muro em arco (s ≈ 22,6, l ≈ ±7,3) |
| 2. 100 ms, andarilho, 2 rodadas | **y travado (correção)** | **0 correções em 14.482 comparações**; servidor sem `ERROR` |
| 2. 100 ms, PI jogando (RTT 121 ms no HUD) | **y travado (correção)** | OK, "rodando liso" (PI); servidor sem `ERROR` |

Causa: perto do muro, a despenetração mexe no y do herói. Aí o encaixe no chão do `move_and_slide()` (modo GROUNDED) passa a depender de `is_on_floor()` do tick anterior. Esse é estado interno do `CharacterBody3D` e fica fora das `state_properties` do rollback, então servidor e cliente ressimulam o mesmo tick com resultados diferentes. No GUT, o mesmo tick dá 0,05 u de diferença conforme esse estado (`test_hero_rollback.gd`). Correção: `axis_lock_linear_y = true` no `Hero`, porque o herói é planar.

Observações:
- O passo 2 só funciona depois do #42: até ali, o servidor Docker subia sem `shared/` e o herói não compilava.
