# SPEC-084 — Spike visual, parte 1: canto SO (base A + pátio) no estilo Eternal Return, em cena separada e jogável

**Fatia:** F84 / SPEC-084 (MVP4, Slice 4.3) · **Issue:** #247 (issue-pai #246) · **Status:** decidida pelo PI em 2026-10-19 (pop-ups do Cowork: "Cavaleiro"; "Base SO + pátio"; "Blender pelo Claude"; "Cena separada, só comparação"; "Pode passar, medindo"; "Eternal Return"; "Jogando a cena"; "Herói comissionado, cenário no Blender"; "Partir em 2")
**ADR:** ADR-0024 item 5 · **Par:** SPEC-093 (F93, Cavaleiro comissionado — parte 2 do spike)
**Fontes:** ADR-0005 (pipeline Blender), ADR-0006 (direção visual atual — **não muda** nesta fatia), ADR-0009/SPEC-046 (layout e colisão da base SO), ADR-0012 (vale), F50 (pátio, Medieval Village MegaKit), F64 (fonte de cura), F73 (PBR CC0 ≤ 2K e baseline de GPU) · `tools/perf/frametime_probe.gd` · `tools/bake-lightmap.ps1`
**Escopo:** só visual, só numa cena variante da arena carregada por argumento de dev. A arena oficial, o Launcher, o servidor e os números não mudam.

## 1. Motivo

O PI quer saber se o visual do Loot Start pode chegar perto do Eternal Return sem trocar de engine (ADR-0024). A análise apontou que o limite é a arte, não o Godot. Este spike mede isso no cenário: o canto que o jogador vê primeiro (base A + pátio), refeito no Blender pelo Claude, jogável com o Cavaleiro atual. A parte do herói vem no F93, com arte comissionada.

## 2. Entrega

1. **Cena variante** `game/scenes/arena/spike_f84.tscn`: a mesma arena oficial, com o visual da **base A (SO) e do pátio** trocado pela arte nova. Todo o resto da arena fica como está.
   - Recomendação: cena herdada da `ilha_arcana.tscn` (ou equivalente que o Code escolher) que só troca os nós visuais da base SO; registrar a forma na PR.
2. **Argumento de dev** para carregar a variante no treino offline (ex.: `--arena=spike_f84`). É argumento de dev/servidor (`ARCHITECTURE-LAUNCHER.md` §5.2: o Launcher nunca o envia), **não** entra no contrato.
3. **Arte nova no estilo Eternal Return**, feita pelo Claude no Blender MCP:
   - Castelo/muralha da base, portão A (visual), fonte de cura, construções do pátio, chão da base e props de borda do canto.
   - Direção: mais realista que o low-poly do KayKit — proporções reais, detalhe de geometria (bevel, pedras e tábuas individuais onde a câmera vê), materiais PBR com normal e roughness, desgaste, vegetação de borda mais densa.
   - Texturas PBR **CC0** (ambientCG, Poly Haven ou equivalente), até **2K**, licenças em `shared/assets/LICENSES.md`.
   - Nada copiado do Eternal Return: é referência de estilo, não de asset.
   - Fonte em `art/spike/f84/`, exportado em `.glb` para `shared/assets/rrb/spike/f84/`.
4. **Colisão intacta:** a colisão da base vem do builder (SPEC-046). A malha nova cobre a colisão, nunca menor (regra do `CLAUDE.md`). Sem colisão nova.
5. **Luz da variante:** lightmap rebakeado só para a cena variante (`bake-lightmap.ps1` apontado para ela). Ajuste de `WorldEnvironment`/luz é permitido **só na variante**, registrado na PR.

## 3. Orçamento (decisão do PI: "pode passar, medindo")

| Item | Hoje (ADR-0006) | No spike |
|---|---|---|
| Prop/cenário | 50–800 triângulos | até ~2× (≤ 1.600 por peça); peças grandes (castelo) podem ser partidas |
| Texturas | ≤ 2K (F73) | ≤ 2K |
| GPU | baseline F73 | **medido**, sem teto: frame time na base SO, variante × oficial, mesma máquina, mesma câmera |

## 4. Critério de aceite

1. Cena variante abre pelo argumento de dev no treino offline; o Cavaleiro atual anda, ataca e usa Q/E/R no canto novo; a partida roda até o fim sem erro no log.
2. A arena oficial é idêntica à de antes: `git diff` não toca `ilha_arcana.tscn`, o builder nem a colisão; soak curto (`soak.ps1 -Count 10`) verde na arena oficial.
3. Frame time medido (`frametime_probe.gd`) na base SO: oficial × variante, registrado em `docs/evidencias/f84/`.
4. Capturas lado a lado (oficial × variante) na câmera do jogo (11 u) e em close, em `docs/evidencias/f84/` e no roadmap (`docs/roadmap/`).
5. **Verificação do PI jogando a cena** (o Code sobe tudo e deixa aberto). O PI registra a decisão do caminho do cenário: seguir arte própria no Blender, comprar pacote ou comissionar. Essa decisão vira ADR do Cowork; a ADR-0006 só muda com ela.
6. CI verde.

## 5. Fora

- Herói novo (F93), outros cantos, a base B (NE), HUD, Launcher.
- Levar a arte nova para a arena oficial (fatia própria, depois da decisão do item 5).
- Mudar números, colisão, navmesh ou regras.

## 6. Riscos conhecidos

- Estilo misto no F84: cenário semi-realista com o Cavaleiro KayKit low-poly vai parecer desencaixado. É esperado; o F93 fecha a comparação.
- Modelagem por script tem limite em formas orgânicas; se o resultado ficar abaixo da referência, isso é o achado do spike, não falha do card.
