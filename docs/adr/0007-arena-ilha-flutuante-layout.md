# ADR-0007 — Arena "Ilha Flutuante Arcana": simetria por espelho N–S, rio N–S + anel, 4 pontes

**Status:** aceito — 2026-10-10
**Decisor:** Rodrigo Reis (PI)
**Relacionados:** PRD §3.1 · GDB §5.1, §6.2, §7.1 · SPEC-007 (superada em §2, §3, §6.1/2/6) · **SPEC-044** · ADR-0006 · `RASTREABILIDADE.md` V-15, P-02 · doc `docs/prd/especificacao_reforma_arena_godot_blender.md` · imagem `docs/prd/telas/Arena & Mapa — O Vale Rúnico Apocalíptico/full_high_resolution_panoramic_wide_battleground_view_of_the_stylized_3d_low.png`

## Contexto

- A SPEC-007 (2026-10-09) fixou a arena como "Vale Rúnico": simetria por rotação de 180°, bases opostas (SO/NE), rio diagonal + anel, **2 pontes** (travessia única por metade), raio 35 u. A imagem panorâmica do conceito era "referência de clima, não de layout" (SPEC-007 §5); o layout vinha da imagem tática.
- Em 2026-10-10 o PI trouxe um documento de reforma (Rodrigo/Gemini) e pediu a arena **como na imagem panorâmica**: ilha flutuante sobre abismo cósmico, castelos nas bases, rio de mana em anel com 4 pontes, cratera de magma, cristais, cachoeiras.
- O ASCII do documento colocava as duas bases no norte e os campos laterais em O/L/SO/SE sem metades por time — o que quebra o core loop da fase 1 (PRD §3.1: metade segura por time). O Cowork propôs uma topologia que adota a imagem **e** preserva o core loop: espelho no eixo N–S, rio N–S dividindo as metades O/L, anel com 4 pontes (2 por metade).
- F36 (campos laterais) e F20 já estavam mergeados quando a decisão foi tomada; F14 em andamento.

## Decisão

1. **A imagem panorâmica passa a ser referência de layout** (inverte SPEC-007 §5). O layout normativo é a **SPEC-044**: simetria por espelho em `x`, bases nos cantos norte (`(∓24, −24)`), rio N–S (`|x| ≤ 2 u`, `r > 18 u`) + anel `14 < r ≤ 18 u`, **4 pontes** nos azimutes 45°/135°/225°/315° (2 por metade), campos do centro em 0°/180°, cratera, pilares, raio 35 u e escala inalterados.
2. **Core loop preservado:** metade A = oeste, metade B = leste; entre metades só pela ilha central; portões e bases como antes.
3. **Dois cards:** **F44** (MVP2, greybox jogável; logo após o F16 — que já estava em andamento — e antes do F17) troca o layout no builder, colisão, marcadores, portões, mato e navmesh, **sem arte nova**; **F40** (MVP2.5, bloco visual) faz a arte da ilha sobre esse layout.
4. **Torres de vigia e balistas/canhões da imagem são só enfeite**, sem colisão nem função, fora da área jogável (a decisão "sem torres" de 2026-10-09 continua).
5. Continuam excluídos: relevo, degraus nas pontes, fosso (a cratera é plana; o magma é visual).
6. Os campos laterais do F36 são **reposicionados** pelo F44 (marcadores são dados do builder); contagens do GDB inalteradas. Os tempos de referência da SPEC-007 §1 (6,3 s spawn→centro) valem como aceite; spawn→spawn pela ilha é medido no F44 e passa a ser o valor de referência (P-02 atualizado).

## Alternativas descartadas

| Alternativa | Por que não |
|---|---|
| Imagem só como clima (reskin da SPEC-007) | o PI quer o layout da imagem |
| ASCII do documento literal (bases adjacentes sem metades) | quebra a metade segura por time (PRD §3.1) e o F36; exigiria rever PRD e GDB §5.1 |
| Topologia atual + 4 pontes | mantém a diagonal, mas não entrega a imagem (bases nos cantos norte, rio N–S) |
| Layout só no MVP2.5 junto com a arte | F16/F17/F32/F37 (minimapa) e o soak do F19 seriam feitos na arena antiga e refeitos |
| Layout antes do F36 | F36 já estava mergeado quando a decisão foi tomada |

## Consequências

**Positivas**
- O F33 (tela Arena & Mapa) e o roadmap mostram a arena que o conceito prometia.
- Cada time passa a ter 2 rotas para a ilha: menos "fila de uma ponte", mais escolha.

**Custos**
- Reposicionar os campos do F36 e as moitas do F7; re-medir tempos; 1 card a mais no MVP2 antes do F16.
- A emboscada de "travessia única" some — vigiar no playtest (M4) se a fase 1 ficou passiva demais.
- `CONVENTION.md` §(mapa), PRD §3.1, `RASTREABILIDADE.md` V-15/P-02 e SPEC-007 (nota de superação) atualizados.

**O que vigiar**
- Bot (F12/F19) escolhendo ponte e não travando no canal N–S; navmesh assado em runtime cobrindo as 4 pontes.
- Minimapa do F37 lendo o layout novo.
