# ADR-0006 — Direção visual: toon + stylized PBR, Forward+ only, bevel/bake no cenário próprio, LightmapGI

**Status:** aceito — 2026-10-10; **posição do bloco revisada no mesmo dia (item 9): MVP2.5, antes do MVP3**
**Decisor:** Rodrigo Reis (PI)
**Relacionados:** PRD §1.2, §11 · ADR-0005 · ADR-0007 · `CLAUDE.md` §Assets 3D · `TOKENS.md` · `FORA-DE-ESCOPO.md` · `APRENDIZADOS.md` #4 · spec `docs/superpowers/specs/2026-10-10-bloco-visual-design.md` · guia `docs/prd/guia_melhorias_graficas_godot4.md`

## Contexto

- O PI trouxe em 2026-10-10 um guia de melhorias gráficas (Rodrigo/Gemini) propondo "Stylized PBR" (SSAO, SSIL, SDFGI, fog volumétrico), shaders de água/chão, VFX de combate, HUD temática, grama e bevel/bake no Blender.
- O repo não tinha `WorldEnvironment`; o `Sun` está em `main.tscn` com defaults. As regras vigentes diziam "sem bevel, faces planas, cor por atlas" (`CLAUDE.md`), fontes Space Grotesk/Outfit/JetBrains Mono (R-PEND-11) e mobile futuro com renderer Mobile (PRD §1.2, §8.2).
- O único aprendizado gráfico registrado é o #4 de `APRENDIZADOS.md`: cliente que trava compilando shaders frios no sync inicial pode ficar com rollback preso.

## Decisão

1. **Direção artística = toon/outline + stylized PBR.** Cel-shading com contorno em heróis, monstros e cenário (aplicado por pós-import, glTF dos packs intocado); superfícies de água e chão com shaders próprios; luz física com sombras suaves, SSAO, SSIL, glow e fog volumétrico sutil.
2. **Game só Forward+.** Abre mão do renderer Mobile. Mobile (PRD §1.2) passa a exigir perfil gráfico próprio — adiado, gatilho = porte mobile.
3. **GI = `LightmapGI` bakeado** da arena estática. SDFGI e SSIL dinâmico como GI principal são **rejeitados** (custo contínuo sem nada dinâmico na arena; vazamento em paredes finas).
4. **Bevel (1–2 segmentos) e bake de AO/curvatura liberados no Blender para cenário próprio** (`shared/assets/rrb/`: castelos, muralhas, rochas, pilares, rio, piso). Personagens e props dos packs CC0 ficam como vêm. Cor-base continua pelo atlas KayKit.
5. **Água e chão com malhas próprias** (rio como malha única com UV 0..1; piso próprio). Os hexes `hex_water`/`hex_grass` do KayKit não recebem shader procedural (UV em atlas).
6. **Design system v2:** fontes e molduras novas (revoga R-PEND-11). Fontes finais: R-PEND-14, trava só o F43 (HUD v2); o F24 (Theme do launcher) nasce no v2.
7. **Critério transversal de netcode:** toda fatia visual (a) pré-aquece shaders antes do `connect`, (b) prova 3/3 conexões a 100 ms sem `past the history limit`, (c) instancia VFX só no cliente e só com `is_fresh` ou por sinal do `HitLedger`, (d) lê números do GDB, (e) registra delta de frame time contra a baseline do F38 — orçamento do bloco: **+4 ms** médios no PC do PI.
8. **Toggles gráficos** (fog, SSIL, SSAO, grama) entram em `settings.cfg` — mudança do contrato Launcher ↔ Game (`ARCHITECTURE-LAUNCHER.md` §5), autorizada por este ADR; chaves definidas no F38 e consumidas pelo F24.
9. O bloco é o **marco MVP2.5: 6 fatias (F38–F43), depois do `[GATE]` do MVP2 e antes do MVP3** (decisão do PI em 2026-10-10: "antes do MVP3"). Revisão: a versão inicial deste ADR o colocava dentro do MVP3, entre F23 e F24, e rejeitava o MVP2.5; isso não atendia o pedido original do PI. Dependências do bloco: só F14 e F44 (MVP2). O MVP3 herda o design system v2 (F24) e as chaves gráficas de `settings.cfg` (F38). A arte da arena (F40) se aplica ao layout da SPEC-044 (ADR-0007). O marco exige o [INFRA] #100 (roadmap público reconhecer `MVP2.5`).

## Alternativas descartadas

| Alternativa | Por que não |
|---|---|
| Bloco dentro do MVP3 (entre F23 e F24) | foi a primeira versão deste ADR; o PI pediu o bloco antes do MVP3 e o MVP2.5 passou a ser o marco |
| Só luz + legibilidade (sem toon, sem PBR) | o PI quer identidade visual nova, não só polimento |
| SDFGI como no guia | arena estática; só custo; `LightmapGI` entrega o mesmo |
| Shaders sobre os hexes KayKit | UV em atlas: scroll sai da região, costura por tile, máscara quadrada |
| Manter R-PEND-11 (fontes atuais) | o PI escolheu molduras e fontes temáticas |
| Manter renderer Mobile | SSAO/SSIL/fog/decals são Forward+; mobile é fase B |

## Consequências

**Positivas**
- Arena, heróis e combate com identidade própria antes do MVP3 (F24 nasce no design system v2, F33 renderiza a ilha pronta) e do roadmap público.
- Regras explícitas para VFX sob rollback — risco #4 vira critério de aceite em vez de "vigiar".

**Custos**
- 6 cards de arte/shader entre o M2 e o M3; cada um com verificação visual do PI e Blender via MCP. Novo marco M2.5 de 2 semanas (PRD §9.1); M3 segue em 3. Total ≈ 17 semanas.
- Marco com número decimal: `[MVP2.5]` nos títulos e `MVP2.5` no `STATUS.md`; o gerador do roadmap público precisa ser ajustado ([INFRA] #100).
- `CLAUDE.md`, PRD §1.2/§11, `TOKENS.md`, `FORA-DE-ESCOPO.md`, `RASTREABILIDADE.md` revisados (este ADR é a fonte).
- Bake de lightmap vira passo de build (`tools/`).

**O que vigiar**
- Frame time em GPU integrada (orçamento +4 ms); toon × normal map (água/chão ficam fora do cel).
- Sync inicial 3/3 em toda fatia.
