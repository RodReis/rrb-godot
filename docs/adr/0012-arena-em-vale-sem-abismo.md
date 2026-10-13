# ADR-0012 — Arena num vale cercado de floresta e montanhas (fim do abismo)

**Status:** aceito — 2026-10-12
**Decisor:** Rodrigo Reis (PI)
**Supera parcialmente:** ADR-0007 ("ilha flutuante sobre abismo cósmico", ilhotas de fundo, cachoeiras caindo no abismo); ADR-0009 / SPEC-046 §1 e §5 (visual da borda = "beira da ilha + abismo"; ilhotas de fundo ficam); SPEC-040 (abismo e ilhotas).
**Relacionados:** SPEC-056 (corpo da issue) · ADR-0005 · ADR-0006 · ADR-0010 (dia/noite, lightmap sem sol) · SPEC-045 (giro 360° da câmera)

## Contexto

- Pedido do PI (2026-10-12, print do jogo): com o herói no bastião do canto e a câmera girada para fora, metade da tela é céu azul chapado em volta e abaixo da ilha. O PI não quer ver "o fim do mapa"; quer uma continuação do cenário.
- Causa: a câmera (PRD §3.6, `follow_camera.gd`) fica 14 u do herói a 45° — **~9,9 u atrás e ~9,9 u acima** — com FOV vertical 75°. Com o giro livre (SPEC-045), perto da borda ela fica em cima do vazio. A borda de baixo do quadro vê chão até ~11 u além da beira; a borda de cima vê até **~75 u** além da câmera. Estender só a beira atual (42 u) não fecha.
- A arena jogável (`|x|, |z| ≤ 40`, muros em 41 — SPEC-046) e toda a regra de partida não mudam.

## Decisão

1. **A arena deixa de ser ilha flutuante: fica no fundo de um vale.** Em volta da beira atual entra uma **faixa externa só visual** (sem colisão, sem navmesh, fora da regra), colada ao lábio da beira sem fresta.
2. **Relevo:** floresta densa logo depois da beira; depois encostas subindo até **cristas rochosas a ~70–90 u do centro**; chão continua atrás das cristas e uma **neblina de distância** cobre o horizonte. Meta: de qualquer posição jogável, com qualquer giro da câmera, **nenhum pixel de vazio** — só céu acima das cristas.
3. **Cascatas de enfeite NO/SE** viram **riacho**: caem num degrau curto e seguem rasas pela faixa externa até sumir na floresta/neblina. Só visual.
4. **Ilhotas flutuantes de fundo saem.**
5. Céu (`abyss_sky.tres`) e ciclo dia/noite (ADR-0010) ficam; a neblina de distância acompanha as chaves do dia/noite.
6. Implementação pela fatia **F56 / SPEC-056** (Slice 2.22), **depois do F57 (#151) e antes do [GATE] do MVP2 (#69)** — revisão do PI no mesmo dia; o gate homologa a arena já no vale.

## Alternativas rejeitadas

| Alternativa | Motivo |
|---|---|
| Ilha + mar de nuvens abaixo da beira | PI quer continuação do mapa, não céu com nuvens |
| Travar a câmera dentro da ilha | horizonte vazio continua no topo do quadro e tira o giro livre da SPEC-045 |
| Floresta plana até o horizonte | precisa de neblina forte para esconder o fim; PI escolheu vale com montanhas |
| Penhascos e cânion sem vegetação | PI escolheu floresta + montanhas |
| Remover as cascatas / desfiladeiro atrás do bastião | PI escolheu riacho |
| Manter ilhotas no céu | sem abismo, rocha flutuando não faz sentido |
| Deixar para depois do [GATE] #69 | escolha inicial do PI, revista no mesmo dia: entra depois do F57 e antes do gate |

## Consequências

- Arte nova no Blender (ADR-0005): malha de relevo da faixa externa, cristas rochosas, leito do riacho. Pinheiros da faixa por `MultiMesh` (reuso do pinheiro da beira).
- Custo de GPU: área visível maior. Medir frame time antes/depois na mesma câmera e registrar; a faixa externa fica **fora do LightmapGI** (luz do sol + ambiente) para não inflar o `.exr` versionado.
- `CONVENTION.md` §4.1 e a tela Arena & Mapa (F33, MVP3) passam a mostrar o vale; o minimapa da partida continua mostrando só a arena jogável.
- `art/arena/build_island.py` e `tools/arena/` (builder) mudam; o chassi da ilha abaixo do chão fica escondido pelo relevo.
