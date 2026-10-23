# MVP5 — Early Access (= marco M5)

**Objetivo:** abrir o Early Access free-to-play no site próprio e no itch.io, com progressão de conta grátis, bot completando a fila online e loja só cosmética (ADR-0024 a ADR-0028, ADR-0034).
**Módulos:** `backend`, `launcher`, `game`, `shared`, `infra`, `art`. **Prazo:** sem prazo definido pelo PI. **Issue-pai:** #250.
**Critério de pronto:** um jogador novo instala pelo site ou pelo itch.io, faz o tutorial, sobe de Patente e libera heróis, encontra partida em ≤ 30 s (humano ou bot avisado) e compra o Pacote de Fundador por Mercado Pago, vendo a skin na partida dos dois lados.
**Estado:** `backlog` — SPEC-087 a SPEC-092 escritas com as decisões do PI em 2026-10-23; depende do `[GATE]` do MVP4 (ADR-0024 item 1). Pré-condições fora do código: protótipos das telas novas (Cowork faz, PI aprova), conta Mercado Pago no CNPJ do PI e termos de compra revisados por advogado (F90).

## Fatias

| Slice | F / SPEC | Entrega | Fontes |
|---|---|---|---|
| 5.1 | F87 / SPEC-087 | Patente 1–11 grátis (`backend`, `launcher`, `game`, `shared`): Cavaleiro inicial; 1 herói KayKit por Patente da 2 à 10, com escolha livre; demais heróis (Carrasco) na Patente 11; vitória 2, derrota 1, abandono 0, 3 pontos por Patente; pick online e treino só com heróis liberados | ADR-0026, ADR-0034; `spec/SPEC-087.md` |
| 5.2 | F88 / SPEC-088 | recompensas (`backend`, `launcher`, `game`, `shared`): emblema por Patente (2–11), molduras na 5 e na 10; emblema semanal (5/7 dias) e moldura mensal (20 dias) fixos com contador; equipados no perfil, lobby, pick, carregamento e fim de partida | ADR-0025, ADR-0026, ADR-0034; `spec/SPEC-088.md` |
| 5.3 | F89 / SPEC-089 | bot na fila online (`backend`, `game`, `infra`, `launcher`): sem humano em 30 s, bot no VPS com nível pela Patente e herói sorteado; conta no histórico e na Patente, não no V–D; aviso na fila e selo BOT no pick | ADR-0027; `spec/SPEC-089.md` |
| 5.4 | F90 / SPEC-090 | loja (`backend`, `launcher`, `admin`): catálogo, pedido, Mercado Pago (Pix e cartão), webhook, inventário, estorno remove item, relatório de vendas; tela Loja no Launcher | ADR-0025; `spec/SPEC-090.md` |
| 5.5 | F91 / SPEC-091 | skin na partida (`backend`, `game`, `launcher`, `shared`): validação do token devolve heróis liberados e skin equipada; game server replica; treino offline com visual padrão | ADR-0028; `spec/SPEC-091.md` |
| 5.6 | F92 / SPEC-092 | primeiras skins (`shared`, `art`): 1 por herói KayKit (10) + skin exclusiva do Pacote de Fundador no Carrasco | ADR-0025, ADR-0034; `spec/SPEC-092.md` |
| gate | `[GATE]` | abertura do Early Access no site e no itch.io | ADR-0024 |

## Ordem prevista

F87 → F88 → F89 → F90 → F91 → F92 → `[GATE]`. F89 depende da Patente do F87 (nível do bot); antecipá-lo, se o playtest do MVP4 mostrar fila vazia, é decisão do PI. A ordem final do board é do Cowork, com o PI.

## Fora deste marco

Passe de temporada (2ª leva, gatilho: ≥ 10 recompensas prontas), moeda virtual, runas e atributos de conta, Steam, nota fiscal integrada — ver `FORA-DE-ESCOPO.md`.
