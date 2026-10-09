# FORA-DE-ESCOPO.md — Itens adiados ou excluídos por MVP

Fonte única. Cada linha tem motivo, destino e **gatilho de retorno** (o que precisa acontecer para o item voltar). Item sem gatilho é excluído, não adiado. Mantido pelo Cowork; o Code aponta por `[FIX]` quando encontra algo implementado que está aqui.

## Regras

- Nada daqui entra em código antes do MVP4 concluído (PRD §1.3: "nada do roadmap entra antes do M4").
- Arte própria saiu desta lista em 2026-10-09 por decisão do PI (ADR-0005): entra em qualquer MVP quando a fatia precisar.
- Item do design visual ou do benchmark que não está no PRD **não é requisito** — fica aqui ou em `RASTREABILIDADE.md` §5 até o PI decidir.
- "Adiado" tem MVP ou fase de destino; "excluído" tem motivo.

## Adiados (roadmap)

| Item | Fonte | Motivo | Destino | Gatilho de retorno |
|---|---|---|---|---|
| Modos 2x2 e 3x3 | PRD §1.3 | classes e times são conteúdo, não risco | pós-MVP4 | decisão do PI no gate M4 ("ir para 3x3") |
| Heróis Algoz, Suporte, Controle (+ mais) | PRD §1.3, §4.1 | sem sentido no 1x1 | pós-MVP4 | 3x3 aprovado |
| Mais arenas | PRD §1.3 | uma arena valida o loop | fase B | playtest pedir variedade |
| Bestiário maior, tabela de loot completa | PRD §1.3 | 5 monstros/12 itens bastam | fase B | snowball e TTK calibrados |
| IA de time | PRD §1.3 | só com times | pós-MVP4 | 3x3 |
| Steam, ranked, amigos | PRD §1.3 | fatia usa e-mail/senha e fila FIFO | fase B | decisão comercial |
| Moedas, gemas, vales, sorteios, loja, passe, skins | PRD §1.3, §7 | monetização é fase B; risco regulatório R5 | fase B | revisão regulatória + decisão do PI |
| Mobile (câmera/controles revisados, Mobile renderer) | PRD §1.2, §8.2 | PC primeiro (D1) | fase B | PC validado |
| Arte comissionada | PRD §1.3, R6 | CC0 + arte própria no Blender bastam (ADR-0005) | fase B | produto comercial |
| Câmera isométrica + mira assistida (plano B) | PRD §3.6 | decidir com dados | MVP4 | playtest mostrar perda de visão/aversão |
| Armas específicas por herói | PRD §6 | dado genérico basta | fase B | — |
| N partidas por processo (custo R7) | PRD §9.3 | irrelevante na fase A | fase B | custo medido no M3 ultrapassar meta |
| Nível/XP de conta, "14V–6D" como progressão | DV tela 1; R-PEND-02 | decidido: perfil mostra só V–D | pós-MVP4 | decisão do PI após playtest |
| Avatar no backend / visível a outros jogadores | R-PEND-02 | exige armazenamento e moderação de imagem; público 10+ | fase B | decisão do PI + moderação definida |
| Recuperação de senha, verificação de e-mail | R-PEND-07 (decidido 2026-10-09: roadmap) | backend fino | pós-MVP4 | primeiro pedido real de reset de senha |
| Reconexão à partida | PRD §8.5 | fora da fatia | fase B | relato de desconexão frequente no playtest |
| Múltiplas regiões, autoscaling | PRD §8.5 | 1 VPS, Brasil | fase B | jogadores fora do Brasil |
| WebSocket para fila (em vez de polling 2 s) | `ARCHITECTURE-LAUNCHER.md` §3.3 | backend fino | quando medir | polling custar > 5% CPU do backend ou latência de match > 5 s |
| Exportar log de rede `.txt` (DV tela 8) | DV | ferramenta de dev, não de jogador | `tools/` se precisar | debug de netcode no M4 |
| Exportar histórico `.csv`, SQLite local (DV tela 9) | DV | backend é a fonte; dev exporta por script | `tools/export-matches.ps1` no MVP4 | relatório do playtest |
| Ajustar buffer de interpolação / limite de rollback pela UI (DV tela 8) | DV | parâmetro de engenharia, não do jogador | nunca na UI; `match_pacing.tres` | — |
| Torres rúnicas (2 por lado) | conceito Vale Rúnico | PRD não tem torre; portão já protege a base na fase 1 | pós-MVP4 | playtest M4 mostrar invasão de base trivial na fase 2 |
| Buff ao matar o boss ("Aura do Flagelo") | conceito Vale Rúnico | reforça snowball (métrica PRD §9.2 < 75 %) | pós-MVP4 | boss pouco disputado no playtest |
| Orbes de XP soltos no mapa | Astro Arena | muda a curva GDB §5.2 | pós-MVP4 | fase 1 "chata" (R2) no playtest |
| Relevo/depressão da cratera, lama −15 %, fog of war, tier lendário, ouro/economia in-match, câmera isométrica padrão | conceito Vale Rúnico | não estão no PRD; custo de navmesh/câmera/replicação | fase B ou nunca | decisão do PI |
| Merge queue no GitHub | `GITHUB.md` §5 | um autor, fila curta | — | mais de um autor concorrente |

## Excluídos (sem gatilho)

| Item | Fonte | Motivo |
|---|---|---|
| Chat de voz/texto, replays, espectador, clãs, eventos sazonais, cross-play, web export, anti-cheat dedicado, localização além de pt-BR | PRD §12 | explícito no PRD |
| Host migration | PRD §8.5 | inexistente — servidor dedicado |
| Launcher web (React/Tauri/Electron) | ADR-0002 | segundo stack sem validar risco do PRD |
| "Hash de auditoria" / "Audit token" na tela de fim (DV tela 7) | DV | sem requisito; `match_id` do backend cumpre o papel |
| Telemetria netfox no Launcher (DV tela 8) | DV | Launcher não tem netfox; vive em `net_debug.tscn` do Game |
| Protótipo 2D (starter) | PRD §8.6 | descartado na Tarefa 1 do M0 |
| Ferramentas de "audit tracker" no cliente (`m4_audit_tracker.gd`) | DV §3.1 | cliente não é fonte de métrica; backend `telemetry/` |

## Pendentes de classificação

Ver `RASTREABILIDADE.md` §5 (R-PEND-01…10). Quando o PI decidir, a linha migra para "mantido" (na matriz) ou para uma das tabelas acima.
