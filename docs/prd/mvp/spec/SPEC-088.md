# SPEC-088 — Recompensas de Patente e de login diário, semanal e mensal: emblemas e molduras

**Fatia:** F88 / SPEC-088 (MVP5, Slice 5.2) · **Issue:** #257 (issue-pai #250) · **Status:** decidida pelo PI em 2026-10-23 (pop-ups do Cowork: "1 emblema por Patente + 2 molduras"; "Só conta para semanal e mensal"; "Acumula no período, sem zerar"; "Fixos, com contador ×N"; "5 de 7"; emblema no perfil, lobby, pick e carregamento, fim de partida; "Claude gera, PI aprova")
**ADR:** ADR-0025, ADR-0026, ADR-0034 item 8 · **Depende de:** F87
**Escopo:** backend (recompensas, presença), Launcher (inventário de perfil, equipar), Game (mostrar emblema e moldura vindos do servidor), `shared` (arte e catálogo dos itens).

## 1. Itens

| Item | Quando | Quantos |
|---|---|---|
| Emblema de Patente | ao chegar em cada Patente da 2 à 11 | 10 (um por Patente) |
| Moldura de Patente | ao chegar na Patente 5 e na 10 | 2 |
| Emblema semanal | 5 dias de login na semana | 1, fixo, com contador ×N |
| Moldura mensal | 20 dias de login no mês | 1, fixa, com contador ×N |
| Emblema "Fundador" | compra do Pacote de Fundador (F90) | 1 |

Todos grátis, exceto o Fundador, que vem no pacote pago. Nada é vendido avulso (ADR-0025).

## 2. Regras de login

1. **Dia** = 00:00–23:59 no horário de Brasília (`America/Sao_Paulo`). Conta como dia de login o primeiro login bem-sucedido no Launcher naquele dia.
2. O login diário **não dá item**: só conta para a semana e para o mês.
3. **Semana** = segunda a domingo. **5 dias** de login na semana (não precisam ser seguidos) dão o emblema semanal; na 2ª vez em diante, o contador sobe (×2, ×3…).
4. **Mês** = mês do calendário. **20 dias** de login no mês dão a moldura mensal, com contador do mesmo jeito.
5. **Dia perdido não zera nada**: a contagem acumula dentro da semana e do mês e recomeça na semana ou no mês seguinte.
6. O item é entregue no login que completa a meta.

## 3. Equipar e mostrar

- A conta equipa **1 emblema e 1 moldura** (ou nenhum). A escolha mora no backend.
- Aparecem no **perfil**, no **lobby**, no **pick e no carregamento** da partida e na tela de **fim de partida**.
- Na partida, o visual vem do servidor: a validação do token devolve emblema e moldura equipados de cada jogador (ADR-0034 item 8), e o game server replica como dado discreto (fora do rollback). O Launcher não passa emblema por argumento. Treino offline: sem emblema.

## 4. Entrega

1. **Backend:** migration de itens de perfil, inventário de perfil e dias de login; entrega por Patente (no mesmo ponto em que o F87 sobe a Patente) e por login; `GET` do inventário de perfil com contadores; `POST` de equipar (só item possuído). Contas legadas recebem os emblemas e molduras das Patentes que o histórico já deu (F87 §1.6). Testes cobrindo §2 (virada de dia em Brasília, semana segunda–domingo, mês, 5/7, 20 dias, contador).
2. **Arte:** as 15 peças do §1, feitas pelo Claude (SVG/PNG, tokens do design system) e aprovadas pelo PI antes do merge; catálogo dos itens em `shared/data/`.
3. **Launcher:** inventário de perfil e equipar no perfil; emblema e moldura no lobby; progresso da semana e do mês visível. **Pré-condição:** protótipo em `docs/prd/telas/` (Cowork faz, PI aprova) antes do `todo`.
4. **Game:** emblema e moldura no pick, no carregamento e no fim de partida, vindos do servidor.

## 5. Critério de aceite

1. Testes do backend do §2 e da entrega por Patente; testes GUT do Launcher e do Game.
2. Verificação do PI: arte aprovada; conta sobe de Patente e recebe o emblema; equipa e vê no lobby, no pick (os dois lados) e no fim de partida.
3. CI verde.

## 6. Fora

Passe de temporada (2ª leva), itens vendidos avulsos, recompensa por login diário, moeda virtual.
