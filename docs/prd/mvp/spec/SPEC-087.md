# SPEC-087 — Patente 1–11 grátis: Cavaleiro inicial, 1 herói KayKit por Patente, demais heróis na 11

**Fatia:** F87 / SPEC-087 (MVP5, Slice 5.1) · **Issue:** #256 (issue-pai #250) · **Status:** decidida pelo PI em 2026-10-23 (pop-ups do Cowork: "Partida online, vitória vale mais"; "≈ 20 partidas"; "Cavaleiro fixo"; "liberar os 10 KayKit, depois do nível 10 os outros heróis"; "nível 11 já libera todos os heróis"; "usar as três recomendadas" — 3 pontos por Patente, contas atuais pelo histórico, fila FIFO; "Só os liberados" no treino; protótipo `Patente & Perfil/` "aprovado")
**ADR:** ADR-0026, ADR-0034 · **Depende de:** [GATE] MVP4 #255 (ADR-0024 item 1)
**Fontes:** `backend/src/users`, `matches`, `orchestrator/match-token.service.ts`; `POST /internal/matches/:id/validate` e `/result` (`ARCHITECTURE-LAUNCHER.md` §4.2); SPEC-085 (tutorial, fila liberada); ADR-0020 (`left`)
**Escopo:** backend (Patente, posse de herói), Launcher (Patente, escolha de herói, trava no treino), Game (pick online e offline só com liberados), `shared` (marca KayKit no herói).

## 1. Regras (ADR-0034)

1. **Pontos:** cada partida online encerrada com resultado dá ao jogador **vitória 2, derrota 1**; quem perdeu por abandono (`endReason = left`, ADR-0020) recebe **0**. Partida sem resultado (`interrupted`, `aborted`) não dá ponto a ninguém. Partida contra o bot da fila (F89) conta igual. Treino offline e tutorial não dão ponto.
2. **Patente** = mínimo entre 11 e 1 + ⌊pontos ÷ 3⌋. Patente máxima: 11.
3. **Conta nova:** Patente 1, só o **Cavaleiro**.
4. **Patente 2 a 10:** ao chegar em cada uma, a conta ganha **1 escolha** de herói KayKit bloqueado. A escolha fica pendente até o jogador fazê-la (não se perde). Sem herói KayKit bloqueado, não há escolha.
5. **Patente 11:** libera, automaticamente, todos os heróis que não são KayKit (hoje, o Carrasco), inclusive os que entrarem no jogo depois.
6. **Contas que já existem** na migração: pontos calculados pelo histórico de partidas online com a regra do item 1; mantêm **todos os heróis** liberados.
7. **Fila:** FIFO, sem olhar Patente.

## 2. Entrega

### 2.1 `shared`
- Cada `shared/data/heroes/*.tres` marca se o herói é **KayKit** (liberável da 2 à 10) ou da **Patente 11**. O Cavaleiro é o inicial. Regra pura de Patente (pontos → Patente, herói liberável?) em `shared/core/` com teste GUT, usada pelo Launcher; o backend tem a mesma regra com teste próprio.

### 2.2 Backend
- Migration: pontos de Patente por conta e posse de herói por conta (com origem: inicial, escolha, Patente 11, legado). Migração dos dados existentes conforme §1.6.
- Ao gravar `/internal/matches/:id/result`, soma os pontos e libera o que a nova Patente der, na mesma transação.
- `GET` do progresso da conta (Patente, pontos, pontos para a próxima, heróis liberados, escolhas pendentes) e `POST` da escolha (só herói KayKit bloqueado e só com escolha pendente; senão 409).
- **Validação do token** (`/internal/matches/:id/validate`) devolve, por jogador, os heróis liberados (ADR-0026 item 6, ADR-0028).
- OpenAPI atualizado; testes do serviço cobrindo cada item do §1.

### 2.3 Game
- **Pick online:** só heróis liberados de cada jogador podem ser escolhidos; o **servidor** recusa pick de herói bloqueado (nunca só o cliente). A forma visual do herói bloqueado segue o design system.
- **Pick offline (treino):** só os heróis de `--heroes=<id>,…` (ADR-0034). Sem o argumento, todos (modo de dev). O tutorial não muda.

### 2.4 Launcher
- **UI fiel ao protótipo `docs/prd/telas/Patente & Perfil/`** (aprovado pelo PI em 2026-10-23; `FRONTEND-LAUNCHER.md` §8.1): chip do cabeçalho com Patente, Perfil (Patente, pontos, heróis liberados e trilha 1→11), card "Sua conta" do lobby e Tela Heróis (F71) com liberado × bloqueado × "libera na Patente 11". Herói bloqueado continua abrindo o detalhe.
- Ao subir de Patente com escolha pendente, o Launcher abre o modal "Subiu de Patente" com os KayKit bloqueados; LIBERAR HERÓI ou DEPOIS. O modal abre na volta ao lobby depois da partida (F70) e no login, se houver escolha pendente; na Patente 11, o modal "Todos os heróis liberados". Se o modal de presença do F88 cair junto, o de Patente vem primeiro.
- Treino vs Bot passa `--heroes` com os liberados da conta.

## 3. Critério de aceite

1. Testes GUT da regra pura e testes do backend para cada item do §1 (inclusive `left`, `interrupted`, Patente 11, escolha pendente, conta legada).
2. Pick online com herói bloqueado recusado pelo servidor (teste) e soak verde (mexe em servidor/pick).
3. Verificação do PI: conta nova sai do tutorial com o Cavaleiro, joga online, sobe de Patente, escolhe um herói e o vê no pick online e no treino.
4. Captura Godot × protótipo lado a lado (`FRONTEND-LAUNCHER.md` §8.5).
5. CI verde.

## 4. Fora

Recompensas (F88), bot na fila (F89), skins (F91), separação de fila por Patente, Patente acima de 11.
