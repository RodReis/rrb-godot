# GDB — Game Design Balance Specification (MOBA de 2 Tempos)

**Versão:** 1.0 — 2026-10-08  
**Status:** Aprovado para implementação da Fatia Vertical (M1–M4)  
**Autor:** Rodrigo (com apoio da IA)  
**Repositório:** `rrb-godot`  
**Documentos Relacionados:** PRD (`docs/prd/2026-10-08-prd-moba-2-tempos.md`), Benchmark (`docs/specs/benchmark-referencias-moba-2-tempos.md`)

---

## 1. Visão Geral e Metas de Balanceamento

Este documento define os parâmetros numéricos, fórmulas de combate, curvas de progressão e tabelas de balanceamento para a fatia vertical (1v1) do MOBA de 2 Tempos.

### 1.1 Metas Quantitativas da Partida
- **Duração Total da Partida:** Mínimo de 6:00 min, máximo absoluto de 10:00 min.
- **Duração Fase 1 (Preparação):** 5:00 min (cronômetro fixo).
- **Duração Fase 2 (Confronto):** $\le$ 5:00 min (zona fecha em 4:00 min; morte súbita final em até 1:00 min).
- **Time-to-Kill (TTK) Médio:**
  - *Fase 1 (Níveis 1–5, sem itens fechados):* 4.5 a 6.0 segundos de dano contínuo.
  - *Fase 2 (Níveis 6–10, itens Raros/Épicos):* 2.8 a 4.0 segundos de rotação completa de skills.
- **Teto de Snowball:** Jogador com maior nível ao fim da Fase 1 deve vencer em **< 75%** das partidas (critério de sucesso do PRD §9.2).

---

## 2. Fórmulas Globais de Combate e Atributos

Toda computação de atributos e resolução de combate é autoritativa no servidor Godot headless (`scripts/core/`).

### 2.1 Atributos Primários
| Atributo | Abreviatura | Efeito Direto |
|---|---|---|
| **HP (Vida)** | `HP` | Pontos de vida totais. Ao chegar a 0, ativa rotina de morte/respawn. |
| **Defesa** | `DEF` | Redução percentual assintótica de dano físico e mágico. |
| **Ataque** | `ATK` | Escala o dano do Ataque Básico e habilidades normais (Q e E). |
| **Inteligência** | `INT` | Escala a habilidade Suprema (R) e concede Redução de Cooldown (CDR). |
| **Agilidade** | `AGI` | Escala a Velocidade de Movimento ($u/s$) e Velocidade de Ataque (ataques/s). |

### 2.2 Fórmulas Fundamentais

#### A. Redução de Dano por Defesa
$$\text{Dano Recebido} = \text{Dano Bruto} \times \left(\frac{100}{100 + \text{DEF}}\right)$$
*Exemplos de mitigação:*
- $10\text{ DEF} \rightarrow \approx 9.1\%$ de mitigação.
- $30\text{ DEF} \rightarrow \approx 23.1\%$ de mitigação.
- $60\text{ DEF} \rightarrow \approx 37.5\%$ de mitigação.
- $100\text{ DEF} \rightarrow 50.0\%$ de mitigação.

#### B. Redução de Cooldown (CDR) por Inteligência
$$\text{CDR (\%)} = \min(30.0,\; \text{INT} \times 0.5\%)$$
- Cada ponto de `INT` fornece $0.5\%$ de CDR.
- **Teto rígido (Hard Cap):** $30\%$ (atingido com $60\text{ INT}$).
$$\text{Cooldown Efetivo} = \text{Cooldown Base} \times \left(1 - \frac{\text{CDR}}{100}\right)$$

#### C. Velocidade de Movimento por Agilidade
$$\text{Velocidade} = \text{Velocidade Base} \times \left(1 + \frac{\text{AGI} \times 0.4\%}{100}\right)$$
- Base padrão de mobilidade: $6.0\text{ u/s}$.

#### D. Velocidade de Ataque por Agilidade
$$\text{Intervalo de Ataque (s)} = \frac{\text{Recarga Base}}{1 + \left(\frac{\text{AGI} \times 0.6\%}{100}\right)}$$

---

## 3. Progressão de Nível e Curva de XP

### 3.1 Níveis e Pontos de Habilidade
O nível máximo é **10**. Cada nível concede 1 Ponto de Habilidade (Total: 9 pontos distribuíveis).
- **Skill Q e E:** Desbloqueadas nos níveis 1 e 2; máximo de 5 níveis cada.
- **Skill R (Ultimate):** Desbloqueia obrigatoriamente no nível 6; nível máximo 2 (nível 6 e nível 10).

### 3.2 Tabela de Experiência (XP)
| Nível | XP do Nível | XP Acumulado | Nível de Habilidade Típico |
|---|---|---|---|
| **1** | 0 | 0 | Q1 |
| **2** | 90 | 90 | Q1, E1 |
| **3** | 140 | 230 | Q2, E1 |
| **4** | 210 | 440 | Q2, E2 |
| **5** | 300 | 740 | Q3, E2 |
| **6** | 420 | 1160 | Q3, E2, R1 (Pico de Poder) |
| **7** | 560 | 1720 | Q4, E2, R1 |
| **8** | 720 | 2440 | Q4, E3, R1 |
| **9** | 900 | 3340 | Q5, E3, R1 |
| **10** | 1100 | 4440 | Q5, E3, R2 (Nível Máximo) |

### 3.3 Regras de Catch-up e Experiência em PvP
- **Multiplicador de Retardo (Catch-up):** Se $\text{Nível}_{\text{Jogador}} \le \text{Nível}_{\text{Adversário}} - 2$, todo ganho de XP de monstros e objetivos recebe bônus fixo de $+25\%$.
- **Morte na Fase 1:**
  - Jogador abatido renasce na base em 8.0 s.
  - Não conta para o placar de kills.
  - Vencedor do duelo recebe $80\text{ XP}$ (equivalente a 1 monstro Tier 2).
- **Morte na Fase 2:**
  - Jogador abatido renasce em 6.0 s (enquanto o raio não for o mínimo).
  - Soma +1 kill para a meta de vitória.
  - Concede $150\text{ XP} + (20 \times \text{Nível do Alvo})$ ao matador.

---

## 4. Balanceamento dos Heróis

### 4.1 Cavaleiro (Tanque — Melee)
- **Papel:** Absorção de dano, engajamento frontal e controle de grupo.
- **Velocidade Base:** $5.8\text{ u/s}$.

#### Atributos Base e Crescimento
| Atributo | Nível 1 | Ganho / Nível | Nível 10 (Sem Itens) |
|---|---|---|---|
| **HP** | 600 | +45 | 1005 |
| **Defesa** | 30 | +3.0 | 57 |
| **Ataque** | 40 | +3.5 | 71.5 |
| **Inteligência** | 10 | +1.0 | 19 (CDR: 9.5%) |
| **Agilidade** | 10 | +1.0 | 19 |

#### Habilidades do Cavaleiro
- **Ataque Básico (Espada Curta):**
  - Tipo: Melee em arco cônico ($70^\circ$, raio $2.2\text{ u}$).
  - Cooldown: $1.0\text{ s}$.
  - Dano: $100\%\text{ ATK}$.
- **Q — Investida:**
  - Avança $6.0\text{ u}$ em linha reta (velocidade $14\text{ u/s}$). Colisão empurra inimigos por $1.5\text{ u}$.
  - Cooldown Base: $8.0\text{ s}$.
  - Dano: $[50, 80, 110, 140, 170] + (0.75 \times \text{ATK})$.
- **E — Muralha:**
  - Ergue um escudo por $3.0\text{ s}$ que absorve dano frontal e bloqueia projéteis que cruzam seu volume.
  - Cooldown Base: $11.0\text{ s}$.
  - Escudo Absorvente: $[120, 170, 220, 270, 320] + (0.15 \times \text{HP Máximo})$.
- **R — Terremoto (Ultimate, Nv 6+):**
  - Golpeia o solo criando onda circular de raio $5.0\text{ u}$. Atordoa todos na área.
  - Cooldown Base: $[50.0, 42.0]\text{ s}$.
  - Duração do Atordoamento: $[1.2, 1.6]\text{ s}$.
  - Dano: $[160, 260] + (1.1 \times \text{INT})$.

---

### 4.2 Arqueira (Ranger — Ranged)
- **Papel:** Dano sustentado à distância, mobilidade e controle de terreno.
- **Velocidade Base:** $6.2\text{ u/s}$.

#### Atributos Base e Crescimento
| Atributo | Nível 1 | Ganho / Nível | Nível 10 (Sem Itens) |
|---|---|---|---|
| **HP** | 380 | +28 | 632 |
| **Defesa** | 10 | +1.2 | 20.8 |
| **Ataque** | 55 | +5.0 | 100 |
| **Inteligência** | 15 | +1.5 | 28.5 (CDR: 14.2%) |
| **Agilidade** | 25 | +2.2 | 44.8 |

#### Habilidades da Arqueira
- **Ataque Básico (Disparo com Arco):**
  - Tipo: Projétil balístico direto (velocidade $20\text{ u/s}$, alcance $9.0\text{ u}$, raio colisão $0.3\text{ u}$).
  - Cooldown Base: $0.8\text{ s}$.
  - Dano: $100\%\text{ ATK}$.
- **Q — Flecha Perfurante:**
  - Dispara projétil perfurante de longo alcance ($11.0\text{ u}$). Atravessa alvos com decaimento de $-15\%$ por alvo atravessado (dano mínimo $40\%$).
  - Cooldown Base: $7.0\text{ s}$.
  - Dano Base: $[65, 100, 135, 170, 205] + (0.95 \times \text{ATK})$.
- **E — Rolamento:**
  - Esquiva na direção do movimento por $4.2\text{ u}$ em $0.35\text{ s}$. Concede $0.3\text{ s}$ de invulnerabilidade total a dano e redefine o cooldown do Ataque Básico.
  - Cooldown Base: $[9.0, 8.2, 7.4, 6.6, 5.8]\text{ s}$.
- **R — Chuva de Flechas (Ultimate, Nv 6+):**
  - Marca área circular de raio $4.0\text{ u}$ em até $8.0\text{ u}$ de distância. Dispara saraivada contínua por $3.0\text{ s}$ (6 pulsos de dano a cada $0.5\text{ s}$). Aplica $25\%$ de lentidão dentro da área.
  - Cooldown Base: $[45.0, 38.0]\text{ s}$.
  - Dano por Pulso: $[30, 48] + (0.25 \times \text{INT}) + (0.15 \times \text{ATK})$. Dano Total Máximo: $[180, 288] + (1.5 \times \text{INT}) + (0.9 \times \text{ATK})$.

---

## 5. Bestiário e Economia de Campo (Fase 1)

Os monstros não respawnam. A quantidade é limitada para forçar a disputa do centro e garantir que um jogador sozinho na base atinja no máximo nível 7–8.

### 5.1 Distribuição e Tabela de Monstros
| Monstro | Tier | Qtd por Partida | Onde Fica | HP | Dano/Golpe | Intervalo Atq | XP Concedido | Drop Típico |
|---|---|---|---|---|---|---|---|---|
| **Esqueleto** | 1 | 8 (4 em cada base) | Base Segura | 160 | 14 | 1.2 s | 35 | Ouro / Chance 20% Item Comum |
| **Esqueleto Guerreiro** | 2 | 4 (1 em cada base, 2 no centro) | Base / Centro | 360 | 28 | 1.1 s | 85 | Item Comum Garantido |
| **Esqueleto Mago** | 2 | 2 (ambos no centro) | Centro Contestado | 260 | 38 (Ranged 7u) | 1.5 s | 80 | Item Comum ou Raro |
| **Golem de Pedra** | 3 | 2 (ambos no centro) | Centro Contestado | 680 | 50 (Melee AoE) | 1.6 s | 190 | Item Raro Garantido |
| **Rei Esqueleto (Boss)** | Boss | 1 (surge em 3:30) | Centro Absoluto | 2400 | 75 (AoE + Knockback)| 1.4 s | 550 | 1 Item Épico Garantido |

### 5.2 Alocação Teórica Máxima de XP na Fase 1
- Farm Completo de uma Base: $(4 \times 35) + (1 \times 85) = 225\text{ XP} \rightarrow$ Nível 3 garantido no primeiro 1:30 min.
- Disputa Total do Centro (sem Boss): $(2 \times 85) + (2 \times 80) + (2 \times 190) = 710\text{ XP}$.
- Rei Esqueleto: $550\text{ XP}$.
- **Conclusão:** Farmar apenas a base leva ao nível ~5. Para alcançar o nível 8–9 antes da Fase 2, é mandatório disputar o centro.

---

## 6. Sistema de Itens, Equipamentos e Conjuntos

O inventário possui 4 slots equipáveis: **Arma, Elmo, Peitoral e Botas**.

### 6.1 Catálogo dos 12 Itens da Fatia Vertical

#### A. Armas (3 itens — Escalam ATK)
- **Arma Comum:** $+12\text{ ATK}$
- **Arma Rara:** $+25\text{ ATK}$
- **Arma Épica (Drop do Boss):** $+45\text{ ATK}$, passiva única: *Fúria* (Ataques básicos causam $+6\%$ do HP restante do alvo como dano bônus).

#### B. Armaduras — Conjunto Guarda (Foco Defensivo / Sobrevivência)
| Slot | Comum | Raro | Épico |
|---|---|---|---|
| **Elmo da Guarda** | $+8\text{ DEF}$ | $+15\text{ DEF}$, $+5\text{ INT}$ | $+25\text{ DEF}$, $+12\text{ INT}$ |
| **Peitoral da Guarda** | $+50\text{ HP}$, $+5\text{ DEF}$ | $+110\text{ HP}$, $+12\text{ DEF}$ | $+220\text{ HP}$, $+22\text{ DEF}$ |
| **Botas da Guarda** | $+5\%\text{ AGI}$ | $+10\%\text{ AGI}$, $+5\text{ DEF}$ | $+16\%\text{ AGI}$, $+10\text{ DEF}$ |

- **Bônus de Conjunto Guarda (3/3 peças):** $+15\%\text{ HP Máximo}$ e $+10\text{ DEF}$ plano.

#### C. Armaduras — Conjunto Caçador (Foco Ofensivo / Velocidade)
| Slot | Comum | Raro | Épico |
|---|---|---|---|
| **Elmo do Caçador** | $+4\text{ ATK}$ | $+8\text{ ATK}$, $+6\text{ AGI}$ | $+15\text{ ATK}$, $+12\text{ AGI}$ |
| **Peitoral do Caçador** | $+35\text{ HP}$, $+5\text{ ATK}$ | $+75\text{ HP}$, $+12\text{ ATK}$ | $+140\text{ HP}$, $+22\text{ ATK}$ |
| **Botas do Caçador** | $+8\%\text{ AGI}$ | $+15\%\text{ AGI}$, $+4\text{ ATK}$ | $+24\%\text{ AGI}$, $+8\text{ ATK}$ |

- **Bônus de Conjunto Caçador (3/3 peças):** $+10\%$ de Velocidade de Ataque e $+8\%$ de Velocidade de Movimento.

### 6.2 Baús de Loot no Mapa
- **Baús Comuns (6 por base segura):**
  - Drop: 70% Item Comum, 30% Ouro/Consumível temporário de cura ($+120\text{ HP}$).
- **Baús Raros (4 no centro contestado):**
  - Drop: 65% Item Raro, 25% Item Comum, 10% Item Épico.
- **Regra de Substituição:** O servidor substitui automaticamente o equipamento se a raridade do item coletado for maior. Em caso de empate ou escolha lateral, a tecla `F` (segurada por $0.4\text{ s}$) valida a troca.

---

## 7. Fase 2 — Confronto, Dinâmica da Zona e Resolução

### 7.1 Cronograma da Fase 2 (Início aos 5:00)
| Tempo de Jogo | Tempo Fase 2 | Raio da Zona (% da Arena) | Dano da Zona Fora do Círculo | Estado do Respawn |
|---|---|---|---|---|
| **5:00** | 0:00 | $100\%$ (Raio $35\text{ u}$) | $1.0\%\text{ HP Máx/s}$ | Ativo (6.0 s) |
| **6:00** | 1:00 | $75\%$ (Raio $26\text{ u}$) | $2.0\%\text{ HP Máx/s}$ | Ativo (6.0 s) |
| **7:00** | 2:00 | $50\%$ (Raio $17.5\text{ u}$) | $3.0\%\text{ HP Máx/s}$ | Ativo (6.0 s) |
| **8:00** | 3:00 | $25\%$ (Raio $8.75\text{ u}$) | $4.0\%\text{ HP Máx/s}$ | Ativo (6.0 s) |
| **9:00** | 4:00 | **Mínimo** (Raio $3.5\text{ u}$) | $5.0\%\text{ HP Máx/s}$ | **DESATIVADO (Morte Súbita)** |
| **10:00** | 5:00 | Raio $0\text{ u}$ (Colapso total) | Dano dobra a cada 10 s | Desativado (Fim forçado) |

### 7.2 Regras de Vitória (Ordem de Avaliação pelo Servidor)
1. **Meta de Kills Atingida:**
   - 1v1: **5 kills**.
   - 2v2: **7 kills** (Roadmap).
   - 3v3: **10 kills** (Roadmap).
2. **Eliminação por Sobrevivência (após 9:00):** O primeiro jogador a ficar sem vidas após o desligamento do respawn é derrotado.
3. **Morte Súbita Matemática (10:00):** O colapso final da zona impossibilita cura sustentada; o herói com maior vida percentual sobrevivente vence. Jamais há empate.

---

## 8. Estrutura de Arquivos de Dados no Godot (`data/`)

Para manter a separação estrita de dados exigida no PRD §4.3 e §8.6, todos os parâmetros acima são serializados como Resources (`.tres`) carregados dinamicamente pelo servidor:

```
game/data/
├── heroes/
│   ├── knight.tres          # Herói Cavaleiro (HP, Def, Atk, Skills Q/E/R)
│   └── ranger.tres          # Herói Arqueira (HP, Def, Atk, Skills Q/E/R)
├── items/
│   ├── weapons/
│   │   ├── sword_t1.tres
│   │   ├── sword_t2.tres
│   │   └── sword_t3_epic.tres
│   ├── guard_set/           # Elmo, Peitoral, Botas (T1 a T3) + guard_bonus.tres
│   └── hunter_set/          # Elmo, Peitoral, Botas (T1 a T3) + hunter_bonus.tres
├── monsters/
│   ├── skeleton_t1.tres
│   ├── skeleton_warrior_t2.tres
│   ├── skeleton_mage_t2.tres
│   ├── golem_t3.tres
│   └── skeleton_king_boss.tres
└── rules/
    ├── match_pacing.tres    # Timers, raio da zona, curvas de dano
    └── xp_table.tres        # Vetor de XP por nível (1 a 10)
```