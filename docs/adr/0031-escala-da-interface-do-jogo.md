# ADR-0031 — Escala da interface do jogo em `settings.cfg`: `[ui] hud_scale`

**Status:** aceito. Decisão do PI em 2026-10-21, na verificação do F95 ("a HUD do jogo está grande, principalmente a de baixo no centro, atrapalha muito a visão"). O PI escolheu em pop-up: escala configurável, mudada no Launcher e dentro da partida, faixa de 70 a 120 % e padrão de 85 %. Também pediu que o Code abrisse a fatia (F97 / SPEC-097, issue #272).
**Decisor:** Rodrigo Reis (PI)
**Emenda:** `ARCHITECTURE-LAUNCHER.md` §5.3 (contrato `user://settings.cfg`, ADR-0002): seção nova `[ui]`.
**Relacionados:** F24 (#80, nasceu o contrato) · F57 (HUD moderna) · F67 (`[camera] distance`, gravada pelo Game) · F97 · [Godot 4.7, Multiple resolutions › Stretch Scale](https://docs.godotengine.org/en/4.7/tutorials/rendering/multiple_resolutions.html)

## Contexto

O painel de baixo, o minimapa e os avisos foram desenhados para a base de 1920x1080 (stretch `canvas_items`, aspecto `expand`). O PI achou o HUD grande demais e tapando a visão. Não há chave de escala no contrato, e mudar o `settings.cfg` exige ADR (`ARCHITECTURE-LAUNCHER.md` §5).

## Decisão

1. **Chave nova:** `[ui] hud_scale = float`, de 0.70 a 1.20, em passos de 0.05, com padrão 0.85. Valor fora da faixa ou de tipo errado volta ao padrão, como a `[camera] distance`.
2. **Quem aplica:** o Game, no boot e a cada mudança. Ele usa `get_tree().root.content_scale_factor = hud_scale`, que a doc do 4.7 indica para expor a escala ao jogador com `canvas_items`. A chave vale para **toda a interface 2D do jogo**: HUD, seleção de herói, fim de partida, menu do Esc e telas de loading. O 3D não muda, e isso inclui as barras de vida e os nomes sobre os personagens. O Launcher não usa a chave.
3. **Quem grava:**
   - O Launcher grava a chave na tela Configurações.
   - O Game grava só `[ui] hud_scale` quando o jogador muda pelo ⚙ "Opções do jogo". Antes de gravar, relê o arquivo, como faz com o zoom no F67.
   - A mudança vale na hora, sem reiniciar.
4. **`schema` continua 1.** A mudança é aditiva: arquivo sem `[ui]` lê o padrão.
5. **O padrão 0,85 vale também para quem já tem `settings.cfg`.** Na primeira partida depois da atualização, a interface abre menor. É o pedido do PI.

## Consequências

- `UserSettings` (`shared/`) ganha a seção `[ui]` com faixa e padrão, e o teste de contrato em `shared/test/` passa a cobri-la.
- As telas do Game têm de caber de 70 % a 120 % na janela mínima de 1280x720. A 120 %, a base efetiva cai para 1600x900, e o layout que não couber é bug da fatia.
- Fora: escala do Launcher, escala por painel e tamanho de fonte separado.
