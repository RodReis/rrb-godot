# SPEC-096 — Arte nova na borda da ilha e no vale

**Fatia:** F96 / SPEC-096 (MVP4, Slice 4.9) · **Issue:** #268 (issue-pai #246) · **Status:** decidida pelo PI em 2026-10-20 (mesmos pop-ups da SPEC-094)
**ADR:** ADR-0030 · **Depende de:** F94 e F95 (kit, materiais e folhagem oficiais)
**Fontes:** F40 (moldura: floresta da borda, tochas, cristais, cavalo-de-frisa, torre de vigia, balista), ADR-0012/F56 (vale: terreno, riacho, pinheiros, neblina de distância, cascata nos bastiões NO/SE) · `tools/arena/arena_dressing.gd`, `arena_valley.gd`, `art/arena/build_island.py`, `art/arena/build_valley.py`
**Escopo:** só o visual fora da área jogável (borda da ilha e vale). Nada de colisão nova.

## 1. Motivo

3ª e última fatia da arena nova (ADR-0030): a moldura que fecha o quadro em volta da partida.

## 2. Entrega

1. **Borda da ilha:** floresta da borda com árvores no estilo novo (tronco modelado e copa por cartões com vento), tochas, cristais arcanos, cavalo-de-frisa, torre de vigia e balista refeitos com o kit e os materiais oficiais.
2. **Chassi e bastiões:** a ilha (`island_chassis`) e os bastiões, incluindo a poça e a cascata dos cantos NO e SE, com cantaria e rocha no estilo novo.
3. **Vale:** terreno, riacho e pinheiros do vale no estilo novo. As encostas continuam fundindo na neblina de distância (ADR-0012).
4. **Luz:** lightmap rebakeado. O vale segue com o preenchimento de ambiente (`ambient_lift`) se continuar fora do bake.

## 3. Orçamento

Mesmo da SPEC-094 §3. A floresta e o vale entram por MultiMesh ou instâncias, conforme o Code medir; o frame time é medido com a câmera do jogo nas bordas e em visão aberta (cinemática de abertura, F69).

## 4. Critério de aceite

1. A borda e o vale estão com a arte nova, e a partida roda inteira sem erro no log.
2. Colisão, marcadores e navmesh iguais (teste do F94), sem colisão nova.
3. `soak.ps1 -Count 50 -Parallel 8` verde. Warm-up cobre os shaders novos, com 3/3 conexões a 100 ms.
4. Frame time antes × depois na borda e na cinemática de abertura, e capturas em `docs/evidencias/f96/` e no roadmap.
5. Verificação do PI e CI verde.

## 5. Fora

- Bases (F94), meio do mapa (F95), heróis, monstros e baús.
- Área jogável nova, colisão ou números.
