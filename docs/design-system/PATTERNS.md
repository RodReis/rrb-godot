# PATTERNS.md — Padrões de composição

Como os componentes se combinam. Cada padrão diz **quando usar**, **estrutura** e **o que não fazer**.

## P1 — Layout de tela do Launcher

Quando: toda tela que não é o lobby. Estrutura: `FRONTEND-LAUNCHER.md` §3 (`ScreenHeader` → corpo → `ScreenFooter`). Margem externa `SPACE_SCREEN`; colunas separadas por `SPACE_XL`. Não fazer: título fora do `ScreenHeader`; botão "voltar" em outro lugar.

## P2 — Lobby (hub)

Coluna esquerda `SIZE_NAV_COL` (logo, `PanelCard` do jogador, `VBox` de `ButtonPrimary`/`Button` com `SPACE_MD`); centro expande sobre o diorama; coluna direita `SIZE_SIDE_COL` (status do backend, card de fila). Rodapé `ScreenFooter` com região/versão. Fila é **estado do card direito**, não tela (`PULSE_QUEUE` na borda; `TimerLabel`; botão cancelar `ButtonDanger`).

## P3 — Lista + detalhe (bestiário, forja, histórico)

`CatalogList`/`Tree` à esquerda (`SIZE_LIST_COL`), `DetailCard` à direita expandindo. Seleção por teclado (setas) e mouse; o primeiro item vem selecionado. `StateBox` envolve o detalhe. Não fazer: scroll na tela inteira — só na lista.

## P4 — Formulário (login, configurações)

`FormRow` empilhados com `SPACE_SM`; botão primário no fim, à direita; secundário à esquerda. Configurações: `TabContainer` com abas Vídeo / Áudio / Controles; "Restaurar padrões" no `%RightSlot` do header com `ModalDialog` de confirmação. Salvar aplica imediatamente e persiste; sem "aplicar" separado.

## P5 — Estados de dado remoto

Qualquer card com dado do backend: `StateBox`. `LOADING` após 150 ms (evita flicker); `ERROR` com botão "Tentar de novo"; `EMPTY` com frase curta ("Nenhuma partida ainda"). Nunca tela em branco.

## P6 — Raridade

Comum = borda `RARITY_COMMON` + texto "Comum"; Raro = `RARITY_RARE` + "Raro"; Épico = `RARITY_EPIC` + "Épico" + ícone. Sempre cor **e** texto. Aplica-se a `SlotItem`, `DetailCard`, botões da forja, nome do boss (`PURPLE`).

## P7 — Timers e alertas de fase (HUD)

`TimerLabel` central na barra superior; `warning` nos últimos 30 s da fase; `danger` quando o respawn desliga. Alertas de fase (portões caem, morte súbita) são **banner central** com `DUR_SLOW`, somem sozinhos em 3 s; nunca modal. Boss: `PanelCard accent=PURPLE` no canto superior direito com contagem regressiva.

## P8 — Vinheta de zona (HUD F2)

`ColorRect` full-rect com `ShaderMaterial` de vinheta `RED`; intensidade = `dano/s ÷ 5%` (0–1); `PULSE_ZONE`. Só quando fora da zona (estado replicado `outside_zone`). Não fazer: calcular "fora da zona" no cliente por posição — usar o flag do servidor.

## P9 — Barras de atributo com animação

`StatBar.animate_to(value, DUR_BASE)` ao trocar herói/item; `max_ref` = maior valor entre os heróis da fatia para que as barras sejam comparáveis (pick e forja). HP próprio `GREEN`, inimigo `RED`, XP `GOLD_BRIGHT`, atributos `BLUE`.

## P10 — Fim de partida

`TYPE_VICTORY` em `GOLD` (vitória, `TRANS_BOUNCE`) ou `RED` (derrota, fade + dessaturação do fundo); razão + duração em `TYPE_BODY`; `ScoreBanner`; duas colunas `PanelCard` (vencedor `accent=GOLD`, perdedor `accent=RED`) com `StatsGrid`; dois botões (`ButtonPrimary` "Jogar novamente", `Button` "Voltar ao lobby"). Ambos encerram o processo do Game (`ARCHITECTURE-GAME.md` §3.7).

## P11 — Navegação por teclado/gamepad

Primeiro foco explícito; `focus_neighbor` em toda grade; `Esc`/`B` volta; `Enter`/`A` confirma; atalhos numéricos no pick (`1`, `2`) e `Espaço` confirma. `HotkeyBadge` visível em todo botão com atalho. Dual-focus (4.6): testar que o anel de foco aparece ao navegar por teclado e some ao usar mouse.

## P12 — Feedback de ação

Sucesso → `Toast SUCCESS` 3 s; erro recuperável → `Toast ERROR` + estado da tela; ação destrutiva (sair, abandonar partida, restaurar padrões, encerrar jogo) → `ModalDialog` com botão destrutivo `ButtonDanger`. Som de hover/clique por `AudioStreamPlayer` no `App`, não por botão.
