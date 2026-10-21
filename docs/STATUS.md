# STATUS.md — Kanban, roadmap e Índice Fatia ↔ SPEC

Prosa curta. Detalhe histórico vai para `STATUS-ARQUIVO.md`. O **Índice Fatia ↔ SPEC** (§3) é a fonte única da numeração: alocado pelo Cowork, número nunca reaproveitado. Progresso por item é do Code (`DEVELOPMENT.md`); aqui só o estado agregado.

## 1. Agora

| Campo | Valor |
|---|---|
| Marco / MVP ativo | **MVP3 — Meta + deploy** (issue-pai `#76`): F21–F27, F33 e F35 `finalizado` pelo PI (2026-10-15/16); **F28 #82** `done` (VPS no ar, Release `v0.1.0` publicado em 2026-10-19; aguarda aceite do PI), mais F79 #226, F80 #230 e os `[FIX]` #228, #229 e #233 `done` na mesma data; resta o **[GATE] #87** (`todo`). **MVP2.7 — Acabamento e controle** (F66–F75, ADR-0015) e **MVP2.8 — Heróis 9 e 10** (F76–F78, ADR-0016) entregues e `finalizado` pelo PI (2026-10-16 a 2026-10-19): 10 heróis jogáveis. MVP2.6 fechado em 2026-10-14; [GATE] MVP2 #69 aprovado em 2026-10-13; MVP2.5 entregue; MVP1 gate 2026-10-10; MVP0 2026-10-09 (ADR-0001) |
| Site público | `site/` — landing **Loot Start** (React + Vite) **no ar** em https://rodreis.github.io/rrb-godot/ desde 2026-10-18 (PR #218, GitHub Pages por Actions), pedido do PI, fora do board; ADR-0017, `docs/SITE.md`. Nome "Loot Start" só no site; o rename do jogo é decisão do PI (card futuro). Dados extraídos em build de `shared/data/heroes`, `docs/roadmap/historia.json` e deste arquivo (§2/§3, `tools/roadmap/status.mjs`) |
| Módulo em foco | `infra/` e `backend/` (F28, [GATE] MVP3); último trabalho em `game/` (F76–F78) e `launcher/` (F68, F70, F71) |
| Próximo marco | **MVP4 — Playtest** (planejado; ganhou F84 spike visual, F85 tutorial e F86 itch.io em 2026-10-19), depois **MVP5 — Early Access** (ADR-0024 a ADR-0028); antes, o [GATE] MVP3 #87 depende do VPS do PI (F28). Balanceamento dos 10 heróis fica para o F30: nos soaks fora do espelho o Berserker venceu 44/44 (F75), o Ocultista 8/45 (F77) e o Paladino 33/45 (F76) |
| Próximo gate | [GATE] MVP3 #87: dois amigos jogam pela internet pelo Release `v0.1.0` (VPS no ar); MVP2.5 a MVP2.8 não têm `[GATE]` (aceite visual + soak por fatia) |
| Documentação de governança | criada em 2026-10-08 (ADR-0002/0003/0004, arquitetura dos dois módulos); ADR-0006 (direção visual) e ADR-0007 (layout da arena) em 2026-10-10; **ADR-0016** (MVP2.8: Paladino Radiante, Ocultista e Servos do Vazio) em 2026-10-18; **ADR-0015** (MVP2.7: controle v2, câmera, loading/cinemática, lobby, Tela Heróis, silhueta, cenário, Protetor da Selva e Berserker) em 2026-10-16 |
| Board | **2026-10-19:** MVP2.7 (`#193`: F66–F75) e MVP2.8 (`#213`: F76 #214, F77 #215, F78 #216) com todas as fatias `finalizado`; MVP3 (`#76`): F28 #82 e [GATE] #87 em `todo`, F21–F27, F33, F35 e o `[FIX]` SPEC-023 `finalizado`; MVP4 `planejado`. Histórico do board (ADR-0010 a ADR-0016, ordem de cada marco) em `STATUS-ARQUIVO.md` § Board. |
| Bloqueios do PI | `RASTREABILIDADE.md` §5 — resolvidos em 2026-10-09: R-PEND-01, 05, 08, 09. R-PEND-11 decidida em 2026-10-09 (paleta e fontes de `docs/prd/telas/`). R-PEND-02 (completada), 04, 06, 12 e 13 decididas em 2026-10-10; 03 e 07 em 2026-10-09; R-PEND-11 emendada em 2026-10-10 (protótipo vence o DV na estrutura). Abertos: 10, 14 (fontes do design system v2 — trava só o F43) |

## 2. Roadmap (MVP-n = marco M-n do PRD §9.1)

| MVP | Entrega | Módulos | Critério de pronto | Estado |
|---|---|---|---|---|
| **MVP0** | Spike de netcode: 2 clientes + servidor headless em Docker, cápsula com predição, 1 ataque validado | game, infra | jogável a 100 ms sem "borracha" perceptível | **gate aprovado** — segue Godot (ADR-0001) |
| MVP1 | Arena single-player: mapa 3 zonas, Cavaleiro, monstros, XP/níveis, baús/itens, boss, bot, HUD F1 | game, shared | fase 1 completa contra bot, offline | **gate aprovado** (2026-10-10) |
| MVP2 | Partida em rede: Arqueiro, pick, fase 2 (zona, kills, fim garantido), HUD F2, fim de partida, economia de campo (laterais + respawn), mato alto e neblina de guerra | game, shared | 1x1 online termina sempre; soak 50 partidas bot×bot | **gate aprovado** (2026-10-13, #69) |
| MVP2.5 | Bloco visual: giro 360° da câmera (F45), iluminação e pós, toon/outline, arte da ilha, VFX, vegetação, HUD v2 (ADR-0006) | game, shared | 6 fatias aceitas pelo PI + critério de netcode do ADR-0006 item 7 | **entregue** (#99, 8/8 fatias `finalizado`) |
| MVP2.6 | Heróis 5 e 6: Ladina (Algoz, besta) e Engenheiro (classe nova) — ADR-0013 | game, shared | 2 fatias aceitas pelo PI; soak de cada herói verde; critério de netcode do ADR-0006 item 7 | **entregue** (#160, fechado em 2026-10-14) |
| MVP2.7 | Acabamento e controle: herói encara o movimento + alvo travado com auto-ataque, zoom da câmera, splash/loading, cinemática de abertura, volta ao lobby com resultado, Tela Heróis, silhueta no mato alto, cenário PBR, Protetor da Selva (Controle) e Berserker (Lutador) — ADR-0015 | game, shared, launcher | 10 fatias aceitas pelo PI; soak verde onde mexe em servidor/FSM/input; GPU dentro do orçamento | **entregue** (#193, 10/10 `finalizado`) |
| MVP2.8 | Heróis 9 e 10: Paladino Radiante (Tanque reativo), Ocultista (Mago de dano contínuo) e Servos do Vazio — ADR-0016 | game, shared | 3 fatias aceitas pelo PI; soak verde em cada uma; critério de netcode do ADR-0006 item 7 | **entregue** (#213, 3/3 `finalizado`; 10 heróis) |
| MVP3 | Meta + deploy: backend, launcher, pool no VPS, build PC | launcher, backend, infra | dois amigos jogam pela internet sem o dev | **em andamento** (#76): F21–F27, F33, F35 finalizados; F28, F79, F80 e 3 `[FIX]` feitos (Release `v0.1.0` publicado); gate #87 `todo` |
| MVP4 | Playtest: telemetria, 10+ pessoas, ajuste de números; spike visual, tutorial e itch.io antes do teste | todos | decisão câmera/duração/3x3; critérios PRD §9.2; abrir ou não o EA | planejado |
| MVP5 | Early Access F2P no site + itch.io (issue-pai #250): Patente e heróis, recompensas de login, bot na fila, loja cosmética, skins (ADR-0024 a ADR-0028) | backend, launcher, game, shared, infra | jogador novo instala, faz o tutorial, acha partida em ≤ 30 s e compra o Fundador vendo a skin na partida | planejado |

## 3. Índice Fatia ↔ SPEC (fonte única)

`F<n>` = `SPEC-<nnn>`, sempre iguais. Uma fatia = uma issue. `[GATE]` não tem F/SPEC. Coluna **Mód.**: `game`, `launcher`, `backend`, `shared`, `infra`. Estado: `—` (sem issue), `planejado`, `backlog`, `todo`, `doing`, `done`, `finalizado`.

| F / SPEC | MVP | Mód. | Fatia (Slice do MVP) | Estado |
|---|---|---|---|---|
| F1 / SPEC-001 | MVP0 | game, infra | Slice 0.1 — Reestruturar em `game/`, addons netfox + GUT, runner de testes | finalizado (#2) |
| F2 / SPEC-002 | MVP0 | game | Slice 0.2 — Regras puras: `LaunchArgs`, `CombatRules`, `AimMath`, `InputActions` (TDD) | finalizado (#3) |
| F3 / SPEC-003 | MVP0 | game | Slice 0.3 — Arena, cena principal, conexão servidor/cliente, player com rollback | finalizado (#4) |
| F4 / SPEC-004 | MVP0 | game | Slice 0.4 — Ataque corpo a corpo validado no servidor, HUD de rede, autopilot | finalizado (#5) |
| F5 / SPEC-005 | MVP0 | infra | Slice 0.5 — Servidor em Docker com latência/perda simuladas | finalizado (#6) |
| [GATE] | MVP0 | — | Protocolo do gate M0 e ADR-0001 | finalizado (#7) |
| F6 / SPEC-006 | MVP1 | shared | Slice 1.1 — `shared/` por junction; classes Resource; `.tres` de heróis, itens, monstros, regras (GDB §8); `stats.gd`, `xp_table.gd`, `set_bonus.gd`, `item_rules.gd`; cena de alinhamento | finalizado (#18) |
| F7 / SPEC-007 | MVP1 | game | Slice 1.2 — Arena "Vale Rúnico": layout da `spec/SPEC-007.md`, rio + 2 pontes, cratera com pilares, portões, mato (geometria), marcadores | finalizado (#19) |
| F31 / SPEC-031 | MVP1 | game, shared | Slice 1.3 — Câmera 3ª pessoa, controles teclado/mouse/gamepad, cena de alinhamento KayKit (avaliação de câmera B-02 pelo PI) | finalizado (#20) |
| F8 / SPEC-008 | MVP1 | game | Slice 1.4 — Cavaleiro: modelo KayKit, ataque básico, Q Investida, E Muralha, R Terremoto, lendo `shared/data` | finalizado (#21) |
| F9 / SPEC-009 | MVP1 | game | Slice 1.5 — Monstros tier 1–3 com IA, XP, níveis, pontos de skill, catch-up | finalizado (#22) |
| F10 / SPEC-010 | MVP1 | game | Slice 1.6 — Baús, itens, inventário 4 slots, substituição, bônus de conjunto | finalizado (#23) |
| F11 / SPEC-011 | MVP1 | game | Slice 1.7 — Rei Esqueleto aos 3:30, drop épico | finalizado (#24) |
| F12 / SPEC-012 | MVP1 | game | Slice 1.8 — Bot FSM fase 1 (`BotInput`), modo offline com servidor embutido | finalizado (#25) |
| F13 / SPEC-013 | MVP1 | game, shared | Slice 1.9 — HUD fase 1 + relógio + aviso do boss aos 3:00 + bestiário em partida (`B`) + componentes base do design system | finalizado (#26) |
| F34 / SPEC-034 | MVP1 | game, shared | Slice 1.10 — Pilares da cratera e mato alto com assets do Blender (só visual; colisão do F7 intacta) — depois do [INFRA] #34 | finalizado (#38) |
| [GATE] | MVP1 | — | Homologação: fase 1 completa contra bot, offline (PRD M1) | finalizado (#27) |
| [INFRA] | MVP1 | ci | CI: `lint-gd` (tipagem, literais em `core/`, I9), path filter por módulo, `shared/test` no `test-game` — antes de F6 | finalizado (#17) |
| [INFRA] | — | infra | Pipeline Blender (ADR-0005): `art/`, `.gitattributes`/`.gitignore`, import de `.blend` desligado — antes do primeiro asset via Blender | finalizado (#34) |
| F14 / SPEC-014 | MVP2 | game | Slice 2.1 — Arqueiro: projétil validado no servidor, Q perfurante, E rolamento, R chuva | finalizado (#62) |
| F15 / SPEC-015 | MVP2 | game | Slice 2.2 — Ciclo de partida: `MatchController` (FSM), seleção de heróis, PvP fase 1, respawn, eventos por RPC | finalizado (#58) |
| F16 / SPEC-016 | MVP2 | game | Slice 2.3 — Fase 2: zona, dano, respawn, kills, morte súbita, regras de vitória | finalizado (#63) |
| F17 / SPEC-017 | MVP2 | game | Slice 2.4 — Transição 5:00 + HUD fase 2 + vinheta de zona | finalizado (#64) |
| F18 / SPEC-018 | MVP2 | game | Slice 2.5 — Tela de fim de partida com estatísticas | finalizado (#65) |
| F19 / SPEC-019 | MVP2 | game | Slice 2.6 — Bot fase 2 + soak 50 partidas headless (`tools/soak.ps1`) | finalizado (#68) |
| F20 / SPEC-020 | MVP2 | game | Slice 2.7 — Monstros, baús e boss replicados (2 clientes reais) | finalizado (#60) |
| F36 / SPEC-036 | MVP2 | game, shared | Slice 2.9 — Economia de campo: 4 campos laterais (2 T1 + 1 T2 e 2 baús comuns cada), respawn de monstros não-boss 90 s na fase 1 (GDB §5, §6.2) | finalizado (#59) |
| F37 / SPEC-037 | MVP2 | game, shared | Slice 2.10 — Neblina de guerra: visão 12 u + explorado, filtro de replicação por peer (generaliza o F32), minimapa (`CONVENTION.md` §4.9) | finalizado (#67) |
| [GATE] | MVP2 | — | Homologação: 1x1 online termina sempre; soak verde | finalizado (#69) |
| F21 / SPEC-021 | MVP3 | backend | Slice 3.1 — NestJS: auth e-mail/senha, JWT, usuários, migrações | finalizado (#77) |
| F22 / SPEC-022 | MVP3 | backend | Slice 3.2 — Fila 1x1 FIFO + orquestrador (pool Docker, token de partida, heartbeat) | finalizado (#78) |
| F23 / SPEC-023 | MVP3 | game | Slice 3.3 — Game server: `--token`, validar no backend, reportar resultado, códigos de saída | finalizado (#79) |
| F24 / SPEC-024 | MVP3 | launcher, shared | Slice 3.4 — Shell do launcher: `App`, pilha de telas, Theme completo, galeria de componentes, configurações (vídeo/áudio/controles, aba Créditos) e `settings.cfg` | finalizado (#80) |
| F25 / SPEC-025 | MVP3 | launcher | Slice 3.5 — Login, lobby com diorama, fila (polling), lançar/esperar o Game, treino vs bot | finalizado (#81) |
| F26 / SPEC-026 | MVP3 | launcher, backend | Slice 3.6 — Histórico de partidas (`GET /matches`) | finalizado (#83) |
| F27 / SPEC-027 | MVP3 | launcher | Slice 3.7 — Bestiário e Forja (simulador com `shared/core`) | finalizado (#84) |
| F33 / SPEC-033 | MVP3 | launcher, shared | Slice 3.9 — Tela Arena & Mapa (DV tela 10): render da arena real, marcadores (POIs), regras das 2 fases pelos números do GDB | finalizado (#85) |
| F35 / SPEC-035 | MVP3 | launcher, backend | Slice 3.10 — Perfil de conta: nickname único obrigatório no 1º login (3–16 `A–Z a–z 0–9 _`, prefixo `#` de exibição); avatar predefinido ou upload ≤ 1 MB, só local; sem XP de conta, sem data de nascimento (R-PEND-02) | finalizado (#86) |
| F38 / SPEC-038 | MVP2.5 | game | Slice 2.5.1 — Iluminação e pós: `WorldEnvironment`, `Sun`, `LightmapGI`, warm-up de shaders, baseline do profiler, toggles em `settings.cfg` (ADR-0006) | finalizado (#93) |
| F39 / SPEC-039 | MVP2.5 | game, shared | Slice 2.5.2 — Toon + outline por pós-import | finalizado (#94) |
| F40 / SPEC-040 | MVP2.5 | game, shared | Slice 2.5.3 — Arte da ilha sobre a SPEC-044: ilha + abismo, castelos, rio de mana e cachoeiras, cratera de magma, cristais, skybox, ilhotas; shaders de água/magma/cristal/sky (ADR-0007) | finalizado (#95) |
| F41 / SPEC-041 | MVP2.5 | game | Slice 2.5.4 — Arquitetura VFX + VFX do Cavaleiro e do Arqueiro | finalizado (#96) |
| F42 / SPEC-042 | MVP2.5 | game, shared | Slice 2.5.5 — Vegetação (grama `MultiMesh`, distinta do mato alto) | finalizado (#97) |
| F43 / SPEC-043 | MVP2.5 | game, shared | Slice 2.5.6 — HUD v2 (ghost bar, ícones, molduras, fontes R-PEND-14, 3 pontos) | finalizado (#98) |
| F28 / SPEC-028 | MVP3 | infra | Slice 3.8 — Deploy no VPS (Coolify, compose, UDP 7000–7020), export presets, pacote de instalação (`launcher/` + `game/`) | done (#82) — VPS no ar (api.lootstart.cloud, São Paulo, ping 16 ms), aceite com 2 clientes e Release v0.1.0 publicado em 2026-10-19 |
| F45 / SPEC-045 | MVP2.5 | game, shared | Slice 2.5.7 — Câmera: giro 360° com o botão esquerdo segurado; ataque básico no botão direito (só cliente; substitui #47) | finalizado (#103) |
| [INFRA] | MVP2.5 | infra | Roadmap público (`build-roadmap.mjs`) e `GITHUB.md` passam a aceitar o marco `MVP2.5` — antes da 1ª fatia do marco ser entregue | finalizado (#100) |
| [GATE] | MVP3 | — | Dois amigos jogam pela internet sem intervenção do dev | todo (#87) |
| F29 / SPEC-029 | MVP4 | backend, launcher, game | Slice 4.1 — Telemetria: ping médio, duração, líder de nível F1 × vencedor; painel de KPIs no histórico | planejado (#253) |
| F30 / SPEC-030 | MVP4 | shared | Slice 4.2 — Ajustes de balanceamento pós-playtest (só `.tres`) | planejado (#254) |
| F32 / SPEC-032 | MVP2 | game | Slice 2.8 — Mato alto: herói dentro da moita não é replicado para o adversário (visibilidade no servidor); regra em `CONVENTION.md` §4.7, números em GDB §7.3 (revelação 1,5 s) | finalizado (#66) |
| F44 / SPEC-044 | MVP2 | game, shared | Slice 2.11 — Arena "Ilha Flutuante Arcana": layout novo (espelho N–S, rio N–S + anel, 4 pontes), builder, colisão, marcadores, navmesh **+ a arte do F40 no mesmo card** (decisão do PI 2026-10-10: kits Blender, shaders de rio/magma/cristal/céu, baú novo) | finalizado (#92) |
| F46 / SPEC-046 | MVP2 | game, shared | Slice 2.12 — Arena "Rift Medieval adaptado": borda quadrada 80×80, rio em S NO–SE com lagoas, bases SO/NE (rotação 180°), 2 pontes na MID, 3 corredores de 8 u, selva nos quadrantes; builder, chassi Blender, marcadores, navmesh; kits do F44 reposicionados (ADR-0009) | finalizado (#110) |
| F47 / SPEC-047 | MVP2 | game, shared | Slice 2.13 — Baú: `F` só para item melhor, nada automático, regra por herói, item recusado fica no baú; card de comparação na HUD; bot segura `F` (GDB §6.2) | finalizado (#120) |
| F48 / SPEC-048 | MVP2 | game, shared | Slice 2.14 — Equipamento visível: armas e armaduras modeladas no Blender presas a ossos; ícones dos itens (ADR-0010) | finalizado (#121) |
| F49 / SPEC-049 | MVP2 | game, shared | Slice 2.15 — Ciclo dia/noite pelo relógio da partida, sentido pela seed, lightmap sem sol (ADR-0010) | finalizado (#122) |
| F50 / SPEC-050 | MVP2 | game, shared | Slice 2.16 — Pátio da base com construções do Medieval Village MegaKit (Quaternius, CC0), adaptadas no Blender ao castelo atual; só complementa (decisão do PI 2026-10-11) | finalizado (#131) |
| F51 / SPEC-051 | MVP2 | game | Slice 2.17 — Tela de seleção de heróis fiel ao protótipo novo (`docs/prd/telas/Seleção de Heróis/`), só com dados reais (4 heróis — ADR-0011) | finalizado (#132) |
| F52 / SPEC-052 | MVP2 | game | Slice 2.18 — Tela de vitória/derrota fiel ao protótipo novo (`docs/prd/telas/Destaques da Tela de Fim de Partida/`), só com dados reais | finalizado (#133) |
| F53 / SPEC-053 | MVP2 | game, shared | Slice 2.19 — Bárbaro (Algoz): Machado, Salto Brutal, Rodopio, Execução; pick, bot, VFX, machado visível (ADR-0011) | finalizado (#135) |
| F54 / SPEC-054 | MVP2 | game, shared | Slice 2.20 — Bruxo de Fogo (Mago): Bola de Fogo, Explosão de Chamas, Anel de Fogo, Meteoro; pick, bot, VFX de fogo, cajado visível (ADR-0011) | finalizado (#136) |
| F55 / SPEC-055 | MVP2 | game, shared | Slice 2.21 — Campos de canto NO/SE: Golem de canto + 2 Lobos + 2 Baús Reforçados; moita de lagoa movida; 35 monstros, 28 baús (ADR-0011) | finalizado (#137) |
| F56 / SPEC-056 | MVP2 | game, shared | Slice 2.22 — Arena num vale: faixa externa só visual (floresta, encostas, cristas, neblina de distância), cascatas viram riacho, ilhotas saem; câmera nunca mostra o vazio (ADR-0012) | finalizado (#150) |
| F57 / SPEC-057 | MVP2.5 | game, shared | Slice 2.5.8 — HUD moderna fiel ao protótipo (`docs/prd/telas/HUD Moderno/`): painéis de vidro só na HUD, dock único, minimapa no canto inferior direito com baús e monstros, telemetria FPS·PING·TICK, engrenagem com Bestiário e 2 switches de som, grade de atributos; fases 1 e 2 (decisão do PI 2026-10-12) | finalizado (#151) |
| [INFRA] | MVP2.6 | infra | Roadmap público aceita o marco `MVP2.6` (sem F/SPEC) — antes do F58 | finalizado (#161) |
| F58 / SPEC-058 | MVP2.6 | game, shared | Slice 2.6.1 — Ladina (Algoz): Virote, Rajada em Leque, Bomba de Fumaça (moita temporária), Emboscada; besta visível; bot; VFX (ADR-0013) | finalizado (#162) |
| F59 / SPEC-059 | MVP2.6 | game, shared | Slice 2.6.2 — Engenheiro (classe Engenheiro): Bacamarte, Garra Mecânica, Torreta, Caixa de Dinamite; bacamarte visível; bot; VFX (ADR-0013) | finalizado (#163) |
| F60 / SPEC-060 | MVP2 | game, shared | Slice 2.23 — Centro livre: saem os 8 pilares de obsidiana da cratera; magma fica (ADR-0014) | finalizado (#164) |
| F61 / SPEC-061 | MVP2 | game, shared | Slice 2.24 — Baú com menu: `F` abre, 3 itens, clique escolhe, baú reservado a quem abriu; bot escolhe o melhor (ADR-0014) | finalizado (#165) |
| F62 / SPEC-062 | MVP2 | game, shared | Slice 2.25 — Tecla `B`: ficha do herói (itens, atributos, habilidades com descrição) com aba Monstros (ADR-0014) | finalizado (#166) |
| F63 / SPEC-063 | MVP2 | game, shared | Slice 2.26 — Água do rio e do riacho com shader realista; só visual (ADR-0014) | finalizado (#167) |
| F64 / SPEC-064 | MVP2 | game, shared | Slice 2.27 — Fonte de cura remodelada no Blender, textura realista e água caindo; só visual (ADR-0014) | finalizado (#168) |
| F65 / SPEC-065 | MVP2 | game, shared | Slice 2.28 — Minimapa claro: imagem pronta do mapa no lugar da câmera ao vivo; neblina como véu leve (ADR-0014) | finalizado (#170) |
| F66 / SPEC-066 | MVP2.7 | game, shared | Slice 2.7.1 — Controle v2: herói encara o movimento (janela 0,4 s ao atacar); botão direito clicado trava alvo (`target_id` validado por visão), auto-ataque em alcance sem perseguir, moldura do alvo + anel, `RT`, bot por alvo; segurar no chão = contínuo (ADR-0015) | finalizado (#194) |
| F67 / SPEC-067 | MVP2.7 | game, shared | Slice 2.7.2 — Câmera com zoom: roda + `camera_zoom_in/out` (`=`/`-`, remapeáveis), 9–14 u passo 1 u, padrão 11 u, `settings.cfg` `[camera] distance`; só cliente (ADR-0015) | finalizado (#195) |
| F68 / SPEC-068 | MVP2.7 | game, launcher, shared | Slice 2.7.3 — Splash próprio nos 2 projetos (sem logo do Godot) + 3 telas de loading sorteadas (renders reais) com dica e progresso real, do boot à seleção, na fila e no treino (ADR-0015) | finalizado (#196) |
| F69 / SPEC-069 | MVP2.7 | game | Slice 2.7.4 — Cinemática de abertura: estado `INTRO` (≥ 5 s, até os 2 `ready`, corta aos 8 s), voo pela arena 3 s → close no próprio herói 2 s; sem pular; vale no treino (ADR-0015) | finalizado (#197) |
| F70 / SPEC-070 | MVP2.7 | game, launcher | Slice 2.7.5 — Fim de partida → lobby: "Voltar ao lobby" + fechamento em 15 s; Launcher no LOBBY com card "Resultado da partida" ("Jogar de novo", "Ver histórico"); espera a partida no `GET /matches`; treino sem card (ADR-0015) | finalizado (#198) |
| F71 / SPEC-071 | MVP2.7 | launcher, shared | Slice 2.7.6 — Tela Heróis fiel a `docs/prd/telas/Tela Herois/`: rota `heroes`, item HERÓIS, dados só de `shared/data`, retratos 512 px; sem epíteto/lore; "Arqueiro" (ADR-0015) | finalizado (#199) |
| F72 / SPEC-072 | MVP2.7 | game, shared | Slice 2.7.7 — Silhueta no mato alto: próprio herói translúcido e moita semitransparente em 2,5 u; só cliente; SPEC-032 intacta (ADR-0015) | finalizado (#200) |
| F73 / SPEC-073 | MVP2.7 | game, shared | Slice 2.7.8 — Acabamento do cenário dentro da ADR-0006: PBR CC0 ≤ 2K (terreno, rochas, muralhas, pontes, madeira), normal maps, grama ×2 com fade; GPU ≤ +1,5 ms sobre o F65; lightmap rebakeado (ADR-0015) | finalizado (#201) |
| F74 / SPEC-074 | MVP2.7 | game, shared | Slice 2.7.9 — Protetor da Selva (Controle): `Druid` do Extra, Seiva, Raízes Vivas, Poção Verde, Pântano; cajado visível; bot; VFX (ADR-0015, GDB §4.7) | finalizado (#202) |
| F75 / SPEC-075 | MVP2.7 | game, shared | Slice 2.7.10 — Berserker (Lutador): `Barbarian_Large` do Extra, textura alt, 2 machados, `Rig_Large`; passiva Frenesi, Machados Gêmeos, Arremesso de Machado, Grito de Guerra, Ragnarök; bot; VFX (ADR-0015, GDB §2.2-E, §4.8) | finalizado (#203) |
| F76 / SPEC-076 | MVP2.8 | game, shared | Slice 2.8.1 — Paladino Radiante (Tanque reativo): `Knight` do Extra `alt_B` sem elmo, maça própria; Maça, Golpe Consagrado, Retribuição, Bênção Inviolável (imune a todo dano, inclusive zona); bot; VFX (ADR-0016, GDB §4.9) | finalizado (#214) |
| F77 / SPEC-077 | MVP2.8 | game, shared | Slice 2.8.2 — Ocultista (Mago): `Mage` do Extra com atlas escuro e capuz próprios; Projétil Sombrio + Maldição (até 3 marcas, piso 0), Praga, Círculo Profano; R desligado até o F78; bot; VFX (ADR-0016, GDB §2.2-F, §4.10) | finalizado (#215) |
| F78 / SPEC-078 | MVP2.8 | game, shared | Slice 2.8.3 — Servos do Vazio (R do Ocultista): 2 servos móveis 7 s, IA no servidor (alvo travado → herói → monstro, só o visível ao dono), morrem sem recompensa, dano/kill para o Ocultista, visão como monstro (ADR-0016, GDB §4.10) | finalizado (#216) |
| F79 / SPEC-079 | MVP3 | launcher, shared | Slice 3.11 — Tipo de tela nas Configurações: Modo Janela, Janela sem Borda e Tela Cheia Exclusiva; `[video] window_mode` (ADR-0019) | done (#226) |
| F80 / SPEC-080 | MVP3 | game, backend, launcher, shared | Slice 3.12 — Sair do jogo: menu no ESC (Continuar / Sair) e derrota por abandono (`endReason` no resultado, ADR-0020) | done (#230) |
| F81 / SPEC-081 | MVP3 | game, launcher, shared | Slice 3.13 — Três níveis de bot no treino (Fácil, Médio = bot atual, Difícil), escolha no card Treino vs Bot; `--bot-difficulty=1..N` (ADR-0021; formato numérico pelo ADR-0027) | todo (#239) |
| F82 / SPEC-082 | MVP3 | launcher, game, shared, tools | Slice 3.14 — Nome "Loot Start" em tudo que o jogador vê; marca e splash no visual do site; `LootStart.exe` (ADR-0022) | done (#241) |
| F83 / SPEC-083 | MVP3 | launcher, backend, tools | Slice 3.15 — Instalador `LootStart-Setup.exe` e atualização ao abrir; obrigatória para fila online, treino livre (ADR-0023) | done (#242) |
| F84 / SPEC-084 | MVP4 | game, shared, art | Slice 4.3 — Spike visual, parte 1: canto SO (base A + pátio) no estilo Eternal Return, feito no Blender, em cena variante jogável; frame time medido (ADR-0024) | todo (#247) |
| F85 / SPEC-085 | MVP4 | game, launcher, backend, shared | Slice 4.4 — Tutorial guiado offline (Cavaleiro, arena real, 6 passos): obrigatório na 1ª vez após o nickname, pulável; fila online liberada na conta após tutorial ou 1 vitória vs bot de qualquer nível; `--tutorial` + `offline_result.cfg` (ADR-0026, ADR-0029) | todo (#251) |
| F86 / SPEC-086 | MVP4 | infra, tools | Slice 4.5 — Publicação no itch.io: página e build a cada Release (ADR-0024) | planejado (#252) |
| F93 / SPEC-093 | MVP4 | game, shared, art | Slice 4.6 — Spike visual, parte 2: Cavaleiro comissionado jogável na cena do F84 | cancelada — substituída pelo F98 em 2026-10-21 (ADR-0032); a issue #248 passa ao F98 |
| F94 / SPEC-094 | MVP4 | game, shared, art | Slice 4.7 — Arena nova, parte 1: bases A e B da arena oficial com o kit do F84 (cor do time B dourada) e folhagem com vento; sai a variante do spike (ADR-0030) | todo (#266) |
| F95 / SPEC-095 | MVP4 | game, shared, art | Slice 4.8 — Arena nova, parte 2: rio, lagoas, pontes, centro, rochas, selva, mato alto (mesma área e leitura) e chão (ADR-0030) | todo (#267) |
| F96 / SPEC-096 | MVP4 | game, shared, art | Slice 4.9 — Arena nova, parte 3: borda da ilha (floresta, tochas, cristais, defesas, bastiões, cascatas) e vale (ADR-0030) | todo (#268) |
| F97 / SPEC-097 | MVP4 | game, launcher, shared | Slice 4.10 — Escala da interface do jogo: `[ui] hud_scale` 70–100 %, padrão 85 %, no Launcher e no ⚙ da partida; `content_scale_factor` na raiz (ADR-0031) | doing (#272) |
| F98 / SPEC-098 | MVP4 | game, shared, art | Slice 4.11 — Carrasco, 11º herói (Tanque): modelo realista do Tripo + rig/animações Mixamo, nada do KayKit; Couraça, Dor, Espinhos, Penitência, Correntes do Julgamento (execução < 25 %); bot; VFX (ADR-0032, GDB §4.11) | todo (#248) |
| [GATE] | MVP4 | — | Playtest 10+ pessoas; critérios PRD §9.2; decisão câmera/duração/3x3; abrir ou não o EA | planejado (#255) |
| F87 / SPEC-087 | MVP5 | backend, launcher, game, shared | Slice 5.1 — Patente 1–10 grátis: 1 herói inicial + 1 por Patente com escolha livre; pick online validado no servidor (ADR-0026) | planejado (#256) |
| F88 / SPEC-088 | MVP5 | backend, launcher, shared | Slice 5.2 — Recompensas de Patente e de login diário/semanal/mensal: emblemas e molduras de perfil (ADR-0025, ADR-0026) | planejado (#257) |
| F89 / SPEC-089 | MVP5 | backend, game, infra, launcher | Slice 5.3 — Bot na fila online após 30 s sem humano, com aviso (ADR-0027) | planejado (#258) |
| F90 / SPEC-090 | MVP5 | backend, launcher | Slice 5.4 — Loja: catálogo, pedido, Mercado Pago (Pix e cartão), inventário, tela Loja (ADR-0025) | planejado (#259) |
| F91 / SPEC-091 | MVP5 | backend, game, launcher, shared | Slice 5.5 — Skin na partida: token devolve heróis liberados e skin equipada; game server replica (ADR-0028) | planejado (#260) |
| F92 / SPEC-092 | MVP5 | shared, art | Slice 5.6 — Primeiras skins (variantes KayKit Extra) + skin do Pacote de Fundador (ADR-0025) | planejado (#261) |
| [GATE] | MVP5 | — | Abertura do Early Access no site e no itch.io (ADR-0024) | planejado (#262) |

Próximo número livre: **F99 / SPEC-099**.

## 4. Regras deste índice

- Só o Cowork aloca número. Partir uma fatia = número novo (nunca sufixo). Ex.: F8 partido em 2026-10-09 → F31 (câmera/controles) saiu dele e **entra antes** dele na ordem. Fatia cancelada mantém a linha com estado `cancelada` e motivo em `STATUS-ARQUIVO.md`.
- A issue-pai de cada MVP tem título `[MVPn] <título>`; cada F é sub-issue nativa dela (`GITHUB.md` §9).
- Os próximos 5 cards da ordem ficam em `proplan:todo`.
- `shared` como módulo: a fatia muda `shared/` e, por isso, dispara CI de `game` e `launcher`.
