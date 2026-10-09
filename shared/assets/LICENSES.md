# Licenças dos assets de `shared/assets/`

Todo asset de terceiro entra aqui com pack, autor, licença, origem e o que foi usado. Pack CC0 entra como vem (ADR-0005); escala e posição ficam nas cenas que o usam, conferidas em `_alignment.tscn` (PRD §11).

| Pasta | Pack | Autor | Licença | Origem | Arquivos usados |
|---|---|---|---|---|---|
| `kaykit/medieval_hexagon/` | KayKit Medieval Hexagon Pack 1.0 | Kay Lousberg | CC0 1.0 | github.com/KayKit-Game-Assets/KayKit-Medieval-Hexagon-Pack-1.0 | `hex_grass`, `hex_water`, `building_bridge_A`, `mountain_A`, `wall_straight`, `wall_straight_gate` (glTF) + `hexagons_medieval.png` |
| `kaykit/adventurers/` | KayKit Character Pack: Adventurers 1.0 | Kay Lousberg | CC0 1.0 | github.com/KayKit-Game-Assets/KayKit-Character-Pack-Adventures-1.0 | `Knight.glb` |
| `kaykit/skeletons/` | KayKit Character Pack: Skeletons 1.0 | Kay Lousberg | CC0 1.0 | github.com/KayKit-Game-Assets/KayKit-Character-Pack-Skeletons-1.0 | `Skeleton_Minion.glb` |

Cada pasta guarda o `LICENSE.txt` original do pack. Crédito não obrigatório: Kay Lousberg, www.kaylousberg.com.

## Escalas de referência (`_alignment.tscn`)

| Asset | Escala | Por quê |
|---|---|---|
| Personagens KayKit (Knight, esqueletos) | 0,78 | cabeça a 2,31 u no pack → ≈ 1,8 u (PRD §11) |
| Tiles hex | 1,5 | 2,0 u → 3,0 u face a face (SPEC-007 §1) |
| Muro, portão, ponte, rocha, montanha da borda | 1,5 × 2,27 × 1 · 2,5 · 4,1 × 1 × 3,9 · 1,5 · 2,2 | as da arena (`tools/arena/build_arena.gd`) |
