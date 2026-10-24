# F30 — Balanceamento dos 11 heróis (SPEC-030, #254)

Só números em `shared/data/heroes/*.tres` (Engenheiro não mudou). Medição por soak cruzado bot × bot, nível Médio nos dois lados, **seed 30**, só partidas fora do espelho. Taxa = vitórias ÷ partidas do herói; nenhuma partida terminou sem vencedor. Contagem por `winrate.ps1 <pasta>` (lê `report.csv`).

## Resultado

| Herói | Baseline (60 part.) | Rodada 4 (40 part.) — estado entregue |
|---|---|---|
| Berserker | 100 % | **67,5 %** |
| Carrasco | 70 % | **67,5 %** |
| Ladina | 23,3 % | 57,5 % |
| Bárbaro | 25 % | 55 % |
| Cavaleiro | 25 % | 52,5 % |
| Paladino | 40 % | 47,5 % |
| Ocultista | 15 % | 45 % |
| Bruxo de Fogo | 30 % | 42,5 % |
| Engenheiro | 56,7 % | 40 % |
| Protetor da Selva | 80 % | 40 % |
| Arqueiro | 85 % | **35 %** |

**Fora da faixa de 40–60 %: Berserker, Carrasco (acima) e Arqueiro (abaixo).** Nove de onze estão dentro. O soak final de 396 partidas **não foi rodado** (interrompido a pedido do PI); o aceite pelos números fica com ele. Margem estatística: ±15 pontos com ~45 partidas, ±22 com 20. As rodadas 1–3 usaram 20 partidas por herói e oscilaram bem mais que isso (ver `rodada3`).

Os desvios restantes não foram atribuídos à IA do bot: não houve investigação de causa, então não há `[FIX]` do bot aberto.

## Rodadas (todas: 0 falhas, todas por `kill_goal`, 343–518 s de jogo)

| Rodada | Comando | Pasta |
|---|---|---|
| Baseline | `soak.ps1 -Count 396 -Parallel 8 -Seed 30` | `baseline/` |
| 1 | `-Count 132` | `rodada1/` |
| 2 | `-Count 132` | `rodada2/` |
| 3 | `-Count 132` | `rodada3/` |
| 4 | `-Count 264` | `rodada4/` |

Uma rodada 5 (396 partidas) com ajuste fino de Carrasco, Berserker e Arqueiro foi iniciada e interrompida; os ajustes dela **não** estão na PR.

## Números alterados (antes → depois)

| Herói | Alterações |
|---|---|
| Berserker | HP 560→500 · HP/nv 44→38 · ATQ 58→42 · ATQ/nv 5,0→3,8 · básico (recarga) 0,9→1,0 s · Frenesi: vel. de ataque +60 %→+30 %, roubo de vida 25 %→10 % |
| Arqueiro | ATQ 55→46 · ATQ/nv 5,0→4,4 · básico (recarga) 0,8→0,95 s |
| Protetor da Selva | HP 470→440 · ATQ 44→40 · INT 24→20 · INT/nv 2,4→2,0 · Q: raiz 1,5→1,0 s |
| Carrasco | HP 600→560 · HP/nv 45→40 · DEF 26→24 · ATQ 42→38 |
| Cavaleiro | HP 600→620 · ATQ 40→47 · ATQ/nv 3,5→4,0 |
| Bárbaro | HP 480→540 · HP/nv 35→40 · ATQ 52→56 |
| Paladino | ATQ 38→43 · ATQ/nv 3,4→3,6 |
| Ladina | HP 400→450 · HP/nv 30→34 · DEF 12→14 |
| Ocultista | HP 370→470 · HP/nv 27→32 · DEF 9→12 · ATQ 42→50 · INT 32→34 |
| Bruxo de Fogo | HP 360→450 · HP/nv 26→30 · DEF 8→11 |
| Engenheiro | sem alteração |

As descrições do Frenesi e do Q do Protetor da Selva foram atualizadas junto.

## Para o Cowork

O GDB §4 (ADR-0004) está desalinhado destes `.tres` até o aceite do PI. Os testes `shared/test/test_*_data.gd` ("bate com o GDB") foram atualizados para os números novos.
