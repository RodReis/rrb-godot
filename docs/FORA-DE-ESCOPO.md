# FORA-DE-ESCOPO.md — Itens adiados ou excluídos por MVP

Fonte única. Cada linha tem motivo, destino e **gatilho de retorno** (o que precisa acontecer para o item voltar). Item sem gatilho é excluído, não adiado. Mantido pelo Cowork; o Code aponta por `[FIX]` quando encontra algo implementado que está aqui.

## Regras

- Nada daqui entra em código antes do MVP4 concluído (PRD §1.3: "nada do roadmap entra antes do M4").
- Bárbaro (Algoz), Bruxo de Fogo (Mago) e campos de canto saíram desta lista em 2026-10-11 por decisão do PI (ADR-0011): entram no MVP2.
- Ladina (Algoz) e Engenheiro (classe nova) entraram em 2026-10-13 por decisão do PI (ADR-0013): marco MVP2.6. A "Ladina" do protótipo da seleção volta com dado real (F58).
- Protetor da Selva (classe Controle, `Druid` do Extra) e Berserker (classe nova Lutador, `Barbarian_Large` do Extra, primeira passiva) entraram em 2026-10-16 por decisão do PI (ADR-0015): marco MVP2.7. Saem daqui as linhas "Heróis Controle", "Druida e `BARBARIAN_LARGE`" e "passivas" (Suporte continua).
- Paladino Radiante (Tanque reativo, redesenho do pedido "Suporte") e Ocultista (Mago, com Servos do Vazio) entraram em 2026-10-18 por decisão do PI (ADR-0016): marco MVP2.8. Suporte continua no roadmap.
- Arte própria saiu desta lista em 2026-10-09 por decisão do PI (ADR-0005): entra em qualquer MVP quando a fatia precisar.
- Item do design visual ou do benchmark que não está no PRD **não é requisito** — fica aqui ou em `RASTREABILIDADE.md` §5 até o PI decidir.
- "Adiado" tem MVP ou fase de destino; "excluído" tem motivo.

## Adiados (roadmap)

| Item | Fonte | Motivo | Destino | Gatilho de retorno |
|---|---|---|---|---|
| Modos 2x2 e 3x3 | PRD §1.3 | classes e times são conteúdo, não risco | pós-MVP4 | decisão do PI no gate M4 ("ir para 3x3") |
| Heróis Suporte (+ mais) | PRD §1.3, §4.1 | sem sentido no 1x1 (Algoz e Mago entraram pelo ADR-0011; Controle entrou pelo ADR-0015 como controlador com autocura; o pedido "Paladino suporte" entrou como Tanque reativo pelo ADR-0016) | pós-MVP4 | 2x2/3x3 aprovado — a Poção Verde do Protetor passa a curar aliado (ADR-0015) |
| Retribuição e Bênção Inviolável do Paladino em aliados | ADR-0016 item 3 | 1x1 sem aliado; as regras já valem "em aliados no raio" | pós-MVP4 | 2x2/3x3 aprovado |
| Servo do Vazio dar XP ou drop ao ser morto | pop-up do PI 2026-10-18 | mexe na economia da fase 1 (GDB §5.2); PI escolheu "nada" | excluído | — |
| Ajuste do Rei Esqueleto (knockback 2,5 u > alcance 2,2 u do Cavaleiro; HP 2.400 às 3:30) | ADR-0011 (análise apresentada ao PI) | PI escolheu só campos e baús novos | F30 (MVP4) | medição do F55 (nível do bot aos 3:30) ou soak do F19 mostrar boss ainda inviável, ou pedido do PI |
| Queimadura (dano contínuo) no Bruxo de Fogo | ADR-0011 | mecânica nova no rollback; PI aprovou o kit sem | pós-MVP4 | pedido do PI |
| Necromante e Golem do KayKit Skeletons Extra (pago) | ADR-0011 | PI escolheu não usar agora (golem atual + lobo no Blender) | pós-MVP4 | compra do pack Extra pelo PI |
| Torreta do Engenheiro com HP (destrutível) ou com visão própria | ADR-0013 | mecânica nova (alvo que não é herói nem monstro, kill credit, bot que ataca estrutura); PI escolheu indestrutível, 6 s | pós-MVP4 | playtest M4 mostrar Torreta forte demais ou sem resposta |
| Textura alternativa do Extra na Ladina; `Rogue` sem capuz; besta de 2 mãos | ADR-0013 | PI escolheu `Rogue_Hooded` com a cor original | pós-MVP4 | pedido do PI (skins) |
| Escala visual dos personagens (1,1–1,2×, colisão igual) | ADR-0015 | PI escolheu aproximar a câmera (F67, padrão 11 u) | MVP2.7 ou MVP4 | PI achar 11 u insuficiente no aceite do F67 |
| Silhueta no mato alto para aliado | ADR-0015 | 1x1 não tem aliado; F72 cobre só o próprio herói | pós-MVP4 | 2x2 aprovado |
| Cinemática de abertura pulável (`Esc`) | ADR-0015 | PI escolheu 5 s mínimo, corta aos 8 s, sem pular | MVP4 | playtest reclamar da espera |
| Alvo travado que persegue (anda até entrar em alcance) | ADR-0015 | mistura com WASD; mais código no bot e no cliente; PI escolheu "só ataca em alcance" | MVP4 | playtest pedir |
| Epíteto e lore dos heróis na Tela Heróis (ex.: "dos Ventos") | ADR-0015, protótipo `Tela Herois/` | texto não existe em nenhum documento; regra do F27 (só `shared/data`) | — | PI escrever os textos (vão para `HeroData`) |
| Realismo fora da ADR-0006 (retexturizar heróis KayKit; o toon/outline já fora abandonado no F39, ADR-0018) | ADR-0015 | semanas de arte e reaceite de tudo; PI manteve a direção | — | nova ADR do PI |
| Ajuste dos números dos heróis 7–10 (soak fora do espelho: Protetor 13/43, Berserker 44/44, Paladino 33/45, Ocultista 8/45) | ADR-0015 item 15, ADR-0016 item 11; comentários de encerramento de #202, #203, #214, #215 | números aprovados pelo PI como proposta; PI mandou registrar e seguir | F30 (MVP4) | playtest M4 ou pedido do PI |
| Rig `Rig_Large` em outros heróis / variante "Large" de outros corpos | ADR-0015 | só o Berserker usa | pós-MVP4 | pedido do PI |
| Garra do Engenheiro puxando monstro/boss; veneno ou sangramento na Ladina | ADR-0013 | monstro tem leash e IA própria; dano contínuo é mecânica nova no rollback | pós-MVP4 | pedido do PI |
| Pontes nas pontas do rio e pontes de selva (5 travessias) | ADR-0009 | PI escolheu 3 rotas (TOP/MID/BOT) | MVP2 ou MVP4 | F19/[GATE] mostrar funil na MID |
| Três portões por base (um por rota) | ADR-0009 / SPEC-046 §7 | 1 portão por base basta; regra e testes do F8 intactos | — | pedido do PI após playtest |
| Cascatas do rio de mana (F40) | SPEC-046 §5 | rio em S não toca mais a borda | — | rio voltar a tocar a borda |
| Mais arenas | PRD §1.3 | uma arena valida o loop | fase B | playtest pedir variedade |
| Vale Rúnico (SPEC-007) como arena 1x1 alternativa | ADR-0008 | uma arena oficial na fatia; o PI quer preservá-lo sem gastar recurso agora. Congelado em `game/scenes/arena/legacy/` + tag `arena-vale-runico` | fase B (junto com "Mais arenas") | "Mais arenas" aprovado ou seleção de mapa entrar no escopo |
| Bestiário maior, tabela de loot completa | PRD §1.3 | 5 monstros/12 itens bastam | fase B | snowball e TTK calibrados |
| IA de time | PRD §1.3 | só com times | pós-MVP4 | 3x3 |
| Steam, ranked, amigos | PRD §1.3 | fatia usa e-mail/senha e fila FIFO | fase B | decisão comercial |
| Moedas, gemas, vales, sorteios, loja, passe, skins | PRD §1.3, §7 | monetização é fase B; risco regulatório R5 | fase B | revisão regulatória + decisão do PI |
| Mobile (câmera/controles revisados, **perfil gráfico próprio** — Game é Forward+ only, ADR-0006) | PRD §1.2, §8.2 | PC primeiro (D1) | fase B | PC validado + decisão de porte |
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
| Relevo/depressão da cratera, lama −15 %, tier lendário, ouro/economia in-match, câmera isométrica padrão | conceito Vale Rúnico | não estão no PRD; custo de navmesh/câmera/replicação | fase B ou nunca | decisão do PI |
| "Configurações (ESC)" no menu da engrenagem da HUD; switches de som gravados entre sessões | protótipo `docs/prd/telas/HUD Moderno/` (F57) | o jogo não tem tela de configurações; gravar no `settings.cfg` muda o contrato Launcher ↔ Game (exige ADR) | F24/F27 (MVP3, Configurações do launcher) | tela de configurações do launcher |
| Renomear o jogo, o Launcher e o README para "Loot Start" | ADR-0017 | o nome vale só no site; rename troca README, Launcher e roadmap | card futuro | decisão do PI |
| Domínio próprio do site (o `base` do Vite volta a `/`) | ADR-0017 item 5 | o jogo não tem domínio; o site está em `rodreis.github.io/rrb-godot/` | — | PI registrar o domínio |
| Merge queue no GitHub | `GITHUB.md` §5 | um autor, fila curta | — | mais de um autor concorrente |

## Excluídos (sem gatilho)

| Item | Fonte | Motivo |
|---|---|---|
| Chat de voz/texto, replays, espectador, clãs, eventos sazonais, cross-play, web export, anti-cheat dedicado, localização além de pt-BR | PRD §12 | explícito no PRD |
| SDFGI e SSIL dinâmico como GI principal | guia gráfico 2026-10-10 | arena estática: `LightmapGI` bakeado entrega o mesmo sem custo contínuo; vazamento em paredes finas (ADR-0006) |
| Shaders procedurais sobre os hexes KayKit (`hex_water`/`hex_grass`) | guia gráfico 2026-10-10 | UV em atlas; substituído por malhas próprias (F40, ADR-0006) |
| Torres de vigia e balistas/canhões **com função** | doc de reforma da arena 2026-10-10 | decisão "sem torres" mantida; entram só como enfeite sem colisão, fora da área jogável (ADR-0007) |
| Relevo, degraus nas pontes, fosso na cratera | doc de reforma da arena 2026-10-10 | arena plana (V-16); magma é visual (ADR-0007) |
| Host migration | PRD §8.5 | inexistente — servidor dedicado |
| Clique para andar (estilo LoL/Dota) e olhar para a frente da câmera (strafe de shooter) | ADR-0015 | clique muda input, bot e pathfinding no cliente; strafe prende skills de área ao eixo da câmera |
| Escudo do Paladino bloqueando projétil; Maldição aplicada por Q/E; resistência mágica (o jogo só tem Defesa); controle manual dos servos; mais de uma invocação ativa | F76 #214, F77 #215, F78 #216; ADR-0016 itens 7 e 9; GDB §2.1 | projétil é da Muralha do Cavaleiro; só o básico aplica marca; Servos do Vazio têm IA e uma invocação por vez |
| Site público: login, backend, analytics, i18n | ADR-0017 item 1 | landing estática em pt-BR; 2x2 e 3x3 aparecem só como "em breve" |
| Launcher web (React/Tauri/Electron) | ADR-0002 | segundo stack sem validar risco do PRD |
| "Hash de auditoria" / "Audit token" na tela de fim (DV tela 7) | DV | sem requisito; `match_id` do backend cumpre o papel |
| Telemetria netfox no Launcher (DV tela 8) | DV | Launcher não tem netfox; vive em `net_debug.tscn` do Game |
| Protótipo 2D (starter) | PRD §8.6 | descartado na Tarefa 1 do M0 |
| Ferramentas de "audit tracker" no cliente (`m4_audit_tracker.gd`) | DV §3.1 | cliente não é fonte de métrica; backend `telemetry/` |
| Na tela de seleção (protótipo `docs/prd/telas/Seleção de Heróis/`): heróis Maga Violeta e Esqueleto (a Ladina voltou pelo ADR-0013, F58); dificuldade/nível do bot ("Platina I", "IA • Dificuldade Difícil"); servidor, ping, versão do Godot, nº da partida e nome do mapa; legenda do pack do modelo; "(BASE AZUL/VERMELHA)"; atalhos TAB "Ver Estatísticas" e ESC "Cancelar Busca"; rótulos de atributo que não existem no `HeroData` | F51 #132 (PI 2026-10-11) | sem regra no PRD/GDB: o jogo tinha 4 heróis (ADR-0011; 6 com o MVP2.6, ADR-0013), o bot não tem dificuldade, o time não tem cor e a seleção não tem estatística nem busca para cancelar; a tela mostra só dado real (`FRONTEND-LAUNCHER.md` §8.3) |
| Na tela de fim (protótipo `docs/prd/telas/Destaques da Tela de Fim de Partida/`): nota de desempenho ("S+ (MVP)", classificação "B"); XP de maestria do herói (barra, "+680 XP", "Nv. 11 em breve"); "Baú do conquistador rúnico"; conquista "Tático impecável"; "Drop Épico Conquistado" no Rei Esqueleto; "(BOT)" no nome do oponente; bônus do conjunto ("Set 3/3 • +15% HP"); "Servidor: SA-East-1 (18ms)"; "Log de combate & netfox"; "Tickrate"; "Seu Nexus foi destruído"; alternador vitória/derrota do topo e barra "Godot 4.7 build" (só preview) | F52 #133 (PI 2026-10-11) | sem regra no PRD/GDB: não há maestria, desempenho, conquista, baú de vitória nem nexus; o jogo não tem log de combate; servidor e tickrate não são dado de partida; a tela mostra só o `MatchStats` do F18 (`FRONTEND-LAUNCHER.md` §8.3) |

## Pendentes de classificação

Ver `RASTREABILIDADE.md` §5 (R-PEND-01…10). Quando o PI decidir, a linha migra para "mantido" (na matriz) ou para uma das tabelas acima.
