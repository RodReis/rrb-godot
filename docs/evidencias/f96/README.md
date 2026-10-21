# F96 / SPEC-096 — Arena nova, parte 3: borda da ilha e vale

Evidência de aceite (issue #268, ADR-0030). As imagens põem o antes (`main` `1ef5086`, com as bases do F94 e o meio do F95) à esquerda e o depois à direita, com a mesma câmera, seed 38 e a mesma luz (`tools/perf/scenery_capture.gd --poses=borda`).

## Capturas (aceite 1 e 4)

| Arquivo | O que mostra |
|---|---|
| `torre.webp` | torre de vigia com a escada virada para a arena, tocha e floresta da borda |
| `balista.webp` | balista e cavalo-de-frisa no lado N |
| `frisa.webp` | cavalo-de-frisa e tocha |
| `cristal.webp`, `floresta.webp` | cristal do kit, tochas e floresta de cartões |
| `cascata.webp` | poça do canto NO com cantaria, vertedouro e cortina d'água caindo no riacho do vale, com pedras e juncos na margem |
| `bastiao.webp` | bastião NO visto de cima: borda, poça e riacho |
| `vale.webp` | floresta do vale (`kit_pine_far`) e encostas |
| `aberta.webp` | visão aberta da ilha e do vale, como na cinemática de abertura |

## Frame time (aceite 4)

Medido com `tools/perf/frametime_probe.gd` em 1920x1080 (RTX 5060, Vulkan). As rodadas alternam antes e depois; o "antes" roda num worktree da `main` com a mesma sonda. A opção nova `--intro` mede a cinemática de abertura (F69) do nascimento dos heróis até 5 s, sem aquecimento. Os JSONs estão nesta pasta (`<cenário>_<antes|depois>_<rodada>.json`).

| Cenário | Antes GPU média (ms) | Depois GPU média (ms) | Delta |
|---|---|---|---|
| Borda O: herói ao lado da torre de vigia (`--at=-37,-9`), 3 rodadas | 3,651 / 3,875 / 3,840 → **3,789** | 3,840 / 3,869 / 3,873 → **3,861** | +0,07 ms |
| Canto NO: herói perto da poça e da cascata (`--at=-36,-36`), 3 rodadas | 3,721 / 4,032 / 3,960 → **3,905** | 3,798 / 4,009 / 3,936 → **3,914** | +0,01 ms |
| Cinemática de abertura (`--intro`), 3 rodadas | 3,923 / 3,961 / 3,947 → **3,944** | 4,016 / 4,025 / 4,020 → **4,020** | +0,08 ms |

Os três deltas ficam muito abaixo do teto de +4 ms do bloco visual (ADR-0006 item 7). A CPU fica em 16,7 ms nos dois casos, presa nos 60 quadros por segundo. A floresta do vale (2.115 árvores) usa o `kit_pine_far`, de 280 triângulos (o pinheiro antigo tinha 132), num MultiMesh por tile de 40 u, sem sombra e fora do bake.

## Colisão e testes (aceite 2)

- `test_arena_colisao_fixa`: colisão, marcadores e navmesh iguais à fixture do F94/F95. A borda, a cantaria, a cortina e a margem do riacho são só visual; `test_arena_rim` prova que a `RimDecor` não tem colisão e `test_arena_valley` prova o mesmo para o vale.
- Testes: game 1786/1786, launcher 763/763.

## Rede e soak (aceite 3)

- `soak.ps1 -Count 50 -Parallel 8` deu `SOAK OK: 50/50 terminadas, todas <= 10:00, todas com vencedor`.
- `net-measure.ps1 -DelayMs 100 -Minutes 1`, 3 rodadas com o servidor em Docker já com a arena nova:
  - zero `past the history limit`, zero `Node not found` e nenhum ERROR nas 3;
  - warm-up de 446 instâncias, entre 1,4 e 1,6 s;
  - checkpoints: 6/6 iguais ao servidor nos dois clientes das 3 rodadas.
- Na rodada 2, o cliente 1 registrou 4 avisos `DiffHistoryEncoder: Reference tick missing` no tick ~1150, sem perda configurada. O remoto não congelou (0% parado) e os checkpoints bateram. A VM do Docker estava dividida com outra pilha (1,5 GB livres); é o caso já registrado em `APRENDIZADOS.md` (diff states sem referência).
- Os logs ficaram em `soak-report/`, `logs/f96-net-{1,2,3}/` e `logs/f96/`, fora do git.

## Verificação do PI

Aprovada em 2026-10-21, numa partida `--offline --bot` com borda, cascata, vale e cinemática de abertura. A partida rodou até o fim sem ERROR no log.
