# SPEC-089 — Bot na fila online: sem humano em 30 s, partida contra bot com aviso

**Fatia:** F89 / SPEC-089 (MVP5, Slice 5.3) · **Issue:** #258 (issue-pai #250) · **Status:** decidida pelo PI em 2026-10-23 (pop-ups do Cowork: "Pela Patente"; "Histórico e Patente sim, V–D não"; aviso "Na fila, ao bater 30 s" e "No pick, selo BOT"; "bot aleatório também na seleção")
**ADR:** ADR-0027 · **Depende de:** F87 (Patente) · **Fontes:** F22 (fila e orquestrador), F23 (game server), F81 (níveis do bot), `BotInput`
**Escopo:** backend (fila, orquestrador, resultado), infra (game server com bot), Game (bot online no servidor, selo BOT), Launcher (aviso, histórico).

## 1. Regras

1. Se o ticket da fila não encontrar adversário humano em **30 s** (contados da criação do ticket), a partida começa contra um **bot no servidor do VPS**.
2. **Nível do bot pela Patente do jogador:** Patente 1–3 → 1 (Fácil); 4–7 → 2 (Médio); 8–11 → 3 (Difícil).
3. **Herói do bot:** sorteado entre todos os heróis jogáveis, com a mesma chance.
4. **Conta no histórico e na Patente** (F87, mesma regra de pontos); **não conta no V–D** do perfil. No histórico, a partida aparece marcada como "contra bot".
5. **Aviso:** na fila, ao bater 30 s: "Nenhum adversário humano encontrado: você vai jogar contra um bot."; e **selo BOT** no adversário na seleção de heróis.

## 2. Entrega

1. **Backend:** a fila cria a partida com 1 humano + bot depois de 30 s; a partida guarda que é contra bot, o nível e o herói do bot; o resultado só pontua o humano; o V–D do perfil ignora partida contra bot; `GET /matches` traz a marca. Testes de tempo da fila (29 s com humano = humano; 30 s sem humano = bot).
2. **Orquestrador / infra:** sobe o game server da partida com o bot (nível e herói). Isso é argumento do servidor, não do contrato Launcher ↔ Game (§5.2 não muda).
3. **Game (servidor):** um jogador é `BotInput` na partida online, com input sintetizado pelo servidor (`ARCHITECTURE-GAME.md` §6); resultado reportado como numa partida normal, com o lado bot sem conta.
4. **Game (cliente):** selo BOT no pick; o restante da partida igual.
5. **Launcher:** texto do aviso na fila; histórico mostra "contra bot"; perfil sem essa partida no V–D.

## 3. Critério de aceite

1. Testes do backend (§2.1) e GUT do Game e do Launcher.
2. Soak verde (mexe em servidor e input).
3. Verificação do PI no VPS: entra sozinho na fila, vê o aviso aos 30 s, vê o selo BOT, joga, vê a partida "contra bot" no histórico, a Patente sobe e o V–D não muda.
4. CI verde.

## 4. Fora

Escolha do nível pelo jogador, oferta de "jogar contra bot enquanto espera", mudança nos KPIs do F29, separação de fila por Patente.
