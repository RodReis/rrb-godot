# F97 / SPEC-097 — Escala da interface do jogo

Evidência de aceite (issue #272, ADR-0031). O contrato `settings.cfg` ganhou `[ui] hud_scale`, de 70 a 100 %, com padrão de 85 %. O Game aplica a escala em `get_tree().root.content_scale_factor`.

## Capturas (aceite 4)

As capturas vêm das vitrines `tools/ui/hud_showcase.gd`, `hero_select_showcase.gd` e `match_end_showcase.gd`, com a opção nova `--ui-scale <x>`. O Launcher veio de `capture_launcher.gd --route=settings`.

| Arquivo | O que mostra |
|---|---|
| `hud_1080p_100_x_85.webp` | HUD da fase 1 em 1920x1080: 100 % (como era) à esquerda e 85 % (padrão novo) à direita |
| `engrenagem_1080p_100_x_70.webp` | engrenagem aberta com o controle "Tamanho da interface": 100 % × 70 % |
| `hud_720p_100_x_70.webp` | HUD da fase 1 em 1280x720: 100 % × 70 % |
| `fase2_85_720p_x_1080p.webp` | HUD da fase 2 a 85 %: 1280x720 × 1920x1080 |
| `selecao_720p_70.webp` | seleção de heróis a 70 % em 1280x720 |
| `fim_720p_70.webp` | fim de partida a 70 % em 1280x720 |
| `launcher_configuracoes.webp` | Configurações do Launcher com "Tamanho da interface na partida" no card de gráficos |

De 70 a 100 %, todas as capturas saíram no tamanho de janela pedido, sem nada fora da tela nem sobreposto.

## Por que o teto é 100 % (decisão do PI, 2026-10-21)

A faixa pedida era de 70 a 120 %. Com o stretch `canvas_items` e o aspecto `expand`, a área lógica é 1920x1080 dividido pelo fator. A 120 % ela vira 1600x900, qualquer que seja o tamanho da janela. Nessa escala, a seleção de heróis sobrepôs os cartões, e a janela de 1280x720 cresceu sozinha para 1920x1009 para caber o mínimo do conteúdo. O PI escolheu em pop-up baixar a faixa para 70 a 100 %, mantendo o padrão de 85 %.

## Testes (aceites 1 a 3)

- `shared/test/test_user_settings.gd` cobre:
  - padrão 0,85 e limites 0,70 e 1,00;
  - passo do slider com arredondamento de float;
  - 0,5, 1,2, 2,0 e texto voltam ao padrão;
  - arquivo sem `[ui]` lê o padrão;
  - ida e volta pelo arquivo;
  - `save_value` grava uma chave sem desfazer a `[camera] distance`.
- `shared/test/test_settings_applier.gd`: a escala vira o `content_scale_factor` da janela.
- `game/test/unit/test_hero_plate.gd`: o slider da engrenagem abre na escala atual. Enquanto arrasta, só o número muda; ao soltar, aplica na janela e grava só a escala, sem desfazer o zoom.
- `launcher/test/unit/test_settings_screen.gd`: o controle vai de 70 a 100 %, abre em 85 % e grava ao salvar. "Restaurar padrões" volta a 85 %, pelo teste que já existia.
- Resultado: game 1794/1794, launcher 771/771.
