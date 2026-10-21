# SPEC-097 — Escala da interface do jogo: configurável no Launcher e na partida

**Fatia:** F97 / SPEC-097 (MVP4, Slice 4.10) · **Issue:** #272 (issue-pai #246) · **Status:** decidida pelo PI em 2026-10-21, em pop-up na verificação do F95. O teto caiu de 120 % para 100 % num 2º pop-up: a seleção de heróis quebrava acima de 100 % (ADR-0031). O Code abriu a fatia a pedido do PI.
**ADR:** ADR-0031 · **Depende de:** nada
**Fontes:** ADR-0031; `ARCHITECTURE-LAUNCHER.md` §5.3; F57 (HUD moderna, `hero_plate.gd`, ⚙ Opções do jogo); F67 (`[camera] distance`, gravação pelo Game em `main.gd`); F24/F79 (tela Configurações, `settings_screen.gd`); `shared/core/user_settings.gd`
**Escopo:** só tamanho. Layout, conteúdo e comportamento das telas não mudam.

## 1. Motivo

O PI achou o HUD grande demais e tapando a visão, principalmente o painel de baixo, no centro. Ele escolheu uma escala configurável que já abre menor.

## 2. Entrega

1. **Contrato:** `[ui] hud_scale` em `UserSettings`, de 0,70 a 1,00, em passos de 0,05 e padrão 0,85. Fora da faixa ou com tipo errado, volta ao padrão.
2. **Game:**
   - No boot, aplica `get_tree().root.content_scale_factor = hud_scale`.
   - Aplica de novo a cada mudança, sem reiniciar.
   - Headless não faz nada.
3. **Na partida:** o painel ⚙ "Opções do jogo" ganha o controle "Tamanho da interface", com o valor em %. Mexer aplica na hora e grava só `[ui] hud_scale` (relê o arquivo antes, como o zoom do F67).
4. **Launcher:** a tela Configurações ganha o mesmo controle, "Tamanho da interface na partida", com o valor em %. Fica no card que fizer sentido no layout atual, no padrão dos sliders que já existem. A chave grava com o resto ao salvar, e "Restaurar padrões" volta a 85 %.

## 3. Critério de aceite

1. Testes do contrato:
   - padrão 0,85;
   - limites 0,70 e 1,00 aceitos;
   - 0,5, 2,0 e texto voltam ao padrão;
   - arquivo sem `[ui]` lê o padrão;
   - ida e volta pelo `write`/`read`.
2. Teste do Game: a escala lida vira o `content_scale_factor` da raiz, e a mudança pelo ⚙ aplica e grava, sem desfazer a `[camera] distance`.
3. Teste do Launcher: o controle aparece, grava a chave ao salvar e o "Restaurar padrões" volta a 0,85.
4. Capturas do HUD na partida a 70 %, 85 % e 100 % em 1280x720 e 1920x1080, mais a seleção de herói e o fim de partida a 70 % em 1280x720. Nada pode sair da tela nem se sobrepor. Ficam em `docs/evidencias/f97/` e no roadmap.
5. Verificação do PI e CI verde.

## 4. Fora

- Escala do Launcher.
- Escala por painel ou mover painéis.
- Tamanho de fonte separado.
- Redesenho do HUD.
