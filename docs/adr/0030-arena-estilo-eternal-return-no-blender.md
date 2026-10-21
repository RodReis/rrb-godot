# ADR-0030 — Arena no estilo Eternal Return, feita no Blender pelo Claude

**Status:** aceito — decisão do PI em 2026-10-20 (pop-ups no aceite do F84 e no pedido "vamos implementar em toda arena")
**Data:** 2026-10-20
**Decisor:** Rodrigo Reis (PI)
**Emenda:** ADR-0006 itens 1 e 4 (direção do cenário próprio e cor-base pelo atlas KayKit) · `CLAUDE.md` §Assets 3D (estilo e orçamento do cenário)
**Relacionados:** ADR-0005 (pipeline Blender) · ADR-0024 item 5 (spike visual) · SPEC-084/F84 (#247, PR #265) · SPEC-093/F93 · SPEC-094 a SPEC-096

## Contexto

O spike do F84 refez a base A e o pátio no estilo Eternal Return, numa cena variante jogável (`spike_f84.tscn`). O cenário foi feito no Blender por script: muralha, torre, portão, torreão, casas, fonte, praça e props. As texturas são PBR CC0 do Poly Haven, e a folhagem é feita de cartões de folha CC0 do ambientCG, com vento. As medições e capturas estão em `docs/evidencias/f84/`. O frame time de GPU ficou em +0,12 ms (+3 %) na câmera da base. O PI jogou a cena e escolheu o caminho "seguir no Blender pelo Claude". Em seguida aprovou o cenário e pediu a arte nova na arena inteira.

## Decisão

1. **Direção do cenário próprio:** semi-realista no estilo Eternal Return. Isso significa proporções reais, bevel nas quinas, blocos e tábuas onde a câmera vê e PBR por UV planar em metros (≤ 2K). A cor de vértice traz sujeira perto do chão e variação por peça. Vale para tudo de `shared/assets/rrb/` que for cenário: castelos, muralhas, casas, pontes, rochas, rio, piso e props de borda. A cor-base pelo atlas KayKit deixa de valer para esse cenário.
2. **Quem faz:** o Claude, no Blender por script (ADR-0005), com fonte em `art/`. A referência de estilo é o Eternal Return, mas nenhum asset dele é copiado.
3. **Folhagem:** cartões de folha (atlas CC0) com normais esféricas, recorte por alpha scissor e vento suave (`shared/shaders/spike_foliage.gdshader`). O mato alto (moita de esconder, SPEC-007/SPEC-072) também ganha esse visual. A área, a colisão, a abertura do herói e a silhueta dele não mudam.
4. **Orçamento:** até 1.600 triângulos por objeto, como decidiu o PI no spike ("pode passar, medindo"); peças grandes são partidas. Texturas ≤ 2K. O frame time é medido em toda fatia, e o teto do bloco visual segue o do ADR-0006 item 7 (+4 ms médios no PC do PI).
5. **Na arena oficial**, em 3 fatias por região, no MVP4, antes do playtest: F94 (bases A e B), F95 (meio do mapa: rio, lagoas, pontes, centro, rochas, selva e mato alto) e F96 (borda e vale). Layout, colisão, navmesh e números não mudam (SPEC-046, ADR-0012).
6. **Fica de fora:** personagens e props dos packs CC0, ou seja, heróis, monstros e baús. O herói é do F93 (comissionado).

## Alternativas descartadas

| Alternativa | Por que não |
|---|---|
| Comprar pacote de cenário | o PI escolheu o Blender pelo Claude depois de jogar o spike |
| Comissionar o cenário | idem; a comissão fica só para o herói (F93) |
| Manter o visual atual até o EA | o PI quer o playtest já com o visual novo |

## Consequências

- `CLAUDE.md` §Assets 3D passa a citar este ADR para o estilo e o orçamento do cenário próprio. O ADR-0006 continua valendo no resto: Forward+, LightmapGI e os critérios de netcode do item 7.
- Toda fatia de arte da arena prova: (a) warm-up dos shaders novos antes do `connect` e 3/3 conexões a 100 ms (ADR-0006 item 7); (b) colisão e marcadores iguais aos de antes (teste); (c) frame time oficial antes × depois, em rodadas alternadas.
- A cena variante `spike_f84.tscn` e o `--arena=spike_f84` saem quando a base A da oficial receber a arte (F94). A partir daí o F93 usa a arena oficial.
