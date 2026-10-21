# F95 / SPEC-095 — Arena nova, parte 2: rio, pontes, centro, selva e mato alto

Evidência de aceite (issue #267, ADR-0030). As imagens põem o antes (`main` `796fc3a`, com as bases do F94) à esquerda e o depois (este card) à direita. Cada par usa a mesma câmera, seed 38 e a mesma luz.

## Frame time (aceite 5)

Medido com `tools/perf/frametime_probe.gd` em 1920x1080 (RTX 5060, Vulkan). As rodadas alternam antes e depois. O "antes" roda num worktree da `main` com a mesma sonda. A opção nova `--at=x,z` segura o herói num ponto; `--grass` o põe no centro da moita mais perto. Os JSONs estão nesta pasta.

| Cenário | Antes GPU média (ms) | Depois GPU média (ms) | Delta |
|---|---|---|---|
| MID: herói na ponte, lado da ilha (`--at=-9.5,9.5`), 3 rodadas | 4,073 / 4,396 / 4,230 → **4,233** | 4,112 / 4,400 / 4,247 → **4,253** | +0,02 ms |
| Centro: ao lado da rocha do centro (`--at=4,-9`), 3 rodadas | 3,796 / 3,874 / 4,050 → **3,907** | 3,813 / 3,815 / 4,074 → **3,901** | −0,01 ms |
| Moita de emboscada da metade A (`--grass`), 3 rodadas | 3,831 / 3,979 / 3,935 → **3,915** | 3,864 / 3,995 / 3,815 → **3,891** | −0,02 ms |
| Spawn A, herói parado, 2 rodadas | 3,848 / 3,835 → **3,842** | 3,872 / 3,744 → **3,808** | −0,03 ms |

Nos quatro cenários, o delta fica dentro da variação entre rodadas (até 0,3 ms), muito abaixo do teto de +4 ms do bloco visual (ADR-0006 item 7). A CPU fica em 16,7 ms nos dois casos, presa nos 60 quadros por segundo.

No meio do trabalho, duas medições isoladas no spawn, fora das rodadas alternadas, deram +3,0 ms e depois +1,7 ms. A queda veio de deixar a anti-repetição do terreno só no albedo. As rodadas alternadas finais acima não repetem esse custo, e a causa da diferença não foi isolada. O "antes" daquelas medições não rodou alternado com o "depois", então a variação da máquina entre uma rodada e outra entra no número.

## Capturas (aceite 5)

| Arquivo | O que mostra |
|---|---|
| `jogo_mid.webp` | câmera do jogo na ponte: cantaria, rio com margem, cratera e rochas com cristal |
| `jogo_centro.webp` | câmera do jogo no centro: borda de colunas de basalto e mato alto |
| `jogo_moita.webp` | câmera do jogo com o herói na moita de emboscada |
| `close_*.webp` | ponte, moita, centro, cratera e selva (`scenery_capture.gd --poses=meio`) |

## Mato alto (aceite 3)

Os testes do F32 e do F72 seguem verdes: área, abertura em volta do herói e herói coberto. O PI confirmou na verificação de 2026-10-21 que a moita nova ainda lê como esconderijo.

## Colisão e testes (aceite 2)

- `test_arena_colisao_fixa`: as 369 formas de colisão são idênticas às de antes. Pontes, rochas e borda da cratera vêm só como visual e cobrem os cilindros e prismas do código.
- O fixture `game/test/fixtures/arena_colisao_f94.json` foi regravado só por causa dos marcadores, que mudaram por decisão do PI (65 → 69). Saíram os 2 baús de dentro da muralha, e entraram 2 baús de fora do muro e 4 esqueletos T1 de guarda.
- Testes: game 1777/1777, launcher 763/763.

## Rede e soak (aceite 4)

- `soak.ps1 -Count 50 -Parallel 8` deu `SOAK OK: 50/50 terminadas, todas <= 10:00, todas com vencedor`. Todas acabaram por kill_goal, com duração entre 351 e 485 s. As vitórias por lado foram 19 da A e 31 da B. O mapa é simétrico por rotação, e esse desvio não foi investigado neste card. Fica registrado para o F30 (balanceamento).
- `net-measure.ps1 -DelayMs 100 -Minutes 1`, 3 rodadas com o servidor em Docker já com a arena nova. Nas 3 deu zero `past the history limit`, zero `Node not found`, zero `Reference tick missing` e nenhum ERROR. O warm-up aqueceu 446 instâncias, entre 1,4 e 3,2 s.
- Nas rodadas 2 e 3, os 6 checkpoints dos dois clientes bateram com os do servidor. Na rodada 1, 5 bateram e 1 ficou sem par no cliente, sem nenhum diferente.
- Os logs ficaram em `logs/f95-soak/` e `logs/f95-net-{1,2,3}/`, fora do git.

## Decisões do PI na verificação (2026-10-21)

- Lava: as partículas quadradas viraram fumaça suave e brasas redondas.
- Herói no mato alto: fica translúcido com o próprio visual. Isso substitui a silhueta azul do F72.
- Fonte de cura: cortina de água contínua caindo da taça, no lugar das partículas de transbordamento.
- Baús: os 2 de dentro da muralha (perto do portão) foram para fora, no capim rente ao muro de fechamento, entre as torres. Cada um tem um esqueleto T1 de guarda. Monstros por metade passam de 17 para 19; no total, 34 → 38, mais o Rei Esqueleto.
- Monstros: nascem virados para quem chega e retomam essa rotação ao voltar para casa. Os de dentro da base olham para o portão. Os dos campos lateral e de canto olham para a boca do bolsão. Os do centro olham para o anel do rio.
- Moita de emboscada do corredor N: saiu de x −5 para −11,5, porque cobria o campo lateral Bot da base B.
- Ponte: o parapeito e os pilares ficam só sobre a água, para deixar livre a passagem entre a ponte e as torres do portão. A colisão não mudou.
- O tamanho da HUD virou pedido de "escala configurável", em card separado.
