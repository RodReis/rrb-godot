# Licenças dos assets de `shared/assets/`

Todo asset de terceiro entra aqui com pack, autor, licença, origem e o que foi usado. Pack CC0 entra como vem (ADR-0005); escala e posição ficam nas cenas que o usam, conferidas em `_alignment.tscn` (PRD §11).

| Pasta | Pack | Autor | Licença | Origem | Arquivos usados |
|---|---|---|---|---|---|
| `kaykit/medieval_hexagon/` | KayKit Medieval Hexagon Pack 1.0 | Kay Lousberg | CC0 1.0 | github.com/KayKit-Game-Assets/KayKit-Medieval-Hexagon-Pack-1.0 | `hex_grass`, `hex_water`, `building_bridge_A`, `mountain_A`, `wall_straight`, `wall_straight_gate` (glTF) + `hexagons_medieval.png` |
| `kaykit/adventurers/` | KayKit Character Pack: Adventurers 1.0 | Kay Lousberg | CC0 1.0 | github.com/KayKit-Game-Assets/KayKit-Character-Pack-Adventures-1.0 | `Knight.glb`; `Barbarian.glb` (Bárbaro, F53: como vem, rig e animações iguais aos do Knight) |
| `kaykit/adventurers2/` | KayKit Character Pack: Adventurers 2.0 (Free) | Kay Lousberg | CC0 1.0 | kaylousberg.itch.io/kaykit-adventurers (download Free 2.0, 2026-10-10) | `arrow_bow.gltf` + `.bin` + `ranger_texture.png`: flecha da Arqueira (F14) |
| `kaykit/skeletons/` | KayKit Character Pack: Skeletons 1.0 | Kay Lousberg | CC0 1.0 | github.com/KayKit-Game-Assets/KayKit-Character-Pack-Skeletons-1.0 | `Skeleton_Minion.glb`, `Skeleton_Warrior.glb`, `Skeleton_Mage.glb` |
| `ambientcg/` | ambientCG: Grass004, Ground037, Ground067, PavingStones138, Rock030, Bricks076C | Lennart Demes (ambientcg.com) | CC0 1.0 | ambientcg.com (download 2K-JPG, 2026-10-11) | cor, normal (GL) e rugosidade, recomprimidas (albedo 2048 px, normal e rugosidade 1024 px): terreno, castelo, rochas e pinheiros da Ilha (F40, PI 2026-10-11: realista e sombrio). Mapa por arquivo no `LICENSE.txt` da pasta |
| `kenney/music_jingles/` | Music Jingles | Kenney Vleugels (kenney.nl) | CC0 1.0 | kenney.nl/assets/music-jingles | `jingles_STEEL07.ogg`: som do aviso do boss aos 3:00 (F13, PI 2026-10-09) |

| `rrb/heroes/ranger.glb` | KayKit Adventurers 2.0 (Ranger, `bow_withString`) + animações do Knight do Adventurers 1.0, montados no Blender (ADR-0005) | Kay Lousberg | CC0 1.0 | fonte `art/heroes/ranger.blend`, gerada por `art/heroes/build_ranger.py` | Arqueira (F14): `Ranger.glb` como vem (rig de 23 ossos igual ao do Knight 1.0: mesmos nomes e pose de repouso), arco no `handslot.l`, 7 animações do `Knight.glb` (Idle, Running_A, Dodge_Forward, 2H_Ranged_Shoot, Spellcast_Shoot, Hit_B, Death_A). O pack 2.0 grátis não traz animação de tiro nem de esquiva |
| `rrb/arena/` | Arte própria (Blender, ADR-0005) | projeto rrb-godot | do projeto | fonte `art/arena/crater_props.blend` | `crater_pillar.glb`, `tall_grass_4x4.glb`, `tall_grass_4x3.glb` (cores do atlas KayKit embutido) |
| `rrb/arena/` (selva, F40) | Arte própria (Blender, ADR-0005) | projeto rrb-godot | do projeto | fonte `art/arena/jungle.blend`, gerada por `art/arena/build_island.py` | `rock_outcrop_a/b/c.glb` (1.280 triângulos), `pine_dark.glb` (280), `torch_post.glb` (82); textura pelos materiais triplanar com as texturas de `ambientcg/` |
| `rrb/monsters/` | "Lava Golem", adaptado no Blender (ADR-0005) | **vladimirmejia** (Blend Swap) | **CC-BY 3.0 — crédito obrigatório** | blendswap.com/blend/6023 (PI 2026-10-09); fonte adaptada `art/monsters/golem.blend` | `golem.glb`: malha original (1.142 triângulos), escalada a 2,5 u, faces planas, texturas de lava trocadas pela faixa cinza do atlas KayKit (Golem de Pedra) |
| `rrb/monsters/crown.glb` | Arte própria (Blender, ADR-0005) | projeto rrb-godot | do projeto | fonte `art/monsters/crown.blend` | `crown.glb`: coroa do Rei Esqueleto, 24 triângulos, faixa dourada do atlas KayKit embutido (F11) |
| `rrb/equipment/` (F48) | Arte própria (Blender, ADR-0005); armas derivadas do KayKit Adventurers (`1H_Sword` e `2H_Axe` do 1.0, `bow_withString` do 2.0) | projeto rrb-godot; armas: Kay Lousberg | do projeto; armas CC0 1.0 | fonte `art/heroes/equipment/equipment.blend`, gerada por `art/heroes/equipment/build_equipment.py` | 18 armaduras (Guarda e Caçador × elmo/peitoral/botas × 3 raridades, 112–426 triângulos) e 9 armas (espada, arco e machado `2H_Axe` do `Barbarian.glb` — F53 — × 3 raridades, 300–736; a comum é a peça do pack como vem), modeladas no espaço do herói em pose de repouso e presas aos ossos pelo `HeroVisual`; cor pelo atlas `hexagons_medieval` embutido + material liso `PURPLE` no detalhe épico. Ícones em `shared/ui/icons/items/` renderizados das mesmas peças |
| `rrb/arena/megakit_*.glb` (F50) | Medieval Village MegaKit (Standard, grátis), peças compostas no Blender (ADR-0005) | Quaternius (quaternius.com) | CC0 1.0 | store.godotengine.org/asset/quaternius/medieval-village-megakit (download 2026-10-11; pack não versionado, 161 MB); fonte `art/arena/megakit_patio.blend`, gerada por `art/arena/build_megakit.py`; licença em `art/arena/LICENSE_megakit.txt` | `megakit_house_long.glb` (casa de 2 andares, 8.794 triângulos), `megakit_house_small.glb` (casinha, 4.591), `megakit_yard_corner.glb` (carroça, caixotes, cerca e tijolos, 2.996): peças e materiais como vêm, malha juntada por material, texturas reduzidas a 1024 px em JPEG (extraídas pelo import como `megakit_*_T_*.jpg`) |

Cada pasta de pack guarda o `LICENSE.txt` original. Crédito não obrigatório: Kay Lousberg, www.kaylousberg.com; Kenney, www.kenney.nl; Quaternius, quaternius.com.

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
| Construções do MegaKit (`rrb/arena/megakit_*.glb`) | 1,0 | pack em metros: andar de 3,12 u e porta de 2,35 u para o herói de ~1,8 u (F50) |
| Rei Esqueleto (`Skeleton_Minion` + `crown.glb`) | 1,35 | ~2,9 u de crânio + coroa até ~3,2 u, maior que o Cavaleiro (F11); coroa no osso `head` (`test_boss.gd`) |
