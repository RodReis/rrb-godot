---
proplan: v1
updated: 2026-10-10
---
<!-- gerado pelo ProPlan a partir das Issues — não edite à mão -->
# Status

## Backlog

### [MVP3] Meta + deploy (#76)

- [MVP3][SPEC-035][F35] Perfil de conta: nickname único obrigatório no 1º login e avatar local (#86)
- [MVP3][SPEC-033][F33] Tela Arena & Mapa: render estático da arena real, marcadores e regras das 2 fases pelos números do GDB (#85)
- [MVP3][SPEC-027][F27] Bestiário e Forja no launcher com simulador de builds sobre shared/core (#84)
- [MVP3][SPEC-026][F26] Histórico de partidas: GET /matches e tela com herói do oponente (#83)
- [MVP3][SPEC-025][F25] Login e cadastro, lobby com diorama, fila por polling, lançar o Game e treino vs bot (#81)
- [MVP3][SPEC-024][F24] Shell do launcher: App, pilha de telas, Theme completo, galeria, Configurações com aba Créditos e settings.cfg (#80)
- [MVP3][GATE] Homologação: dois amigos jogam pela internet sem intervenção do dev (#87)
- [MVP3][SPEC-028][F28] Deploy no VPS (Coolify, compose, UDP 7000–7020), export presets e pacote ZIP no GitHub Release (#82)
- [MVP3][SPEC-023][F23] Game server: --token, validação no backend, report do resultado, heartbeat e códigos de saída (#79)
- [MVP3][SPEC-022][F22] Fila 1x1 FIFO e orquestrador: pool Docker, token de partida, heartbeat e endpoints internos (#78)
- [MVP3][SPEC-021][F21] Backend NestJS: cadastro e login por e-mail/senha, JWT, usuários, migrações e OpenAPI (#77)

### [MVP2] Partida em rede (#57)

- [MVP2][GATE] Homologação: 1x1 online termina sempre; soak de 50 partidas verde (#69)
- [MVP2][SPEC-019][F19] Bot da fase 2 (Perseguir, Fugir da zona) e soak de 50 partidas bot × bot headless (#68)
- [MVP2][SPEC-037][F37] Neblina de guerra: visão de 12 u + explorado, filtro de replicação por peer e minimapa (#67)
- [MVP2][SPEC-032][F32] Mato alto: herói na moita não é replicado para o adversário e revela 1,5 s ao atacar (#66)
- [MVP2][SPEC-018][F18] Tela de fim de partida com estatísticas acumuladas no servidor (#65)

### Sem épico

- Câmera: pilares e muros tapam o herói (oclusão) (#70)
- Câmera: girar em volta do herói com o botão direito segurado (#47)

## A Fazer

### [MVP2] Partida em rede (#57)

- [MVP2][SPEC-017][F17] Transição de 5 s, HUD da fase 2 e vinheta da zona (#64)
- [MVP2][SPEC-016][F16] Fase 2: zona, dano da zona, respawn, kills, morte súbita, colapso e regras de vitória (#63)
- [MVP2][SPEC-014][F14] Arqueira: modelo KayKit, flecha validada no servidor, Q Flecha Perfurante, E Rolamento e R Chuva de Flechas (#62)
- [MVP2][SPEC-020][F20] Monstros, baús e boss replicados para 2 clientes reais sob latência e perda (#60)

## Em Andamento

_(vazio)_

## Feito

_(vazio)_

## Finalizado

### [MVP2] Partida em rede (#57)

- [MVP2][SPEC-036][F36] Economia de campo: 4 campos laterais de monstros e baús e respawn de 90 s na fase 1 (#59, finalizado em: 2026-10-10)
- [MVP2][SPEC-015][F15] Ciclo de partida: MatchController (FSM), seleção de heróis, PvP na fase 1, respawn e eventos por RPC (#58, finalizado em: 2026-10-10)
- [MVP2][SPEC-012][FIX] Bot contesta o Rei Esqueleto em loop e morre sem parar (#74, finalizado em: 2026-10-10)

### #16 (#16)

- [MVP1][SPEC-011][FIX] test_boss: empurrão do boss intermitente (física sem frame após montar a arena) (#71, finalizado em: 2026-10-10)
- [MVP1][GATE] Homologação: fase 1 completa contra bot, offline (#27, finalizado em: 2026-10-10)
- [MVP1][SPEC-013][F13] HUD da fase 1, aviso do boss aos 3:00, bestiário por B e componentes base do design system (#26, finalizado em: 2026-10-10)
- [MVP1][SPEC-011][F11] Rei Esqueleto aos 3:30, drop épico e relógio de partida (#24, finalizado em: 2026-10-10)
- [MVP1][SPEC-012][F12] Bot da fase 1 (BotInput) e modo offline com servidor embutido (#25, finalizado em: 2026-10-10)
- [MVP1][SPEC-010][F10] Baús, itens, inventário de 4 slots, substituição e bônus de conjunto (#23, finalizado em: 2026-10-09)
- [MVP1][SPEC-009][F9] Monstros tier 1–3 com IA, XP, níveis, pontos de skill e catch-up (#22, finalizado em: 2026-10-09)
- [MVP1][FIX] Herói é puxado de volta (rollback) ao passar pelo portão/muro da base (#41, finalizado em: 2026-10-09)
- [MVP1][SPEC-005][FIX] Servidor Docker sobe sem shared/ e o herói não compila (#42, finalizado em: 2026-10-09)
- [MVP1][SPEC-034][F34] Arena: pilares da cratera e mato alto com assets do Blender (#38, finalizado em: 2026-10-09)
- [MVP1][SPEC-008][F8] Cavaleiro: modelo KayKit, ataque básico, Q Investida, E Muralha e R Terremoto lendo shared/data (#21, finalizado em: 2026-10-09)
- [INFRA] CI: lint-gd, path filter por módulo e shared/test no test-game (#17, finalizado em: 2026-10-09)
- [MVP1][SPEC-006][F6] shared/ por junction, classes Resource, .tres do GDB e fórmulas compartilhadas (#18, finalizado em: 2026-10-09)
- [MVP1][SPEC-007][F7] Arena "Vale Rúnico": layout da SPEC-007, rio com pontes, cratera, portões, mato e marcadores (#19, finalizado em: 2026-10-09)
- [MVP1][SPEC-031][F31] Câmera 3ª pessoa, controles teclado/mouse/gamepad e cena de alinhamento KayKit (#20, finalizado em: 2026-10-09)

### #1 (#1)

- [MVP0][GATE] Gate Godot × Unity: jogável a 100 ms sem borracha (#7, finalizado em: 2026-10-09)
- [MVP0][SPEC-005][F5] Servidor headless em Docker com latência e perda simuladas (#6, finalizado em: 2026-10-09)
- [MVP0][SPEC-003][F3] Arena, conexão servidor/cliente e player com movimento por rollback (#4, finalizado em: 2026-10-09)
- [MVP0][SPEC-004][F4] Ataque corpo a corpo validado no servidor, HUD de rede e autopilot (#5, finalizado em: 2026-10-09)
- [MVP0][SPEC-002][F2] Regras puras LaunchArgs, CombatRules, AimMath e InputActions com TDD (#3, finalizado em: 2026-10-09)
- [MVP0][SPEC-001][FIX] Runner de testes devolve 0 quando um teste não compila (#9, finalizado em: 2026-10-09)
- [MVP0][SPEC-001][F1] Reestruturar em game/, instalar netfox e GUT e criar o runner de testes (#2, finalizado em: 2026-10-09)

### Sem épico

- [MVP1][FIX] Bot gira no lugar no centro depois que o boss morre e não há mais alvo (#52, finalizado em: 2026-10-10)
- [INFRA] Pipeline Blender: art/, .gitattributes/.gitignore e import de .blend desligado (ADR-0005) (#34, finalizado em: 2026-10-09)

## Descartado

_(vazio)_
