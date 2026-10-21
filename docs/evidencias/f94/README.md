# F94 / SPEC-094 — Arte nova nas bases A e B da arena oficial

Evidência de aceite (issue #266, ADR-0030). Nas imagens, a arena **antes** (`main` `5d50c8e`) está à esquerda e **depois** (este card) à direita, com a mesma câmera, seed 38 e luz forçada.

## Frame time (aceite 5)

Medido com `tools/perf/frametime_probe.gd` em 1920x1080, RTX 5060, Vulkan. As rodadas alternam antes e depois; o "antes" roda num worktree da `main`. Os JSONs estão nesta pasta.

| Cenário | Antes GPU média (ms) | Depois GPU média (ms) | Delta |
|---|---|---|---|
| Spawn A, herói parado (3 rodadas) | 3,628 / 3,636 / 3,638 → **3,634** | 3,803 / 3,813 / 3,812 → **3,809** | +0,18 ms (+4,8 %) |
| Partida com o herói jogado pelo bot (`--autopilot=bot`, 2 rodadas; passa pelas duas metades) | 3,691 / 3,648 → **3,670** | 3,878 / 3,876 → **3,877** | +0,21 ms (+5,6 %) |

O delta fica bem abaixo do teto de +4 ms do bloco visual (ADR-0006 item 7). A CPU fica em 16,74 ms nos dois casos, preso nos 60 quadros por segundo. A base B não teve medição isolada (o herói local nasce na A), mas usa as mesmas peças em rotação e entra na medição da partida com autopilot.

## Capturas (aceite 5)

| Arquivo | O que mostra |
|---|---|
| `jogo_11u.webp` | câmera do jogo no spawn A |
| `mapa_autopilot.webp` | quadro do meio da medição com autopilot |
| `close_*.webp` | portão, fonte, casa, pátio e torreão de dia (`scenery_capture.gd --poses=base`) |
| `noite_*.webp` | os mesmos closes à noite |

## Achado para o PI

À noite, a base nova fica bem mais clara que a antiga (veja os `noite_*.webp`). A pedra e o calçamento do kit têm albedo alto, e o indireto do lightmap é assado com céu neutro e não muda com o ciclo. A antiga escurecia porque a pedra dela era escura. Se o PI quiser a noite mais fechada, um ajuste possível é escurecer o albedo do kit ou bakear o indireto com menos energia. Isso fica para a decisão dele na verificação.

## Rede e soak (aceites 3 e 4)

- `soak.ps1 -Count 50 -Parallel 8`: `SOAK OK: 50/50 terminadas, todas <= 10:00, todas com vencedor`.
- `net-measure.ps1 -DelayMs 100 -Minutes 1`, 3 rodadas, com o servidor em Docker já com a arena nova: nas 3, zero `past the history limit`, zero `Node not found` e zero `Reference tick missing`, nenhum ERROR, e os 6 checkpoints dos dois clientes iguais aos do servidor. Os logs ficaram em `logs/f94-net-{1,2,3}/`, fora do git.

## Colisão e testes (aceites 2 e 3)

- `test_arena_colisao_fixa`: as 369 formas de colisão (caminho, tipo, tamanho e transform global) e os 65 marcadores são idênticos ao fixture gravado antes da arte nova (`game/test/fixtures/arena_colisao_f94.json`, gerado por `tools/arena/collision_fixture.gd`). O kit não traz colisão.
- Os testes de arena foram atualizados para o kit, incluindo o tecido do time (ciano na A, dourado na B).
