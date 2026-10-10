# Bloco visual + layout da arena (F44) — Plano de governança (Cowork)

> **Revisão 2026-10-10 14:40 (posição do bloco):** este plano foi executado com o bloco **dentro do MVP3** (F38–F43 entre F23 e F24, "MVP2.5 não existe"). O PI esclareceu que pediu o marco **MVP2.5, antes do MVP3**. Corrigido em seguida: `MVP-2.5.md`, issue-pai #99, títulos `[MVP2.5]` em #93–#98, `[INFRA]` #100, PRD §9.1, ADR-0006 item 9, STATUS e DEVELOPMENT. Onde este plano diz "MVP3", "3.11–3.16" ou "entre F23 e F24" para o bloco visual, vale o MVP2.5. O restante (decisões, ADRs, F44) segue válido.

> **Para agentes:** SUB-SKILL OBRIGATÓRIA: use superpowers:executing-plans (inline). Este plano **não escreve código**: é o plano do Cowork (documentação direto na `main` + issues). O código é do Code, a partir das issues.

**Objetivo:** registrar na governança as decisões do PI de 2026-10-10 (spec `docs/superpowers/specs/2026-10-10-bloco-visual-design.md`, ADR-0006 e ADR-0007) e criar os cards: **F44** (layout da arena, MVP2, após F14) e **F38–F43** (bloco visual, MVP3, entre F23 #79 e F24 #80).

**Estado em 2026-10-10 14:30 (revisão):** `origin/main` em `ff7fe70` — F36 (#89), F20 (#90) e F14 (#91) mergeados; MVP3 com issues #76–#87; `docs/STATUS.md` ainda projetava F36/F20/F14 como `todo`/`done` (a projeção `proplan` corrige). Os commits locais `dd31f06`/`afdc4b2` (spec + plano) nunca foram enviados e foram refeitos sobre a `origin/main` atual. O envio é feito pela API do GitHub (commit direto na `main`), porque o shell no PC do PI não tem credencial de push e o diretório de trabalho está na branch do Code.

**Execução:** Tasks 1–6 executadas e enviadas num único commit de docs (ver §Resultado no fim). Task 7 (issues) em seguida.

---

### Task 1: ADR-0006 — Revisão da direção visual

**Files:**
- Create: `docs/adr/0006-direcao-visual-toon-pbr.md`
- Modify: `docs/DECISIONS.md` (tabela de ADRs, após a linha `[0005]`)

- [ ] **Step 1: Escrever o ADR**

```markdown
# ADR-0006 — Direção visual: toon + stylized PBR, Forward+ only, bevel/bake no cenário próprio, LightmapGI

**Status:** aceito — 2026-10-10
**Decisor:** Rodrigo Reis (PI)
**Relacionados:** PRD §1.2, §11 · ADR-0005 · `CLAUDE.md` §Assets 3D · `TOKENS.md` · `FORA-DE-ESCOPO.md` · `APRENDIZADOS.md` #4 · spec `docs/superpowers/specs/2026-10-10-bloco-visual-design.md` · guia `docs/prd/guia_melhorias_graficas_godot4.md`

## Contexto

- O PI trouxe em 2026-10-10 um guia de melhorias gráficas (Rodrigo/Gemini) propondo "Stylized PBR" (SSAO, SSIL, SDFGI, fog volumétrico), shaders de água/chão, VFX de combate, HUD temática, grama e bevel/bake no Blender.
- O repo não tinha `WorldEnvironment`; o `Sun` está em `main.tscn` com defaults. As regras vigentes diziam "sem bevel, faces planas, cor por atlas" (`CLAUDE.md`), fontes Space Grotesk/Outfit/JetBrains Mono (R-PEND-11) e mobile futuro com renderer Mobile (PRD §1.2, §8.2).
- O único aprendizado gráfico registrado é o #4 de `APRENDIZADOS.md`: cliente que trava compilando shaders frios no sync inicial pode ficar com rollback preso.

## Decisão

1. **Direção artística = toon/outline + stylized PBR.** Cel-shading com contorno em heróis, monstros e cenário (aplicado por pós-import, glTF dos packs intocado); superfícies de água e chão com shaders próprios; luz física com sombras suaves, SSAO, SSIL, glow e fog volumétrico sutil.
2. **Game só Forward+.** Abre mão do renderer Mobile. Mobile (PRD §1.2) passa a exigir perfil gráfico próprio — adiado, gatilho = porte mobile.
3. **GI = `LightmapGI` bakeado** da arena estática. SDFGI e SSIL dinâmico como GI principal são **rejeitados** (custo contínuo sem nada dinâmico na arena; vazamento em paredes finas).
4. **Bevel (1–2 segmentos) e bake de AO/curvatura liberados no Blender para cenário próprio** (`shared/assets/rrb/`: portões, muralhas, rochas, pilares, rio, piso). Personagens e props dos packs CC0 ficam como vêm. Cor-base continua pelo atlas KayKit.
5. **Água e chão com malhas próprias** (rio como malha única com UV 0..1; piso hex próprio). Os hexes `hex_water`/`hex_grass` do KayKit não recebem shader procedural (UV em atlas).
6. **Design system v2:** fontes e molduras novas (revoga R-PEND-11). Fontes finais: R-PEND-14, trava só o F43 (HUD v2); o F24 (Theme do launcher) nasce no v2.
7. **Critério transversal de netcode:** toda fatia visual (a) pré-aquece shaders antes do `connect`, (b) prova 3/3 conexões a 100 ms sem `past the history limit`, (c) instancia VFX só no cliente e só com `is_fresh` ou por sinal do `HitLedger`, (d) lê números do GDB, (e) registra delta de frame time contra a baseline do F38 — orçamento do bloco: **+4 ms** médios no PC do PI.
8. **Toggles gráficos** (fog, SSIL, SSAO, grama) entram em `settings.cfg` — mudança do contrato Launcher ↔ Game (`ARCHITECTURE-LAUNCHER.md` §5), autorizada por este ADR; chaves definidas no F38 e consumidas pelo F24.
9. O bloco é **6 fatias no MVP3 (F38–F43), entre F23 e F24**. Não existe "MVP2.5".

## Alternativas descartadas

| Alternativa | Por que não |
|---|---|
| "MVP2.5" como marco | MVP-n = M-n do PRD; marco novo exigiria reescrever §9.1 e atrasar o M3 |
| Só luz + legibilidade (sem toon, sem PBR) | o PI quer identidade visual nova, não só polimento |
| SDFGI como no guia | arena estática; só custo; `LightmapGI` entrega o mesmo |
| Shaders sobre os hexes KayKit | UV em atlas: scroll sai da região, costura por tile, máscara quadrada |
| Manter R-PEND-11 (fontes atuais) | o PI escolheu molduras e fontes temáticas |
| Manter renderer Mobile | SSAO/SSIL/fog/decals são Forward+; mobile é fase B |

## Consequências

**Positivas**
- Arena, heróis e combate com identidade própria antes do F33 (render da arena) e do roadmap público.
- Regras explícitas para VFX sob rollback — risco #4 vira critério de aceite em vez de "vigiar".

**Custos**
- 6 cards de arte/shader antes do launcher; cada um com verificação visual do PI e Blender via MCP.
- `CLAUDE.md`, PRD §1.2/§11, `TOKENS.md`, `FORA-DE-ESCOPO.md`, `RASTREABILIDADE.md` revisados (este ADR é a fonte).
- Bake de lightmap vira passo de build (`tools/`).

**O que vigiar**
- Frame time em GPU integrada (orçamento +4 ms); toon × normal map (água/chão ficam fora do cel).
- Sync inicial 3/3 em toda fatia.
```

- [ ] **Step 2: Indexar no `DECISIONS.md`** — inserir após a linha `| [0005](adr/0005-blender-pipeline-de-assets.md) | ... |`:

```markdown
| [0006](adr/0006-direcao-visual-toon-pbr.md) | Direção visual toon + stylized PBR; Game só Forward+; LightmapGI (SDFGI rejeitado); bevel/bake no cenário próprio; design system v2; critério de netcode para fatias visuais; bloco F38–F43 no MVP3 | aceito | 2026-10-10 |
```

- [ ] **Step 3: Commit** — `docs(adr): ADR-0006 direção visual toon + stylized PBR`

### Task 2: `CLAUDE.md` — regra de estilo

**Files:**
- Modify: `CLAUDE.md` linha "Estilo: sem subdivisão nem bevel, ..."

- [ ] **Step 1: Substituir a linha por:**

```markdown
- Estilo (ADR-0006): personagens e props dos packs CC0 ficam como vêm (faces planas, cor por UV no atlas do KayKit `shared/assets/kaykit/medieval_hexagon/hexagons_medieval.png`). Cenário próprio em `shared/assets/rrb/` pode ter bevel de 1–2 segmentos e bake de AO/curvatura (máscara em canal UV2), cor-base ainda pelo atlas. Toon/outline aplicado por pós-import, nunca editando o glTF. Referência de orçamento: prop/cenário 50–800 triângulos, personagem 500–3.000. Conferir a silhueta na distância da câmera do jogo.
```

- [ ] **Step 2: Na seção "Projeto", item Stack, trocar `**Godot 4.7.2** (Forward+)` por `**Godot 4.7.2** (Forward+ **only** — ADR-0006)`.**
- [ ] **Step 3: Commit** — `docs(claude): regra de estilo do cenário próprio e Forward+ only (ADR-0006)`

### Task 3: PRD §1.2, §9.1 e §11

**Files:**
- Modify: `docs/prd/PRD.md`

- [ ] **Step 1: §1.2 — substituir o item "PC primeiro..." por:**

```markdown
- **PC primeiro** (Windows; Steam/itch na fase B). Mobile depois, com câmera/controles revisados — a decisão de câmera (§3.6) já considera isso. **O Game roda só no renderer Forward+ (ADR-0006, 2026-10-10)**: o porte mobile exigirá um perfil gráfico próprio (adiado em `FORA-DE-ESCOPO.md`).
```

- [ ] **Step 2: §9.1 — linha M3, coluna Entrega, acrescentar `; bloco visual (toon/PBR, arena, VFX, HUD v2 — ADR-0006)` e Prazo `3 sem` → `5 sem` (6 cards de arte). Atualizar "Total ≈ 15 semanas" → "Total ≈ 17 semanas".**

- [ ] **Step 3: §11 — acrescentar ao fim da seção:**

```markdown
- **Direção visual (ADR-0006, 2026-10-10):** toon/outline + stylized PBR; `WorldEnvironment` (ACES, SSAO, SSIL, glow, fog sutil) + `LightmapGI` bakeado; cenário próprio (`shared/assets/rrb/`) pode ter bevel e bake de AO/curvatura; água e chão com malhas próprias e shaders dedicados; VFX de combate só no cliente. Spec: `docs/superpowers/specs/2026-10-10-bloco-visual-design.md`.
```

- [ ] **Step 4: Commit** — `docs(prd): Forward+ only, bloco visual no M3 e direção visual (ADR-0006)`

### Task 4: Design system v2 (`TOKENS.md`, `DESIGN-SYSTEM-LAUNCHER.md`, `DEBITO.md`)

**Files:**
- Modify: `docs/design-system/TOKENS.md` §2 Tipografia
- Modify: `docs/design-system/DESIGN-SYSTEM-LAUNCHER.md` (nota de versão no topo)
- Modify: `docs/design-system/DEBITO.md` (nova linha)

- [ ] **Step 1: `TOKENS.md` §2 — substituir o parágrafo "Famílias de `docs/prd/telas/` (R-PEND-11)..." por:**

```markdown
**v2 (ADR-0006, 2026-10-10):** as famílias acima são **provisórias** até o PI decidir R-PEND-14 (candidatas do guia: Cinzel, Barlow Condensed, Montserrat SemiBold). Regras novas que já valem: todo texto sobre a arena (HUD) tem **outline 1–2 px `#000000`**; painéis usam `StyleBoxTexture` com moldura temática (metal escuro, cantos dourados) em vez de `StyleBoxFlat`; atalhos `Q/E/R` viram *badge* metálica no canto inferior direito do slot (`TYPE_BADGE`). Os nomes dos tokens não mudam; só os arquivos `font_*.ttf` e os `StyleBox` do `theme_moba.tres` — trocados no F43 (HUD) e consumidos pelo F24 (Theme do launcher).
```

- [ ] **Step 2: `DESIGN-SYSTEM-LAUNCHER.md` — inserir logo abaixo do título:**

```markdown
> **v2 em andamento (ADR-0006, 2026-10-10):** fontes e molduras passam a temáticas (ver `TOKENS.md` §2); paleta mantida. R-PEND-14 decide as famílias. F43 implementa no `shared/ui/theme/`; F24 herda.
```

- [ ] **Step 3: `DEBITO.md` — acrescentar linha na tabela:**

```markdown
| DS-05 | Fontes provisórias (Space Grotesk/Outfit/JetBrains Mono) até R-PEND-14; `StyleBoxFlat` até o F43 | ADR-0006 | F43 |
```

- [ ] **Step 4: Commit** — `docs(design-system): v2 — fontes/molduras temáticas pendentes de R-PEND-14 (ADR-0006)`

### Task 5: `MVP-3.md`, `STATUS.md`, `DEVELOPMENT.md`

**Files:**
- Modify: `docs/prd/mvp/MVP-3.md` (tabela Fatias + nova seção Ordem)
- Modify: `docs/STATUS.md` §1 Board, §2 linha MVP3, §3 índice, "Próximo número livre"
- Modify: `docs/DEVELOPMENT.md` seção MVP3

- [ ] **Step 1: `MVP-3.md` — inserir na tabela, após a linha 3.10:**

```markdown
| 3.11 | F38 / SPEC-038 | iluminação e pós (`WorldEnvironment`, `Sun`, `LightmapGI`), warm-up de shaders, baseline do profiler, toggles em `settings.cfg` | ADR-0006; spec bloco visual §4 |
| 3.12 | F39 / SPEC-039 | toon + outline por pós-import (heróis, monstros, cenário) | ADR-0006; spec §4 |
| 3.13 | F40 / SPEC-040 | arena: rio e piso como malhas próprias no Blender, bevel/bake nos props, shaders de água e chão | ADR-0005/0006; SPEC-007; spec §4 |
| 3.14 | F41 / SPEC-041 | arquitetura VFX (pool, `is_fresh`, sinal do `HitLedger`) + VFX do Cavaleiro e da Arqueira | ADR-0006; GDB §3–4; spec §4 |
| 3.15 | F42 / SPEC-042 | vegetação: grama `MultiMesh` com vento, distinta do mato alto | ADR-0006; CONVENTION §4.7; spec §4 |
| 3.16 | F43 / SPEC-043 | HUD v2: ghost bar, ícones Q/E/R + badge, molduras, fontes (R-PEND-14), 3 pontos na seleção | ADR-0006; TOKENS v2; spec §4 |
```

- [ ] **Step 2: `MVP-3.md` — inserir antes de "## Pendências do PI":**

```markdown
## Ordem de implementação (decisão do PI em 2026-10-10)

F21 → F22 → F23 → **F38 → F39 → F40 → F41 → F42 → F43** → F24 → F25 → F26 → F27 → F35 → F33 → F28 → [GATE].

Motivo: backend e game server primeiro (risco técnico herdado); o bloco visual (ADR-0006) entra antes do launcher para o Theme do F24 nascer no design system v2 e o F33 renderizar a arena pronta. Se o prazo apertar, F42 e F43 podem ir para depois do F33 sem quebrar dependências. Critério transversal do bloco: ADR-0006 item 7.
```

- [ ] **Step 3: `MVP-3.md` — em "## Pendências do PI" acrescentar:** `R-PEND-14 (fontes do design system v2) — trava só o F43.`

- [ ] **Step 4: `STATUS.md` §3 — inserir após a linha `F35 / SPEC-035`:**

```markdown
| F38 / SPEC-038 | MVP3 | game | Slice 3.11 — Iluminação e pós: `WorldEnvironment`, `Sun`, `LightmapGI`, warm-up de shaders, baseline do profiler, toggles em `settings.cfg` (ADR-0006) | planejado |
| F39 / SPEC-039 | MVP3 | game, shared | Slice 3.12 — Toon + outline por pós-import | planejado |
| F40 / SPEC-040 | MVP3 | game, shared | Slice 3.13 — Arena: rio e piso próprios no Blender, bevel/bake nos props, shaders de água e chão | planejado |
| F41 / SPEC-041 | MVP3 | game | Slice 3.14 — Arquitetura VFX + VFX do Cavaleiro e da Arqueira | planejado |
| F42 / SPEC-042 | MVP3 | game, shared | Slice 3.15 — Vegetação (grama `MultiMesh`, distinta do mato alto) | planejado |
| F43 / SPEC-043 | MVP3 | game, shared | Slice 3.16 — HUD v2 (ghost bar, ícones, molduras, fontes R-PEND-14, 3 pontos) | planejado |
```

- [ ] **Step 5: `STATUS.md` — "Próximo número livre: **F38 / SPEC-038**" → "**F44 / SPEC-044**". §2 linha MVP3, coluna Entrega: acrescentar `, bloco visual F38–F43 (ADR-0006)`. (a linha do Board em §1 é atualizada na Task 7, com os números das issues).**

- [ ] **Step 6: `DEVELOPMENT.md` seção MVP3 — inserir após a linha `**F23**`:**

```markdown
- [ ] **F38** — `arena.tscn`: `WorldEnvironment` (ACES, SSAO, SSIL, glow 1.05, fog 0.008) + `Sun` (4 splits, blur 1.8) + `LightmapGI` bakeado (`tools/bake-lightmap.ps1`); `scripts/client/shader_warmup.gd` antes do `connect`; baseline do profiler em `docs/roadmap/`; chaves `graphics.*` em `settings.cfg`. Critério 3/3 sync a 100 ms (ADR-0006 item 7).
- [ ] **F39** — `shared/assets/post_import_toon.gd` (`EditorScenePostImport`), `shared/resources/materials/toon_base.tres` + `outline_pass.tres`; sem editar glTF. Critério 3/3; delta de frame time.
- [ ] **F40** — Blender: `art/arena/{rio,piso,props}.blend` → `shared/assets/rrb/arena/*.glb` (UV 0..1, UV2 com AO/curvatura); `game/shaders/water.gdshader` (`water_depth = linear_depth + VERTEX.z`, `NORMAL_MAP`), `game/shaders/hex_ground.gdshader`; colisão do F7 intacta; cena de alinhamento. Critério 3/3; delta.
- [ ] **F41** — `game/scenes/vfx/`, `scripts/vfx/vfx_pool.gd`, `vfx_spawner.gd` (cliente, `is_fresh`, sinal do `HitLedger`), teste GUT de spawn único; VFX de básico/Q/E/R do Cavaleiro e da Arqueira; trail da flecha com interpolação visual separada do estado. Servidor headless sem nós de VFX. Vídeo no roadmap.
- [ ] **F42** — `game/scenes/arena/vegetation.tscn` (`MultiMeshInstance3D`), `game/shaders/grass_wind.gdshader` (fase por instância), máscara de distribuição longe do mato alto. Aceite visual do PI: grama ≠ mato.
- [ ] **F43** — `stat_bar.gd` ghost bar (tipado), ícones Q/E/R + badge, `StyleBoxTexture`, fontes (R-PEND-14) com outline, 3 pontos em `hero_select.tscn` e `monster_preview_3d.tscn`; `_gallery.tscn` atualizada.
```

- [ ] **Step 7: Commit** — `docs(mvp3): fatias F38–F43 do bloco visual, ordem e índice (ADR-0006)`

### Task 6: `FORA-DE-ESCOPO.md`, `RASTREABILIDADE.md`, `APRENDIZADOS.md`

**Files:**
- Modify: `docs/FORA-DE-ESCOPO.md` (linha Mobile + seção Excluídos)
- Modify: `docs/RASTREABILIDADE.md` (V-10, nova R-PEND-14)
- Modify: `docs/APRENDIZADOS.md` (#4)

- [ ] **Step 1: `FORA-DE-ESCOPO.md` — substituir a linha "Mobile (câmera/controles revisados, Mobile renderer)" por:**

```markdown
| Mobile (câmera/controles revisados, **perfil gráfico próprio** — Game é Forward+ only, ADR-0006) | PRD §1.2, §8.2 | PC primeiro (D1) | fase B | PC validado + decisão de porte |
```

- [ ] **Step 2: `FORA-DE-ESCOPO.md` — na seção de excluídos (ou criar `## Excluídos` se não houver), acrescentar:**

```markdown
| SDFGI e SSIL dinâmico como GI principal | guia gráfico 2026-10-10 | arena estática: `LightmapGI` bakeado entrega o mesmo sem custo contínuo; vazamento em paredes finas (ADR-0006) | excluído | — |
| Shaders procedurais sobre os hexes KayKit (`hex_water`/`hex_grass`) | guia gráfico 2026-10-10 | UV em atlas; substituído por malhas próprias (F40) | excluído | — |
```

- [ ] **Step 3: `RASTREABILIDADE.md` — linha V-10, coluna Estado:** `mantido — paleta de docs/prd/telas/; fontes e molduras em revisão (design system v2, ADR-0006, R-PEND-14)`.

- [ ] **Step 4: `RASTREABILIDADE.md` — acrescentar na tabela de pendências:**

```markdown
| R-PEND-14 | Fontes do design system v2 (ADR-0006): o guia só exemplifica Cinzel / Barlow Condensed / Montserrat SemiBold | escolher 1 display + 1 corpo (+ mono opcional), licença OFL | trava só o F43 (HUD v2); F24 herda |
```

- [ ] **Step 5: `APRENDIZADOS.md` — substituir a linha do #4 "shaders frios" por:**

```markdown
- [game] Cliente que trava ~1,4 s no sync inicial (shaders frios) pode ficar com rollback preso (`past the history limit of 64`); visto 1× (#4) — **promovido** a critério de aceite de toda fatia visual: warm-up de shaders antes do `connect` + 3/3 conexões a 100 ms (ADR-0006 item 7).
```

- [ ] **Step 6: Commit** — `docs(governanca): fora de escopo, rastreabilidade R-PEND-14 e aprendizado #4 promovido (ADR-0006)`

### Task 7: Issues no GitHub (`RodReis/rrb-godot`)

- [ ] **Step 1: F44 no MVP2** — criar sub-issue de #57 com label `proplan:todo`, reprioritizada **antes de F16 #63**:

Título: `[MVP2][SPEC-044][F44] Arena "Ilha Flutuante Arcana": layout novo em greybox (espelho N–S, 4 pontes)`
Corpo: Entrega = SPEC-044 §2–5 (builder, colisão, marcadores — reposiciona os campos do F36 —, portões, mato, navmesh; **sem arte**, continua KayKit); Aceite = SPEC-044 §6 (9 itens); Fontes = ADR-0007, SPEC-044, GDB §5.1/§6.2/§7.1, `CONVENTION.md`.

- [ ] **Step 2: F38–F43 no MVP3** — 6 sub-issues de #76 com label `proplan:backlog`, reprioritizadas **depois de F23 #79 e antes de F24 #80**, na ordem F38 → F43. Títulos e corpos:

1. `[MVP3][SPEC-038][F38] Iluminação, pós-processamento e aquecimento de shaders` — Entrega: `WorldEnvironment` em `arena.tscn` (ACES, exposure 1.0–1.15, SSAO r1.5/i2.0, SSIL, glow threshold 1.05 soft light, fog 0.008); `Sun` cor (1.0,0.96,0.88), energia 1.35, rot (-48,38,0), blur 1.8, 4 splits, max 65; `LightmapGI` bakeado + `ReflectionProbe` (`tools/bake-lightmap.ps1`); `shader_warmup` antes do `connect`; baseline do profiler (frame médio e p99, 1080p, partida vs bot); chaves `graphics.*` em `settings.cfg`. Aceite: antes/depois no roadmap; 3/3 conexões a 100 ms (Docker netem) sem `past the history limit`; delta de frame time em `DEVELOPMENT.md`; verificação visual do PI. Fontes: ADR-0006; spec §3–4; `APRENDIZADOS.md` #4.
2. `[MVP3][SPEC-039][F39] Toon e outline por pós-import` — Entrega: material base cel (3 bandas, rim leve, albedo do atlas) + outline *inverted hull* por `next_pass`; `EditorScenePostImport` em `shared/assets/` aplicando aos glTF sem editá-los; toon só na luz direta (`light()`), GI do F38 mantida; `world_health_bar.gdshader` legível. Aceite: heróis, monstros, cenário e props com contorno; 3/3 sync; delta; PI. Fontes: ADR-0006; spec §4.
3. `[MVP3][SPEC-040][F40] Arte da Ilha Flutuante Arcana sobre o layout da SPEC-044` — Entrega: kits Blender em `art/arena/` → `shared/assets/rrb/arena/*.glb` (ilha + abismo, castelos, cratera de obsidiana/magma plano, 4 pontes, cristais, pinheiros, torres/balistas só enfeite, ilhotas de fundo), bevel/bake em UV2; shaders `arcane_river` (`water_depth = linear_depth + VERTEX.z`, `NORMAL_MAP`, `NoiseTexture2D`), `volcanic_lava`, `arcane_crystal`, `abyss_sky` (com estrelas/nebulosa); cachoeiras e brasas (`GPUParticles3D`, cliente); luzes locais. Colisão/navmesh do F44 intactos. Aceite: cena de alinhamento; GUT de marcadores + 3 partidas offline; rio sem costura; mato ≠ cristais; 3/3 sync; delta; roadmap; PI contra a imagem. Fontes: ADR-0005/0006/0007; SPEC-044; spec §4.
4. `[MVP3][SPEC-041][F41] Arquitetura VFX e efeitos do Cavaleiro e da Arqueira` — Entrega: `game/scenes/vfx/`, `scripts/vfx/vfx_pool.gd`, `vfx_spawner.gd` (só cliente; `is_fresh` ou sinal do `HitLedger`); `OmniLight3D` efêmera 0.15–0.3 s; GUT de spawn único em ressimulação. Cavaleiro: trail 0.25 s, faíscas, Investida (linhas + poeira), Muralha fresnel (0.2,0.6,1.0,0.7), Terremoto (`Decal` 4 s, erupção, onda com refração). Arqueira: trail `RibbonTrailMesh` 0.08×0.12 s com interpolação visual desacoplada, Q espiral 3.5 + pulso por alvo, E poeira + ghost 0.2 s, R indicador + saraivada 3 s. Números do GDB. Aceite: zero VFX duplicada a 100 ms / 2 % perda; servidor headless sem nós de VFX; 3/3; delta; vídeo; PI. Fontes: ADR-0006; GDB §3–4; `CLAUDE.md` §Regras de rede; spec §3–4.
5. `[MVP3][SPEC-042][F42] Vegetação: grama MultiMesh com vento` — Entrega: `MultiMeshInstance3D` sobre a ilha, `grass_wind.gdshader` com fase por instância, máscara longe de caminhos, pontes, cratera e mato alto; toggle em `settings.cfg`. Aceite do PI: grama inconfundível com o mato alto; delta. Fontes: ADR-0006; `CONVENTION.md` §4.7; spec §4.
6. `[MVP3][SPEC-043][F43] HUD v2: ghost bar, ícones, molduras, fontes e luz de estúdio` — Entrega: `stat_bar.gd` com amortecimento (`Tween` 0.35 s + 0.4 s QUAD/EASE_OUT; cura imediata; tipado); ícones Q/E/R + badge; `StyleBoxTexture` no `theme_moba.tres`; fontes de R-PEND-14 com outline 1–2 px; 3 pontos em `hero_select.tscn` e `monster_preview_3d.tscn`; `_gallery.tscn`. Aceite: HUD fase 1 e 2 legíveis; `shared/test` verde; PI. **Bloqueado por R-PEND-14.** Fontes: ADR-0006; `TOKENS.md` v2; `FRONTEND-LAUNCHER.md`; spec §4.

- [ ] **Step 3: Anotar os números das issues em `STATUS.md` §1 e §3 e enviar** — `docs(status): issues F44 e F38–F43`.

### Task 8: Verificação final

- [ ] `git log --oneline -8` mostra os 6–7 commits de docs; `git status` limpo (exceto a renomeação pendente do PI em `docs/prd/telas/`).
- [ ] `grep -rn "F38\|ADR-0006" docs/STATUS.md docs/prd/mvp/MVP-3.md docs/DECISIONS.md CLAUDE.md` retorna todas as referências.
- [ ] Issues abertas no GitHub com título no formato de `GITHUB.md` §9 e vinculadas à issue-pai.
- [ ] Resumo ao PI com os números das issues e a pendência R-PEND-14.


## Resultado (2026-10-10 15:10)

- Docs enviados para a `main` em `2175fb6` (Tasks 1–6) e neste commit (Task 7 Step 3).
- Issues: **F44 #92** (MVP2, `proplan:todo`, após F16 #63 — que já estava em `doing` — e antes de F17 #64); **F38 #93, F39 #94, F40 #95, F41 #96, F42 #97, F43 #98** (MVP3, `proplan:backlog`, entre F23 #79 e F24 #80). Issues-pai #57 e #76 atualizadas.
- Pendência do PI: R-PEND-14 (fontes do design system v2) — trava só o F43.
