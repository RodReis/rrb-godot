# ADR-0008 — Arena "Vale Rúnico" preservada congelada; F44 gera a Ilha em cena nova

**Status:** aceito — 2026-10-10
**Decisor:** Rodrigo Reis (PI)
**Supera parcialmente:** ADR-0007 (só o modo de entrega do F44: "regerar `arena.tscn`" e a posição "antes do F17"). Topologia, escala e demais itens do ADR-0007 seguem valendo.
**Relacionados:** SPEC-007 · SPEC-044 §5–6 · `FORA-DE-ESCOPO.md` ("Mais arenas", "Vale Rúnico como arena 1x1 alternativa") · PRD §1.3

## Contexto

- O ADR-0007 mandava o F44 regerar `arena.tscn` no layout da Ilha, apagando na prática o Vale Rúnico (SPEC-007), e entrar antes do F17.
- Até 2026-10-10, F16, F17, F18 e F32 foram mergeados no layout antigo e o F37 (neblina + minimapa) está em andamento nele.
- O PI propôs manter a arena atual ("não desperdiçar") e criar a nova. Avaliação: o PI considera o Vale Rúnico bom para 1x1 e pequeno para 2x2/3x3; quer preservá-lo para uso futuro em 1x1, **sem gastar recurso nele agora**. O nome "Arena Village" foi considerado e descartado: segue "Ilha Flutuante Arcana".

## Decisão

1. **Uma arena oficial na fatia vertical** (PRD §1.3 inalterado): a Ilha Flutuante Arcana (SPEC-044).
2. O F44 gera a Ilha numa **cena nova** (`game/scenes/arena/ilha_arcana.tscn`), que passa a ser a carregada pela partida. A regra "edite o builder, não a cena" continua.
3. O Vale Rúnico fica **congelado**: a cena atual vai para `game/scenes/arena/legacy/vale_runico.tscn`, fora do fluxo da partida, sem teste, sem CI e **sem garantia de abrir**. Não é apagado.
4. Antes do merge do F44 o Code cria a tag `arena-vale-runico` no último commit da `main` em que o Vale Rúnico é a arena jogável (builder da época incluso). A tag é a versão de referência para reviver a arena; a cena congelada é só conveniência.
5. Reviver o Vale Rúnico como segunda arena 1x1 é item de roadmap (`FORA-DE-ESCOPO.md`), não desta fase.
6. **Ordem:** o F37 termina no layout antigo; o F44 entra depois do F37 e antes do F19. O F44 confere no layout novo a neblina e o minimapa do F37 e as moitas do F32.

## Alternativas descartadas

| Alternativa | Por que não |
|---|---|
| Duas arenas oficiais jogáveis agora | contraria PRD §1.3 (1 arena); exige seleção de mapa, argumento novo no contrato Launcher ↔ Game (ADR), GDB/P-02 por arena e testar F37, F19, F40 e F33 nas duas |
| Substituir in-place (só histórico do git) | o PI quer o Vale Rúnico preservado à vista para uso futuro |
| Pausar o F37 e fazer o F44 antes (ADR-0007 à risca) | joga fora trabalho em curso; o ajuste do minimapa/neblina no layout novo é menor que parar o card |
| Nome "Arena Village" | o PI manteve "Ilha Flutuante Arcana"; "vila" seria outra direção de arte (ADR-0006/0007) |

## Consequências

**Positivas**
- A arena antiga não se perde e não cobra manutenção.
- Ilha nova ao lado da antiga facilita comparar e voltar durante o F44.

**Custos**
- A cena congelada apodrece em silêncio conforme scripts, grupos e marcadores mudam; reviver custa um card (a partir da tag).
- F44 ganha itens de aceite: minimapa/neblina (F37) e moitas (F32) no layout novo.

**O que vigiar**
- Nenhum teste, cena ou script de produção pode referenciar `legacy/`.
- Tamanho: a Ilha tem o **mesmo raio 35 u** do Vale Rúnico (SPEC-044 §1). Se o tamanho não comporta 2x2/3x3, vale para as duas; isso se decide no gate M4 (`FORA-DE-ESCOPO.md`, "Modos 2x2 e 3x3").
