# SPEC-044 — Arena "Ilha Flutuante Arcana": novo layout (espelho N–S, rio N–S + anel, 4 pontes)

**Fatia:** F44 / SPEC-044 (MVP2, Slice 2.11 — entra **antes do F36**) · **Issue:** a criar · **Status:** aprovada pelo PI em 2026-10-10 (topologia proposta pelo Cowork sobre o doc `docs/prd/especificacao_reforma_arena_godot_blender.md` e a imagem `docs/prd/telas/Arena & Mapa…/full_high_resolution_panoramic…png`)
**Supera:** SPEC-007 §2 (topologia), §3 (posições), §6 itens 1, 2 e 6. Mantém SPEC-007 §1 (escala, coordenadas, velocidade de referência), §4 (marcadores) e a regra "edite o builder, não a cena".
**Fontes:** PRD §3.1, §3.2 · GDB §5.1, §6.2, §7.1 · ADR-0007 (decisão de layout) · `CONVENTION.md` §4.1, §4.7
**Escopo desta fatia:** **greybox jogável** — builder, colisão, marcadores, portões, mato (geometria), navmesh, aceite por medidas. **Sem arte nova**: continua com hexes KayKit, rio e pontes do pack. A arte da ilha (castelos, abismo, magma, cristais, skybox, cachoeiras) é o **F40** (MVP3, bloco visual).

## 1. Sistema de coordenadas e escala — inalterado (SPEC-007 §1)

Origem no centro da cratera; `+X` leste, `−Z` norte; plano `Y = 0`, **sem relevo** (pontes planas; cratera plana). Azimute anti-horário a partir do norte (N 0°, O 90°, S 180°, L 270°). Tile 3,0 u face a face. Arena jogável = círculo de raio **35 u**, tiles até 36,5 u; fora, borda intransponível (visual: abismo — F40). Velocidade de referência 5,8 u/s.

## 2. Topologia (vista de cima)

```
                          N (−Z)
        ┌────────────────────╥────────────────────┐
        │   BASE A (NO)      ║      BASE B (NE)   │   ║ rio de mana N–S (bloqueia; projétil passa)
        │   spawn (−24,−24)  ║   spawn (+24,−24)  │   ○ anel do rio 14 < r ≤ 18 u
        │   portão A (−15,−15)║ portão B (+15,−15)│   = ponte (4), nos azimutes 45°, 135°, 225°, 315°
        │     ↘   =NO      ○○○○○      NE=   ↙     │   ● pilar da cratera (8), entradas alinhadas às pontes
   O    │ campo O       ○ ●  ●  ● ○       campo L │    L
 (−X)   │ (F36)        ○ ●  (0,0)  ● ○     (F36)  │  (+X)
        │               ○ ●  ●  ● ○               │
        │ campo SO  =SO    ○○○○○    SE=  campo SE │
        │ (F36)              ║              (F36) │
        │                    ║                    │
        └────────────────────╨────────────────────┘
                          S (+Z)
```

**Simetria por espelho no eixo N–S:** tudo o que vale para A em `(x, z)` vale para B em `(−x, z)`. (SPEC-007 usava rotação de 180°.)

| Elemento | Posição / forma | Observações |
|---|---|---|
| **Cratera (boss pit)** | disco raio **6 u** no centro, chão plano | boss em `(0,0)` aos 3:30 (inalterado) |
| **Pilares da cratera** | 8 pilares no anel `r = 6 u`, **4 entradas** de 4 u nos azimutes **45°, 135°, 225°, 315°** | inalterado; entradas agora coincidem com as 4 pontes |
| **Anel central (ilha)** | coroa `6 u < r ≤ 14 u` | estrada de 8 u; conteúdo do centro (§3) |
| **Rio — anel** | coroa `14 u < r ≤ 18 u` | bloqueia movimento; projétil atravessa |
| **Rio — canal N–S** | banda `|x| ≤ 2 u` para `r > 18 u`, do anel até a borda, **norte e sul** | separa as metades A (`x < 0`) e B (`x > 0`); onde toca a borda (N e S) nascem as cachoeiras (F40) |
| **Pontes (4)** | sobre o anel, centradas em `r = 16 u` nos azimutes 45° (NO), 135° (SO), 225° (SE), 315° (NE); eixo radial; largura nominal 4 u (efetiva ≈ 5 u) | **2 por metade**: NO e SO são da metade A; NE e SE da metade B. Entre metades só pela ilha central |
| **Metade A** | `x < −2` fora do anel | Base A + pátio A + campos O e SO |
| **Metade B** | `x > +2` | espelho |
| **Base A** | região da metade A a ≤ **12,7 u** do spawn A `(−24, −24)`, fechada por **muro em arco** com **portão** centrado em `(−15, −15)` (largura 5 u) voltado para a ponte NO | fase 1 só o time A passa; portão cai aos 5:00 (inalterado) |
| **Pátio A** | faixa entre o portão A e a ponte NO `(−11,3, −11,3)` | neutro; emboscada agora disputa 2 pontes por metade |
| **Spawn A** | `(−24, −24)`, olhando para o centro; distância ao centro 33,9 u (= SPEC-007) | respawn fase 1 e 2 |
| **Muros/rochas** | 3 segmentos por base (quebram linha reta spawn→portão) + 2 rochas por metade no pátio + 4 rochas no anel central entre os campos | bloqueiam tudo; altura ≥ 2 u |
| **Mato alto** | 1 moita 4×4 u ao lado de cada ponte, lado de fora (4) + 2 no anel central nos azimutes 90° e 270°, `r ≈ 12 u` (4×3 u) | geometria (`Area3D` grupo `tall_grass`); regra = F32 |
| **Borda** | `r > 35 u` | intransponível; abismo (F40) |

## 3. Conteúdo por zona

As contagens de base e centro seguem o GDB §5.1/§6.2 como na SPEC-007 §3; as dos **campos laterais** são do F36 (esta spec só reserva o lugar).

| Zona | Monstros | Baús | Posição |
|---|---|---|---|
| Base A / B | 4 × Esqueleto T1 + 1 × Guerreiro T2 | 6 comuns | como SPEC-007 §3, espelhado em `x` |
| **Campos laterais** (F36) | 2 × T1 + 1 × T2 cada | 2 comuns cada | **O** `(−26, 0)` e **SO** `(−16, +24)` na metade A; **L** `(+26, 0)` e **SE** `(+16, +24)` na metade B — F36 ajusta as coordenadas dentro da metade |
| Anel central | 1 × Guerreiro T2 + 1 × Mago T2 + 1 × Golem T3 no **campo Norte** (azimute 0°, `r ≈ 10 u`) e o mesmo no **campo Sul** (180°) | 4 raros: 1 por campo + 1 em cada lado do anel (azimutes 90° e 270°, `r ≈ 8 u`) | os dois campos ficam sobre o eixo de espelho: **equidistantes das 4 pontes e dos dois times** |
| Cratera | Rei Esqueleto aos 3:30 | drop do boss | `(0,0)` |

## 4. Marcadores — inalterado (SPEC-007 §4)

`SpawnMarker` por `kind/team/tier`; `SpawnDirector` só lê marcadores; nenhuma posição em código. Portões `gate.tscn` por time.

## 5. Implementação

- `tools/arena/build_arena.gd`: trocar a simetria (função de espelho em vez de rotação), `AXIS_A`/`LATERAL` pelos eixos das 4 pontes, canal do rio N–S (`|x| ≤ 2`, `r > 18`), `SPAWN`/`GATE` nos cantos norte, mato e campos do centro em 0°/180°. Medidas da spec = constantes do builder. Regerar `arena.tscn`.
- `ArenaNav`: nada a mudar (assa em runtime dos colisores); conferir que o bot cruza as 4 pontes.
- `bot_rules.gd` / `bot_input.gd`: se houver referência a "a ponte" do time, passa a escolher a ponte mais próxima; sem mudança de FSM.
- Roadmap: screenshot da vista de cima (greybox) na mesma PR.

## 6. Critério de aceite do F44

1. Medidas com a cápsula a 5,8 u/s: spawn A → centro **6,3 s ± 10 %** (= SPEC-007); spawn A → spawn B pela ilha **medido e registrado** (previsão ≈ 10,5 s; passa a ser o valor de referência, substituindo 12,7 s).
2. Rio não atravessável a pé em nenhum ponto exceto pelas **4 pontes** (autopilot em 12 pontos — 0 sucessos fora das pontes). Entre a metade A e a B só pela ilha central (autopilot tentando cruzar o canal N e S — 0 sucessos).
3. Portão: time A passa, B não; aos 5:00 ambos (GUT + roteiro) — inalterado.
4. Contagem de marcadores de base e centro = §3 (GUT); os 4 campos laterais ficam com marcador **vazio reservado** (`kind` definido no F36).
5. Flecha de 0,3 u não passa entre pilares; passa pelas 4 entradas — inalterado.
6. **Simetria de espelho:** para cada marcador em `(x, z)` existe o espelho em `(−x, z)` com mesmo `kind`/`tier` (GUT, substitui o teste de rotação).
7. Arena idêntica em servidor e cliente.
8. Bot (F12) completa a fase 1 offline no novo layout: farma a base, atravessa uma ponte e contesta o centro, sem travar (3 partidas offline `--bot`).
9. Testes existentes de F7/F9–F13 continuam verdes (a cena muda, as regras não).

## 7. Fora desta spec

Toda a arte (F40: ilha, abismo, castelos, magma, cristais, skybox, cachoeiras, ilhotas, torres/balistas como enfeite sem colisão). Regra do mato (F32), neblina (F37), economia de campo (F36). Relevo e degraus (continuam excluídos). Torres/balistas com função (excluídas — decisão do PI 2026-10-10: só enfeite).
