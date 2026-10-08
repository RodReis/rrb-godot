# Benchmark e Análise de Referências — MOBA de 2 Tempos

**Versão:** 1.0 — 2026-10-08  
**Documentos Relacionados:** PRD (`2026-10-08-prd-moba-2-tempos.md`), GDB (`gdb-game-design-balance-specification.md`)  
**Foco:** Mapeamento de jogos análogos, análise de dinâmicas (core loop, pacing, transição, netcode) e lições aplicadas à arquitetura do projeto.

---

## 1. Objetivo do Documento

Este documento analisa títulos comerciais com dinâmicas similares ao **MOBA de 2 Tempos** (hibridização de MOBA de arena, farming rápido de preparação e finalização via *ring/zone* battle royale). O intuito é:

1. Validar as decisões de design já tomadas no PRD e GDB.
2. Identificar armadilhas clássicas desse subgênero (snowball incontrolável, tempo morto de farm, anti-clímax na transição).
3. Extrair referências de implementação adequadas ao escopo de dev solo e arquitetura autoritativa em Godot 4.7.

---

## 2. Matriz Comparativa de Jogos de Referência

| Jogo | Loop Principal | Divisão de Fases | Escopo & Duração | Câmera & Controle | Ponto Forte / Armadilha Evitada |
|---|---|---|---|---|---|
| **Brawl Stars** | Arena 3v3 / Showdown rápido | Fase única contínua com gás/zona gradual | 2–3 min, mobile/casual | Top-down / Twin-stick | **Forte:** Clareza de leitura e rapidez de combate. **Evitar:** Falta de personalização ou senso de build. |
| **Eternal Return** | Farm / Crafting $\rightarrow$ Confronto em zonas restritas | 3 fases: Dia 1–2 (farm/respawn), Meio (créditos), Fim (morte súbita) | 15–20 min, PC | Isométrica (RTS/MOBA clássico) | **Forte:** O ciclo "farm seguro $\rightarrow$ disputa de objetivos $\rightarrow$ anel final". **Armadilha:** Complexidade excessiva de receitas de craft que afasta casuais. |
| **SUPERVIVE** (Theorycraft) | MOBA Battle Royale sandbox | Drop $\rightarrow$ Jungle/Camps $\rightarrow$ Encolhimento do círculo | 15–20 min, PC | Isométrica com WASD + Mira livre no mouse | **Forte:** Combate ágil e verticalidade com esquivas/glider. **Lição:** Respawn temporário antes do anel final previne eliminação frustrante precoce. |
| **Battlerite Royale** | Adaptação de arena brawler para mapa aberto | Drop $\rightarrow$ Loot de orbes/habilidades $\rightarrow$ Vortex fecha | 10–12 min, PC | Top-down WASD + Mira direta | **Forte:** Mecânica de duelo 1v1 visceral e skillshots. **Armadilha:** Não balancear skills para arena vs. mapa aberto; tempo de partida arrastado se o mapa for grande. |
| **Pokemon UNITE** | Farm de creeps $\rightarrow$ Pontuação em bases $\rightarrow$ Boss final (Zapdos/Rayquaza) | 10 min fixos (Transição crítica nos últimos 2 min) | 10 min estritos, Switch/Mobile | Top-down com auto-aim e direcionais | **Forte:** O relógio estrito de 10 min com grande objetivo central de virada no fim. |

---

## 3. Análise Detalhada por Eixo de Mecânica

### 3.1 O Pacing de 2 Tempos: Preparação vs. Confronto

#### O que o mercado ensina:
* **Eternal Return:** O jogador passa os primeiros minutos focado na sua rota de itens. Se outro jogador o invade muito cedo, a corrida de itens é arruinada. A introdução de respawn automático até o Dia 2 salvou o jogo da frustração inicial.
* **Supervive:** Mantém a "Ressurgência" ativa nos primeiros ciclos da tempestade, permitindo que novatos errem nos acampamentos da selva sem irem direto para o lobby.

#### Aplicação no nosso projeto:
* A divisão estrita com **portão trancado (Fase 1)** e **respawn na base sem penalidade de kill** é perfeita para evitar invasões destrutivas (*early cheese*).
* A janela de **5 minutos** é o limite máximo para não tornar o farm monótono. Com 6 baús e poucos monstros na base, o jogador é empurrado organicamente ao centro a partir de 2:30–3:00.

---

### 3.2 O "Boss Central" como Gatilho de Transição

#### Referências:
* **Rayquaza / Zapdos (Pokémon Unite):** Surge aos 2 minutos finais. Obriga ambos os lados a abandonarem farms isolados para se encontrar no mesmo ponto.
* **Alpha / Omega / Dr. Wickeline (Eternal Return):** Mini-bosses com horários fixos de anúncio global que sinalizam quem está no comando da partida.

#### Decisão de Design (PRD §3.2 / GDB §4.2):
* O **Rei Esqueleto (spawn em 3:30)** atua como catalisador. Se um jogador tenta ficar 100% passivo na base dele até os 5:00, o adversário garante o drop Épico e nível 8–9, entrando na Fase 2 com vantagem matemática substancial.
* **Aviso Global:** Deve haver um broadcast de UI/áudio em 3:00 anunciando o surgimento em 30 segundos, atraindo ambos os heróis para o raio de visão central.

---

### 3.3 Economia e Curva de Itens: Simplicidade vs. Profundidade

#### O erro comum:
Títulos como *Eternal Return* sofrem com barreira de entrada alta porque o jogador precisa memorizar rotas de coleta de múltiplos ingredientes (ex: ferro + galho + couro = armadura).

#### A solução ágil (Brawl Stars / Battlerite Royale):
* Drops diretos em **baús de tiers claros** (Comum, Raro, Épico).
* Apenas **4 slots de equipamentos** (Arma, Elmo, Peitoral, Botas) e **2 conjuntos passivos** (Guarda para defesa/vida; Caçador para velocidade/ataque).
* **Troca automática inteligente:** O servidor substitui o item se a raridade for estritamente superior; se houver conflito de atributos ou mesma raridade, exige interação voluntária do jogador (tecla `F`).

---

### 3.4 Condições de Encerramento (Endgame) e Antídoto ao "Stall"

#### O problema:
Em jogos 1v1 onde um jogador constrói vantagem defensiva, ele pode tentar fugir e enrolar (*kite infinito*).

#### Como as referências resolvem:
1. **Battlerite Royale / Supervive:** A zona não apenas fecha até um raio pequeno, mas contrai até zero.
2. **Dano Progressivo / Morte Súbita:** Ficar fora da zona não pode ser tankado com poções ou escudos por muito tempo.

#### Validação da regra do projeto:
* Fase 2 possui teto de **5:00 minutos**.
* Fechamento completo em 4:00 (aos 9:00 da partida total).
* Desligamento de respawn aos 4:00 da Fase 2.
* Aos 5:00 (10:00 totais), o dano ambiental dobra a cada 10 segundos. O sistema garante matematicamente o critério de sucesso do PRD: **100% das partidas terminam em $\le$ 10 minutos**.

---

## 4. Implicações Técnicas e Arquitetura no Godot 4.7

A partir das lições de netcode de jogos como *Battlerite* (onde skillshots precisavam de resposta instantânea sem autoridade do cliente):

| Funcionalidade | Benchmark de Mercado | Implementação no Godot 4.7 (`rrb-godot`) |
|---|---|---|
| **Controle & Câmera** | WASD + Mira no mouse (Battlerite / Supervive) | Câmera 3ª pessoa inclinada (~45°) com rotação de personagem travada no vetor de mira do mouse. |
| **Predição de Movimento** | Rollback client-side para evitar delay de input | Addon **netfox** operando em tickrate fixo de **30 Hz** com interpolação de snapshots para o oponente. |
| **Resolução de Hit / Dano** | Servidor autoritativo absoluto com compensação de atraso | `Hitbox` e projéteis validados no processo headless. O cliente prevê o disparo do projétil, mas a colisão e cálculo de dano residem no core do servidor. |
| **Distribuição de Loot** | Spawns pré-definidos para evitar dessincronização | Seeds de baús geradas e abertas pelo servidor; itens enviados via RPC confiável como IDs inteiros correspondentes aos `.tres`. |

---

## 5. Recomendações e Próximos Passos para a Fatia Vertical

1. **Testar Câmera no M1:** Testar a câmera de terceira pessoa contra a isométrica logo na implementação do Cavaleiro. Se a mira de projéteis (Arqueira) gerar perda de visão vertical, adotar a isométrica de *Battlerite* precocemente.
2. **Alertas da Fase 1:** Implementar pistas visuais claras no mapa (ex: holofotes hexagonais ou partículas no portal de saída da base) aos 3:00 minutos para alertar o surgimento do boss e preparar para a transição dos 5:00.
3. **Métrica Anti-Snowball:** Monitorar a taxa de vitória do jogador que garante o boss aos 3:30 durante os playtests do Marco M4 (deve permanecer abaixo do teto de 75% estabelecido no PRD).