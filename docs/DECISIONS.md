# DECISIONS.md — Índice de decisões (ADRs)

Ler antes de propor mudança estrutural. Decisão nova = ADR novo em `docs/adr/NNNN-slug.md`, numerado em sequência, nunca reaproveitado. ADR não se edita depois de aceito: supersede-se com outro.

## Formato do ADR

`# ADR-NNNN — título` · Status (proposto / aceito / superado por ADR-X) · Data · Decisor · Contexto · Decisão · Alternativas descartadas (tabela: alternativa | por que não) · Consequências (positivas, custos, o que vigiar).

## Decisões do PRD (não são ADR, mas valem como tal)

Fonte: `docs/prd/PRD.md` §2. Resumo para referência rápida; o texto normativo é o do PRD.

| # | Decisão | Módulo afetado |
|---|---|---|
| D1 | PC primeiro (Windows) | ambos |
| D2 | Fase A de aprendizado com arquitetura de produto | ambos |
| D3 | Fase 1 em mapa único: bases seguras + centro contestado | game |
| D4 | Fase 2 com zona encolhendo + meta de kills; sem respawn crescente | game |
| D5 | Monetização por sorteios/vales/loja/passe só na fase B | launcher/backend (futuro) |
| D6 | Fatia 1x1 com 2 heróis (ampliada para 4 no MVP2 — ADR-0011 —, para 6 no MVP2.6 — ADR-0013 — para 8 no MVP2.7 — ADR-0015 — e para 10 no MVP2.8 — ADR-0016) | game |
| D7 | Engine Godot 4.7, condicionada ao gate M0 | ambos |
| D8 | GDScript (não C#) | ambos |
| D9 | Assets KayKit (principal) + Quaternius (secundário), cena de alinhamento; ajustes e arte própria no Blender (ADR-0005) | shared |
| D10 | Backend meta em NestJS + Postgres | launcher |

## ADRs

| ADR | Título | Status | Data |
|---|---|---|---|
| [0001](adr/0001-gate-m0.md) | Gate M0: Godot 4 + netfox para ação em rede — segue Godot | aceito | 2026-10-09 |
| [0002](adr/0002-dois-modulos-launcher-e-game.md) | Dois módulos independentes: Launcher (Godot) e Game; backend no Launcher; pick e fim de partida no Game | aceito | 2026-10-08 |
| [0003](adr/0003-shared-por-junction.md) | `shared/` montado nos dois projetos por junction NTFS | aceito | 2026-10-08 |
| [0004](adr/0004-gdb-vence-numeros.md) | Em divergência numérica, o GDB vence o PRD | aceito | 2026-10-08 |
| [0005](adr/0005-blender-pipeline-de-assets.md) | Blender no pipeline de assets 3D (criação, acabamento, ajustes, rascunhos); fonte `.blend` em `art/`, só glTF em `shared/assets/` | aceito | 2026-10-09 |
| [0006](adr/0006-direcao-visual-toon-pbr.md) | Direção visual toon + stylized PBR; Game só Forward+; LightmapGI (SDFGI rejeitado); bevel/bake no cenário próprio; design system v2; critério de netcode para fatias visuais; bloco F38–F43 = marco MVP2.5 (antes do MVP3) | aceito | 2026-10-10 |
| [0007](adr/0007-arena-ilha-flutuante-layout.md) | Arena "Ilha Flutuante Arcana": imagem panorâmica vira layout; espelho N–S, rio N–S + anel, 4 pontes (2 por metade); F44 (greybox, MVP2) + F40 (arte, MVP2.5); supera SPEC-007 §2–3 | aceito (entrega e ordem supersedidas pelo ADR-0008; topologia superada pelo ADR-0009) | 2026-10-10 |
| [0008](adr/0008-vale-runico-preservado.md) | Vale Rúnico preservado congelado (`legacy/` + tag `arena-vale-runico`); F44 gera a Ilha em cena nova; F44 depois do F37, antes do F19 | aceito | 2026-10-10 |
| [0009](adr/0009-arena-rift-medieval-adaptado.md) | Arena "Rift Medieval adaptado": quadrado 80×80 (spawn ≤ 35 u, zona do GDB intacta), rio em S NO–SE com lagoas, bases SO/NE por rotação 180°, 3 rotas (2 pontes na MID), corredores livres + selva nos quadrantes; Ilha v1 só por tag (sem `legacy/`); F46 depois do F44, antes do F19; supera ADR-0007 (topologia) | aceito | 2026-10-10 |
| [0010](adr/0010-equipamento-visivel-e-dia-noite.md) | Equipamento visível (armas + armaduras próprias presas a ossos) e ciclo dia/noite pelo relógio (sentido pela seed, dia claro × noite do F40, lightmap sem sol); supera parcialmente ADR-0006 itens 3–4 e o clima fixo do F40 | aceito | 2026-10-11 |
| [0011](adr/0011-quatro-herois-e-campos-de-canto.md) | Quatro heróis no MVP2 (Bárbaro/Algoz e Bruxo de Fogo/Mago, KayKit Adventurers 1.0) e campos de canto NO/SE (Golem de canto + 2 Lobos + 2 Baús Reforçados 50/50); boss não muda; F53–F55 antes do F51; supera parcialmente PRD §1.3/D6/§4.1 e SPEC-046 §2.7/§3 | aceito | 2026-10-11 |
| [0012](adr/0012-arena-em-vale-sem-abismo.md) | Arena num vale: faixa externa só visual (floresta densa, encostas e cristas rochosas a ~70–90 u, neblina de distância), cascatas NO/SE viram riacho, ilhotas saem; F56 depois do F57 e antes do [GATE] do MVP2; supera parcialmente ADR-0007, ADR-0009/SPEC-046 (borda = abismo) e SPEC-040 | aceito | 2026-10-12 |
| [0013](adr/0013-ladina-e-engenheiro-mvp2-6.md) | Ladina (Algoz, besta, `Rogue_Hooded`) e Engenheiro (classe nova, Adventurers 2.0 Extra) no marco MVP2.6; fumaça = moita temporária que não revela ao lançar; Torreta indestrutível 6 s contra heróis e monstros; nome "Arqueiro" | aceito | 2026-10-13 |
| [0014](adr/0014-ajustes-pos-gate-mvp2.md) | Ajustes do PI depois do [GATE] do MVP2, antes do MVP2.6/MVP3: centro sem pilares (F60), baú com menu de 3 itens por clique e reservado a quem abriu (F61), `B` = ficha do herói com aba Monstros (F62), água por shader (F63), fonte de cura remodelada (F64), minimapa claro por imagem pronta (F65); supera parcialmente SPEC-047, GDB §6.2, SPEC-034/044 (pilares) | aceito | 2026-10-13 |
| [0015](adr/0015-acabamento-controle-v2-e-herois-7-8.md) | Marco MVP2.7 "Acabamento e controle" antes do [GATE] MVP3: herói encara o movimento + alvo travado com auto-ataque em alcance (F66), zoom da câmera 9–14 u padrão 11 u (F67), splash próprio + 3 loadings de renders reais (F68), estado `INTRO` com cinemática in-engine 5–8 s (F69), fim de partida → lobby com card de resultado (F70), Tela Heróis (F71), silhueta do próprio herói no mato (F72), cenário PBR dentro da ADR-0006 com orçamento +1,5 ms (F73), Protetor da Selva — classe Controle, `Druid` — (F74) e Berserker — classe nova Lutador, `Barbarian_Large`, primeira passiva — (F75); supera parcialmente PRD §3.6/§4.1/§1.3, SPEC-031, SPEC-045, F26 | aceito | 2026-10-16 |
| [0016](adr/0016-paladino-e-ocultista-mvp2-8.md) | Marco MVP2.8 "Heróis 9 e 10" depois do MVP2.7 e antes do [GATE] MVP3: Paladino Radiante — Tanque reativo, `Knight` `alt_B` sem elmo, maça própria; Retribuição contra heróis/servos/monstros; Bênção imune a todo dano inclusive zona — (F76), Ocultista — Mago de dano contínuo, Maldição até 3 marcas com piso 0, exceção à ADR-0006 (atlas escuro + capuz) — (F77) e Servos do Vazio — invocação móvel com IA, sem recompensa ao matar, kill para o dono — (F78); supera parcialmente PRD §1.3/§4.3 | aceito | 2026-10-18 |
| [0017](adr/0017-site-publico-loot-start.md) | Site público "Loot Start": landing em React em `site/` (3º diretório de código, sem relação com Game/Launcher/Backend), dados extraídos em build de `shared/data` e `docs/roadmap`, deploy no GitHub Pages; nome "Loot Start" só no site; emenda o ADR-0002 | aceito | 2026-10-18 |

## Decisões de processo fixadas em documento (não precisam de ADR)

| Decisão | Onde |
|---|---|
| Trunk-based, squash merge, `main` protegida, sem merge queue | `GITHUB.md`, `CI-PR.md` |
| MVP-n = marco M-n do PRD (MVP0..MVP4) | `STATUS.md`, `docs/prd/mvp/` |
| Uma issue por fatia, numeração `F<n>` = `SPEC-<nnn>` | `CLAUDE.md`, `STATUS.md` |
| Contrato Launcher → Game por processo e argumentos | `ARCHITECTURE-LAUNCHER.md` §5 |
| Configuração do jogador compartilhada via `custom_user_dir_name` | `ARCHITECTURE-LAUNCHER.md` §5.3 |
| Modo "Praticar vs Bot" = Game em processo único com servidor local embutido | `ARCHITECTURE-GAME.md` §4 |

## Pendências de decisão do PI

Registradas em `RASTREABILIDADE.md` §"Pendências" (R-PEND-*). Nenhuma delas é decidida por agente.
