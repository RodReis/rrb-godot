# ADR-0020 — Sair do jogo pelo menu: derrota por abandono

**Status:** aceito — decisão do PI em 2026-10-19 (pop-up, sem Cowork: o Code abriu a fatia F80 / SPEC-080, issue #230)
**Decisor:** Rodrigo Reis (PI)
**Emenda:** `CONVENTION.md` (estados e invariantes da partida) · `ARCHITECTURE-GAME.md` §6 (o contrato do resultado não muda: `endReason` ganha o valor `left`)
**Relacionados:** F23 (#79) · F70 (ADR-0015, card "Resultado da partida") · F80 (#230)

## Contexto

Dentro do Game não havia como sair: o ESC só cancela o alvo, e em tela cheia o jogador fica preso até a partida acabar. Ao testar a tela cheia (F79), o PI pediu uma saída. A regra de domínio não existia: hoje quem fecha o Game vira `disconnected`, o servidor sintetiza input vazio e a partida segue (`ARCHITECTURE-GAME.md` §6), sem derrota imediata.

## Decisão

1. **Menu no ESC** com **Continuar** e **Sair do jogo** (com confirmação). Com alvo selecionado, o 1º ESC só cancela o alvo; com o menu aberto, ESC = Continuar. O jogo **não pausa** (tempo real).
2. **Sair no meio de uma partida online conta como derrota por abandono** (escolha do PI entre "igual a fechar a janela hoje" e esta). O cliente envia um RPC discreto de saída; o servidor encerra a partida na hora (`ENDED`, motivo `left`), o adversário vence, e o resultado vai ao backend: quem saiu = `loss`, o outro = `win`.
3. **Motivo no contrato:** o `endReason` **já existe** no resultado (texto livre, guardado em `matches.end_reason` e devolvido por `GET /matches`); o Game passa a mandar o valor novo `left`. **Sem mudança de backend nem de migração**; o Launcher mapeia `left` para "Abandono" (histórico e card "Resultado da partida"). O motivo vem do servidor, nunca do cliente.
4. **Escopo da regra:** só a saída deliberada pelo menu, com os **dois** jogadores conectados. Se o adversário ainda não chegou, sair é só desconectar e vale o timeout `abandoned` de hoje. Treino offline: sair não tem consequência.
5. **Lacuna aceita:** fechar a janela, Alt+F4, queda de conexão e crash **não** são abandono; seguem `disconnected` com input vazio. Quem fecha a janela escapa da regra. Fica para decisão futura do PI (gatilho: playtest com abandono por fechar a janela).

## Consequências

- Muda o domínio: `ENDED` passa a ter o motivo `left` além de vitória por meta, por zona e por colapso (`CONVENTION.md`). Não cria empate: o abandono sempre tem vencedor.
- O servidor passa a aceitar um evento do cliente que encerra a partida; precisa validar que vem de um peer da partida e que só vale uma vez (o adversário nunca é derrotado por RPC do outro).
- Só o Game e o texto do Launcher mudam; backend, migrações e `openapi.json` ficam como estão (o teste do serviço passa a cobrir `left`).
- Não cobre pausa, reconexão, punição além da derrota nem placar de abandonos.
