# Bloco visual (MVP3) — Design

**Data:** 2026-10-10 · **Autor:** Cowork (planejamento) · **Aprovação:** PI (Rodrigo Reis), decisões registradas abaixo
**Fonte de entrada:** `docs/prd/guia_melhorias_graficas_godot4.md` (guia Rodrigo/Gemini, 2026-10-10) — usado como *inspiração*, não como spec. A errata do guia está no §7.
**Status:** aprovada pelo PI em 2026-10-10 11:13; revisada às 14:30 (ADR-0007: layout da arena). Plano: `docs/superpowers/plans/2026-10-10-bloco-visual-governanca.md`.

---

## 1. Objetivo

Elevar a qualidade visual do módulo Game (arena, heróis, combate, HUD) de "KayKit cru" para um visual estilizado com identidade própria, **sem quebrar o netcode** (MVP2) e **sem mexer em regra de jogo**. Resultado esperado: a arena renderizada pela tela Arena & Mapa (F33) e as capturas do roadmap público passam a ter a cara do concept art de `docs/prd/telas/Arena & Mapa — O Vale Rúnico Apocalíptico`.

Não é um MVP. É um **bloco de 6 fatias dentro do MVP3**, entre F23 e F24 (decisão do PI, §2).

## 2. Decisões do PI (2026-10-10)

| # | Decisão | Consequência |
|---|---|---|
| D-V1 | "MVP2.5" **não existe**; o bloco entra no MVP3 entre F23 (game server) e F24 (shell do launcher) | `MVP-3.md` e `STATUS.md` ganham F38–F43; MVP-n = M-n continua valendo |
| D-V2 | Direção artística = **toon/outline + stylized PBR** (opções B+C do brainstorm) | heróis, monstros e cenário com cel-shading e contorno; superfícies com variação procedural; luz física com sombras suaves |
| D-V3 | **Bevel e bake de AO/curvatura liberados no Blender para props de cenário** (portões, muralhas, rochas) | revoga parcialmente a regra "sem bevel, faces planas, cor por atlas" do `CLAUDE.md` — vale só para cenário próprio (`shared/assets/rrb/`); personagens KayKit ficam como vêm |
| D-V4 | **Fontes e molduras novas** no design system | revoga R-PEND-11 (Space Grotesk / Outfit / JetBrains Mono). Fontes finais: pendência R-PEND-14 (trava só o F43) |
| D-V5 | **Game só Forward+**; abre mão do renderer Mobile | PRD §1.2: mobile passa a exigir perfil gráfico próprio, fora de escopo. Libera SSAO, SSIL, fog volumétrico, decals |
| D-V6 | GI = **LightmapGI bakeado** (não SDFGI) | arena é estática; custo zero em runtime; SDFGI/SSIL dinâmicos vão para `FORA-DE-ESCOPO.md` como rejeitados |
| D-V7 | Água e chão com **malhas próprias no Blender** (rio como malha única UV 0..1; piso hex próprio) | os shaders do guia não funcionam sobre os hexes do KayKit (UV em atlas, costura por tile) |
| D-V8 | 6 cards: F40 = malhas + shaders; F41 = arquitetura VFX + Cavaleiro + Arqueira | menos PRs, cards maiores |
| D-V9 | **Arena vira a "Ilha Flutuante Arcana" da imagem panorâmica** (doc `docs/prd/especificacao_reforma_arena_godot_blender.md`): layout novo com espelho N–S, bases nos cantos norte, rio N–S + anel, 4 pontes (2 por metade). Layout em greybox = **F44 (MVP2, após F14)**; arte = F40. Torres/balistas só enfeite | ADR-0007; SPEC-044; o F40 abaixo é a arte sobre esse layout |

## 3. Regras transversais (valem para toda fatia do bloco)

1. **Netcode intocado.** Nada do bloco entra em *state property* do `RollbackSynchronizer` nem em `_rollback_tick` como estado. VFX, luz e trilha são **só cliente**; o servidor headless não instancia nada de `scenes/vfx/`.
2. **VFX nasce uma vez.** Efeito disparado dentro da simulação só instancia quando `is_fresh == true`; efeito de impacto vem por sinal emitido a partir do `HitLedger` (servidor → RPC discreto → cliente), nunca da ressimulação.
3. **Pré-aquecimento de shaders.** F38 cria o passo de *warm-up* (materiais/partículas compilados numa cena oculta antes do `connect`) e **reabre o critério** de `APRENDIZADOS.md` #4: cliente entra 3× seguidas a 100 ms (Docker netem) sem `past the history limit`. Toda fatia seguinte roda esse critério. Confirmar em `docs/engine-reference/godot/modules/rendering.md` o estado do ubershader (4.4+); se cobrir, documentar e manter o teste.
4. **Número é do GDB.** Raio do Terremoto, alcance da Investida, duração do rolamento, raio da Chuva etc. são lidos de `shared/data/*.tres`; VFX não duplica valor. Se o GDB não tem o número, o Code pergunta — não inventa.
5. **Medição.** F38 registra baseline do profiler (frame time médio e p99 em 1080p na cena de partida com bot, GPU RTX 5060 **e** com `--rendering-driver` forçado a perfil baixo se disponível). Cada fatia reporta o delta. Orçamento: o bloco inteiro não pode passar de **+4 ms** de frame time médio sobre a baseline no PC do PI.
6. **Leitura antes de beleza.** Mato alto (regra de jogo F32/F34) tem de continuar inconfundível com grama decorativa; indicador de área de skill tem de ser legível sobre qualquer shader de chão. Critério de aceite visual do PI.
7. **Roadmap.** Toda fatia do bloco gera screenshot (e vídeo quando o que importa é movimento) em `docs/roadmap/` + `build-roadmap.ps1`, na mesma PR.
8. **Pipeline Blender (ADR-0005).** `.blend` em `art/<área>/`, `.glb` em `shared/assets/rrb/<área>/`, sufixos `-col`/`-colonly` só se a colisão vier da malha (no F40 a colisão continua a do F7, por código). Todo asset passa pela cena de alinhamento.

## 4. Fatias

### F38 / SPEC-038 — Iluminação, pós-processamento e aquecimento de shaders (`game`)

- Criar `WorldEnvironment` (hoje **não existe**; o `Sun` está em `main.tscn` com rotação `(-1, 0.6, 0)` e só `shadow_enabled`): tonemap ACES, exposure 1.0–1.15, SSAO (raio 1.5, intensidade 2.0), SSIL ligado, glow com threshold 1.05 e blend *soft light*, fog volumétrico densidade 0.008. Valores iniciais do guia; ajuste final é verificação visual do PI.
- `Sun`: cor `(1.0, 0.96, 0.88)`, energia 1.35, rotação `(-48, 38, 0)`, `shadow_blur 1.8`, `PARALLEL_4_SPLITS`, `max_distance 65`.
- `LightmapGI` bakeado da arena (cenário estático) + `ReflectionProbe` único; heróis/monstros iluminados pelos *probes* do bake.
- Mover o `Sun` e o `WorldEnvironment` para `arena.tscn` (dono da ambientação), não `main.tscn`.
- Warm-up de shaders + reabertura do critério APRENDIZADOS #4 (regra 3).
- Baseline do profiler (regra 5).
- **Aceite:** antes/depois no roadmap; critério de sync 3/3; delta de frame time registrado em `DEVELOPMENT.md`.

### F39 / SPEC-039 — Toon + outline (`game`, `shared`)

- Um `ShaderMaterial` base de cel-shading (3 bandas, *rim* leve, lê `ALBEDO` do atlas KayKit) e um passe de contorno (*inverted hull* por `next_pass`, espessura em unidades de tela).
- Aplicado por **pós-import** (`EditorScenePostImport` em `shared/assets/`) — glTF do KayKit/Quaternius não é editado; material próprio (`shared/assets/rrb/`) recebe o mesmo material base.
- Toon substitui só a luz direta (`light()`); ambiente/GI do F38 continua.
- **Aceite:** heróis, monstros, cenário e props com contorno; HP bar no mundo (`world_health_bar.gdshader`) continua legível; critério de sync 3/3; delta de frame time.

### F40 / SPEC-040 — Arte da ilha sobre o layout da SPEC-044 (`shared` art, `game`)

- Blender (via MCP, verificação visual do PI), kits modulares em `art/arena/` exportados para `shared/assets/rrb/arena/*.glb`: **ilha** (chassi com penhascos e abismo, sulcos do rio e da cratera — a colisão continua a do F44, a malha cobre a colisão), **castelo** (torre, muralha reta/curva, portal com portão, ranhuras de runas emissivas) nas bases, **cratera** (pilares de obsidiana nas posições dos 8 pilares, lago de magma plano), **pontes de pedra** (4, planas, 4 u), **props** (cristais arcanos nos campos laterais, pinheiros, barreiras, torres de vigia/balistas **só enfeite fora da área jogável**), **ilhotas de fundo** (3–5, sem colisão). Bevel 1–2 seg. + bake AO/curvatura em UV2 (D-V3). Orçamento de tris do `CLAUDE.md`.
- Shaders em `game/shaders/`: `arcane_river.gdshader` (rio de mana emissivo; profundidade com `water_depth = linear_depth + VERTEX.z`, `NORMAL_MAP`, `NoiseTexture2D` para o fluxo, espuma), `volcanic_lava.gdshader` (voronoi + pulso, emissivo), `arcane_crystal.gdshader` (fresnel emissivo), `abyss_sky.gdshader` (`shader_type sky`: degradê + estrelas + nebulosa — o degradê sozinho não entrega a imagem). Materiais em `shared/resources/materials/`. Água, magma e cristal ficam **fora do toon**.
- VFX ambiental (cliente, `GPUParticles3D`): cachoeiras de mana onde o rio toca a borda (N e S), brasas sobre o magma. Luzes locais: `OmniLight3D` laranja no magma (alcance 12 u), cianas/magentas nos cristais, tochas nos portões — contadas no orçamento do F38.
- **Aceite:** cena de alinhamento com os novos assets; colisão/navmesh do F44 idênticos antes e depois (teste GUT de marcadores + 3 partidas offline com bot); rio sem costura; mato alto inconfundível com cristais/pinheiros; critério de sync 3/3; delta de frame time; captura para o roadmap; verificação visual do PI contra a imagem.

### F41 / SPEC-041 — Arquitetura VFX + Cavaleiro + Arqueira (`game`)

- `game/scenes/vfx/` + `scripts/vfx/`: `VfxPool` (pooling de partículas/decals/luzes efêmeras), `VfxSpawner` cliente que escuta sinais de combate; `OmniLight3D` efêmera 0.15–0.3 s; regra `is_fresh` (regra 2). Teste GUT da regra de spawn único.
- Cavaleiro: trail do básico (ribbon 0.25 s), faíscas no impacto, linhas de velocidade na Investida + poeira no fim, Muralha com fresnel `(0.2, 0.6, 1.0, 0.7)` e favo sutil, Terremoto com `Decal` de rachadura (raio do GDB, 4 s fade), erupção de fragmentos e onda de choque com refração.
- Arqueira (depende do F14, MVP2): flecha com `RibbonTrailMesh` 0.08 × 0.12 s **com interpolação visual desacoplada do estado de rede** (projétil ressimulado não pode ziguezaguear), Q com espiral emissiva 3.5 e pulso por alvo atravessado, E com 2 tufos de poeira + *ghost mesh* 0.2 s, R com indicador de área (raio do GDB, borda rotativa) + saraivada 3 s.
- **Aceite:** nenhuma VFX duplicada em ressimulação (teste GUT + inspeção em 100 ms / 2 % perda); servidor headless sem nós de VFX; critério de sync 3/3; delta de frame time; vídeo curto no roadmap.

### F42 / SPEC-042 — Vegetação (`game`, `shared`)

- Tufos de grama em `MultiMeshInstance3D` sobre o piso do F40, vento no `vertex()` com fase por instância (`INSTANCE_CUSTOM` ou posição de mundo via `MODEL_MATRIX`), não por `VERTEX` local.
- Distribuição por máscara (fora de caminhos, pontes, cratera e **longe do mato alto**).
- **Aceite do PI:** grama decorativa e mato alto inconfundíveis à distância da câmera do jogo (regra 6); delta de frame time.

### F43 / SPEC-043 — HUD v2 (`game`, `shared`)

- `stat_bar.gd`: *ghost bar* (camada de amortecimento com `Tween`, atraso 0.35 s, 0.4 s `QUAD/EASE_OUT`; cura atualiza na hora). Tipagem estática obrigatória (o exemplo do guia tem `var old_hp` sem tipo — falha o lint).
- Ícones Q/E/R + *badge* da tecla, molduras `StyleBoxTexture`, fontes novas com outline 1–2 px (R-PEND-14), iluminação de 3 pontos em `hero_select.tscn` e `monster_preview_3d.tscn`.
- Pré-requisito documental: `TOKENS.md`/`DESIGN-SYSTEM-LAUNCHER.md` v2 (Cowork) — o F24 (Theme do launcher) nasce nesse v2.
- **Aceite:** galeria `_gallery.tscn` atualizada; HUD fase 1 e fase 2 legíveis sobre a arena nova.

## 5. Ordem e dependências

MVP2: … F14 → **F44 (layout, SPEC-044)** → F16 → … MVP3: F21 → F22 → F23 → **F38 → F39 → F40 → F41 → F42 → F43** → F24 → F25 → F28 → F26 → F27 → F33 → F35 → [GATE] (ordem das issues #77–#87).
Dependências internas: F39←F38; F40←F39 e F44; F41←F38 (e F14); F42←F40; F43←design system v2.

## 6. Documentos a atualizar (Cowork, direto na `main`)

- **ADR-0006** — Revisão da direção visual (D-V2…D-V7) e registro do que revoga (`CLAUDE.md` estilo; R-PEND-11; PRD §1.2 mobile).
- **ADR-0007** — Layout da arena (D-V9): imagem panorâmica vira layout; SPEC-044 supera SPEC-007 §2–3; F44 no MVP2.
- `docs/prd/mvp/spec/SPEC-044.md`, `docs/prd/mvp/MVP-2.md` (Slice 2.11, ordem), `CONVENTION.md` (mapa), SPEC-007 (nota de superação).
- `CLAUDE.md` §Assets 3D — regra de estilo passa a: "personagens dos packs como vêm; cenário próprio pode ter bevel 1–2 seg. e bake AO/curvatura; cor-base pelo atlas".
- `docs/prd/PRD.md` §1.2 (mobile → perfil gráfico próprio, fora de escopo) e §11 (Forward+ only; toon/outline).
- `docs/design-system/TOKENS.md` + `DESIGN-SYSTEM-LAUNCHER.md` v2 (fontes/molduras; R-PEND-14 aberta).
- `docs/prd/mvp/MVP-3.md` (fatias 3.11–3.16), `docs/STATUS.md` (índice F38–F43; próximo livre F44), `docs/DEVELOPMENT.md`.
- `docs/FORA-DE-ESCOPO.md` — SDFGI, SSIL dinâmico como GI principal, renderer Mobile: rejeitados, motivo e gatilho de retorno (porte mobile).
- `docs/RASTREABILIDADE.md` — V-10 revisado; R-PEND-14 (fontes).
- `docs/APRENDIZADOS.md` — #4 vira critério de aceite do bloco.

## 7. Errata do guia (por que não vira spec como está)

- Assume `WorldEnvironment`/`DirectionalLight3D` em `arena.tscn`: não existem lá. Caminhos inexistentes: `game/shaders/`, `game/data/materials/`, `game/scenes/vfx/`, `hud.tscn`, `health_bar.gd`.
- Água: `linear_depth - VERTEX.z` (sinal errado), `NORMAL =` tangent-space (usar `NORMAL_MAP`), `screen_texture` sem uso, UV de atlas dos hexes KayKit incompatível com scroll.
- Chão: máscara `abs(UV-0.5)*2` é quadrada e pressupõe UV 0..1 por tile.
- Grama: fase do vento por `VERTEX` local → tufos sincronizados.
- Ghost bar: declaração sem tipo.
- SDFGI numa arena estática; stack só Forward+ contradizia o PRD (resolvido por D-V5/D-V6).
- Fontes/molduras contradiziam R-PEND-11 (resolvido por D-V4).
- Bevel/bake contradiziam o `CLAUDE.md` (resolvido por D-V3).
- Números hardcoded (6.0 u, 5.0 m, 4.0 m, 3.0 s) — GDB vence (ADR-0004).
- Ignorava APRENDIZADOS #4 (shader frio × rollback) e a duplicação de VFX em ressimulação.

## 8. Riscos

| Risco | Mitigação |
|---|---|
| Shader frio trava rollback no sync inicial | warm-up no F38 + critério 3/3 em toda fatia |
| Toon + PBR brigam (banding feio em superfícies com normal map) | água e chão ficam fora do toon (shaders próprios); só o cel na luz direta de malhas opacas |
| Bake de lightmap invalida a cada mudança de arena | bake é passo do `tools/` (script PowerShell), não manual; F40 rebakeia |
| Frame time estoura em GPU integrada | orçamento +4 ms no PC do PI e teste com perfil baixo; itens caros (fog, SSIL) têm toggle em `settings.cfg` — mudança do contrato Launcher ↔ Game, coberta pelo ADR-0006 |
| Bloco atrasa o MVP3 (6 cards antes do launcher) | cada card é independente após F38/F40; o PI pode mover F42/F43 para depois do F33 sem quebrar o resto |
