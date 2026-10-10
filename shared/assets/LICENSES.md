# Licenças dos assets de `shared/assets/`

Todo asset de terceiro entra aqui com pack, autor, licença, origem e o que foi usado. Pack CC0 entra como vem (ADR-0005); escala e posição ficam nas cenas que o usam, conferidas em `_alignment.tscn` (PRD §11).

| Pasta | Pack | Autor | Licença | Origem | Arquivos usados |
|---|---|---|---|---|---|
| `kaykit/medieval_hexagon/` | KayKit Medieval Hexagon Pack 1.0 | Kay Lousberg | CC0 1.0 | github.com/KayKit-Game-Assets/KayKit-Medieval-Hexagon-Pack-1.0 | `hex_grass`, `hex_water`, `building_bridge_A`, `mountain_A`, `wall_straight`, `wall_straight_gate` (glTF) + `hexagons_medieval.png` |
| `kaykit/adventurers/` | KayKit Character Pack: Adventurers 1.0 | Kay Lousberg | CC0 1.0 | github.com/KayKit-Game-Assets/KayKit-Character-Pack-Adventures-1.0 | `Knight.glb` |
| `kaykit/adventurers2/` | KayKit Character Pack: Adventurers 2.0 (Free) | Kay Lousberg | CC0 1.0 | kaylousberg.itch.io/kaykit-adventurers (download Free 2.0, 2026-10-10) | `arrow_bow.gltf` + `.bin` + `ranger_texture.png`: flecha da Arqueira (F14) |
| `kaykit/skeletons/` | KayKit Character Pack: Skeletons 1.0 | Kay Lousberg | CC0 1.0 | github.com/KayKit-Game-Assets/KayKit-Character-Pack-Skeletons-1.0 | `Skeleton_Minion.glb`, `Skeleton_Warrior.glb`, `Skeleton_Mage.glb` |
| `kenney/music_jingles/` | Music Jingles | Kenney Vleugels (kenney.nl) | CC0 1.0 | kenney.nl/assets/music-jingles | `jingles_STEEL07.ogg`: som do aviso do boss aos 3:00 (F13, PI 2026-10-09) |

| `rrb/heroes/ranger.glb` | KayKit Adventurers 2.0 (Ranger, `bow_withString`) + animações do Knight do Adventurers 1.0, montados no Blender (ADR-0005) | Kay Lousberg | CC0 1.0 | fonte `art/heroes/ranger.blend`, gerada por `art/heroes/build_ranger.py` | Arqueira (F14): `Ranger.glb` como vem (rig de 23 ossos igual ao do Knight 1.0: mesmos nomes e pose de repouso), arco no `handslot.l`, 7 animações do `Knight.glb` (Idle, Running_A, Dodge_Forward, 2H_Ranged_Shoot, Spellcast_Shoot, Hit_B, Death_A). O pack 2.0 grátis não traz animação de tiro nem de esquiva |
| `rrb/arena/` | Arte própria (Blender, ADR-0005) | projeto rrb-godot | do projeto | fonte `art/arena/crater_props.blend` | `crater_pillar.glb`, `tall_grass_4x4.glb`, `tall_grass_4x3.glb` (cores do atlas KayKit embutido) |
| `rrb/monsters/` | "Lava Golem", adaptado no Blender (ADR-0005) | **vladimirmejia** (Blend Swap) | **CC-BY 3.0 — crédito obrigatório** | blendswap.com/blend/6023 (PI 2026-10-09); fonte adaptada `art/monsters/golem.blend` | `golem.glb`: malha original (1.142 triângulos), escalada a 2,5 u, faces planas, texturas de lava trocadas pela faixa cinza do atlas KayKit (Golem de Pedra) |
| `rrb/monsters/crown.glb` | Arte própria (Blender, ADR-0005) | projeto rrb-godot | do projeto | fonte `art/monsters/crown.blend` | `crown.glb`: coroa do Rei Esqueleto, 24 triângulos, faixa dourada do atlas KayKit embutido (F11) |

Cada pasta de pack guarda o `LICENSE.txt` original. Crédito não obrigatório: Kay Lousberg, www.kaylousberg.com; Kenney, www.kenney.nl.

**Crédito obrigatório (CC-BY):** Golem de Pedra baseado em "Lava Golem" de vladimirmejia (blendswap.com/blend/6023), CC-BY 3.0 — modificado (escala, faces planas, cores). Tem de aparecer nos créditos do jogo e do roadmap público.

- Roadmap público: feito (`docs/roadmap/historia.json` → `creditos`, F9).
- Créditos do jogo: **pendente** — ainda não há tela de créditos; entra na primeira que existir (registrado no F24 em `docs/DEVELOPMENT.md`, fatia a confirmar pelo Cowork). Build distribuída sem esse crédito descumpre a licença.

## Escalas de referência (`_alignment.tscn`)

| Asset | Escala | Por quê |
|---|---|---|
| Personagens KayKit (Knight, Ranger, esqueletos; flecha) | 0,78 | cabeça a 2,31 u no pack → ≈ 1,8 u (PRD §11) |
| Tiles hex | 1,5 | 2,0 u → 3,0 u face a face (SPEC-007 §1) |
| Muro, portão, ponte, rocha, montanha da borda | 1,5 × 2,27 × 1 · 2,5 · 4,1 × 1 × 3,9 · 1,5 · 2,2 | as da arena (`tools/arena/build_arena.gd`) |
| Pilar da cratera, moitas (`rrb/arena/`) | 1,0 | modelados em metros: pilar ≈ 3,4 × 3,0 u cobre a colisão r 1,4 × h 3,0; moitas 4 × 4 e 4 × 3 u (SPEC-034) |
| Rei Esqueleto (`Skeleton_Minion` + `crown.glb`) | 1,35 | ~2,9 u de crânio + coroa até ~3,2 u, maior que o Cavaleiro (F11); coroa no osso `head` (`test_boss.gd`) |
