# Roteiro F5 — servidor em Docker com latência e perda (SPEC-005, #6)

O Code executa todos os comandos (`CLAUDE.md`); o PI só olha as janelas.

1. Sem latência: `docker compose -f infra/docker-compose.yml up --build -d` e `.\tools\run-clients.ps1 -Autopilot`.
   - Log do servidor: `[server] escutando na porta 7000` e `peer <id> conectou` 2x.
   - HUD com RTT baixo, autopilot em círculo, WASD responde.
2. Com 100 ms e 2% de perda: `$env:NETEM_DELAY_MS=100; $env:NETEM_LOSS_PCT=2`, depois o mesmo `up --build -d` e os mesmos clientes.
   - Log: `[netem] delay=100ms jitter=0ms loss=2%`.
   - HUD com RTT ≈ 100 ms + base local.
   - Movimento próprio sem atraso perceptível; remoto suave; golpe tira 92 nas duas janelas.
3. Ao terminar: `docker compose -f infra/docker-compose.yml down` e `Remove-Item Env:NETEM_DELAY_MS, Env:NETEM_LOSS_PCT`.

## Execução — 2026-10-09 (servidor no Docker Desktop/WSL2, clientes locais)

| Item | Resultado |
|---|---|
| Imagem | build ok. Camadas descompactadas: 261 MB (debian 85 + apt 21 + Godot 146 + jogo 9). `docker save`: 115 MB. O `docker images` mostra 383 MB porque o image store do containerd soma as camadas comprimidas e as descompactadas |
| 1. Sem latência | OK. 2 conectaram; RTT 16–21 ms; autopilot em círculo; WASD ok (PI) |
| 2. 100 ms / 2% | OK. `[netem] delay=100ms jitter=0ms loss=2%`; RTT 111–123 ms; autopilot suave, passando de raspão no bloco sem tranco; HP 416/600 idêntico nas duas janelas após golpes (PI). WASD do cliente 1 sob 100 ms não confirmado nesta execução: fica para o gate |
| Log do servidor (~4 min a 100 ms/2%) | 0 `ERROR`, 0 `WRN` |

Observações:
- No `--import` do build aparece `ERROR: Unable to load fontconfig, system font support is disabled.`, porque a imagem não tem fontconfig. O erro não aparece com o servidor rodando.
- Teste headless do Code a 100 ms/2%: numa rodada, o 2º cliente teve 7× `ERROR: Node not found: "Main/Players/<peer1>/RollbackSynchronizer/Node"` logo depois do sync. Uma RPC de estado do player 1 chegou antes do spawn retransmitido. O Godot descarta o pacote e o jogo segue. Em outra rodada de 40 s, deu 0 ocorrências.
- O job `build-server` da CI (`CI-PR.md` §2, "a partir de F5") não entrou. Pela decisão do PI no F1, os demais jobs vêm por card `[INFRA]`.
