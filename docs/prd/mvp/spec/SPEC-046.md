# SPEC-046 — Arena "Rift Medieval adaptado": relayout da Ilha (borda quadrada, rio em S NO–SE, 3 rotas, selva nos quadrantes)

**Fatia:** F46 / SPEC-046 (MVP2, Slice 2.12 — entra **logo depois do F44 e antes do F19**) · **Issue:** #110 · **Status:** aprovada pelo PI em 2026-10-10 (4 pontos do PI + 4 decisões em pop-up, registradas no ADR-0009)
**Supera:** SPEC-044 §1 (forma e tamanho da arena), §2 (topologia e posições), §3 (posições do centro e dos campos), §6 itens 1, 2, 4, 6 e 11 (medidas). Mantém SPEC-044 §4 (marcadores), §5 (builder gera a cena; "edite o builder, não a cena") e toda a arte do F40 entregue no F44 (kits Blender, shaders, baú).
**Fontes:** PRD §3.1, §3.2 · GDB §5.1, §6.2, §7.1 (inalterados) · ADR-0009 (decisão de layout) · imagem tática `docs/prd/telas/Arena & Mapa — O Vale Rúnico Apocalíptico/tactical_overview_battleground_map_view_of_a_futuristic_medieval_apocalyptic.png` · `CONVENTION.md` §4.1, §4.7
**Escopo desta fatia:** relayout **jogável com a arte atual** — borda quadrada, rio novo, posições novas do builder, chassi da ilha regerado no Blender (`art/arena/build_island.py`), colisão, marcadores, navmesh, aceite por medidas. **Nenhum kit novo**: castelo modular, pontes de pedra, pilares, cristais, pinheiros, torre de vigia, balista, baú e os 4 shaders são os do F44, reposicionados.

## 1. Sistema de coordenadas e escala

Origem no centro da cratera; `+X` leste, `−Z` norte; plano `Y = 0`, **sem relevo**. Azimute anti-horário a partir do norte (N 0°, O 90°, S 180°, L 270°). Velocidade de referência 5,8 u/s.

- **Arena jogável = quadrado** `|x| ≤ 40 u` e `|z| ≤ 40 u` (80 × 80 u). Fora, borda intransponível: 4 muros retos (espessura 2 u, altura 4 u) em `|x| = 41` e `|z| = 41`; visual = beira da ilha + abismo (chassi regerado, §5).
- **Zona (GDB §7.1) não muda:** círculo de raio 35 u (100 %) inscrito no quadrado, centrado em `(0,0)`. Os cantos (`r` até 56,6 u) ficam **fora da zona desde 5:00** — decisão do PI: os spawns ficam a ≤ 35 u (§2), o resto do canto é castelo e enfeite.
- **Simetria por rotação de 180°** em torno de `(0,0)`: tudo o que vale para A em `(x, z)` vale para B em `(−x, −z)`. (Substitui o espelho em `x` da SPEC-044; volta ao modelo da SPEC-007.)
- Base A no canto **SO** (`x < 0`, `z > 0`); base B no canto **NE**. Rio em S na diagonal **NO–SE** separa a metade A (`z > x`) da metade B (`z < x`).

## 2. Topologia (vista de cima)

```
 (−40,−40)                      N (−Z)                        (40,−40)
   ┌──────────────────────────────────────────────┬──────┐
   │  TOP (N) ─────────────────────────────── 8 u │ BASE │
   │ T  ⌒ lagoa NO (−26,−18)   campo B-bot (−4,−26)│  B   │   ⌒  rio: lagoa → braço em arco → anel 14–18 → braço → lagoa
   │ O   ⌒ braço NO            ╱ MID (NE→SO)       │ (24,−24)
   │ P      ⌒⌒ ○○○○○      ╱   campo B-top (26,4)   │   ○  anel do rio (bloqueia; projétil passa)
   │ (W)  ○ ●  ●  ● ○ ═ ponte NE (315°)           │   ●  pilares da cratera (8), 4 entradas (45/135/225/315)
   │ 8 u  ○ ●  (0,0)  ● ○                          │   ═  ponte (2): só na MID, azimutes 135° (SO) e 315° (NE)
   │      ○ ●  ●  ● ○                              │
   │ campo A-top (−26,−4)  ═ ponte SO (135°)       │
   │          ╱ MID        ○○○○○  ⌒⌒               │
   │ BASE   ╱       campo A-bot (4,26)   braço SE ⌒ │ B
   │  A  ╱                       lagoa SE (26,18) ⌒│ O
   │(−24,24)│ BOT (S) ───────────────────── 8 u    │ T (E) 8 u
   └────────┴──────────────────────────────────────┴──────┘
 (−40,40)                        S (+Z)                        (40,40)
```

### 2.1 Rio (bloqueia movimento; projétil atravessa)

| Trecho | Forma | Observações |
|---|---|---|
| **Anel** | coroa `14 u < r ≤ 18 u` em torno da cratera | igual à SPEC-044; a cratera é uma **ilha no meio do S** |
| **Braço NO** | faixa de 4 u de largura ao longo de um **arco de círculo** de centro `(−22,5, −6,2)` e raio 12,35 u (eixo), do ponto de junção com o anel (azimute 45°, `r` 16 → `(−11,3, −11,3)`) até o centro da lagoa NO; o arco é o curto, com a barriga voltada para **NE** (ápice ≈ `(−17,4, −17,4)`) | colisão por setores poligonais como o anel (SPEC-044 §5); o Code pode ajustar centro/raio do arco para o visual fechar, **mantendo** os dois extremos, a largura e o lado da barriga — registra o valor final na entrega |
| **Lagoa NO** | disco de raio **5 u** centrado em `(−26, −18)` | fim do rio: **não toca a borda**; entre a lagoa e o muro O sobra o corredor TOP (§2.3) |
| **Braço SE / Lagoa SE** | rotação de 180°: arco de centro `(22,5, 6,2)`, barriga para **SO**; lagoa em `(26, 18)` | — |
| **Travessias** | **3 rotas**: (1) TOP contorna a lagoa NO por fora, pelo corredor O/N; (2) MID cruza o anel pelas **2 pontes** em 135° (SO) e 315° (NE), centradas em `r = 16 u`, eixo radial, largura nominal 4 u (efetiva ≈ 5 u); (3) BOT contorna a lagoa SE | **sem ponte** nas pontas do rio e sem ponte de selva (decisão do PI; alternativas em §7). Nos azimutes 45° e 225° o anel recebe os braços: não há ponte, e as 2 entradas da cratera ali dão para a ilha interna, não para fora |

### 2.2 Cratera e ilha central — inalteradas (SPEC-044 §2)

Cratera disco `r` 6 u, boss `(0,0)` aos 3:30; 8 pilares em `r = 6` com 4 entradas de 4 u em 45°, 135°, 225°, 315°; ilha = coroa `6 < r ≤ 14`. Só as **2 pontes da MID** dão acesso à ilha (uma por metade).

### 2.3 Rotas (corredores livres) — decisão do PI

Corredores de **8 u sem colisor e sem mato** (rochas, muros, moitas e lagoas ficam fora deles):

| Rota | Banda |
|---|---|
| **TOP** | O: `x ∈ [−40, −32]`, `z ∈ [−40, 15]` (começa no muro de fechamento da base A) · N: `z ∈ [−40, −32]`, `x ∈ [−40, 15]` (termina no muro de fechamento da base B) |
| **MID** | faixa de 4 u para cada lado da reta `z = −x` (`|x + z| ≤ 5,66`), entre os portões; cruza o anel pelas 2 pontes |
| **BOT** | rotação de 180° da TOP: S: `z ∈ [32, 40]`, `x ∈ [−15, 40]` · L: `x ∈ [32, 40]`, `z ∈ [−15, 40]` |

Sem torres, sem minions, sem função de rota além de ser chão livre (o bot usa o navmesh; não há regra nova).

### 2.4 Bases (conteúdo e medidas locais = SPEC-044/007, só o canto muda)

Eixo local da base A: `s` ao longo de centro → spawn (`AXIS_A = (−0,707, 0, +0,707)`), `l` à esquerda de quem está no spawn olhando o centro (`LATERAL = (−0,707, 0, −0,707)`). Base B = rotação de 180°.

| Elemento | Posição | Observações |
|---|---|---|
| **Spawn A** | `(−24, +24)` (`s` 33,94), olhando o centro; distância ao centro **33,9 u** (dentro da zona) | respawn fase 1 e 2; = SPEC-007 |
| **Portão A** | centrado em `(−15, +15)` (`s` 21,21), largura 5 u, voltado para a ponte SO | fase 1 só o time A passa; cai aos 5:00 (inalterado); 1 portão por base (3 portões → §7) |
| **Muro em arco** | semicírculo de raio 12,7 u em torno do spawn, só no lado voltado ao centro (`|l| ≤ 12,7`, `s ≤ 33,94`), extremos em `(−33, 15)` e `(−15, 33)` | = SPEC-044 |
| **Muros de fechamento (novos)** | 2 segmentos retos: `(−33, 15) → (−40, 15)` e `(−15, 33) → (−15, 40)`; altura ≥ 2 u | fecham a base contra a borda quadrada (o arco não alcança as bordas); o canto atrás do spawn é base |
| Muros internos, T1 ×4, Guerreiro T2, 6 baús, fonte | constantes locais **iguais** às do builder atual (`BASE_WALLS`, `BASE_T1`, `BASE_T2`, `BASE_CHESTS`, `FOUNTAIN_LOCAL (32, 11)`) | fonte em `(−30,4, 14,8)`, `r` 33,8 — dentro da zona |
| **Castelo (kit F40)** | muralha/torres/portal seguem o arco e os muros de fechamento; torres onde o fechamento encontra a borda; o canto atrás do spawn recebe o corpo do castelo | enfeite, sem colisão além da spec |

### 2.5 Selva — 4 campos laterais (F36) nos quadrantes entre as rotas

| Campo | Centro | Metade / lado | Conteúdo (GDB §5.1/§6.2, = F36) |
|---|---|---|---|
| **A-top** | `(−26, −4)` | A, entre TOP (O) e MID | 2 × Esqueleto T1 em `(±2,5, −1,5)`, 1 × Guerreiro T2 em `(0, +1,5)`, 2 baús comuns em `(±3, +2,5)` — offsets atuais do builder |
| **A-bot** | `(+4, +26)` | A, entre MID e BOT (S) | idem |
| **B-top** | `(+26, +4)` | B | rotação de A-top |
| **B-bot** | `(−4, −26)` | B | rotação de A-bot |

- Cada campo ganha **2 rochas** (cilindro `r` 1,3, altura 2,5) em `(0, −5,5)` e `(0, +5,5)` do centro do campo (bolso de selva).
- Distâncias conferidas: campo → corredor mais próximo ≥ 3 u; campo → lagoa ≥ 6 u; campo → spawn do próprio time ≥ 20 u (fora da base); `leash` 10 u e `aggro` 6 u do GDB não alcançam corredor nem lagoa.
- Sem torres (decisão do PI); as marcações T1/T2/T3 da imagem tática são ignoradas.

### 2.6 Centro contestado (ilha `6 < r ≤ 14`)

| Elemento | Posição | Observações |
|---|---|---|
| **Campos do centro (2)** | azimutes **45° e 225°**, `r = 10`, abertura ±15° | 1 × Guerreiro T2 + 1 × Mago T2 + 1 × Golem T3 cada; **equidistantes das 2 pontes** (90° de cada) — substitui 0°/180° |
| **Baús raros (4)** | 1 por campo em `r = 12,5` (45°, 225°) + 1 em 90° e 1 em 270°, `r = 8` | pares simétricos por rotação |
| **Rochas do centro (4)** | azimutes 0°, 180° (`r` 9,5) e 112°, 292° (`r` 9,5) | fora do caminho ponte → campo |
| **Mato do centro (2)** | 90° e 270°, `r = 12`, 4 × 3 u | = SPEC-044 |
| Cratera | Rei Esqueleto aos 3:30, `(0,0)` | inalterado |

### 2.7 Mato alto e obstáculos fora de base e centro

| Item | Posição | Qtd |
|---|---|---|
| Moita de ponte | `(s 19,5, l +4,6)` no eixo radial de cada ponte (lado de fora do anel), 4 × 4 u; rocha do outro lado `(19,5, −4,6)` | 2 moitas + 2 rochas |
| **Moita de lagoa (nova)** | `(−30, −26)` e `(+30, +26)`, 4 × 4 u — ao lado da lagoa, fora do corredor TOP/BOT | 2 |
| Rochas de selva | §2.5 | 8 |

Total de mato: **6 moitas** (= SPEC-044). Regra do mato = F32; geometria `Area3D` grupo `tall_grass`.

## 3. Contagens (GDB §5.1 / §6.2 — inalteradas)

| Zona | Monstros | Baús |
|---|---|---|
| Base A / B | 4 × T1 + 1 × Guerreiro T2 cada | 6 comuns cada |
| 4 campos laterais | 2 × T1 + 1 × Guerreiro T2 cada | 2 comuns cada |
| Centro | 2 × Guerreiro T2 + 2 × Mago T2 + 2 × Golem T3 | 4 raros |
| Cratera | Rei Esqueleto (3:30) | drop do boss |
| **Total** | **29** | **24** |

## 4. Marcadores — inalterado (SPEC-044 §4)

`SpawnMarker` por `kind/team/tier`; `SpawnDirector` só lê marcadores; nenhuma posição em código. `gate.tscn` por time.

## 5. Implementação

- **Tag antes de tudo (ADR-0009):** `arena-ilha-arcana` no último commit da `main` em que a Ilha Arcana v1 (SPEC-044) é a arena. **Sem cópia em `legacy/`**; o builder regera **no lugar** a `game/scenes/arena/ilha_arcana.tscn` (o nome do arquivo fica: a arena continua sendo a ilha flutuante; "Rift Medieval adaptado" é o nome do layout).
- `tools/arena/build_arena.gd`: simetria por rotação (`_rotate_if` em vez de `_mirror_if`); `ARENA_HALF = 40` no lugar de `ARENA_RADIUS` (chão e borda quadrados: `max(|x|, |z|)`); `AXIS_A`/`LATERAL` para SO; `BRIDGE_AZIMUTHS = [135, 315]` (1 por metade); rio = anel + 2 braços em arco + 2 lagoas (sem canal reto); muros de fechamento da base; campos laterais, campos do centro, raros, rochas, moitas e corredores conforme §2; **asserção de corredor livre** (nenhum colisor/moita com AABB dentro das bandas do §2.3) — o builder sai com 1 se violar, como já faz para o rio.
- `art/arena/build_island.py`: chassi **quadrado** (meia-lado 42 u + lábio), leito do rio seguindo o S (anel + arcos + lagoas), **sem cascatas** (o rio não toca a borda); castelo por time no canto SO/NE; enfeite da beira (pinheiros, cristais, cavalos-de-frisa, torre, balista) redistribuído pelos 4 lados; ilhotas de fundo ficam. Partículas de cascata (`arena_ambience.gd`) saem; brasas ficam.
- HUD/F37: `world_extent` do minimapa e da neblina passa a cobrir o quadrado (40 u); a zona continua círculo de 35 u.
- `ArenaNav`: nada a mudar; conferir que o bot cruza as 2 pontes e contorna as lagoas.
- `bot_rules.gd` / `bot_input.gd`: "ponte mais próxima" (F44) continua valendo; sem mudança de FSM.
- Testes: `test_ilha_arcana.gd` (rotação no lugar de espelho; borda quadrada; 2 pontes), `test_ilha_arcana_physics.gd` (`BRIDGE_AZIMUTHS`), `test_arena_side_fields.gd` (borda quadrada e as 4 posições novas), novos testes de corredor livre e de contorno das lagoas.
- Roadmap: screenshot da vista de cima na mesma PR (`tools/arena/snapshot_arena.gd`).

## 6. Critério de aceite do F46

1. Medidas com a cápsula a 5,8 u/s: spawn A → centro **6,3 s ± 10 %** (geometria da base igual); spawn A → spawn B pela ilha (portão → ponte SO → ilha → ponte NE → portão) **medido e registrado** (previsão ≈ 12 s; substitui 11,10 s do F44 como referência em P-02); spawn A → spawn B pela TOP (contornando a lagoa NO) **medido e registrado**.
2. Rio não atravessável a pé em nenhum ponto exceto pelas **2 pontes** (autopilot em 12 pontos: 6 no anel, 2 por braço, 1 por lagoa — 0 sucessos). TOP e BOT contornam as lagoas: autopilot do campo A-top até o corredor N passa sem tocar o rio (1 sucesso).
3. Borda: autopilot contra os 4 lados — 0 saídas; `max(|x|, |z|)` do herói nunca passa de 40 u (GUT com a cena carregada).
4. Portão: time A passa, B não; aos 5:00 ambos (GUT + roteiro) — inalterado. Os muros de fechamento não deixam sair da base por fora do arco (autopilot em 2 pontos — 0 sucessos).
5. Contagem de marcadores = §3 (GUT): 29 monstros, 24 baús; campos laterais nas 4 posições do §2.5.
6. **Simetria por rotação:** para cada marcador em `(x, z)` existe `(−x, −z)` com mesmo `kind`/`tier` (GUT, substitui o teste de espelho).
7. Corredores livres: nenhum colisor nem `tall_grass` com AABB dentro das bandas do §2.3 (GUT sobre a cena gerada).
8. Flecha de 0,3 u não passa entre pilares; passa pelas 4 entradas — inalterado.
9. Arena idêntica em servidor e cliente.
10. Bot (F12) completa a fase 1 offline no novo layout: farma a base, atravessa uma ponte e contesta o centro, sem travar (3 partidas offline `--bot`).
11. Testes existentes de F7/F9–F13, F32, F36, F37 continuam verdes (cena muda, regras não); neblina e minimapa mostram o quadrado inteiro (verificação visual do PI).
12. **Ilha Arcana v1 preservada:** tag `arena-ilha-arcana` criada; nenhuma pasta `legacy/` nova.
13. Zona: `ZoneRules` e HUD intactos (raio 35 u); verificação visual do PI de que o anel da zona fica inscrito no quadrado e o spawn fica dentro aos 5:00.
14. Chassi regerado abre no jogo com a arte do F40 nos lugares novos (castelos nos cantos SO/NE, rio em S, lagoas) — verificação visual do PI, lado a lado com a imagem tática.

## 7. Fora desta spec

Torres (decisão do PI: nenhuma, nem enfeite com função). Pontes nas pontas do rio e pontes de selva (PI escolheu 3 rotas; voltam se o playtest do F19/[GATE] mostrar funil na MID). Três portões por base (um por rota — hoje 1 portão; entra só se o PI pedir). Cascatas (saem com o rio longe da borda). Mudar a zona para cobrir os cantos (GDB §7.1 fica; ADR-0004). Relevo e degraus. Minions, ouro por rota. Regra do mato (F32), neblina (F37), economia de campo (F36) — só reposicionadas. Renomear `ilha_arcana.tscn`.
