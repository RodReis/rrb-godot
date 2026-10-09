# Roteiro F4 — ataque validado no servidor, HUD de rede e autopilot (SPEC-004, #5)

Pré-requisitos e terminais iguais aos do `roteiro-f3-conexao-movimento.md`. Reinicie o servidor antes de cada parte, porque o limite é de 2 peers.

## Parte A — dano (`run-server.ps1` + `run-clients.ps1`)

1. O topo de cada janela mostra `peer <id> | RTT <n> ms | tick <n>`, com o tick subindo.
2. A cápsula 1 encosta na 2, mira e clica: o HP da 2 cai 92 nas **duas** janelas (600 → 508).
3. Cliques seguidos respeitam ~0,5 s de recarga.
4. Golpe de costas ou a mais de 2 u não tira HP.
5. Depois de 7 acertos (HP 0), o HP volta para 600.
6. Fechar as janelas: o servidor imprime `peer <id> saiu` 2x, sem `ERROR`.

## Parte B — autopilot (`run-server.ps1` + `run-clients.ps1 -Autopilot`)

7. A janela 2 mostra `| AUTOPILOT` e a cápsula dela anda em círculo.
8. Na janela 1, a cápsula do autopilot se move suave.

## Execução — 2026-10-09 (PI, servidor e clientes locais)

| Passo | Resultado |
|---|---|
| 1 | OK. RTT local de 12 a 22 ms (o plano esperava 0 a 2) |
| 2 | OK. HP 232/600 idêntico nas duas janelas após 4 acertos (600 − 4×92) |
| 3 | Não verificado isoladamente |
| 4 | Não verificado isoladamente |
| 5 | Não verificado |
| 6 | OK. `peer ... saiu` 2x |
| 7 | OK |
| 8 | OK |

Observações:
- Na primeira tentativa, o texto de HP (fonte padrão do `Label3D`) ficou ilegível a ~15 m. Aumentei para `font_size` 96, `pixel_size` 0.01 e contorno.
- A Parte B falhou numa tentativa em que o servidor ainda tinha um jogador da Parte A: com o limite de 2, o cliente em autopilot foi recusado. Por isso o roteiro manda reiniciar o servidor entre as partes.
- O dano é calculado só no servidor (decisão do PI). O atacante vê o HP cair depois de ~1 RTT.
