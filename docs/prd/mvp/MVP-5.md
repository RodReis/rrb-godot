# MVP5 — Early Access (= marco M5)

**Objetivo:** abrir o Early Access free-to-play no site próprio e no itch.io, com progressão de conta grátis, bot completando a fila online e loja só cosmética (ADR-0024 a ADR-0028).
**Módulos:** `backend`, `launcher`, `game`, `shared`, `infra`, `art`. **Prazo:** sem prazo definido pelo PI.
**Critério de pronto:** um jogador novo instala pelo site ou pelo itch.io, faz o tutorial, sobe de Patente e libera heróis, encontra partida em ≤ 30 s (humano ou bot avisado) e compra o Pacote de Fundador por Mercado Pago, vendo a skin na partida dos dois lados.
**Estado:** planejado — depende do `[GATE]` do MVP4 (ADR-0024 item 1). Nenhuma SPEC escrita: cada fatia tem dúvidas em aberto que o Cowork leva ao PI antes da issue.

## Fatias

| Slice | F / SPEC | Entrega | Fontes | Em aberto antes da SPEC |
|---|---|---|---|---|
| 5.1 | F87 / SPEC-087 | Patente 1–10 grátis (`backend`, `launcher`, `game`, `shared`): conta nova com 1 herói, 1 herói por Patente com escolha livre; pick online só com heróis liberados, validado no servidor | ADR-0026 | como se ganha Patente; herói inicial; contas existentes; separação de fila por Patente |
| 5.2 | F88 / SPEC-088 | recompensas de Patente e de login diário, semanal e mensal (`backend`, `launcher`, `shared`): emblemas e molduras de perfil, grátis | ADR-0025, ADR-0026 | quais itens, em quais Patentes; calendário do login; dia perdido |
| 5.3 | F89 / SPEC-089 | bot na fila online (`backend`, `game`, `infra`, `launcher`): sem adversário humano em 30 s, partida contra bot no VPS, com aviso | ADR-0027 | nível do bot; conta no histórico, V–D e Patente; onde aparece o aviso |
| 5.4 | F90 / SPEC-090 | loja (`backend`, `launcher`): catálogo, pedido, Mercado Pago (Pix e cartão), webhook, inventário; tela Loja no Launcher | ADR-0025 | termos de compra e reembolso; parte fiscal; protótipo da tela em `docs/prd/telas/` |
| 5.5 | F91 / SPEC-091 | skin na partida (`backend`, `game`, `launcher`, `shared`): validação do token devolve heróis liberados e skin equipada; game server replica; Launcher grava a escolha no backend | ADR-0028 | skin no treino offline |
| 5.6 | F92 / SPEC-092 | primeiras skins (`shared`, `art`): variantes de textura do KayKit Extra como skins avulsas + skin exclusiva do Pacote de Fundador | ADR-0025; F84 (arte) | quantas skins e de quais heróis; herói da skin do Fundador |
| gate | `[GATE]` | abertura do Early Access no site e no itch.io | ADR-0024 | — |

## Ordem prevista

F87 → F88 → F89 → F90 → F91 → F92 → `[GATE]`. F89 pode subir antes do F87 se o playtest do MVP4 mostrar fila vazia. A ordem final do board é do Cowork, com o PI.

## Fora deste marco

Passe de temporada (2ª leva, gatilho: ≥ 10 recompensas prontas), moeda virtual, runas e atributos de conta, Steam — ver `FORA-DE-ESCOPO.md`.
