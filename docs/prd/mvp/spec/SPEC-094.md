# SPEC-094 — Arte nova nas bases A e B da arena oficial

**Fatia:** F94 / SPEC-094 (MVP4, Slice 4.7) · **Issue:** #266 (issue-pai #246) · **Status:** decidida pelo PI em 2026-10-20 (pop-ups: "aprovado cenário, vamos implementar em toda arena"; "Code cria tudo agora"; "3 fatias por região"; "MVP4, antes do playtest"; "Mato alto: sim, mesma área e leitura")
**ADR:** ADR-0030 · **Base:** SPEC-084/F84 (kit, folhagem e builder da variante; PR #265)
**Fontes:** ADR-0005, ADR-0006 item 7 (netcode e frame time), ADR-0009/SPEC-046 (layout e colisão das bases), ADR-0012 (vale), F50 (pátio), F64 (fonte), SPEC-007 §5 (cor do time: ciano A, dourado B) · `art/spike/f84/build_spike_f84.py` · `tools/arena/build_spike_f84.gd` · `docs/evidencias/f84/`
**Escopo:** visual das duas bases e dos dois pátios na `ilha_arcana.tscn`. Layout, colisão, navmesh, marcadores e números não mudam.

## 1. Motivo

O PI aprovou o cenário do spike (F84) e pediu a arte nova na arena inteira (ADR-0030). Esta é a 1ª de 3 fatias: as bases, onde o kit já existe.

## 2. Entrega

1. **Kit oficial:** o kit do F84 sai do caminho de spike e vira o da arena. O script vai para `art/arena/build_castle_er.py` (ou nome equivalente) e os `.glb` para `shared/assets/rrb/arena/`. O Code escolhe os nomes e registra na PR. Os materiais saem de `spike_f84/` para um nome de arena, e as texturas idem, com licenças atualizadas.
2. **Bases A e B no builder oficial:** `tools/arena/build_arena.gd` monta muralha, mureta interna, torres, portão e folhas, torreão, casas, pátio (sobrado, casinha, galpão), fonte, praça e props com o kit novo nas duas bases, a B pela rotação de 180° como hoje. Saem os `castle_*_a/b`, `stone_house`, `megakit_*` e a `fountain.glb` antiga da arena (os arquivos ficam se outro uso existir; o Code confere).
3. **Cor do time:** estandartes, escudos e flâmulas em ciano na base A e dourado na base B (SPEC-007 §5).
4. **Folhagem das bases e dos pátios:** moitas, arbustos, touceiras floridas e floreiras com vento, como no F84.
5. **Luz:** lanternas e luzes das duas bases sob o `Ambience`, e lightmap da oficial rebakeado (`tools/bake-lightmap.ps1`).
6. **Variante do spike sai:** saem `spike_f84.tscn`, o builder dela, `--arena`/`LaunchArgs.ARENA_VARIANTS`, a troca no `main.gd` e o `scenery_capture --poses=f84` (as poses podem ficar para a oficial). Com isso, o F93 passa a usar a arena oficial (ADR-0030, Consequências).

## 3. Orçamento (ADR-0030 item 4)

| Item | Teto |
|---|---|
| Triângulos | ≤ 1.600 por objeto (peça grande partida) |
| Texturas | ≤ 2K |
| GPU | frame time medido, oficial antes × depois, em 3 rodadas alternadas, na base A e na base B; teto do bloco +4 ms médios (ADR-0006 item 7) |

## 4. Critério de aceite

1. As duas bases da arena oficial estão com a arte nova, e a base B tem a cor do time B. O Cavaleiro joga a partida inteira sem erro no log.
2. A colisão, os marcadores e o navmesh são iguais aos de antes. Um teste GUT compara as formas e os marcadores com os da arena antes da fatia (fixture ou contagem e transform), e os testes de arena que já existem continuam verdes.
3. `soak.ps1 -Count 50 -Parallel 8` verde, porque a fatia mexe na cena que o servidor carrega.
4. Warm-up cobre os shaders novos (folhagem); 3/3 conexões a 100 ms sem `past the history limit` (ADR-0006 item 7).
5. Frame time antes × depois nas duas bases, e capturas antes × depois (câmera do jogo e closes) em `docs/evidencias/f94/` e no roadmap.
6. O PI vê as duas bases (o Code sobe tudo e deixa aberto).
7. CI verde.

## 5. Fora

- O meio do mapa (F95), a borda e o vale (F96).
- Heróis, monstros e baús (F93 e futuras).
- Qualquer mudança de layout, colisão, navmesh ou número.
