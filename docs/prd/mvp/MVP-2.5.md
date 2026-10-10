# MVP2.5 — Bloco visual (= marco M2.5)

**Objetivo:** elevar a qualidade visual do Game (arena, heróis, combate, HUD) de "KayKit cru" para um visual estilizado (toon/outline + stylized PBR, ADR-0006) **sem quebrar o netcode** do MVP2 e **sem mexer em regra de jogo**.
**Módulos:** `game`, `shared`. **Prazo PRD:** 2 semanas.
**Posição:** depois do `[GATE]` do MVP2 e **antes** do MVP3 (decisão do PI em 2026-10-10: "antes do MVP3").
**Critério de pronto:** as 7 fatias aceitas pelo PI por verificação visual; F38–F43 cada uma com o critério transversal do ADR-0006 item 7 (warm-up de shaders antes do `connect`; 3/3 conexões a 100 ms sem `past the history limit`; VFX só no cliente e só com `is_fresh`/sinal do `HitLedger`; números dos VFX vindos do GDB; orçamento de frame time +4 ms no total contra o baseline do F38).

> Numeração: as fatias deste marco usam `Slice 2.5.n` (três componentes), para não colidir com a Slice 2.5 do MVP2 (F18). Os números `F38–F43`/`SPEC-038–043` foram alocados no Índice do `STATUS.md` e não mudam.

## Fatias

| Slice | F / SPEC | Entrega | Fontes |
|---|---|---|---|
| 2.5.7 | F45 / SPEC-045 | câmera: giro 360° com o botão esquerdo segurado; ataque básico no botão direito; só cliente (**1º card do marco**) | SPEC-045; PRD §3.6 |
| 2.5.1 | F38 / SPEC-038 | iluminação e pós (`WorldEnvironment`, `Sun`, `LightmapGI`), warm-up de shaders, baseline do profiler, toggles em `settings.cfg` | ADR-0006; spec bloco visual §4 |
| 2.5.2 | F39 / SPEC-039 | toon + outline por pós-import (heróis, monstros, cenário) | ADR-0006; spec §4 |
| 2.5.3 | F40 / SPEC-040 | arte da ilha sobre o layout da SPEC-044: ilha + abismo, castelos modulares, rio de mana (malha única) e cachoeiras, cratera de magma, cristais, skybox cósmico, ilhotas de fundo, torres/balistas como enfeite; bevel/bake nos props; shaders de água, magma, cristal e sky | ADR-0005/0006/0007; SPEC-044; spec §4 |
| 2.5.4 | F41 / SPEC-041 | arquitetura VFX (pool, `is_fresh`, sinal do `HitLedger`) + VFX do Cavaleiro e da Arqueira | ADR-0006; GDB §3–4; spec §4 |
| 2.5.5 | F42 / SPEC-042 | vegetação: grama `MultiMesh` com vento, distinta do mato alto | ADR-0006; CONVENTION §4.7; spec §4 |
| 2.5.6 | F43 / SPEC-043 | HUD v2: ghost bar, ícones Q/E/R + badge, molduras, fontes (R-PEND-14), 3 pontos na seleção | ADR-0006; TOKENS v2; spec §4 |

## Ordem e issues

Issue-pai **[MVP2.5]** (número no `STATUS.md` §1). Ordem: **F45 #103 → F38 #93 → F39 #94 → F40 #95 → F41 #96 → F42 #97 → F43 #98**.

Dependências (spec do bloco §5): F39←F38; F40←F39 e **F44** (layout da arena, MVP2); F41←F38 e **F14** (Arqueira, MVP2); F42←F40; F43←design system v2 (R-PEND-14). F45 é independente (só cliente). Nenhuma depende de fatia do MVP3. Os pré-requisitos F14 e F44 são do MVP2 e fecham antes.

## O que o MVP3 herda

O F24 (Theme do launcher) nasce no design system v2 e lê as chaves gráficas do `settings.cfg` definidas no F38; o F33 (Arena & Mapa) renderiza a ilha pronta (F40). O `settings.cfg` é contrato Launcher ↔ Game — a mudança é autorizada pelo ADR-0006.

## Pendências do PI

- **R-PEND-14** — fontes do design system v2 (o guia só exemplifica Cinzel / Barlow Condensed / Montserrat SemiBold). Trava só o F43.
- **Gate do MVP2.5:** não foi criado card `[GATE]`; cada fatia tem aceite visual do PI. Se quiser um gate de marco, é decisão do PI.

## Fora deste MVP

Perfil gráfico para mobile (ADR-0006), SDFGI e SSIL como GI (`FORA-DE-ESCOPO.md`), relevo/degraus/fosso (ADR-0007), torres e balistas funcionais.
