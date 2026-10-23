# SPEC-029 — Telemetria de partida e web-admin de KPIs

**Fatia:** F29 / SPEC-029 (MVP4, Slice 4.1) · **Issue:** #253 (issue-pai #246) · **Status:** especificada pelo Cowork em 2026-10-23, com as decisões do PI tomadas em pop-up na mesma data (abaixo).
**ADR:** ADR-0033 · **Depende de:** F28 (backend e VPS no ar, entregue)
**Fontes:** PRD §8.5 e §9.2; ADR-0033; ADR-0001 (medição de "maior salto"); `ARCHITECTURE-LAUNCHER.md` §4; `backend/src/matches/matches.dto.ts`; `game/scripts/server/match_result_builder.gd`; `game/scripts/net/net_probe.gd`

## 1. Decisões do PI (2026-10-23)

1. A fatia entrega **telemetria + web-admin** numa só fatia. O Cowork avisou que é grande; se estourar, partir é decisão do PI e gera spec nova com número novo.
2. **Ping, duração e nível ao fim da fase 1 vêm do servidor** autoritativo. Do cliente só vem a contagem de teleportes.
3. **Teleporte** = salto visual por correção de rede. Detecção **automática no cliente**, sem ação do jogador. Limite provisório de **1,0 u** (proposta do Cowork, aprovada pelo PI), calibrado na fatia.
4. **Painel global** de todas as partidas, num **web-admin** `React + Vite + TS`, servido pelo próprio backend. Acesso só pelo papel `admin` na tabela de usuários. A conta vira `admin` por seed, com e-mail em variável de ambiente.
5. **KPIs:** ping médio e % acima de 80 ms; duração média e % acima de 10 min; líder de nível F1 × vencedor, com coluna de empates; teleportes por partida e total; e a lista de partidas com todos os campos que o backend persiste.
6. **Sem campo novo** além de `teleportCount`. Campo novo vira outra fatia.

## 2. Estado de hoje (verificado)

O backend já tem as colunas `avg_ping_ms`, `level_at_phase1_end` e `set_active` em `match_players` e aceita os três campos no DTO como opcionais. **O Game não os envia** (`match_result_builder.gd`), então ficam sempre nulos. Esta fatia faz o Game preenchê-los.

## 3. Entrega

### 3.1 Game (servidor) — coleta

1. **`avgPingMs`:** o servidor amostra o RTT de cada peer a cada 1 s durante a partida (`ENetPacketPeer.get_statistic(PEER_ROUND_TRIP_TIME)`; confirmar a API em `docs/engine-reference/godot/`) e envia a média inteira por jogador. Sem amostra, nulo.
2. **`levelAtPhase1End`:** o nível de cada herói no instante em que a FSM sai da fase 1 (`MatchController`, `phase1_ended`). Quem não tem herói nesse instante, nulo.
3. **`setActive`:** o nome do set de equipamento ativo ao fim da partida, derivado de `MatchStats.Player.equipment` pela regra de set que já existe em `Inventory`. Se a regra não resolver para um nome único, nulo. Não inventar regra de set.
4. **`teleportCount`:** o cliente manda ao servidor, no fim da partida, o total contado (item 3.2). Evento discreto fora da simulação: `@rpc` simples, aceito só do próprio peer, uma vez por partida. O servidor valida inteiro de 0 a 10.000 e repassa no resultado. Cliente que caiu ou não enviou: nulo. **É dado não confiável** (cliente) e o painel o rotula assim.

### 3.2 Game (cliente) — detecção de teleporte

1. Mede, a cada quadro renderizado, o deslocamento de cada herói visível (o local e os remotos). Conta **1 teleporte** quando o deslocamento passa de `teleport_threshold_u` além do que a velocidade e o tempo do quadro explicam.
2. **Não conta** quadros em que o herói está num avanço, investida ou blink de habilidade, nem respawn e retorno à fonte. O Code lista esses estados lendo o código do herói e do `NetProbe` (que já acompanha o avanço) e os cobre com teste.
3. Um mesmo salto não conta várias vezes: intervalo mínimo `teleport_cooldown_s` entre eventos do mesmo herói.
4. Valores em Resource `.tres` em `shared/data/`: `teleport_threshold_u = 1.0` e `teleport_cooldown_s = 0.5` (**provisórios**; o segundo é proposta do Cowork). A lógica de decisão é regra pura em `scripts/core/` com teste GUT; o node só alimenta posições.
5. Só no cliente; nada no servidor headless. Offline e tutorial não contam nem enviam.
6. **Calibração (parte do aceite):** acrescentar a métrica de maior salto ao `NetProbe` e rodar `net-measure.ps1` nos cenários A, B e C (ADR-0001). Confirmar ou ajustar o limite com a evidência.

### 3.3 Backend

1. **Migration 0005:** `match_players.teleport_count integer null` e `users.role text not null default 'player'` com valores `player` ou `admin`.
2. **Seed:** na subida, `ADMIN_EMAILS` (lista separada por vírgula, sem distinção de caixa) promove contas existentes a `admin`. Só promove, nunca rebaixa. Não há endpoint para se promover. Conta criada depois só vira admin na próxima subida do backend.
3. **DTO de resultado:** `teleportCount` opcional, inteiro de 0 a 10.000. Os três campos do item 2 ficam como estão.
4. **Módulo `telemetry/`** (já previsto no `ARCHITECTURE-LAUNCHER.md` §4.1), com `AdminGuard`: exige JWT válido **e** `role = admin` lido do banco a cada chamada (não só do token). Outras contas recebem 403.
5. **Endpoints** (todos sob `/admin`, no OpenAPI):
   - `GET /admin/kpis`: os KPIs da seção 4.
   - `GET /admin/matches`: lista paginada (50 por página), ordenada da mais recente, com filtro por `endReason` e por herói; cada partida traz os dois jogadores com todos os campos persistidos.
   - `GET /admin/matches.csv`: o mesmo conteúdo da lista, completo, uma linha por jogador por partida.
6. **O que a resposta mostra de cada jogador:** `nickname`, herói e os campos de estatística. **Nunca** e-mail, hash, token ou id de conta (mesmo padrão do histórico, `matches.dto.ts`).
7. O web-admin é servido pelo backend em `/admin-ui` (arquivos estáticos do build do `admin/`). Sem CORS aberto.

### 3.4 Web-admin (`admin/`, módulo novo — ADR-0033)

1. React 19 + Vite + TypeScript, mesma stack do `site/`. Sem relação de código com Game, Launcher ou `site/`. Gera o cliente da API a partir do `openapi.json`, como o Launcher.
2. Telas: **login** (usa `POST /auth/login`; conta sem `admin` vê "sem acesso"), **KPIs** e **Partidas** (tabela com filtros e botão "Baixar CSV").
3. Cada KPI mostra o valor, o limite do PRD §9.2 e se está dentro ou fora. Estados de carregamento, vazio e erro tratados.
4. Build no CI; testes de componente com o que o `site/` já usa.

## 4. Definição dos KPIs

Base: partidas `finished` que tenham pelo menos uma linha de jogador. Partida abandonada ou abortada fica fora de todos os KPIs, mas aparece na lista.

| KPI | Cálculo | Limite (PRD §9.2) |
|---|---|---|
| Ping médio | média de `avg_ping_ms` sobre jogador-partida não nulo | ≤ 80 ms |
| Ping acima do limite | % de jogador-partida com `avg_ping_ms` > 80 | — |
| Duração média | média de `duration_s` | — |
| Duração acima do limite | % de partidas com `duration_s` > 600 | 0 % (todas ≤ 10 min) |
| Líder F1 vence | entre partidas com os dois `level_at_phase1_end` não nulos, diferentes e vencedor definido: % em que o de maior nível venceu | < 75 % |
| Empates no F1 | quantidade de partidas com nível igual nos dois, **fora** do % acima | — |
| Teleportes | total e média por jogador-partida, só `teleport_count` não nulo | nenhum relato |

Todo KPI mostra também o **N** usado (quantas partidas ou jogador-partida entraram).

## 5. Critério de aceite

1. Testes do Game: ping médio calculado das amostras; nível congelado na saída da fase 1; teleporte contado acima do limite e ignorado em avanço, respawn e dentro do `cooldown`; `@rpc` recusa peer errado, segundo envio e valor fora da faixa; o `MatchResultBuilder` leva os quatro campos.
2. Testes do backend: DTO com `teleportCount`; migration; seed promove só os e-mails listados e não rebaixa; `AdminGuard` devolve 403 para `player` e 401 sem JWT; cálculo de cada KPI com massa de dados à mão (incluindo empate, nulos e partida abandonada); resposta sem e-mail, hash, token e id de conta.
3. Testes do `admin/`: login, "sem acesso", KPIs com valor dentro e fora do limite, vazio e erro.
4. **Soak** (`soak.ps1 -Count 50 -Parallel 8`, obrigatório: mexe em servidor e FSM) verde, e `teleportCount` = 0 no cenário A (sem latência).
5. **Calibração do teleporte** nos cenários A, B e C com a evidência em `docs/evidencias/f29/`; o limite do `.tres` é confirmado ou ajustado, e o valor final é registrado na issue.
6. **Ponta a ponta no VPS** (`api.lootstart.cloud`): uma partida real de dois clientes chega ao web-admin com ping, duração, nível F1 e teleportes preenchidos; o CSV baixado bate com a tela. Capturas em `docs/evidencias/f29/` e no roadmap.
7. Verificação visual do web-admin pelo PI e CI verde.
8. O Code atualiza `ARCHITECTURE-LAUNCHER.md` (§4.1, §4.3) e o `CLAUDE.md` com a pasta `admin/` no mesmo PR.

## 6. Riscos

- **Falso positivo de teleporte** por habilidade de deslocamento. Mitigação: item 3.2.2 e o aceite 4 (cenário A deve dar zero).
- **Fatia grande** (Game, backend e módulo novo). Se a revisão pedir, partir no ponto Game+backend / web-admin.
- **Contagem do cliente é falsificável.** Aceito pelo PI para a fase de playtest; rotulada como não confiável.

## 7. Fora

- Campo novo de telemetria além de `teleportCount`.
- Gestão de admins pela interface (criar, remover, rebaixar).
- Consentimento, aviso ou qualquer regra sobre dado de jogador: não foi passado pelo PI e **não é especificado aqui**. `PRIVACIDADE.md` segue como registro, sem gerar requisito.
- Telemetria no Launcher; gráficos históricos e alertas; multi-região.
- Ajuste de balanceamento (F30).
