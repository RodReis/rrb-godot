# F81 — soak por nível do bot

`tools/soak.ps1 -Heroes knight,ranger,barbarian,fire_wizard -BotLevels <a>,<b>` (partidas bot × bot headless; o lado A usa o nível `a`, o lado B o nível `b`). Os lados trocam de herói a cada rodada, nunca de nível. Colunas: vitórias do lado A / do lado B. CSV por rodada em `experimentos/`.

| Confronto (A × B) | Partidas | Vitórias A | Vitórias B | Observação |
|---|---|---|---|---|
| Médio × Médio (linha-base, `lv2v2`) | 20 | 13 | 7 | viés do lado A |
| Médio × Médio (`m40`) | 40 | 23 | 17 | linha-base final |
| Fácil × Médio (`lv1v2`) | 20 | 2 | 18 | abates 17 × 95; partidas ~495 s |
| Difícil (final, código revisado) × Médio (`hard-final`) | 40 | 27 | 13 | Nv 7,17 × 5,83 aos 5:00 (linha-base 5,9 × 5,4); 0 falhas |
| Difícil só com farm por habilidade (`hard-so-farm`, antes da revisão) | 40 | 27 | 13 | Nv 7,15 × 5,8 aos 5:00 |

**Resultado final:** Fácil < Médio < Difícil. O Fácil perde claramente (2/20). O Difícil final ganha 27 de 40 do Médio contra 23 de 40 da linha-base Médio × Médio, e chega aos 5:00 com nível 7,17 contra 5,83 (linha-base 5,9 × 5,4): a alavanca é **usar Q e E nos monstros do farm** (R reservado para herói e boss), mais **briga em nível igual** (`level_slack = 1`) e **mira antecipada** de 0,25 s nas habilidades. A diferença em vitórias está perto do ruído de 40 partidas; a de nível aos 5:00 é clara.

**Histórico da decisão (pop-up do PI, 2026-10-20):** com só limiar e mira o Difícil ficou em paridade com o Médio; o PI aceitou o critério "Fácil < Médio ≤ Difícil" para fechar, depois jogou no Difícil e achou o bot "fugindo" e farmando mal, o que levou ao farm por habilidade e à folga de nível.

## Variantes testadas para o Difícil (todas × Médio)

| Variante | Partidas | Vitórias A |
|---|---|---|
| recuo 40 %, briga 10 u (`lv3v2`) | 20 | 4 |
| recuo 40 %, briga 8 u | 20 | 4 (1 crash de largada, sem log) |
| recuo 30 %, briga 10 u | 20 | 9 |
| recuo 20 % | 20 | 7 |
| recuo 10 % | 20 | 10 |
| mira antecipada 0,25 s no alcance, caminho e habilidade (`h40`) | 40 | 16 |
| mira antecipada 0,25 s só na habilidade (`h25`, **adotada**) | 40 | 20 |
| mira antecipada 0,5 s só na habilidade (`h50`) | 40 | 20 |

Subir o limiar de recuo piora forte; alcance de briga maior e recuo menor não ajudam; antecipar também o caminho piora. Só limiar e mira não tiram o Difícil do empate com o Médio; o farm por habilidade tira.
