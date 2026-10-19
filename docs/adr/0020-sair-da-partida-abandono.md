# ADR-0020 — Sair do jogo pelo menu: derrota por abandono

**Status:** aceito — decisão do PI em 2026-10-19 (pop-up, sem Cowork: o Code abriu a fatia F80 / SPEC-080, issue #230)
**Decisor:** Rodrigo Reis (PI)
**Emenda:** `CONVENTION.md` (estados e invariantes da partida) · `ARCHITECTURE-GAME.md` §6 · contrato do resultado (`POST /internal/matches/:id/result`)
**Relacionados:** F23 (#79) · F70 (ADR-0015, card "Resultado da partida") · F80 (#230)

## Contexto

Dentro do Game não havia como sair: o ESC só cancela o alvo, e em tela cheia o jogador fica preso até a partida acabar. Ao testar a tela cheia (F79), o PI pediu uma saída. A regra de domínio não existia: hoje quem fecha o Game vira `disconnected`, o servidor sintetiza input vazio e a partida segue (`ARCHITECTURE-GAME.md` §6), sem derrota imediata.

## Decisão

1. **Menu no ESC** com **Continuar** e **Sair do jogo** (com confirmação). Com alvo selecionado, o 1º ESC só cancela o alvo; com o menu aberto, ESC = Continuar. O jogo **não pausa** (tempo real).
2. **Sair no meio de uma partida online conta como derrota por abandono** (escolha do PI entre "igual a fechar a janela hoje" e esta). O cliente envia um RPC discreto de saída; o servidor encerra a partida na hora, o adversário vence, e o resultado vai ao backend: quem saiu = `loss`, o outro = `win`.
3. **Motivo no contrato:** `POST /internal/matches/:id/result` ganha `endReason` (`normal` | `abandon`, padrão `normal`, aditivo); o backend guarda e `GET /matches` devolve; Launcher (histórico e card "Resultado da partida") mostram "Abandono". O motivo vem do servidor, nunca do cliente.
4. **Escopo da regra:** só a saída deliberada pelo menu, com os **dois** jogadores conectados. Se o adversário ainda não chegou, sair é só desconectar e vale o timeout `abandoned` de hoje. Treino offline: sair não tem consequência.
5. **Lacuna aceita:** fechar a janela, Alt+F4, queda de conexão e crash **não** são abandono; seguem `disconnected` com input vazio. Quem fecha a janela escapa da regra. Fica para decisão futura do PI (gatilho: playtest com abandono por fechar a janela).

## Consequências

- Muda o domínio: `ENDED` passa a ter o motivo `abandon` além de vitória por meta, por zona e por colapso (`CONVENTION.md`). Não cria empate: o abandono sempre tem vencedor.
- O servidor passa a aceitar um evento do cliente que encerra a partida; precisa validar que vem de um peer da partida e que só vale uma vez (o adversário nunca é derrotado por RPC do outro).
- O backend ganha uma coluna (migração) e o `openapi.json` muda; o Launcher regenera os models (`tools/launcher/gen_models.mjs`).
- Não cobre pausa, reconexão, punição além da derrota nem placar de abandonos.
