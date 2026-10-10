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
| D6 | Fatia 1x1 com 2 heróis | game |
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
| [0006](adr/0006-direcao-visual-toon-pbr.md) | Direção visual toon + stylized PBR; Game só Forward+; LightmapGI (SDFGI rejeitado); bevel/bake no cenário próprio; design system v2; critério de netcode para fatias visuais; bloco F38–F43 no MVP3 | aceito | 2026-10-10 |
| [0007](adr/0007-arena-ilha-flutuante-layout.md) | Arena "Ilha Flutuante Arcana": imagem panorâmica vira layout; espelho N–S, rio N–S + anel, 4 pontes (2 por metade); F44 (greybox, MVP2) + F40 (arte, MVP3); supera SPEC-007 §2–3 | aceito | 2026-10-10 |

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
