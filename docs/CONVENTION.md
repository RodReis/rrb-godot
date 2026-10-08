# CONVENTION.md — Domínio: entidades, estados, invariantes e regras

**Normativo, comum aos dois módulos.** Números e fórmulas: `docs/prd/GDB.md` (vence o PRD — [ADR-0004](adr/0004-gdb-vence-numeros.md)). Escopo: `docs/prd/PRD.md`. Este documento não repete tabelas: aponta a seção.

## 1. Vocabulário (pt-BR no domínio, `snake_case` inglês no código)

| Termo | Código | Definição |
|---|---|---|
| Conta | `user` | e-mail + senha; dona de partidas. Só existe no backend. |
| Sessão | `session` | JWT de acesso do Launcher. |
| Ticket de fila | `queue_ticket` | pedido de partida 1x1; `waiting → matched \| cancelled \| expired`. |
| Partida | `match` | uma execução do Game com 2 jogadores; `assigned → running → finished \| aborted \| abandoned`. |
| Jogador | `player` | participante de uma partida (peer + conta + herói). |
| Herói | `hero` | Cavaleiro (`knight`) ou Arqueira (`ranger`). Dados em `shared/data/heroes/`. |
| Atributos | `stats` | HP, DEF, ATK, INT, AGI (GDB §2.1). |
| Habilidade | `skill` | Q, E (5 níveis), R (2 níveis, nível 6+). |
| Nível / XP | `level`, `xp` | 1–10; tabela GDB §3.2. |
| Monstro | `monster` | 5 tipos, tier 1–3 + boss (GDB §5.1). Não respawna. |
| Baú | `chest` | comum (base) ou raro (centro); abre uma vez (GDB §6.2). |
| Item | `item` | 12 itens, 4 slots, 3 raridades (GDB §6.1). |
| Conjunto | `set` | Guarda ou Caçador; bônus com 3/3 peças de armadura. |
| Fase | `phase` | ver §3. |
| Zona | `zone` | círculo que encolhe na fase 2 (GDB §7.1). |
| Kill | `kill` | morte de herói **na fase 2**. Na fase 1 não conta. |
| Servidor de partida | `game_server` | processo headless do Game, 1 por partida. |
| Pool | `pool` | containers pré-aquecidos do orquestrador. |

## 2. Entidades e quem é dono

| Entidade | Dono da verdade | Quem lê |
|---|---|---|
| `user`, `session`, `queue_ticket`, `match` (registro), `match_players` | Backend | Launcher (sua conta), Game server (validar/reportar) |
| Estado da partida (posições, HP, XP, itens, zona, kills, relógio) | Game **server** | Game client (replicado) |
| `settings.cfg` | Launcher | Game |
| `shared/data/*.tres` | repositório (Cowork/PI) | ambos |

Nada de gameplay é persistido pelo cliente. Nada de conta é lido pelo Game client.

## 3. Estados da partida (`MatchState`)

```
LOBBY_WAIT → HERO_PICK → PHASE1 → TRANSITION → PHASE2 → SUDDEN_DEATH → ENDED
                                                   └──────(meta de kills)──────┘
```

| Estado | Entra quando | Sai quando | Relógio |
|---|---|---|---|
| `LOBBY_WAIT` | servidor sobe | 2 peers válidos (ou timeout → `ENDED/abandoned`) | — |
| `HERO_PICK` | 2 peers | ambos lock-in **ou** 24 s (sem escolha → herói padrão do slot: P1 Cavaleiro, P2 Arqueira — **R-PEND-04**) | pick |
| `PHASE1` | pick concluído | `t_match = 5:00` | `t_match` 0:00–5:00 |
| `TRANSITION` | 5:00 | +5 s | aviso visual/sonoro |
| `PHASE2` | 5:05 | meta de kills **ou** `t_phase2 = 4:00` | `t_phase2` 0:00–4:00 |
| `SUDDEN_DEATH` | `t_phase2 = 4:00` (9:00 de partida) | último time com vivo; aos 10:00 dano dobra a cada 10 s | até ≤ 10:00 |
| `ENDED` | vitória ou abandono | processo encerra após reportar | — |

Invariantes: a partida **sempre** termina em ≤ 10:00 (PRD §9.2); **nunca** há empate (GDB §7.2); não há transição de volta.

## 4. Regras por tema (fonte → seção)

### 4.1 Fase 1 — preparação
- Portões: só o time dono passa (PRD §3.1). Centro é PvP desde 0:00.
- Monstros: quantidade fixa, não respawnam; distribuição e XP em GDB §5.1. Boss surge aos **3:30**; aviso global aos **3:00** (benchmark §3.2 — **R-PEND-05**: o aviso aos 3:00 não está no PRD).
- Morte na fase 1: respawn 8,0 s na própria base, **não** conta kill, matador recebe 80 XP (GDB §3.3). Sem perda de itens.
- Catch-up: `nível ≤ nível_adversário − 2` → +25% em todo XP de monstro/objetivo (GDB §3.3).

### 4.2 Progressão
- XP acumulado por nível: GDB §3.2. Nível máximo 10. 1 ponto por nível a partir do 2 (9 pontos).
- Q e E: máx. 5 níveis cada. R: desbloqueia no 6, nível 2 no 10.
- Fórmulas de DEF, CDR, velocidade de movimento e de ataque: GDB §2.2 — implementadas **uma vez** em `shared/core/stats.gd` e usadas por servidor e Forja.

### 4.3 Itens
- 4 slots: arma, elmo, peitoral, botas. Catálogo GDB §6.1.
- Substituição: raridade maior → automática; igual ou "escolha lateral" → `F` segurado 0,4 s (GDB §6.2).
- Bônus de conjunto 3/3: Guarda +15% HP máx e +10 DEF; Caçador +10% vel. ataque e +8% vel. movimento (GDB; ADR-0004 N1/N2).
- Épico: drop garantido do boss; baú raro 10% (GDB §6.2; ADR-0004 N8 pendente).
- Consumível de cura +120 HP (GDB §6.2, baú comum 30%) — único consumível da fatia.

### 4.4 Fase 2 — confronto
- Zona centrada no centro do mapa; raio, dano e respawn por minuto em GDB §7.1.
- Meta de kills 1x1 = 5. Morte dá 150 + 20×nível do alvo em XP ao matador (GDB §3.3).
- Respawn 6,0 s até 4:00 da fase 2; depois desligado.
- Ordem de vitória (GDB §7.2): 1) meta de kills; 2) após 9:00, adversário sem vivos; 3) colapso aos 10:00 — maior HP% sobrevivente vence.
- Monstros não respawnam na fase 2; os que sobraram continuam vivos (PRD §3.4 — **R-PEND-06**: o PRD não diz se são removidos).

### 4.5 Heróis
- Base, crescimento e habilidades: GDB §4.1 (Cavaleiro) e §4.2 (Arqueira).
- Ataque básico: Cavaleiro arco 70°/2,2 u; Arqueira projétil 20 u/s, 9 u, raio 0,3 u.
- Tudo validado no servidor; cliente prevê só movimento próprio e disparo visual do projétil (benchmark §4).

### 4.6 Bot
- FSM PRD §3.7: `Farmar → Saquear → Contestar (3:00, se nível ≥ adversário) → Lutar (vantagem) → Recuar (HP < 30%)`; fase 2: `Perseguir`, `Fugir da zona`.
- Bot produz input; não tem informação além do que um cliente teria (sem ler estado interno do servidor fora do replicado). **Invariante de honestidade do bot.**

### 4.7 Conta e fila
- Conta: e-mail + senha (PRD §8.4). Sem verificação de e-mail, sem recuperação de senha na fatia (**R-PEND-07** — não está no PRD; registrado em `FORA-DE-ESCOPO.md`).
- Fila 1x1 FIFO, sem rating (PRD §8.4). Um ticket por conta por vez.
- Histórico: partidas da própria conta, com os campos de `match_players` (`ARCHITECTURE-LAUNCHER.md` §4.3).

## 5. Invariantes globais (testáveis)

| # | Invariante | Onde se prova |
|---|---|---|
| I1 | Toda partida termina em ≤ 10:00 | soak 50 partidas (gate MVP2) |
| I2 | Nunca empate | `VictoryRules` GUT |
| I3 | Kill só na fase 2 | `KillTracker` GUT |
| I4 | Nenhum número de balanceamento fora de `.tres` | revisão de PR (grep de literais em `core/`) |
| I5 | Servidor e Forja dão o mesmo atributo final para o mesmo build | teste GUT em `shared/test` com fixture usado pelos dois |
| I6 | Cliente nunca altera estado replicado fora de `_rollback_tick` | revisão (`.claude/rules/network-code.md`) |
| I7 | XP acumulado é monotônico; nível nunca cai | `XpTable` GUT |
| I8 | Um ticket ativo por conta | backend e2e |
| I9 | Launcher não contém referência a `netfox`, `ENet` ou `res://scenes/arena` | lint de CI (`CI-PR.md` §4) |

## 6. Nomes de ações de input (InputMap)

Definidos uma vez em `shared/core/input_actions.gd` e usados pelo Game (jogo) e pelo Launcher (tela de controles): `move_forward`, `move_back`, `move_left`, `move_right`, `primary_attack`, `skill_q`, `skill_e`, `skill_r`, `interact`, `dodge`, `scoreboard`, `cancel`. Mapeamento padrão: design visual §3.3. (`open_bestiary` em partida: **R-PEND-08**, não está no PRD.)

## 7. Divergências e pendências

Lista viva em `RASTREABILIDADE.md` (§"Pendências"). Este documento referencia por `R-PEND-nn` e não decide por conta própria.
