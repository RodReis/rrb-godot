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

#### E. Frenesi do Berserker (passiva, ADR-0015, F75)
$$f = \min\!\left(1,\ \frac{1 - \text{HP}/\text{HP}_{\max}}{0.8}\right)$$
$$\text{Velocidade de Ataque} \mathrel{+}= 60\% \times f \qquad \text{Roubo de Vida (básico)} = 25\% \times f$$
- $f$ cresce linearmente com o HP perdido e chega a $1$ com **20 % de HP** (teto). A 100 % de HP, nada.
- O bônus de velocidade de ataque entra **depois** da fórmula D (multiplica o intervalo por $1/(1+0.6f)$). O roubo de vida cura o Berserker em $25\%\,f$ do dano **do ataque básico** efetivamente causado (depois da Defesa do alvo); skills não roubam vida.
- Durante **Ragnarök** (§4.8), $f = 1$ independentemente do HP.
- Nome **Frenesi** para não confundir com a passiva *Fúria* da Arma Épica (§6.1-A), que é outra regra.
- Única passiva de herói do jogo; `HeroData.passive` (`PassiveData.FRENZY`), aplicada no `_rollback_tick` do próprio herói.

#### F. Maldição do Ocultista (debuff, ADR-0016, F77)
$$\text{DEF}_{\text{efetiva}} = \max\!\left(0,\ \text{DEF} - m \times 6\right), \qquad m \in \{0, 1, 2, 3\}$$
- Cada acerto do **ataque básico** do Ocultista (§4.10) aplica **1 marca** ($m \mathrel{+}= 1$, teto $m = 3$) em herói ou monstro inimigo (boss incluído). Só o básico aplica marca; Q, E e Servos não.
- As marcas duram $4.0\text{ s}$; **a marca nova renova a duração de todas**. Ao expirar, caem todas juntas ($m = 0$).
- A Defesa efetiva **nunca fica negativa** (piso 0) e entra na fórmula A no lugar da Defesa; bônus temporários de Defesa (Grito de Guerra, itens) somam antes do desconto.
- Estado no próprio alvo (`curse_stacks`, `curse_ticks`), aplicado no `_rollback_tick` dele pelo ledger (ADR-0001).

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
| **3** | 135 | 225 | Q2, E1 |
| **4** | 215 | 440 | Q2, E2 |
| **5** | 300 | 740 | Q3, E2 |
| **6** | 420 | 1160 | Q3, E2, R1 (Pico de Poder) |
| **7** | 560 | 1720 | Q4, E2, R1 |
| **8** | 720 | 2440 | Q4, E3, R1 |
| **9** | 900 | 3340 | Q5, E3, R1 |
| **10** | 1100 | 4440 | Q5, E3, R2 (Nível Máximo) |

*Nível 3 em 225 XP (era 230) para o farm completo de uma base (§5.2) dar nível 3 — decisão do PI em 2026-10-09 (F9). Os demais acumulados não mudam.*

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

### 4.2 Arqueiro (Ranger — Ranged)
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

#### Habilidades do Arqueiro
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

### 4.3 Bárbaro (Algoz — Melee) — ADR-0011, SPEC-053
- **Papel:** dano alto corpo a corpo, frágil; entra com salto e finaliza com a Execução.
- **Modelo:** KayKit Adventurers 1.0 `Barbarian`; arma visível = machado (F48).
- **Velocidade Base:** $6.0\text{ u/s}$.
- *Números aprovados pelo PI em 2026-10-11 como proposta, conferidos no soak (F19).*

#### Atributos Base e Crescimento
| Atributo | Nível 1 | Ganho / Nível | Nível 10 (Sem Itens) |
|---|---|---|---|
| **HP** | 480 | +35 | 795 |
| **Defesa** | 15 | +1.8 | 31.2 |
| **Ataque** | 52 | +4.5 | 92.5 |
| **Inteligência** | 8 | +0.8 | 15.2 (CDR: 7.6%) |
| **Agilidade** | 20 | +1.8 | 36.2 |

#### Habilidades do Bárbaro
- **Ataque Básico (Machado):**
  - Tipo: Melee em arco cônico ($90^\circ$, raio $2.4\text{ u}$).
  - Cooldown: $0.9\text{ s}$.
  - Dano: $100\%\text{ ATK}$.
- **Q — Salto Brutal:**
  - Salta até $7.0\text{ u}$ até o ponto mirado em $0.45\text{ s}$; o deslocamento para no primeiro obstáculo (rio, muro, pilar — como a Investida). Na aterrissagem, dano em área de raio $2.5\text{ u}$.
  - Cooldown Base: $[10.0, 9.5, 9.0, 8.5, 8.0]\text{ s}$.
  - Dano: $[60, 95, 130, 165, 200] + (0.8 \times \text{ATK})$.
- **E — Rodopio:**
  - Gira por $1.5\text{ s}$: 3 pulsos (a cada $0.5\text{ s}$) em raio $2.5\text{ u}$. Anda normalmente; sem ataque básico enquanto gira.
  - Cooldown Base: $9.0\text{ s}$.
  - Dano por Pulso: $[30, 45, 60, 75, 90] + (0.35 \times \text{ATK})$.
- **R — Execução (Ultimate, Nv 6+):**
  - Golpe frontal único (cone $60^\circ$, raio $2.5\text{ u}$).
  - Cooldown Base: $[55.0, 45.0]\text{ s}$.
  - Dano: $[200, 320] + (1.0 \times \text{INT}) + (0.5 \times \text{ATK}) + 25\%$ do HP faltante do alvo (calculado antes da mitigação por DEF).

---

### 4.4 Bruxo de Fogo (Mago — Ranged) — ADR-0011, SPEC-054
- **Papel:** dano mágico em área à distância, frágil; afasta quem chega perto com o Anel de Fogo.
- **Modelo:** KayKit Adventurers 1.0 `Mage`; arma visível = cajado (F48). Fogo é visual + área — sem queimadura contínua.
- **Velocidade Base:** $6.0\text{ u/s}$.
- *Números aprovados pelo PI em 2026-10-11 como proposta, conferidos no soak (F19). Q e E escalam ATK (regra do §2.1).*

#### Atributos Base e Crescimento
| Atributo | Nível 1 | Ganho / Nível | Nível 10 (Sem Itens) |
|---|---|---|---|
| **HP** | 360 | +26 | 594 |
| **Defesa** | 8 | +1.0 | 17 |
| **Ataque** | 45 | +4.0 | 81 |
| **Inteligência** | 30 | +3.0 | 57 (CDR: 28.5%) |
| **Agilidade** | 15 | +1.2 | 25.8 |

#### Habilidades do Bruxo de Fogo
- **Ataque Básico (Bola de Fogo):**
  - Tipo: Projétil direto (velocidade $16\text{ u/s}$, alcance $8.0\text{ u}$, raio colisão $0.4\text{ u}$). Bloqueado pela Muralha, como a flecha.
  - Cooldown Base: $1.0\text{ s}$.
  - Dano: $100\%\text{ ATK}$.
- **Q — Explosão de Chamas:**
  - Projétil (velocidade $16\text{ u/s}$, alcance $9.0\text{ u}$) que explode no primeiro alvo atingido ou no fim do alcance; dano em área de raio $2.0\text{ u}$.
  - Cooldown Base: $6.0\text{ s}$.
  - Dano: $[70, 105, 140, 175, 210] + (0.9 \times \text{ATK})$.
- **E — Anel de Fogo:**
  - Área instantânea de raio $3.0\text{ u}$ em volta do Bruxo; empurra os inimigos atingidos $2.0\text{ u}$ para fora.
  - Cooldown Base: $10.0\text{ s}$.
  - Dano: $[40, 65, 90, 115, 140] + (0.5 \times \text{ATK})$.
- **R — Meteoro (Ultimate, Nv 6+):**
  - Marca área circular de raio $3.5\text{ u}$ em até $9.0\text{ u}$ de distância; o meteoro cai $1.0\text{ s}$ depois (a marcação é visível como a da Chuva de Flechas).
  - Cooldown Base: $[50.0, 42.0]\text{ s}$.
  - Dano: $[260, 400] + (1.4 \times \text{INT}) + (0.6 \times \text{ATK})$.

---

### 4.5 Ladina (Algoz — Ranged curto) — ADR-0013, SPEC-058
- **Papel:** dano alto de perto com a besta, frágil; some na fumaça e entra com a Emboscada.
- **Modelo:** KayKit Adventurers 2.0 `Rogue_Hooded` (cor original); arma visível = besta (F48).
- **Velocidade Base:** $6.3\text{ u/s}$.
- *Números aprovados pelo PI em 2026-10-13 como proposta, conferidos no soak do F58. Q e E escalam ATK (regra do §2.1).*

#### Atributos Base e Crescimento
| Atributo | Nível 1 | Ganho / Nível | Nível 10 (Sem Itens) |
|---|---|---|---|
| **HP** | 400 | +30 | 670 |
| **Defesa** | 12 | +1.3 | 23.7 |
| **Ataque** | 54 | +4.8 | 97.2 |
| **Inteligência** | 12 | +1.2 | 22.8 (CDR: 11.4%) |
| **Agilidade** | 28 | +2.4 | 49.6 |

#### Habilidades da Ladina
- **Ataque Básico (Virote):**
  - Tipo: Projétil direto (velocidade $24\text{ u/s}$, alcance $7.0\text{ u}$, raio colisão $0.3\text{ u}$). Bloqueado pela Muralha, como a flecha.
  - Cooldown Base: $1.0\text{ s}$.
  - Dano: $100\%\text{ ATK}$.
- **Q — Rajada em Leque:**
  - Dispara 3 virotes ao mesmo tempo, em $-12^\circ$, $0^\circ$ e $+12^\circ$ da mira (mesma velocidade, alcance e raio do básico). Cada virote para no primeiro alvo; o mesmo alvo pode levar os 3 (de perto). Bloqueados pela Muralha.
  - Cooldown Base: $[8.0, 7.5, 7.0, 6.5, 6.0]\text{ s}$.
  - Dano por Virote: $[30, 45, 60, 75, 90] + (0.4 \times \text{ATK})$.
- **E — Bomba de Fumaça:**
  - Nuvem circular de raio $3.0\text{ u}$ centrada na posição da Ladina no lançamento, por $3.0\text{ s}$. A nuvem é uma **moita temporária** (§7.3, CONVENTION §4.7) para qualquer herói dentro dela. **Lançar a Bomba de Fumaça não revela a Ladina** (única exceção à revelação ao agir).
  - Cooldown Base: $[14.0, 13.0, 12.0, 11.0, 10.0]\text{ s}$.
  - Sem dano.
- **R — Emboscada (Ultimate, Nv 6+):**
  - Avança até $8.0\text{ u}$ na direção mirada a $24\text{ u/s}$; para no primeiro herói ou monstro inimigo tocado ou no primeiro obstáculo (como a Investida). Parando num inimigo, golpeia com a faca uma vez.
  - Cooldown Base: $[50.0, 42.0]\text{ s}$.
  - Dano: $[220, 340] + (1.2 \times \text{INT}) + (0.6 \times \text{ATK})$; $\times 1.3$ se, no tick do uso, a Ladina estava oculta (dentro de moita ou fumaça e sem revelação ativa).

---

### 4.6 Engenheiro (Engenheiro — curta distância + zona) — ADR-0013, SPEC-059
- **Papel:** dano em cone de perto com o bacamarte; puxa o adversário com a Garra e controla a área com a Torreta e a Dinamite.
- **Modelo:** KayKit Adventurers 2.0 Extra `Engineer`; arma visível = bacamarte (F48).
- **Velocidade Base:** $5.9\text{ u/s}$.
- *Números aprovados pelo PI em 2026-10-13 como proposta, conferidos no soak do F59. Q e E escalam ATK (regra do §2.1).*

#### Atributos Base e Crescimento
| Atributo | Nível 1 | Ganho / Nível | Nível 10 (Sem Itens) |
|---|---|---|---|
| **HP** | 520 | +38 | 862 |
| **Defesa** | 22 | +2.2 | 41.8 |
| **Ataque** | 46 | +4.0 | 82 |
| **Inteligência** | 18 | +1.8 | 34.2 (CDR: 17.1%) |
| **Agilidade** | 12 | +1.0 | 21 |

#### Habilidades do Engenheiro
- **Ataque Básico (Bacamarte):**
  - Tipo: Cone instantâneo ($40^\circ$, raio $4.5\text{ u}$) — acerta todos os inimigos no cone; sem projétil (a Muralha trata como dano corpo a corpo).
  - Cooldown Base: $1.2\text{ s}$.
  - Dano: $100\%\text{ ATK}$ em cada alvo.
- **Q — Garra Mecânica:**
  - Projétil (velocidade $20\text{ u/s}$, alcance $7.0\text{ u}$, raio colisão $0.4\text{ u}$) que para no primeiro inimigo. Herói atingido é **puxado** em $0.3\text{ s}$ até ficar a $2.0\text{ u}$ do Engenheiro (para no obstáculo). Monstro e boss só tomam dano. Bloqueada pela Muralha.
  - Cooldown Base: $[11.0, 10.5, 10.0, 9.5, 9.0]\text{ s}$.
  - Dano: $[50, 80, 110, 140, 170] + (0.7 \times \text{ATK})$.
- **E — Torreta:**
  - Instala no ponto mirado, até $3.0\text{ u}$ (para no obstáculo). Dura $6.0\text{ s}$; a cada $0.75\text{ s}$ (8 disparos) acerta o inimigo (herói ou monstro) mais próximo a até $7.0\text{ u}$ que o Engenheiro vê (§7.3). Acerto instantâneo, não bloqueado pela Muralha. Indestrutível, sem colisão, uma por vez (a nova substitui a anterior). Disparo da Torreta não revela o Engenheiro.
  - Cooldown Base: $14.0\text{ s}$.
  - Dano por Disparo: $[14, 20, 26, 32, 38] + (0.15 \times \text{ATK})$.
- **R — Caixa de Dinamite (Ultimate, Nv 6+):**
  - Posiciona a caixa no ponto mirado, até $6.0\text{ u}$; explode $1.5\text{ s}$ depois em raio $4.5\text{ u}$ e empurra os atingidos $3.0\text{ u}$ para fora (radial, para no obstáculo, como o Anel de Fogo). A marcação é visível como a do Meteoro.
  - Cooldown Base: $[55.0, 46.0]\text{ s}$.
  - Dano: $[240, 380] + (1.3 \times \text{INT}) + (0.6 \times \text{ATK})$.

---

### 4.7 Protetor da Selva (Controle — Ranged médio) — ADR-0015, SPEC-074
- **Papel:** controlador com autocura: enraíza, cria zona de lentidão e se cura com as poções; dano moderado à distância média. Classe **Controle** (PRD §4.1); redesenhado do pedido "Suporte" porque no 1x1 não há aliado (ADR-0015 item 12).
- **Modelo:** KayKit Adventurers 2.0 Extra `Druid` (cor original); arma visível = cajado `druid_staff` (F48); a Poção Verde usa `potion_large_green` como projétil.
- **Velocidade Base:** $6.0\text{ u/s}$.
- *Números aprovados pelo PI em 2026-10-16 como proposta, conferidos no soak do F74. Q e E escalam ATK (regra do §2.1) — inclusive a cura.*

#### Atributos Base e Crescimento
| Atributo | Nível 1 | Ganho / Nível | Nível 10 (Sem Itens) |
|---|---|---|---|
| **HP** | 470 | +34 | 776 |
| **Defesa** | 16 | +1.6 | 30.4 |
| **Ataque** | 44 | +3.8 | 78.2 |
| **Inteligência** | 24 | +2.4 | 45.6 (CDR: 22.8%) |
| **Agilidade** | 16 | +1.4 | 28.6 |

#### Habilidades do Protetor da Selva
- **Ataque Básico (Seiva):**
  - Tipo: Projétil direto (velocidade $20\text{ u/s}$, alcance $6.5\text{ u}$, raio colisão $0.35\text{ u}$). Bloqueado pela Muralha, como a flecha.
  - Cooldown Base: $1.0\text{ s}$.
  - Dano: $100\%\text{ ATK}$.
- **Q — Raízes Vivas:**
  - Projétil (velocidade $18\text{ u/s}$, alcance $7.0\text{ u}$, raio colisão $0.4\text{ u}$) que para no primeiro herói ou monstro. O atingido fica **enraizado por $1.5\text{ s}$** = lentidão de $100\%$ (reusa o `slow`; pode mirar, atacar e usar skill, só não anda). Bloqueado pela Muralha. Boss: só o dano.
  - Cooldown Base: $[10.0, 9.5, 9.0, 8.5, 8.0]\text{ s}$.
  - Dano: $[40, 65, 90, 115, 140] + (0.5 \times \text{ATK})$.
- **E — Poção Verde:**
  - Arremessa a poção em arco até $5.0\text{ u}$ (para no obstáculo). Zona de cura de raio $3.0\text{ u}$ por $3.0\text{ s}$ ($6$ pulsos a cada $0.5\text{ s}$): cura o Protetor e **aliados** dentro dela (no 1x1, só ele). Usar de dentro da moita revela (§7.3).
  - Cooldown Base: $[16.0, 15.0, 14.0, 13.0, 12.0]\text{ s}$.
  - Cura Total: $[90, 135, 180, 225, 270] + (0.5 \times \text{ATK})$, dividida pelos pulsos. Não passa do HP máximo.
- **R — Pântano (Ultimate, Nv 6+):**
  - Zona circular de raio $5.0\text{ u}$ no ponto mirado, até $7.0\text{ u}$, por $6.0\text{ s}$. Inimigos dentro (heróis e monstros): **lentidão $40\%$** e dano por pulso a cada $1.0\text{ s}$ ($6$ pulsos). A marcação é visível como a do Meteoro.
  - Cooldown Base: $[60.0, 50.0]\text{ s}$.
  - Dano por Pulso: $[30, 50] + (0.25 \times \text{INT})$.

---

### 4.8 Berserker (Lutador — Melee) — ADR-0015, SPEC-075
- **Papel:** lutador corpo a corpo sustentado: quanto menos vida, mais rápido bate e mais rouba vida (Frenesi, §2.2-E); imparável sob controle de grupo no Ragnarök. Classe nova **Lutador** (PRD §4.1).
- **Modelo:** KayKit Adventurers 2.0 Extra `Barbarian_Large` (textura alternativa `alt_A/B/C` — PI escolhe no aceite do F75), rig `Rig_Large`; armas visíveis = dois `axe_1handed_Large` (F48, 3 raridades nos dois). Sem escudo; elmo não aparece (exceção do ADR-0011 item 3). **Colisão igual aos demais heróis.**
- **Velocidade Base:** $6.1\text{ u/s}$.
- *Números aprovados pelo PI em 2026-10-16 como proposta, conferidos no soak do F75. Q e E escalam ATK (regra do §2.1).*

#### Atributos Base e Crescimento
| Atributo | Nível 1 | Ganho / Nível | Nível 10 (Sem Itens) |
|---|---|---|---|
| **HP** | 560 | +44 | 956 |
| **Defesa** | 18 | +1.8 | 34.2 |
| **Ataque** | 58 | +5.0 | 103 |
| **Inteligência** | 8 | +0.8 | 15.2 (CDR: 7.6%) |
| **Agilidade** | 20 | +1.8 | 36.2 |

#### Habilidades do Berserker
- **Passiva — Frenesi:** §2.2-E ($+60\%$ de velocidade de ataque e $25\%$ de roubo de vida no básico, lineares com o HP perdido, teto a 20 % de HP).
- **Ataque Básico (Machados Gêmeos):**
  - Tipo: Melee em arco cônico ($90^\circ$, raio $2.4\text{ u}$), alternando a mão a cada golpe (só visual).
  - Cooldown: $0.9\text{ s}$ (antes da Frenesi).
  - Dano: $100\%\text{ ATK}$.
- **Q — Arremesso de Machado:**
  - Projétil (velocidade $22\text{ u/s}$, alcance $7.0\text{ u}$, raio colisão $0.4\text{ u}$) que para no primeiro herói ou monstro: dano e **lentidão $30\%$ por $1.5\text{ s}$**. Bloqueado pela Muralha. Um dos machados some da mão por $1.0\text{ s}$ (visual).
  - Cooldown Base: $[9.0, 8.5, 8.0, 7.5, 7.0]\text{ s}$.
  - Dano: $[60, 90, 120, 150, 180] + (0.6 \times \text{ATK})$.
- **E — Grito de Guerra:**
  - Por $2.0\text{ s}$: $+[30, 40, 50, 60, 70]$ de **Defesa** e $+15\%$ de velocidade de movimento. Sem dano, sem alvo.
  - Cooldown Base: $[14.0, 13.0, 12.0, 11.0, 10.0]\text{ s}$.
- **R — Ragnarök (Ultimate, Nv 6+):**
  - Por $4.0\text{ s}$: **imune a controle de grupo** (lentidão, raiz, atordoamento, empurrão e puxão não se aplicam; os já ativos são limpos no uso), $+25\%$ de velocidade de movimento e **Frenesi no máximo** ($f = 1$). Sem dano.
  - Cooldown Base: $[70.0, 58.0]\text{ s}$.

---

### 4.9 Paladino Radiante (Tanque — Melee reativo) — ADR-0016, SPEC-076
- **Papel:** tanque que **responde** a quem chega nele: atordoa o primeiro que entra na frente, devolve dano de golpes de perto e fica imune a dano por um instante. O Cavaleiro (§4.1) inicia a luta; o Paladino a pune. Classe **Tanque** (PRD §4.1); redesenho do pedido "Suporte" para valer no 1x1 (ADR-0016 item 3). Retribuição e Bênção valem em aliados no raio quando houver 2x2 (no 1x1, só nele).
- **Modelo:** KayKit Adventurers 2.0 Extra `Knight` com `knight_texture_alt_B` (cinza/dourado), **sem elmo**; escudo do pack diferente do Cavaleiro; arma visível = **maça** (arte própria no Blender, 3 raridades — F48).
- **Velocidade Base:** $5.7\text{ u/s}$.
- *Números aprovados pelo PI em 2026-10-18 como proposta, conferidos no soak do F76. Q e E escalam ATK (regra do §2.1).*

#### Atributos Base e Crescimento
| Atributo | Nível 1 | Ganho / Nível | Nível 10 (Sem Itens) |
|---|---|---|---|
| **HP** | 620 | +46 | 1034 |
| **Defesa** | 28 | +2.8 | 53.2 |
| **Ataque** | 38 | +3.4 | 68.6 |
| **Inteligência** | 16 | +1.6 | 30.4 (CDR: 15.2%) |
| **Agilidade** | 8 | +0.8 | 15.2 |

#### Habilidades do Paladino Radiante
- **Ataque Básico (Maça):**
  - Tipo: Melee em arco cônico ($60^\circ$, raio $2.0\text{ u}$).
  - Cooldown: $1.2\text{ s}$.
  - Dano: $120\%\text{ ATK}$.
- **Q — Golpe Consagrado:**
  - Golpe de maça à frente: acerta o **primeiro** herói, servo ou monstro numa faixa de $2.5\text{ u}$ de comprimento por $1.0\text{ u}$ de largura e o **atordoa**. Boss: só o dano.
  - Cooldown Base: $[10.0, 9.5, 9.0, 8.5, 8.0]\text{ s}$.
  - Atordoamento: $[0.8, 0.9, 1.0, 1.1, 1.2]\text{ s}$.
  - Dano: $[50, 75, 100, 125, 150] + (0.7 \times \text{ATK})$.
- **E — Retribuição:**
  - Por $3.0\text{ s}$: cada golpe **direto** recebido de herói, servo ou monstro cuja origem esteja a até $3.0\text{ u}$ — **não** projétil, **não** zona/pulso — devolve ao atacante $[25, 30, 35, 40, 45]\%$ do dano que o Paladino recebeu (depois da Defesa dele) $+ (0.2 \times \text{ATK})$, mitigado pela Defesa do atacante (fórmula A). Dano devolvido não é devolvido de novo (sem laço). Sem alvo; aura visível.
  - Cooldown Base: $[13.0, 12.5, 12.0, 11.5, 11.0]\text{ s}$.
- **R — Bênção Inviolável (Ultimate, Nv 6+):**
  - No uso: cura $[120, 200] + (1.2 \times \text{INT})$ (não passa do HP máximo) e **imunidade a todo dano** por $[1.5, 2.0]\text{ s}$ — **inclusive a zona da fase 2** (ADR-0016 item 5). Controles (atordoamento, lentidão, empurrão, puxão) **continuam** valendo. Reaproveita o estado de invulnerabilidade do Rolamento (§4.2). Vale também para aliados a até $5.0\text{ u}$ (no 1x1, só nele).
  - Cooldown Base: $[60.0, 50.0]\text{ s}$.

---

### 4.10 Ocultista (Mago — Ranged, dano contínuo) — ADR-0016, SPEC-077 / SPEC-078
- **Papel:** mago de dano ao longo do tempo: amaldiçoa (tira Defesa), corrói com a Praga, prende o alvo no Círculo Profano e invoca servos que perseguem. Classe **Mago** (PRD §4.1), 2º da classe; o Bruxo de Fogo (§4.4) é o mago de explosão.
- **Modelo:** KayKit Adventurers 2.0 Extra `Mage` com **atlas próprio escuro (preto/roxo)** e **capuz** modelado no Blender no lugar do chapéu (exceção à ADR-0006 só para ele — ADR-0016 item 8); `spellbook_open` na mão esquerda; arma visível = `staff` do pack (3 raridades — F48).
- **Velocidade Base:** $6.0\text{ u/s}$.
- *Números aprovados pelo PI em 2026-10-18 como proposta, conferidos no soak do F77 e do F78. Q e E escalam ATK (regra do §2.1).*

#### Atributos Base e Crescimento
| Atributo | Nível 1 | Ganho / Nível | Nível 10 (Sem Itens) |
|---|---|---|---|
| **HP** | 370 | +27 | 613 |
| **Defesa** | 9 | +1.0 | 18 |
| **Ataque** | 42 | +3.8 | 76.2 |
| **Inteligência** | 32 | +3.2 | 60.8 (CDR: 30% — teto) |
| **Agilidade** | 14 | +1.2 | 24.8 |

#### Habilidades do Ocultista
- **Ataque Básico (Projétil Sombrio):**
  - Tipo: Projétil direto (velocidade $15\text{ u/s}$, alcance $7.5\text{ u}$, raio colisão $0.4\text{ u}$). Bloqueado pela Muralha, como a flecha.
  - Cooldown Base: $1.1\text{ s}$.
  - Dano: $90\%\text{ ATK}$ + **1 marca de Maldição** (§2.2-F).
- **Q — Praga:**
  - Projétil (velocidade $17\text{ u/s}$, alcance $8.0\text{ u}$, raio colisão $0.4\text{ u}$) que para no primeiro herói ou monstro: **dano contínuo por $4.0\text{ s}$** ($8$ pulsos a cada $0.5\text{ s}$). Reaplicar renova a duração (não acumula). Bloqueado pela Muralha.
  - Cooldown Base: $[8.0, 7.5, 7.0, 6.5, 6.0]\text{ s}$.
  - Dano Total: $[80, 120, 160, 200, 240] + (1.0 \times \text{ATK})$, dividido pelos pulsos.
- **E — Círculo Profano:**
  - Zona circular de raio $2.5\text{ u}$ no ponto mirado, até $7.0\text{ u}$, por $3.0\text{ s}$. Inimigos dentro (heróis, servos inimigos e monstros): **lentidão $35\%$** e dano por pulso a cada $0.5\text{ s}$ ($6$ pulsos). A marcação é visível como a do Meteoro.
  - Cooldown Base: $[13.0, 12.5, 12.0, 11.5, 11.0]\text{ s}$.
  - Dano Total: $[60, 90, 120, 150, 180] + (0.6 \times \text{ATK})$, dividido pelos pulsos.
- **R — Servos do Vazio (Ultimate, Nv 6+) — F78:**
  - Invoca **2 servos** ao lado do Ocultista por $7.0\text{ s}$. Uma invocação por vez (a nova substitui a anterior).
  - **Servo:** HP $[180, 280] + (2.0 \times \text{INT})$, Defesa $10$, velocidade $5.5\text{ u/s}$, colisão de monstro pequeno; ataque corpo a corpo de alcance $1.2\text{ u}$ a cada $1.0\text{ s}$, dano $[22, 34] + (0.25 \times \text{INT})$.
  - **Alvo:** o alvo travado do Ocultista, se houver e estiver a até $9.0\text{ u}$; senão o herói inimigo mais próximo a até $9.0\text{ u}$; senão o monstro mais próximo (boss incluído) a até $9.0\text{ u}$ — sempre **visível ao Ocultista** (§7.3). Sem alvo: seguem o Ocultista.
  - Podem ser alvo de ataques, skills e do alvo travado; morrem ao zerar o HP ou no fim da duração. **Matar um servo não dá nada** (sem XP, sem drop, não conta kill). **Dano e kill do servo contam para o Ocultista** (como a Torreta, §4.6). O ataque do servo não revela o Ocultista.
  - Cooldown Base: $[55.0, 46.0]\text{ s}$.

---

## 5. Bestiário e Economia de Campo (Fase 1)

**Respawn na fase 1 (decisão do PI em 2026-10-10, F36):** todo monstro não-boss renasce no próprio ponto de spawn **90 s** depois de morrer, enquanto durar a fase 1. Na fase 2 ninguém renasce; os vivos aos 5:00 ficam (o Rei Esqueleto vivo aos 5:00 sai sem drop — §7.1). A quantidade continua limitada para que o centro seja a melhor fonte de XP.

### 5.1 Distribuição e Tabela de Monstros
| Monstro | Tier | Qtd por Partida | Onde Fica | HP | Dano/Golpe | Intervalo Atq | XP Concedido | Drop Típico |
|---|---|---|---|---|---|---|---|---|
| **Esqueleto** | 1 | 16 (4 em cada base + 2 em cada um dos 4 campos laterais) | Base Segura / Lateral | 160 | 14 | 1.2 s | 35 | Ouro / Chance 20% Item Comum |
| **Esqueleto Guerreiro** | 2 | 8 (1 em cada base, 2 no centro, 1 em cada campo lateral) | Base / Centro / Lateral | 360 | 28 | 1.1 s | 85 | Item Comum Garantido |
| **Esqueleto Mago** | 2 | 2 (ambos no centro) | Centro Contestado | 260 | 38 (Ranged 7u) | 1.5 s | 80 | Item Comum ou Raro |
| **Golem de Pedra** | 3 | 2 (ambos no centro) | Centro Contestado | 680 | 50 (Melee AoE) | 1.6 s | 190 | Item Raro Garantido |
| **Lobo** | 2 | 4 (2 em cada campo de canto) | Canto NO / SE | 300 | 22 | 0.9 s | 70 | Chance 20% Item Comum |
| **Golem de Pedra (canto)** | 3 | 2 (1 em cada campo de canto) | Canto NO / SE | 680 | 50 (Melee AoE) | 1.6 s | 190 | Sem item (o loot do canto vem do Baú Reforçado) |
| **Rei Esqueleto (Boss)** | Boss | 1 (surge em 3:30) | Centro Absoluto | 2400 | 75 (AoE + Knockback)| 1.4 s | 550 | 1 Item Épico Garantido |

#### Comportamento dos monstros não-boss (decisão do PI em 2026-10-09, F9)
| Parâmetro | Valor | Efeito |
|---|---|---|
| **Aggro** | $6.0\text{ u}$ | Monstro parado percebe o herói mais próximo nessa distância e passa a persegui-lo. |
| **Leash** | $10.0\text{ u}$ do ponto de spawn | Passou disso, desiste, volta ao spawn e regenera o HP cheio. |
| **Velocidade** | $4.0\text{ u/s}$ | Abaixo dos heróis (5,8 e 6,2): dá para fugir. |
| **Alcance corpo a corpo** | $1.8\text{ u}$ | Esqueleto, Esqueleto Guerreiro e Golem golpeiam o alvo nesse alcance. |
| **Área do Golem** | raio $2.5\text{ u}$ | O golpe acerta todos os heróis em volta do Golem. |
| **Esqueleto Mago** | $7.0\text{ u}$, acerto instantâneo | Sem projétil: não é bloqueado pela Muralha do Cavaleiro. |
| **Campos de canto** (ADR-0011) | aggro $6.0\text{ u}$ (Golem e Lobo — decisão do PI em 2026-10-12 no aceite do F55; antes 4/3 u); leash $10.0\text{ u}$ | Quem passa no meio do corredor TOP/BOT (~7,2 u) não puxa. |
| **Provocação e campo** (decisão do PI em 2026-10-12, F55) | dano de herói → persegue quem feriu, mesmo fora do aggro; monstros com spawn a até $6.0\text{ u}$ (`CAMP_RADIUS`) acordam juntos | Campo inteiro reage a um ataque; voltando ao spawn ignora; boss fora da regra. |
| **Lobo** | velocidade $5.0\text{ u/s}$, corpo a corpo $1.8\text{ u}$ | Mais rápido que os outros monstros, ainda abaixo dos heróis (5,8–6,2): dá para fugir. |

Valores em `shared/data/monsters/*.tres` (`aggro_range`, `leash_range`, `move_speed`, `melee_range`, `area_radius`). O Rei Esqueleto (Boss) fica para o F11.

### 5.2 Alocação Teórica Máxima de XP na Fase 1
- Farm Completo de uma Base: $(4 \times 35) + (1 \times 85) = 225\text{ XP} \rightarrow$ Nível 3 garantido no primeiro 1:30 min.
- Disputa Total do Centro (sem Boss): $(2 \times 85) + (2 \times 80) + (2 \times 190) = 710\text{ XP}$.
- Rei Esqueleto: $550\text{ XP}$.
- **Conclusão (texto original, inválido):** "Farmar apenas a base leva ao nível ~5". Revisão de 2026-10-10: sem respawn, o mapa inteiro somava 1.710 XP (nível 6) e a base sozinha 225 XP (nível 3) — a meta 8–9 era inalcançável.

#### Revisão de 2026-10-10 (F36): campos laterais + respawn de 90 s
- **Campos laterais:** 4 campos (NO e SE, um de cada lado do rio — 2 por metade), cada um com 2 Esqueletos T1 + 1 Esqueleto Guerreiro T2 = $155\text{ XP}$; os 2 da própria metade somam $310\text{ XP}$.
- **Uma limpeza da própria metade** (base + 2 laterais): $535\text{ XP}$ → nível 4.
- **Estimativa com respawn de 90 s** (≈ 3 limpezas até 5:00): ≈ 1.600 XP → nível ~6 farmando só a própria metade; disputando centro + boss → nível 8–9.
- **Meta (mantida):** só a própria metade → nível ~5–6; centro + boss → 8–9. As estimativas acima dependem do tempo real de limpeza e são conferidas no soak (F19) e no playtest (F29/F30).

#### Revisão de 2026-10-11 (ADR-0011, F55): campos de canto
- **Campos de canto:** 2 (NO e SE, no bolso da curva TOP/BOT, sobre a diagonal — alcançáveis pelos dois times sem ponte), cada um com 1 Golem de canto + 2 Lobos = $330\text{ XP}$ e 2 Baús Reforçados. Respawn de 90 s como os demais.
- **Pedido do PI:** campo pensado para herói de nível 4 a 7, para chegar ao Rei Esqueleto (3:30) com mais nível e itens. O boss não muda (decisão do PI em 2026-10-11).
- **Estimativa:** uma limpeza da própria metade (535 XP, nível 4) + 1 canto (330 XP) = 865 XP → nível 5; com 2 limpezas de canto até 3:30 → ~1.200 XP → nível 6. Conferido no F55 (nível do bot aos 3:30, antes e depois) e no soak (F19).
- **Risco aceito pelo PI:** mais XP/itens elevam a curva inteira — vigiar TTK da fase 2 e teto de snowball (§1.1).

---

## 6. Sistema de Itens, Equipamentos e Conjuntos

O inventário possui 4 slots equipáveis: **Arma, Elmo, Peitoral e Botas**.

### 6.1 Catálogo dos 21 Itens da Fatia Vertical

> Contagem corrigida em 2026-10-16 (pendência do F27): 3 armas + 2 conjuntos × 3 slots × 3 raridades = **21** itens em `shared/data/items/` (o "12" original contava só um conjunto).

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
- **Baús Comuns Laterais (2 por campo lateral, 8 no total — decisão do PI em 2026-10-10, F36):**
  - Mesmo drop do baú comum. Total do mapa: **24 baús** (12 de base + 8 laterais + 4 raros). Baús não reabrem.
- **Baús Reforçados (2 por campo de canto, 4 no total — decisão do PI em 2026-10-11, ADR-0011):**
  - Drop: 50% Item Raro, 50% Item Comum. Sem épico, sem ouro/consumível. Total do mapa: **28 baús** (12 de base + 8 laterais + 4 reforçados + 4 raros). Baús não reabrem.
- **Baús Raros (4 no centro contestado):**
  - Drop: 65% Item Raro, 25% Item Comum, 10% Item Épico.
- **Regra de Escolha (decisão do PI em 2026-10-13, ADR-0014 / F61; substitui a regra de substituição da SPEC-047):** nada é automático. `F` abre o baú e mostra **3 itens distintos** da raridade sorteada (o baú de cura aplica na abertura, sem menu; o baú do Rei Esqueleto mostra 3 épicos, arma inclusa). O jogador **escolhe 1 com o clique do mouse**, com a comparação contra o equipado à vista, e **pode escolher item pior**. O baú fica **reservado ao primeiro herói que o abriu** (`Esc` fecha sem pegar e `F` reabre o mesmo menu); levou 1, o baú fecha. Avaliado no servidor. Itens iguais para todas as classes; o item antigo some.

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
| **10:00** | 5:00 | Raio $0\text{ u}$ (Colapso total) | — (resolução imediata, §7.2 item 3) | Desativado (Fim forçado) |

A transição de 5 s (portões caem, aviso) **já conta como fase 2**: o relógio da fase 2 começa às 5:00 (decisão do PI em 2026-10-10). Monstros comuns vivos continuam na fase 2, sem respawn; o Rei Esqueleto vivo aos 5:00 sai do mapa sem drop (decisão do PI em 2026-10-10).

### 7.2 Regras de Vitória (Ordem de Avaliação pelo Servidor)
1. **Meta de Kills Atingida:**
   - 1v1: **5 kills**.
   - 2v2: **7 kills** (Roadmap).
   - 3v3: **10 kills** (Roadmap).
2. **Eliminação por Sobrevivência (após 9:00):** O primeiro jogador a ficar sem vidas após o desligamento do respawn é derrotado.
3. **Morte Súbita Matemática (10:00):** O colapso final da zona impossibilita cura sustentada; aos 10:00 a partida termina **na hora** e o herói com maior vida percentual sobrevivente vence. Desempate, nesta ordem (decisão do PI em 2026-10-10): (a) mais kills na fase 2; (b) mais dano causado em heróis na partida; (c) sorteio determinístico com a seed da partida. Se nenhum jogador estiver conectado, a partida termina como `abandoned`. Jamais há empate.

### 7.3 Visão: Mato Alto (F32) e Neblina de Guerra (F37) — valem nas duas fases
- **Raio de visão do herói:** $12.0\text{ u}$ (decisão do PI em 2026-10-10). Fora dele, herói adversário e monstros não são replicados para aquele jogador; área nunca vista fica escura, área já vista fica cinza. O círculo da zona é sempre visível.
- **Revelação ao agir:** atacar ou usar skill de dentro da moita revela o herói ao adversário por $1.5\text{ s}$ (decisão do PI em 2026-10-10).
- **Proximidade:** sem revelação por proximidade — quem está fora da moita não vê quem está dentro, a qualquer distância; só vê quem está na mesma moita.
- **Servos do Ocultista (ADR-0016, F78):** são vistos e escondidos pelas mesmas regras dos monstros (raio de visão, neblina, moita); só atacam o que o Ocultista vê.
- **Fumaça da Ladina (ADR-0013, F58):** a nuvem da Bomba de Fumaça (§4.5) vale como moita por $3.0\text{ s}$, com as mesmas regras acima; lançar a fumaça não revela. A Torreta do Engenheiro (§4.6) só atira em quem o Engenheiro vê por estas regras.
- **Alvo travado (ADR-0015, F66):** o botão direito **clicado** sobre um herói inimigo ou monstro trava o alvo; o servidor só aceita alvo **visível para aquele peer** por estas regras e destrava no tick em que ele deixa de ser visível (moita, fumaça, neblina) ou morre. Com alvo travado e dentro do alcance do básico, o básico dispara sozinho na cadência normal; fora do alcance, nada. O auto-ataque de dentro da moita revela como qualquer ataque.

---

## 8. Estrutura de Arquivos de Dados no Godot (`data/`)

Para manter a separação estrita de dados exigida no PRD §4.3 e §8.6, todos os parâmetros acima são serializados como Resources (`.tres`) carregados dinamicamente pelo servidor:

```
game/data/
├── heroes/
│   ├── knight.tres          # Herói Cavaleiro (HP, Def, Atk, Skills Q/E/R)
│   ├── ranger.tres          # Herói Arqueiro (HP, Def, Atk, Skills Q/E/R)
│   ├── barbarian.tres       # Herói Bárbaro (ADR-0011, F53)
│   ├── fire_wizard.tres     # Herói Bruxo de Fogo (ADR-0011, F54)
│   ├── rogue.tres           # Heroína Ladina (ADR-0013, F58)
│   └── engineer.tres        # Herói Engenheiro (ADR-0013, F59)
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
│   ├── golem_corner.tres    # Golem de canto, sem item (F55)
│   ├── wolf_t2.tres         # Lobo (F55)
│   └── skeleton_king_boss.tres
└── rules/
    ├── match_pacing.tres    # Timers, raio da zona, curvas de dano
    └── xp_table.tres        # Vetor de XP por nível (1 a 10)
```