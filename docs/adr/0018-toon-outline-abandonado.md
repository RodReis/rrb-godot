# ADR-0018 — Toon/outline abandonado no aceite do F39

**Status:** aceito — decisão do PI em 2026-10-10 (aceite do F39); registrada nesta ADR em 2026-10-19
**Decisor:** Rodrigo Reis (PI)
**Emenda:** [ADR-0006](0006-direcao-visual-toon-pbr.md) item 1 — retira "toon/outline" da direção artística
**Mantém:** ADR-0006 itens 2 a 6 (Forward+ only, LightmapGI, bevel/bake no cenário próprio, malhas de água e chão, design system v2) · ADR-0005 (Blender)
**Relacionados:** ADR-0015 · ADR-0016 · PRD §9.1 (M2.5) e §11 · `CLAUDE.md` §Assets 3D · F39 (#94)

## Contexto

O item 1 do ADR-0006 fixou "toon/outline + stylized PBR". O F39 (Slice 2.5.2, "Toon + outline por pós-import") foi implementado, e o PI **abandonou** o toon/outline no aceite visual em 2026-10-10: entrou smooth shading e luz macia no lugar. A decisão ficou no PRD (§9.1 e §11) e no `CLAUDE.md`, mas nenhuma ADR a registrou. Os ADR-0006, ADR-0015 e ADR-0016 continuaram descrevendo heróis, monstros e Servos como "toon/outline".

## Decisão

1. **Não há cel-shading nem contorno** em heróis, monstros, Servos ou cenário. O item 1 do ADR-0006 vale como "stylized PBR" (luz física, sombras suaves, SSAO, SSIL, glow, fog sutil), sem toon/outline.
2. Personagens e props dos packs CC0 ficam como vêm (faces planas, cor por UV no atlas), com as exceções já aceitas: Ocultista (atlas próprio e capuz, ADR-0016) e Berserker (elmo de chifres, F75).
3. Onde o ADR-0006 (item 1 e "O que vigiar"), o ADR-0015 (itens 11 e "Mantém") e o ADR-0016 (arte nova do Servo) dizem "toon/outline", lê-se sem toon/outline. Os textos originais não foram reescritos; cada um ganhou uma nota apontando para esta ADR.

## Consequências

- Nada muda em código, asset ou teste: esta ADR só registra o que já estava em vigor.
- A opção "tirar toon/outline" listada como rejeitada em `FORA-DE-ESCOPO.md` já está superada por esta ADR; a direção que o PI manteve no ADR-0015 é a do stylized PBR com heróis como vêm.
