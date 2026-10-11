# SPEC-055 — Campos de canto: Golem de canto + 2 Lobos + 2 Baús Reforçados no bolso da curva TOP/BOT

**Fatia:** F55 / SPEC-055 (MVP2, Slice 2.21 — depois do F54, antes do F51) · **Issue:** #137 · **Status:** decidida pelo PI em 2026-10-11 (pop-ups: "Só campos e baús novos"; "São os campos de canto"; "Bolso dentro da curva"; "Intermediário"; "Golem atual + lobo no Blender"; "Golem + 2 lobos, sem item"; "Mover a moita da lagoa"; "Golem 4 u, lobos 3 u")
**ADR:** ADR-0011
**Supera:** SPEC-046 §2.7 (posição da moita de lagoa) e §3 (contagens). Mantém o resto da SPEC-046 (corredores livres, rotação de 180°, rio, bases, selva, centro).
**Fontes:** GDB §5.1, §5.2, §6.2 (números — vencem esta spec) · SPEC-046 · ADR-0005, ADR-0006 · `tools/arena/build_arena.gd` · `game/scripts/world/spawn_marker.gd`, `chest.gd` · `game/scripts/match/spawn_director.gd` · `game/scripts/core/chest_rules.gd`, `monster_rules.gd` · `shared/resources/monster_data.gd` · `shared/assets/rrb/monsters/golem.glb`

## 1. Motivo

O PI acha difícil matar o Rei Esqueleto (3:30) com o nível e a arma de hoje e decidiu **não mexer no boss**: em vez disso, campos novos pensados para herói de nível 4 a 7, com baú melhor, nos cantos livres do mapa. Os cantos NO e SE ficam sobre a diagonal do rio — os dois times chegam a eles pela própria rota (TOP ou BOT), sem ponte.

## 2. Posição (coordenadas da SPEC-046 §1)

| Elemento | Canto NO | Canto SE (rotação de 180°) |
|---|---|---|
| **Centro do campo** | `(−27,5, −27,5)` | `(27,5, 27,5)` |
| Golem de canto | centro | centro |
| Lobos (2) | centro ± `(1,41, −1,41)` → `(−26,1, −28,9)` e `(−28,9, −26,1)` | rotação |
| Baús Reforçados (2) | `(−25,0, −28,5)` e `(−28,5, −25,0)` | rotação |
| **Moita de lagoa (movida)** | de `(−30, −26)` para **`(−19, −29)`**, 4 × 4 u | de `(30, 26)` para **`(19, 29)`** |

Folgas medidas (centro do campo): lagoa NO (raio 5) 4,6 u; corredores O e N (SPEC-046 §2.3) 4,5 u; `r` ≈ 38,9 u (fora da zona desde 5:00). Moita nova: 1 u da banda do corredor N, 15,3 u do campo B-bot, 6 u da lagoa, 6,5 u do campo de canto. O Code pode ajustar cada posição em até ±1 u para o visual fechar, **mantendo** a rotação de 180°, as folgas mínimas abaixo e o asserto de corredor livre; registra os valores finais na entrega.

- Folgas mínimas: qualquer marcador do campo ≥ 2 u da borda da lagoa; colisor (baú, rocha) fora das bandas dos corredores; aggro dos lobos (3 u) a partir do ponto de spawn não alcança a banda do corredor; moita de lagoa fora da banda.

## 3. Conteúdo (GDB §5.1, §6.2)

| Item | Dados | Observações |
|---|---|---|
| **Golem de canto** | `shared/data/monsters/golem_corner.tres`: tier T3, HP 680, dano 50, área 2,5 u, 1,6 s, XP 190, **sem drop**, aggro 4 u, leash 10 u, velocidade 4,0, corpo a corpo 1,8 u | modelo `rrb/monsters/golem.glb` (CC-BY, já creditado); nome "Golem de Pedra (canto)" |
| **Lobo** | `shared/data/monsters/wolf_t2.tres`: tier T2, HP 300, dano 22, 0,9 s, XP 70, 20 % item comum, aggro 3 u, leash 10 u, velocidade 5,0, corpo a corpo 1,8 u | modelo novo (§4) |
| **Baú Reforçado** | `SpawnMarker.ChestKind.REINFORCED` (novo); rolagem 50 % Raro / 50 % Comum, sem épico, sem ouro/consumível; probabilidades em `match_pacing.tres` (ou no Resource que hoje guarda as do baú raro) | `ChestRules.roll` recebe o tipo do baú no lugar do `bool` de raro; regra de troca do F47 vale igual |

- Respawn de 90 s na fase 1 e nenhum na fase 2 (GDB §5) — sem regra nova.
- Bestiário em partida (F13, tecla `B`): entradas novas para Lobo e Golem de Pedra (canto).
- Neblina (F37) e replicação por peer: monstros e baús do canto seguem o filtro existente.

## 4. Arte (Blender — ADR-0005, ADR-0006)

- **Lobo:** arte própria, estilo KayKit (faces planas, cor pelo atlas `hexagons_medieval.png`), 500–3.000 triângulos, rig próprio de quadrúpede e animações `Idle`, `Run`, `Attack`, `Hit`, `Death` (`-loop` nas de laço). Fonte `art/monsters/wolf.blend` (+ script gerador, como o do F48); export `shared/assets/rrb/monsters/wolf.glb`. Silhueta conferida na distância da câmera do jogo; passa pela cena de alinhamento. É o item de arte mais caro do bloco do ADR-0011.
- **Baú Reforçado:** variação do baú do F44 (faixas e cantoneiras de metal, cor pelo atlas) — mesma colisão e mesma área de interação do baú comum. Fonte em `art/arena/`, export em `shared/assets/rrb/arena/`.
- Toon/outline pelo pós-import do F39. Entradas no `shared/assets/LICENSES.md`.

## 5. Implementação

- `tools/arena/build_arena.gd`: marcadores dos 2 campos de canto (§2) e moitas de lagoa nas posições novas; o asserto de corredor livre continua valendo. Regera `ilha_arcana.tscn` (edite o builder, não a cena).
- `spawn_marker.gd` / `spawn_director.gd` / `chest.gd` / `chest_rules.gd`: tipo `REINFORCED`.
- `art/arena/build_island.py`: só se o chão/enfeite da curva precisar abrir espaço para o campo (sem mudar o rio).
- Bot (`bot_rules.gd`/`BotInput`): campo de canto entra como alvo de farm pelos marcadores, como os laterais; sem estado novo na FSM.
- Minimapa/neblina: nada novo.

## 6. Contagens (substituem SPEC-046 §3)

| Zona | Monstros | Baús |
|---|---|---|
| Base A / B | 4 × T1 + 1 × Guerreiro T2 cada | 6 comuns cada |
| 4 campos laterais | 2 × T1 + 1 × Guerreiro T2 cada | 2 comuns cada |
| **2 campos de canto** | **1 × Golem de canto + 2 × Lobo cada** | **2 reforçados cada** |
| Centro | 2 × Guerreiro T2 + 2 × Mago T2 + 2 × Golem T3 | 4 raros |
| Cratera | Rei Esqueleto (3:30) | drop do boss |
| **Total** | **35** | **28** |

## 7. Critério de aceite

1. GUT: contagem de marcadores = §6 (35 monstros, 28 baús); simetria por rotação de 180° (todo marcador tem par em `(−x, −z)` com mesmo `kind`/`tier`/`chest_kind`).
2. GUT: corredor livre (SPEC-046 §6 item 7) continua verde com as moitas movidas e os baús novos; folgas mínimas do §2 conferidas na cena gerada.
3. GUT: `ChestRules` com `REINFORCED` — em 10.000 rolagens com seed fixa, 50 % ± 2 % raro, o resto comum, 0 épico, 0 ouro/consumível.
4. GUT: `wolf_t2.tres` e `golem_corner.tres` batem com o GDB §5.1; golem de canto não dropa item.
5. Integração: herói passando pelo meio do corredor N/O não puxa os lobos (aggro 3 u); entrando no campo, o golem acorda a 4 u; leash de 10 u devolve os monstros ao campo com HP cheio.
6. **Medição para o PI (registrada, não é limite):** nível do bot aos 3:30 em 3 partidas offline `--bot`, antes e depois do F55, e se o bot matou o Rei Esqueleto. Vai no comentário de encerramento.
7. 2 clientes contra servidor local: monstros e baús do canto replicados, sem `Node not found`.
8. Testes de F9–F13, F20, F32, F36, F37, F46, F47 continuam verdes.
9. Lint e CI verdes. Verificação visual do PI (lobo e suas animações, golem no canto, baú reforçado, moitas novas) + screenshot da vista de cima no roadmap (`tools/arena/snapshot_arena.gd`).

## 8. Fora desta spec

Mudar o Rei Esqueleto (decisão do PI em 2026-10-11: não muda); Golem do KayKit Skeletons Extra; Necromante; campos de canto nos cantos das bases; mudar a zona para cobrir os cantos (GDB §7.1); torres e ouro.
