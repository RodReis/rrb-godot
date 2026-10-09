# SPEC-007 — Arena "Vale Rúnico": layout, escala, zonas e marcadores

**Fatia:** F7 / SPEC-007 (MVP1, Slice 1.2) · **Issue:** #19 · **Status:** aprovada pelo PI em 2026-10-09
**Fontes:** PRD §3.1, §3.2, §5, §11 · GDB §5.1, §6.2, §7.1 · conceito `docs/prd/telas/Arena & Mapa — O Vale Rúnico Apocalíptico/` (imagem tática) · referências Astro Arena / Brawl Stars (análise em `STATUS-ARQUIVO.md` 2026-10-09)
**Decisões do PI (2026-10-09):** escala pelo GDB (raio 35 u); rio bloqueia e só se cruza por 2 pontes; bloqueios = muros/rochas + pilares da cratera + mato alto; cratera plana; **sem** torres, ouro, aura do boss, orbes de XP, fog of war, lama, relevo.

## 1. Sistema de coordenadas e escala

- Origem `(0, 0, 0)` no centro da cratera. `+X` = leste, `−Z` = norte (padrão Godot). Plano `Y = 0`, **sem relevo**.
- Tile hexagonal KayKit Medieval Hexagon com **3,0 u de face a face** (o Code mede o tile do pack e ajusta a escala da cena para 3,0 u; orientação do hexágono = a do pack).
- Grade 24 × 18 tiles ≈ 72 × 54 u. **Arena jogável** = círculo de raio **35 u** (= raio inicial da zona, GDB §7.1); fora dele, borda intransponível (muro/abismo visual).
- Velocidade de referência 5,8 u/s (Cavaleiro, GDB §4.1): spawn → centro ≈ 37 u ≈ **6,3 s**; spawn → spawn ≈ 73 u ≈ **12,7 s**. (Substitui os "~8 s / ~20 s" do PRD §3.1 — ver `RASTREABILIDADE.md` P-02.)

## 2. Topologia (vista de cima)

```
                 N (−Z)
        ╔═══════════════════════════╗
        ║  rio ░░░░░░░░░░           ║
        ║ ░░░░░        ┌──────┐  ▓▓ ║        ░ rio de plasma (bloqueia)
        ║ ░░░   mato   │BASE B│ ▓▓▓ ║        ▓ muro / rocha (bloqueia tudo)
        ║ ░░      ╭────┤ NE   │▓▓   ║        ● pilar da cratera (bloqueia projétil e andar)
        ║  ░░   ╭─┴─╮  └──┬───┘     ║        = ponte
   O    ║   ░░  │ ● ● │ pB│ portão B║    L   ≈ mato alto (esconde — regra em F32)
 (−X)   ║ ▓▓ ░░ │●  ●│═══╯          ║  (+X)
        ║ ▓▓▓═══│ ● ● │ ░░   ≈≈     ║
        ║ portão│pA ╰─┬─╯  ░░░      ║
        ║ A  ┌──┴───┐  ░░░░  mato   ║
        ║    │BASE A│    ░░░░░░░    ║
        ║ ≈≈ │ SO   │       ░░░░░░  ║
        ╚═══════════════════════════╝
                 S (+Z)
```

Simetria **por rotação de 180°** em torno da origem: tudo o que vale para a Base A em `(x, z)` vale para a Base B em `(−x, −z)`.

| Elemento | Posição / forma | Observações |
|---|---|---|
| **Cratera (boss pit)** | disco raio **6 u** no centro | chão plano; boss nasce em `(0,0)` aos 3:30 |
| **Pilares da cratera** | 8 pilares de rocha no anel `r = 6 u`, deixando **4 entradas** de 4 u nos azimutes 45°, 135°, 225°, 315° | bloqueiam andar e projétil; a flecha (raio 0,3 u) não passa entre pilares |
| **Anel central (ilha)** | coroa `6 u < r ≤ 14 u` | estrada de 8 u; aqui ficam os monstros e baús do centro (§3) |
| **Rio de plasma** | banda de **4 u** ao longo da diagonal `x = z` (NO → SE), que se abre e contorna a ilha pela coroa `14 u < r ≤ 18 u` | **bloqueia movimento** (colisão); projétil atravessa; visual = plasma KayKit/shader |
| **Ponte A** | sobre o rio, centrada em `(−11, +11)`, eixo apontando para a Base A, largura 4 u | única travessia da metade A para a ilha |
| **Ponte B** | `(+11, −11)` | única travessia da metade B |
| **Metade A** | semiplano `x < z` fora da ilha/rio | contém a Base A e o pátio A |
| **Metade B** | `x > z` | idem |
| **Base A** | região da metade A com distância ≤ **16 u** do spawn A `(−26, +26)`, fechada por um **muro em arco** com um **portão** centrado em `(−15, +15)` (sobre o arco) (largura 5 u) voltado para a ponte A | fase 1: só o time A passa pelo portão; portão cai aos 5:00 (sinal `gates_fallen`) |
| **Pátio A** | faixa entre o portão A `(−15,+15)` e a ponte A `(−11,+11)` | neutro, sem conteúdo; é onde quem sai da base pode ser esperado |
| **Spawn do herói A** | `(−26, +26)`, olhando para o centro | respawn na fase 1 e 2 (enquanto ativo) |
| **Muros/rochas** | 3 segmentos por base (quebram linha reta spawn→portão) + 2 rochas por metade no pátio + 4 rochas no anel central entre os campos de monstros | bloqueiam tudo; altura ≥ 2 u para a câmera ler como parede |
| **Mato alto** | 2 moitas por metade (uma ao lado de cada ponte, no lado de fora, 4×4 u) + 2 no anel central (nos azimutes 90° e 270°, 4×3 u) | F7 entrega só a geometria (`Area3D` grupo `tall_grass`); a regra de esconder é **F32** (MVP2) |
| **Borda da arena** | anel `r > 35 u` | intransponível; visual: destroços/abismo |

## 3. Conteúdo por zona (contagens do GDB)

| Zona | Monstros (GDB §5.1) | Baús (GDB §6.2) | Posição |
|---|---|---|---|
| Base A | 4 × Esqueleto T1 + 1 × Esqueleto Guerreiro T2 | 6 comuns | T1 em arco a 6–10 u do spawn; Guerreiro perto do portão (a 4 u dele, dentro); baús espalhados, nenhum a < 3 u de outro, 2 deles atrás de muro |
| Base B | idem, espelhado | idem | rotação 180° |
| Anel central | 1 × Guerreiro T2 + 1 × Mago T2 + 1 × Golem T3 no **campo Norte** (azimute ~0°, `r ≈ 10 u`) e o mesmo no **campo Sul** (~180°) | 4 raros: 1 por campo + 1 em cada entrada lateral da cratera (azimutes 90° e 270°, `r ≈ 8 u`) | os dois campos ficam **equidistantes das duas pontes** (ponte A em 135°, ponte B em 315°) — nenhum time chega primeiro |
| Cratera | Rei Esqueleto (boss) aos 3:30 | drop do boss | `(0,0)` |

Totais: 10 monstros de base + 6 do centro + 1 boss = **17** (GDB: 8 + 4 + 2 + 2 + 1 ✓); **12 + 4 = 16 baús** ✓.

## 4. Marcadores (`SpawnMarker`)

`Marker3D` com script `spawn_marker.gd` (`@export var kind: Kind` ∈ {HERO, MONSTER, CHEST, BOSS}; `@export var team: int` (0 = neutro, 1 = A, 2 = B); `@export var tier: int`; `@export var monster_id: StringName`; `@export var chest_kind: ChestKind` ∈ {COMMON, RARE}). O `SpawnDirector` (F9/F10/F11) só lê marcadores; **nenhuma posição em código**.

Portão: `gate.tscn` com `@export var team: int`; colisão por layer (`team_a_only` / `team_b_only`) até `gates_fallen`.

## 5. Direção de arte (não normativo para F7, vale para F31/F8)

Base A = "Ordem" (pedra + condutos `CYAN`); Base B = "Ruína" (ferro + plasma `GOLD`/laranja). Rio e cratera com emissivo; o restante flat (PRD §11). O conceito em `docs/prd/telas/Arena & Mapa…` é referência de clima, **não de layout** (as duas imagens divergem; vale a imagem tática).

## 6. Critério de aceite do F7

1. Medidas com a cápsula a 5,8 u/s: spawn A → centro **6,3 s ± 10 %**; spawn A → spawn B **12,7 s ± 10 %** (saída real do roteiro).
2. Rio não atravessável a pé em nenhum ponto exceto pelas 2 pontes (teste: autopilot tentando cruzar em 8 pontos — 0 sucessos fora das pontes).
3. Portão: time A passa, time B não; aos 5:00 ambos passam (GUT na regra + roteiro).
4. Contagem de marcadores = §3 (teste GUT que carrega `arena.tscn` e conta por `kind`/`team`).
5. Flecha de 0,3 u não passa entre pilares; passa pelas 4 entradas (teste de raycast).
6. Simetria: para cada marcador em `(x, z)` existe o espelho em `(−x, −z)` com mesmo `kind`/`tier` (teste GUT).
7. Arena idêntica em servidor e cliente (mesma cena; sem RNG).

## 7. Fora desta spec

Torres, ouro, "Aura do Flagelo", orbes de XP, fog of war, lama/lentidão, relevo da cratera, tier lendário (`FORA-DE-ESCOPO.md`, 2026-10-09). Regra de visibilidade do mato (F32).
