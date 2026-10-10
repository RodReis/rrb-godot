# ADR-0009 — Arena "Rift Medieval adaptado": borda quadrada, rio em S NO–SE, 3 rotas, Ilha Arcana v1 preservada só por tag

**Status:** aceito — 2026-10-10
**Decisor:** Rodrigo Reis (PI)
**Supera parcialmente:** ADR-0007 (topologia: espelho N–S, rio N–S + anel, 4 pontes, bases nos cantos norte, arena circular). Direção de arte, kits e shaders do ADR-0006/0007 seguem valendo. **Desvia do ADR-0008** num ponto: a arena substituída não ganha cópia em `legacy/` — só tag.
**Relacionados:** SPEC-044 · SPEC-046 · GDB §7.1 (zona, inalterada — ADR-0004) · imagem tática de `docs/prd/telas/Arena & Mapa — O Vale Rúnico Apocalíptico/`

## Contexto

- O F44 (#109, mergeado em 2026-10-10) entregou a Ilha Flutuante Arcana: arena circular `r` 35 u, espelho N–S, rio N–S + anel, 4 pontes, com a arte do F40 (kits Blender, shaders, baú).
- No mesmo dia o PI decidiu relayout a partir da imagem tática ("Rift Medieval adaptado"): escala 40, rio em S na diagonal NO–SE, selva sem torres (29 monstros e 24 baús do GDB mantidos), borda quadrada com a zona circular dentro. Kits ficam; chassi, rio e posições do builder regeram-se.
- Quatro pontos ficaram em aberto e foram decididos pelo PI em pop-up (abaixo).

## Decisão

1. **Escala:** quadrado de meia-lado **40 u** (80 × 80). **Spawns ficam a ≤ 35 u do centro** (`(∓24, ±24)` = 33,9 u) — dentro da zona 100 % do GDB §7.1, que **não muda**. Os cantos ficam fora da zona desde 5:00: são castelo e enfeite, não spawn. Tempo spawn → centro continua 6,3 s ± 10 %.
2. **Rio em S NO–SE** que bloqueia (projétil passa) ⇒ bases em **SO (A)** e **NE (B)**; simetria por **rotação de 180°** (não espelho). A cratera é uma ilha no meio do S (anel 14–18 u mantido); os braços terminam em **lagoas** que não tocam a borda.
3. **3 travessias:** TOP contorna a lagoa NO, MID cruza o anel por **2 pontes** (135°, 315°), BOT contorna a lagoa SE. Sem ponte nas pontas do rio, sem ponte de selva.
4. **3 corredores livres de 8 u** (TOP pelas bordas O/N, MID na diagonal, BOT pelas bordas S/L) sem colisor nem mato; **selva (4 campos do F36, rochas, moitas) nos quadrantes** entre eles. Sem torres, sem minions.
5. **Ilha Arcana v1 preservada só por tag** `arena-ilha-arcana`; o builder regera `ilha_arcana.tscn` **no lugar**, sem `legacy/`. O ADR-0008 continua valendo para o Vale Rúnico (já congelado); não se abre nova pasta congelada por relayout.
6. **Ordem:** F46 entra logo depois do F44 e **antes do F19** (soak nasce no layout final).

## Alternativas descartadas

| Alternativa | Por que não |
|---|---|
| Meia-lado 40 com spawn no canto e zona 100 % = 48 u | altera GDB §7.1 (ADR-0004), todos os testes de zona e o pacing da fase 2 |
| Meia-lado 45 como na imagem (±45) | mesmo problema da zona, ampliado; mapa 65 % maior em área sem número do GDB que peça isso |
| Manter raio 35, só mudar a forma | perde a leitura "Rift" (cantos, rotas pelas bordas) que o PI quer |
| 5 travessias (3 + 2 pontes de selva) | mais rotas de emboscada, mais caminhos para bot e autopilot; volta se o playtest mostrar funil na MID |
| Só a cratera como travessia | fase 2 vira funil único pelo boss |
| Campo aberto sem corredores | sem conceito de rota; bot e leitura do mapa piores |
| Congelar a Ilha v1 em `legacy/` (ADR-0008) | segunda cena congelada apodrecendo; a tag basta — a v1 nunca foi jogada por ninguém fora do dev |
| Sem tag, só git log | a tag custa nada e é o ponto de retorno citado em `FORA-DE-ESCOPO.md` |

## Consequências

**Positivas**
- Layout legível (3 rotas + selva por quadrante) com a arte já pronta; zero kit novo.
- Base, portão, spawn e medidas spawn → centro **iguais** às da SPEC-044/007: testes de portão, fonte e tempo de base não mudam.
- Borda quadrada simplifica minimapa e neblina (`world_extent` quadrado).

**Custos**
- Segundo relayout no mesmo dia: builder, chassi Blender, testes de simetria/borda/pontes e snapshots do roadmap refeitos (F46).
- Cantos fora da zona: conteúdo de base além de 35 u (parte do castelo) é só enfeite; a fonte fica dentro (33,8 u).
- Só 1 ponte por metade para a ilha central: contestação do centro concentra na MID. Vigiar no F19/[GATE] (funil → reabrir "5 travessias").
- Cascatas do F40 saem (rio não toca mais a borda).

**O que vigiar**
- `test_ilha_arcana.gd`: espelho → rotação; 4 → 2 pontes; `r` 35 → `max(|x|,|z|)` 40.
- Corredores livres: asserção no builder e GUT, para rocha ou moita não entrar na rota por acidente.
- Nome público no roadmap: "Ilha Flutuante Arcana — layout v2"; "Rift Medieval adaptado" é nome interno de layout.
