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
| `HERO_PICK` | 2 peers | ambos lock-in **ou** 24 s (sem escolha → herói padrão do slot: P1 Cavaleiro, P2 Arqueira — decidido pelo PI em 2026-10-10, R-PEND-04). **Espelho permitido** (os dois podem escolher o mesmo herói) | pick |
| `PHASE1` | pick concluído | `t_match = 5:00` | `t_match` 0:00–5:00 |
| `TRANSITION` | 5:00 | +5 s | aviso visual/sonoro; **já conta como fase 2**: `t_phase2` começa às 5:00 (decisão do PI 2026-10-10) |
| `PHASE2` | 5:05 | meta de kills **ou** `t_phase2 = 4:00` (9:00 de partida) | `t_phase2` 0:05–4:00 |
| `SUDDEN_DEATH` | `t_phase2 = 4:00` (9:00 de partida) | último time com vivo **ou** 10:00 → colapso com resolução imediata (GDB §7.2 item 3) | até 10:00 |
| `ENDED` | vitória ou abandono | processo encerra após reportar | — |

Invariantes: a partida **sempre** termina em ≤ 10:00 (PRD §9.2); **nunca** há empate (GDB §7.2 — a única saída sem vencedor é `abandoned`: ninguém conectado); não há transição de volta.

## 4. Regras por tema (fonte → seção)

### 4.1 Fase 1 — preparação
- Mapa: layout, escala e marcadores em `docs/prd/mvp/spec/SPEC-007.md` (raio 35 u; spawn→centro ~6 s; rio bloqueia, 2 pontes; cratera com 4 entradas).
- Portões: só o time dono passa (PRD §3.1). Centro (ilha + anel) é PvP desde 0:00.
- Monstros: distribuição e XP em GDB §5.1 — base, centro e **4 campos laterais** (NO e SE, um de cada lado do rio). Monstros não-boss renascem **90 s** após morrer, só na fase 1 (decisão do PI 2026-10-10, F36). Baús: 24, não reabrem (GDB §6.2). Boss surge aos **3:30**; aviso global aos **3:00** (banner + som + pista visual no portal — decisão do PI 2026-10-09, origem benchmark §3.2).
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
- Épico: drop garantido do boss; baú raro 10 % (GDB §6.2; confirmado pelo PI 2026-10-09).
- Consumível de cura +120 HP (GDB §6.2, baú comum 30%) — único consumível da fatia.

### 4.4 Fase 2 — confronto
- Zona centrada no centro do mapa; raio, dano e respawn por minuto em GDB §7.1.
- Meta de kills 1x1 = 5. Morte dá 150 + 20×nível do alvo em XP ao matador (GDB §3.3).
- Respawn 6,0 s até 4:00 da fase 2; depois desligado.
- Ordem de vitória (GDB §7.2): 1) meta de kills; 2) após 9:00, adversário sem vivos; 3) colapso aos 10:00 — maior HP% vence na hora; desempate: mais kills na fase 2 → mais dano causado em heróis → sorteio pela seed da partida; os dois desconectados → `abandoned` (decisão do PI 2026-10-10).
- Monstros comuns não respawnam na fase 2; os que sobraram continuam vivos e dão XP. O **Rei Esqueleto** existe até morrer ou até 5:00: vivo na transição, sai do mapa **sem drop** (decisão do PI 2026-10-10, R-PEND-06).

### 4.5 Heróis
- Base, crescimento e habilidades: GDB §4.1 (Cavaleiro) e §4.2 (Arqueira).
- Ataque básico: Cavaleiro arco 70°/2,2 u; Arqueira projétil 20 u/s, 9 u, raio 0,3 u.
- Tudo validado no servidor; cliente prevê só movimento próprio e disparo visual do projétil (benchmark §4).

### 4.6 Bot
- FSM PRD §3.7: `Farmar → Saquear → Contestar (3:00, se nível ≥ adversário) → Lutar (vantagem) → Recuar (HP < 30%)`; fase 2: `Perseguir`, `Fugir da zona`.
- Bot produz input; não tem informação além do que um cliente teria (sem ler estado interno do servidor fora do replicado). **Invariante de honestidade do bot.**

### 4.7 Mato alto (regra nova — decisão do PI 2026-10-09, origem Astro Arena / Brawl Stars)
- Herói dentro de uma moita (`Area3D` grupo `tall_grass`, SPEC-007 §2) **não é visível** para o adversário que está fora dela: o servidor deixa de replicar sua posição para aquele peer (F32).
- Vê quem está na mesma moita. Atacar ou usar skill de dentro revela o herói por **1,5 s** (GDB §7.3). **Sem revelação por proximidade**: chegar perto da moita pelo lado de fora não revela (decisão do PI 2026-10-10, R-PEND-12).
- Monstros e bot seguem a mesma regra que um jogador (invariante de honestidade do bot, §4.6).
- Geometria entra no F7; a regra de visibilidade é F32 (MVP2), porque depende de filtro de replicação do netfox.

### 4.9 Neblina de guerra (decisão do PI 2026-10-10 — reverte a exclusão de 2026-10-09)
- **Visão + explorado** (estilo MOBA): área nunca vista fica escura; área já vista fica revelada em cinza; herói adversário e monstros só aparecem dentro do **raio de visão de 12 u** do herói (GDB — F37).
- O servidor **não replica** para um peer o que está fora da visão dele — mesmo filtro do F32, generalizado. Neblina só visual no cliente é proibida (map hack).
- Mato alto continua valendo dentro do raio de visão (§4.7).
- Minimapa mostra a própria posição, o explorado e só o que está na visão atual.
- **Continua na fase 2**; o círculo da zona é sempre visível, no mundo e no minimapa.
- Bot obedece à neblina (invariante de honestidade, §4.6).

### 4.8 Conta e fila
- Conta: e-mail + senha (PRD §8.4). Sem verificação de e-mail, sem recuperação de senha na fatia (**R-PEND-07** — não está no PRD; registrado em `FORA-DE-ESCOPO.md`).
- Senha: mínimo 8 caracteres, com pelo menos uma letra e um número (decisão do PI 2026-10-10).
- Nickname (F35): obrigatório no 1º login; 3–16 caracteres `A–Z a–z 0–9 _`; único sem diferenciar maiúsculas; exibido com prefixo `#`, que não é guardado. Avatar só local no Launcher (PNG/JPG ≤ 1 MB, 256×256). Sem XP de conta (R-PEND-02, decisões de 2026-10-09 e 2026-10-10).
- Fila 1x1 FIFO, sem rating (PRD §8.4). Um ticket por conta por vez.
- Histórico: partidas da própria conta, com os campos de `match_players` (`ARCHITECTURE-LAUNCHER.md` §4.3). Oponente identificado pelo herói e, a partir do F35, pelo `#nickname`; nunca pelo e-mail.

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

Definidos uma vez em `shared/core/input_actions.gd` e usados pelo Game (jogo) e pelo Launcher (tela de controles): `move_forward`, `move_back`, `move_left`, `move_right`, `primary_attack`, `skill_q`, `skill_e`, `skill_r`, `interact`, `dodge`, `scoreboard`, `cancel`. Mapeamento padrão: design visual §3.3. `open_bestiary` (`B`) abre o bestiário em partida sem pausar (decisão do PI 2026-10-09). `learn_q`, `learn_e`, `learn_r` gastam um ponto de habilidade em Q, E, R com `Ctrl` + tecla da skill, um ponto por toque, sem lançar a skill; só teclado até os botões `+Q/+E/+R` da HUD no F13, que trazem o gamepad (decisão do PI 2026-10-09, F9).

## 7. Divergências e pendências

Lista viva em `RASTREABILIDADE.md` (§"Pendências"). Este documento referencia por `R-PEND-nn` e não decide por conta própria.
