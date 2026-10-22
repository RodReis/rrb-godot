---
proplan: v1
updated: 2026-10-22
---
<!-- gerado pelo ProPlan a partir das Issues — não edite à mão -->
# Status

## Backlog

### [MVP4] Playtest (#246)

- [MVP4][GATE] Playtest com 10+ pessoas: critérios do PRD §9.2 e decisão de abrir o Early Access (#255)
- [MVP4][SPEC-086][F86] Publicação no itch.io: página do jogo e build a cada Release (#252)

### [MVP5] Early Access (#250)

- [MVP5][GATE] Abertura do Early Access no site e no itch.io (#262)
- [MVP5][SPEC-092][F92] Primeiras skins (variantes KayKit Extra) e skin do Pacote de Fundador (#261)
- [MVP5][SPEC-091][F91] Skin na partida: token devolve heróis liberados e skin; game server replica (#260)
- [MVP5][SPEC-090][F90] Loja: catálogo, pedido, Mercado Pago (Pix e cartão), inventário e tela Loja (#259)
- [MVP5][SPEC-089][F89] Bot na fila online: sem humano em 30 s, partida contra bot com aviso (#258)
- [MVP5][SPEC-088][F88] Recompensas de Patente e de login diário, semanal e mensal: emblemas e molduras (#257)
- [MVP5][SPEC-087][F87] Patente 1–10 grátis: 1 herói inicial + 1 por Patente com escolha livre (#256)

### [MVP3] Meta + deploy (#76)

- [MVP3][GATE] Homologação: dois amigos jogam pela internet sem intervenção do dev (#87)

## A Fazer

### [MVP4] Playtest (#246)

- [MVP4][SPEC-030][F30] Balanceamento pós-playtest dos 10 heróis (só .tres) (#254)
- [MVP4][SPEC-029][F29] Telemetria: ping, duração, líder F1 × vencedor e KPIs no histórico (#253)

## Em Andamento

_(vazio)_

## Feito

_(vazio)_

## Finalizado

### [MVP4] Playtest (#246)

- [MVP4][SPEC-085][F85] Tutorial guiado: obrigatório na 1ª vez, pulável, libera a fila online (#251, finalizado em: 2026-10-22)
- [MVP4][SPEC-098][F98] Carrasco, 11º herói (Tanque): modelo realista, Dor, Penitência e Correntes do Julgamento (#248, finalizado em: 2026-10-22)
- [MVP4][SPEC-097][F97] Escala da interface do jogo no Launcher e na partida (#272, finalizado em: 2026-10-21)
- [MVP4][SPEC-096][F96] Arena nova, parte 3: borda da ilha e vale (#268, finalizado em: 2026-10-21)
- [MVP4][SPEC-095][F95] Arena nova, parte 2: rio, pontes, centro, selva e mato alto (#267, finalizado em: 2026-10-21)
- [MVP4][SPEC-084][F84] Spike visual: canto SO estilo Eternal Return em cena jogável (#247, finalizado em: 2026-10-21)
- [MVP4][SPEC-094][F94] Arena nova, parte 1: bases A e B com o kit do F84 (#266, finalizado em: 2026-10-21)

### [MVP3] Meta + deploy (#76)

- [MVP3][SPEC-081][F81] Três níveis de bot no treino: Fácil, Médio e Difícil (#239, finalizado em: 2026-10-20)
- [MVP3][SPEC-082][F82] Nome "Loot Start" no jogo: janelas, marca do Launcher, splash e executável (#241, finalizado em: 2026-10-20)
- [MVP3][SPEC-083][F83] Instalador Windows e atualização automática (obrigatória para jogar online) (#242, finalizado em: 2026-10-20)
- [MVP3][SPEC-028][F28] Deploy no VPS (Coolify, compose, UDP 7000–7020), export presets e pacote ZIP no GitHub Release (#82, finalizado em: 2026-10-19)
- [MVP3][SPEC-028][INFRA] Site e download do jogo no VPS (lootstart.cloud) e Coolify lendo o repositório privado (#237, finalizado em: 2026-10-19)
- [MVP3][SPEC-025][FIX] Launcher mostra 229 ms de "servidor" (HTTP com conexão nova) em vez do ping real (#233, finalizado em: 2026-10-19)
- [MVP3][SPEC-079][F79] Tipo de tela nas Configurações: Modo Janela, Janela sem Borda e Tela Cheia Exclusiva (#226, finalizado em: 2026-10-19)
- [MVP3][SPEC-080][F80] Sair do jogo: menu no ESC (Continuar / Sair) e derrota por abandono (#230, finalizado em: 2026-10-19)
- [MVP3][SPEC-035][F35] Perfil de conta: nickname único obrigatório no 1º login e avatar local (#86, finalizado em: 2026-10-16)
- [MVP3][SPEC-033][F33] Tela Arena & Mapa: render estático da arena real, marcadores e regras das 2 fases pelos números do GDB (#85, finalizado em: 2026-10-15)
- [MVP3][SPEC-027][F27] Bestiário e Forja no launcher com simulador de builds sobre shared/core (#84, finalizado em: 2026-10-15)
- [MVP3][SPEC-026][F26] Histórico de partidas: GET /matches e tela com herói do oponente (#83, finalizado em: 2026-10-15)
- [MVP3][SPEC-025][F25] Login e cadastro, lobby com diorama, fila por polling, lançar o Game e treino vs bot (#81, finalizado em: 2026-10-15)
- [MVP3][SPEC-024][F24] Shell do launcher: App, pilha de telas, Theme completo, galeria, Configurações com aba Créditos e settings.cfg (#80, finalizado em: 2026-10-15)
- [MVP3][SPEC-022][F22] Fila 1x1 FIFO e orquestrador: pool Docker, token de partida, heartbeat e endpoints internos (#78, finalizado em: 2026-10-15)
- [MVP3][SPEC-023][F23] Game server: --token, validação no backend, report do resultado, heartbeat e códigos de saída (#79, finalizado em: 2026-10-15)
- [MVP3][SPEC-021][F21] Backend NestJS: cadastro e login por e-mail/senha, JWT, usuários, migrações e OpenAPI (#77, finalizado em: 2026-10-15)

### #16 (#16)

- [MVP1][SPEC-012][FIX] Bot do treino fica rodando na base (#238, finalizado em: 2026-10-20)
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

### #57 (#57)

- [MVP2][SPEC-051][FIX] Seleção de heróis em tela cheia: layout grande demais, informações cortadas (#228, finalizado em: 2026-10-19)
- [MVP2][SPEC-051][FIX] Seleção de heróis: o modelo 3D começa de costas (#229, finalizado em: 2026-10-19)
- [MVP2][SPEC-063][F63] Água do rio e do riacho com shader realista (#167, finalizado em: 2026-10-14)
- [MVP2][SPEC-064][F64] Fonte de cura: remodelada no Blender, textura realista e água caindo (#168, finalizado em: 2026-10-14)
- [MVP2][SPEC-062][F62] Tecla B: ficha do herói (itens, atributos, habilidades) com aba Monstros (#166, finalizado em: 2026-10-13)
- [MVP2][SPEC-061][F61] Baú com menu: F abre, 3 itens, clique escolhe, baú reservado a quem abriu (#165, finalizado em: 2026-10-13)
- [MVP2][SPEC-060][F60] Centro livre: remove os 8 pilares da cratera e mantém o magma (#164, finalizado em: 2026-10-13)
- [MVP2][SPEC-065][F65] Minimapa claro: imagem pronta do mapa no lugar da câmera ao vivo (#170, finalizado em: 2026-10-13)
- [MVP2][SPEC-056][F56] Arena num vale: floresta e montanhas em volta, câmera nunca mostra o vazio (#150, finalizado em: 2026-10-13)
- [MVP2][GATE] Homologação: 1x1 online termina sempre; soak de 50 partidas verde (#69, finalizado em: 2026-10-13)
- [MVP2][SPEC-037][FIX] Concealment com SCRIPT ERROR depois do fim da partida (herói fora da árvore) (#153, finalizado em: 2026-10-13)
- [MVP2][SPEC-019][F19] Bot da fase 2 (Perseguir, Fugir da zona) e soak de 50 partidas bot × bot headless (#68, finalizado em: 2026-10-13)
- [MVP2][FIX] Cliente loga ERROR a cada quadro depois que o servidor encerra a partida (#108, finalizado em: 2026-10-12)
- [MVP2][FIX] Cliente fica sem tela e loga erro a cada quadro depois que o servidor encerra (#102, finalizado em: 2026-10-12)
- [MVP2][SPEC-052][F52] Tela de vitória/derrota fiel ao protótipo novo, só com dados reais (#133, finalizado em: 2026-10-12)
- [MVP2][SPEC-055][F55] Campos de canto: golem + 2 lobos + 2 baús reforçados na curva TOP/BOT (#137, finalizado em: 2026-10-12)
- [MVP2][SPEC-051][F51] Tela de seleção de heróis fiel ao protótipo novo, só com dados reais (#132, finalizado em: 2026-10-12)
- [MVP2][SPEC-054][F54] Bruxo de Fogo (Mago): Bola de Fogo, Explosão de Chamas, Anel de Fogo, Meteoro, bot e VFX (#136, finalizado em: 2026-10-12)
- [MVP2][SPEC-053][F53] Bárbaro (Algoz): Machado, Salto Brutal, Rodopio, Execução, bot e VFX (#135, finalizado em: 2026-10-12)
- [MVP2][SPEC-050][F50] Pátio da base com construções do Medieval Village MegaKit (CC0) adaptadas ao castelo atual (#131, finalizado em: 2026-10-11)
- [MVP2][SPEC-046][FIX] Muralha do pátio da base esticada e com fresta junto à torre do portão (#130, finalizado em: 2026-10-11)
- [MVP2][SPEC-049][F49] Ciclo dia/noite sincronizado com o relógio da partida, sentido sorteado pela seed (#122, finalizado em: 2026-10-11)
- [MVP2][SPEC-048][F48] Equipamento visível: armas e armaduras modeladas no Blender no herói 3D e ícones dos itens (#121, finalizado em: 2026-10-11)
- [MVP2][SPEC-047][F47] Baú: F só para item melhor, regra por herói no servidor e card de comparação na HUD (#120, finalizado em: 2026-10-11)
- [MVP2][SPEC-046][FIX] Saída direita do portão da base fechada por rocha e bolsão de selva (#123, finalizado em: 2026-10-11)
- [MVP2][SPEC-046][F46] Arena "Rift Medieval adaptado": borda quadrada 80×80, rio em S NO–SE com lagoas, 3 rotas, selva nos quadrantes (#110, finalizado em: 2026-10-10)
- [MVP2][SPEC-044][F44] Arena "Ilha Flutuante Arcana": layout novo em greybox — espelho N–S, rio N–S + anel, 4 pontes (#92, finalizado em: 2026-10-10)
- [MVP2][SPEC-037][F37] Neblina de guerra: visão de 12 u + explorado, filtro de replicação por peer e minimapa (#67, finalizado em: 2026-10-10)
- [MVP2][SPEC-032][F32] Mato alto: herói na moita não é replicado para o adversário e revela 1,5 s ao atacar (#66, finalizado em: 2026-10-10)
- [MVP2][SPEC-018][F18] Tela de fim de partida com estatísticas acumuladas no servidor (#65, finalizado em: 2026-10-10)
- [MVP2][SPEC-017][F17] Transição de 5 s, HUD da fase 2 e vinheta da zona (#64, finalizado em: 2026-10-10)
- [MVP2][SPEC-016][F16] Fase 2: zona, dano da zona, respawn, kills, morte súbita, colapso e regras de vitória (#63, finalizado em: 2026-10-10)
- [MVP2][SPEC-014][F14] Arqueira: modelo KayKit, flecha validada no servidor, Q Flecha Perfurante, E Rolamento e R Chuva de Flechas (#62, finalizado em: 2026-10-10)
- [MVP2][SPEC-020][F20] Monstros, baús e boss replicados para 2 clientes reais sob latência e perda (#60, finalizado em: 2026-10-10)
- [MVP2][SPEC-036][F36] Economia de campo: 4 campos laterais de monstros e baús e respawn de 90 s na fase 1 (#59, finalizado em: 2026-10-10)
- [MVP2][SPEC-015][F15] Ciclo de partida: MatchController (FSM), seleção de heróis, PvP na fase 1, respawn e eventos por RPC (#58, finalizado em: 2026-10-10)
- [MVP2][SPEC-012][FIX] Bot contesta o Rei Esqueleto em loop e morre sem parar (#74, finalizado em: 2026-10-10)

### #213 (#213)

- [MVP2.8][SPEC-076][F76] Paladino Radiante (Tanque reativo): Maça, Golpe Consagrado, Retribuição, Bênção Inviolável; Knight do Extra alt_B sem elmo, maça própria, bot e VFX (#214, finalizado em: 2026-10-19)
- [MVP2.8][SPEC-078][F78] Servos do Vazio (R do Ocultista): 2 servos móveis com IA no servidor, perseguem heróis e monstros visíveis, sem recompensa ao morrer, kill para o dono (#216, finalizado em: 2026-10-19)
- [MVP2.8][SPEC-077][F77] Ocultista (Mago de dano contínuo): Projétil Sombrio com Maldição, Praga, Círculo Profano; Mage do Extra com atlas escuro e capuz próprios, bot e VFX (#215, finalizado em: 2026-10-18)

### #193 (#193)

- [MVP2.7][SPEC-075][F75] Berserker (classe nova Lutador): passiva Frenesi, Machados Gêmeos, Arremesso de Machado, Grito de Guerra, Ragnarök; Barbarian_Large do Extra, Rig_Large, bot e VFX (#203, finalizado em: 2026-10-18)
- [MVP2.7][SPEC-074][F74] Protetor da Selva (Controle): Seiva, Raízes Vivas, Poção Verde, Pântano; Druid do Extra, cajado visível, bot e VFX (#202, finalizado em: 2026-10-18)
- [MVP2.7][SPEC-073][F73] Acabamento do cenário dentro da ADR-0006: texturas PBR CC0, normal maps, grama ×2 com fade; GPU ≤ +1,5 ms (#201, finalizado em: 2026-10-18)
- [MVP2.7][SPEC-072][F72] Mato alto: silhueta translúcida do próprio herói e moita semitransparente ao redor (só cliente; SPEC-032 intacta) (#200, finalizado em: 2026-10-17)
- [MVP2.7][SPEC-071][F71] Tela Heróis no launcher fiel ao protótipo "Tela Herois", só com dados de shared/data (#199, finalizado em: 2026-10-17)
- [MVP2.7][SPEC-070][F70] Fim de partida → lobby: Game fecha em 15 s e o Launcher volta ao lobby com o card "Resultado da partida" (#198, finalizado em: 2026-10-17)
- [MVP2.7][SPEC-069][F69] Cinemática de abertura in-engine: estado INTRO (5–8 s), voo pela arena e close no próprio herói antes da fase 1 (#197, finalizado em: 2026-10-17)
- [MVP2.7][SPEC-068][F68] Splash próprio nos dois projetos e 3 telas de loading sorteadas (renders reais, dica, progresso) do boot do Game até a seleção (#196, finalizado em: 2026-10-16)
- [MVP2.7][SPEC-067][F67] Câmera com zoom: roda do mouse e teclas remapeáveis, 9–14 u, padrão 11 u, salvo em settings.cfg (#195, finalizado em: 2026-10-16)
- [MVP2.7][SPEC-066][F66] Controle v2: herói encara o movimento, alvo travado no botão direito com auto-ataque em alcance, moldura do alvo na HUD (#194, finalizado em: 2026-10-16)

### #160 (#160)

- [MVP2.6][SPEC-059][F59] Engenheiro: Bacamarte, Garra Mecânica, Torreta, Caixa de Dinamite, bot e VFX (#163, finalizado em: 2026-10-15)
- [MVP2.6][SPEC-058][F58] Ladina (Algoz): Virote, Rajada em Leque, Bomba de Fumaça, Emboscada, bot e VFX (#162, finalizado em: 2026-10-14)
- [MVP2.6][INFRA] Roadmap público aceita o marco MVP2.6 (#161, finalizado em: 2026-10-14)

### #99 (#99)

- [MVP2.5][SPEC-057][F57] HUD moderna: painéis de vidro, dock único, minimapa com baús e monstros, engrenagem com som (#151, finalizado em: 2026-10-13)
- [MVP2.5][SPEC-057][FIX] HUD: E e R travados sem aviso de que precisam de ponto; evento do Bestiário reusado (#154, finalizado em: 2026-10-13)
- [MVP2.5][SPEC-040][FIX] Portão da base não abre quando o herói do time passa (#124, finalizado em: 2026-10-11)
- [MVP2.5][SPEC-045][F45] Câmera: giro 360° com o botão esquerdo segurado; ataque básico no botão direito (#103, finalizado em: 2026-10-11)
- [MVP2.5][INFRA] Roadmap público e convenção de título passam a aceitar o marco MVP2.5 (#100, finalizado em: 2026-10-11)
- [MVP2.5][SPEC-043][F43] HUD v2: ghost bar, ícones de habilidade com badge, molduras temáticas, fontes novas e luz de estúdio na seleção (#98, finalizado em: 2026-10-11)
- [MVP2.5][SPEC-042][F42] Vegetação: grama MultiMesh com vento, distinta do mato alto (#97, finalizado em: 2026-10-11)
- [MVP2.5][SPEC-041][F41] Arquitetura de VFX (cliente, pool, is_fresh) e efeitos de combate do Cavaleiro e da Arqueira (#96, finalizado em: 2026-10-11)
- [MVP2.5][SPEC-040][F40] Arte da Ilha Flutuante Arcana sobre o layout da SPEC-044: kits Blender, shaders de rio, magma, cristal e céu (#95, finalizado em: 2026-10-11)
- [MVP2.5][SPEC-039][F39] Toon e outline por pós-import em heróis, monstros e cenário (#94, finalizado em: 2026-10-11)
- [MVP2.5][SPEC-038][F38] Iluminação, pós-processamento, LightmapGI e aquecimento de shaders (#93, finalizado em: 2026-10-11)

### #1 (#1)

- [MVP0][GATE] Gate Godot × Unity: jogável a 100 ms sem borracha (#7, finalizado em: 2026-10-09)
- [MVP0][SPEC-005][F5] Servidor headless em Docker com latência e perda simuladas (#6, finalizado em: 2026-10-09)
- [MVP0][SPEC-003][F3] Arena, conexão servidor/cliente e player com movimento por rollback (#4, finalizado em: 2026-10-09)
- [MVP0][SPEC-004][F4] Ataque corpo a corpo validado no servidor, HUD de rede e autopilot (#5, finalizado em: 2026-10-09)
- [MVP0][SPEC-002][F2] Regras puras LaunchArgs, CombatRules, AimMath e InputActions com TDD (#3, finalizado em: 2026-10-09)
- [MVP0][SPEC-001][FIX] Runner de testes devolve 0 quando um teste não compila (#9, finalizado em: 2026-10-09)
- [MVP0][SPEC-001][F1] Reestruturar em game/, instalar netfox e GUT e criar o runner de testes (#2, finalizado em: 2026-10-09)

### Sem épico

- [MVP3][SPEC-028][FIX] Galeria do site com 80+ capturas que não mostram o jogo: vitrine de no máximo 10 (#243, finalizado em: 2026-10-20)
- [MVP3][SPEC-023][FIX] Container do game server não é preso à partida atribuída (#181, finalizado em: 2026-10-16)
- [FIX] test_components deixa 14 nós órfãos (DetailCard) (#184, finalizado em: 2026-10-16)
- Câmera: pilares e muros tapam o herói (oclusão) (#70, finalizado em: 2026-10-14)
- [MVP2][SPEC-037][FIX] Concealment desliga o _process no cliente que conecta depois do load (sonda lê ? nos monstros) (#148, finalizado em: 2026-10-13)
- Câmera: girar em volta do herói com o botão direito segurado (#47, finalizado em: 2026-10-10)
- [MVP1][FIX] Bot gira no lugar no centro depois que o boss morre e não há mais alvo (#52, finalizado em: 2026-10-10)
- [INFRA] Pipeline Blender: art/, .gitattributes/.gitignore e import de .blend desligado (ADR-0005) (#34, finalizado em: 2026-10-09)

## Descartado

_(vazio)_
