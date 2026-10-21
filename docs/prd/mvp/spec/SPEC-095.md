# SPEC-095 — Arte nova no meio do mapa: rio, lagoas, pontes, centro, rochas, selva e mato alto

**Fatia:** F95 / SPEC-095 (MVP4, Slice 4.8) · **Issue:** #267 (issue-pai #246) · **Status:** decidida pelo PI em 2026-10-20 (mesmos pop-ups da SPEC-094; mato alto: "sim, mesma área e leitura")
**ADR:** ADR-0030 · **Depende de:** F94 (kit e materiais oficiais)
**Fontes:** ADR-0009/SPEC-046 (rio em anel, braços, lagoas, pontes, cratera, corredores), ADR-0011/SPEC-055 (campos de canto), ADR-0014/F60 (centro livre, lago de magma), F40/F73 (selva, terreno com splat, PBR CC0), SPEC-007 e SPEC-072 (mato alto: colisão, abertura do herói, silhueta), F42 (grama decorativa com vento) · `tools/arena/build_arena.gd`, `arena_terrain.gd`, `arena_vegetation.gd`, `art/arena/build_island.py`
**Escopo:** visual de tudo que fica entre as bases e a borda. Layout, colisão, navmesh, regras e números não mudam.

## 1. Motivo

2ª de 3 fatias da arena nova (ADR-0030): é o que o jogador mais vê durante a partida.

## 2. Entrega

1. **Rio e lagoas:** margem de pedra e terra com detalhe (pedras soltas, juncos/folhagem de beira) e água no estilo novo. O shader do rio (`arcane_river`) pode ser ajustado ou trocado, mantendo a cor arcana da ilha.
2. **Pontes:** nova ponte de cantaria nas duas pontes da MID, cobrindo a largura útil de 5 u (SPEC-046 §2.1).
3. **Centro:** cratera e lago de magma com a borda refeita; rochas do centro e do pátio com cristal (`boulder` + cristal) no estilo novo, cobrindo os cilindros de colisão.
4. **Selva:** os bolsões de selva (rochas `rock_outcrop_*`, pinheiros, troncos) e os campos laterais e de canto, com a folhagem por cartões e vento.
5. **Mato alto:** visual novo com folhagem por cartões e vento. A caixa de colisão, a abertura do herói de quem joga (reveal) e a silhueta (SPEC-072) continuam iguais. O mato tem de seguir lendo como "dá para se esconder aqui".
6. **Chão:** o terreno da ilha (splat do F40/F73) recebe texturas e transições no estilo novo (grama, terra, trilhas), com as trilhas e as clareiras do `jungle.json` legíveis. Grama decorativa revista para combinar com a folhagem nova.
7. **Luz:** lightmap da oficial rebakeado.

## 3. Orçamento

Mesmo da SPEC-094 §3. Frame time medido também na MID e no centro.

## 4. Critério de aceite

1. O meio do mapa está com a arte nova, e o Cavaleiro joga a partida inteira sem erro no log.
2. Colisão, marcadores, corredores (§2.3), pontes e navmesh iguais aos de antes. Os testes de arena (corredores, selva, mato, visão, bot) e o teste de igualdade da colisão (F94) continuam verdes.
3. Mato alto: os testes do F32/F72 continuam verdes (área, abertura, silhueta), e o PI confirma na verificação que a moita ainda lê como esconderijo.
4. `soak.ps1 -Count 50 -Parallel 8` verde. Warm-up cobre os shaders novos, com 3/3 conexões a 100 ms.
5. Frame time antes × depois na MID, no centro e numa moita, e capturas em `docs/evidencias/f95/` e no roadmap.
6. Verificação do PI e CI verde.

## 5. Fora

- Bases (F94), borda e vale (F96), heróis, monstros e baús.
- Mudar layout, colisão, corredores, regras do mato ou números.
