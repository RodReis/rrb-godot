# MVP2.7 — Acabamento e controle (= marco M2.7)

**Objetivo:** fechar a sensação de jogar antes do gate do MVP3: controle v2 (herói encara o movimento, alvo travado com auto-ataque), zoom da câmera, splash e loading próprios, cinemática de abertura, volta ao lobby com resultado, Tela Heróis no Launcher, silhueta no mato alto, acabamento PBR do cenário e dois heróis novos — Protetor da Selva (Controle) e Berserker (Lutador) — ADR-0015.
**Módulos:** `game`, `shared`, `launcher`. **Prazo PRD:** sem prazo definido pelo PI.
**Posição:** depois do MVP2.6 (fechado em 2026-10-14) e **antes do `[GATE]` do MVP3** (#87). F28 (#82) e o gate seguem em paralelo quando o PI liberar o VPS (decisão do PI em 2026-10-16: "Novo marco MVP2.7 com tudo").
**Critério de pronto:** as 10 fatias aceitas pelo PI por verificação visual; soak verde (50 partidas bot × bot, ≤ 10 min, nunca empate) nas fatias que mexem em servidor, input ou FSM (F66, F69, F74, F75); o critério de netcode do ADR-0006 item 7 nas fatias de `game`; frame time dentro do orçamento (F72, F73).
**Estado:** entregue — #193, 10/10 `finalizado` (F66–F68 em 2026-10-16, F69–F72 em 2026-10-17, F73–F75 em 2026-10-18); sem `[GATE]`.

> Numeração: as fatias deste marco usam `Slice 2.7.n` (três componentes), como no MVP2.5/2.6.

## Fatias

| Slice | F / SPEC | Mód. | Entrega | Fontes |
|---|---|---|---|---|
| 2.7.1 | F66 / SPEC-066 | game, shared | **Controle v2:** herói encara a direção do movimento (janela de encarar 0,4 s ao atacar/usar skill); botão direito **clicado** num herói inimigo ou monstro trava alvo (`target_id` no input, validado por visão no servidor); auto-ataque em alcance (não anda); moldura do alvo (nome, HP, nível/tier) e anel no chão; `RT` no gamepad; bot usa alvo; **segurar** no chão continua o ataque contínuo | ADR-0015 itens 3–4; PRD §3.6; GDB §7.3; CONVENTION §4.5, §4.6, §6 |
| 2.7.2 | F67 / SPEC-067 | game, shared | **Câmera com zoom:** roda do mouse + `camera_zoom_in`/`camera_zoom_out` (padrão `=`/`-`, remapeáveis em Configurações), 9–14 u em passos de 1 u, padrão 11 u, pitch/FOV iguais; `settings.cfg` `[camera] distance`; só cliente; na calibração o PI manteve 11 u e o **minimapa e o radar da fase 2 deixaram de girar** (travados no yaw inicial do time) | ADR-0015 item 5; SPEC-031; SPEC-045; `ARCHITECTURE-LAUNCHER.md` §5.3 |
| 2.7.3 | F68 / SPEC-068 | game, launcher, shared | **Splash e loading:** logo do Godot fora nos dois projetos; splash "ARENA 1V1" renderizado; no Game, 1 de 3 telas sorteadas (renders reais: arena dia, arena noite, heróis em pose) com dica das regras documentadas e progresso real (warm-up + conexão), do boot até a seleção de heróis, na fila e no treino | ADR-0015 item 6; `FRONTEND-LAUNCHER.md` §8 |
| 2.7.4 | F69 / SPEC-069 | game | **Cinemática de abertura:** estado `INTRO` na FSM (≥ 5 s, até os dois `ready`, corta aos 8 s; relógio da fase 1 começa no fim); cliente: voo pela arena 3 s → close no próprio herói 2 s → blend; sem pular; vale no treino | ADR-0015 item 7; CONVENTION §3 |
| 2.7.5 | F70 / SPEC-070 | game, launcher | **Fim de partida → lobby:** "Voltar ao lobby" + fechamento automático em 15 s no Game; Launcher volta ao LOBBY com card "Resultado da partida" (resultado, heróis e `#nickname`, kills/mortes, nível, duração, motivo, V–D) com "Jogar de novo" e "Ver histórico"; espera a partida aparecer no `GET /matches` (3 × 1 s); treino sem card | ADR-0015 item 8; F18; F26; `ARCHITECTURE-LAUNCHER.md` §4.2, §5.2 |
| 2.7.6 | F71 / SPEC-071 | launcher, shared | **Tela Heróis:** rota `heroes`, item HERÓIS no menu, fiel a `docs/prd/telas/Tela Herois/`; dados só de `shared/data` (heróis, classe, atributos Nv 1/10, 4 skills com descrição, arma); retratos 512 px renderizados; sem epíteto/lore; "Arqueiro" | ADR-0015 item 9; `FRONTEND-LAUNCHER.md` §8; F27 |
| 2.7.7 | F72 / SPEC-072 | game, shared | **Silhueta no mato alto:** próprio herói translúcido (passe sem profundidade, cor do time, alpha 0,35) e moita semitransparente em 2,5 u (alpha 0,4) quando ele está dentro; só cliente; adversário e monstros não | ADR-0015 item 10; SPEC-032; CONVENTION §4.7 |
| 2.7.8 | F73 / SPEC-073 | game, shared | **Acabamento do cenário (ADR-0006 mantida):** texturas PBR CC0 ≤ 2K (terreno, rochas, muralhas, pontes, madeira), normal maps, grama ×2 com fade; GPU ≤ +1,5 ms sobre a baseline do F65 a 1080p; lightmap rebakeado; licenças registradas | ADR-0015 item 11; ADR-0006; F42; F63; F64 |
| 2.7.9 | F74 / SPEC-074 | game, shared | **Protetor da Selva (Controle):** `Druid` do Extra, cajado visível, Seiva, Raízes Vivas (lentidão 100 % 1,5 s), Poção Verde (cura própria em área 3 s), Pântano (zona 40 % 6 s + pulsos); seleção, bot, VFX, ícones | ADR-0015 itens 12, 14; GDB §4.7 |
| 2.7.10 | F75 / SPEC-075 | game, shared | **Berserker (Lutador):** `Barbarian_Large` do Extra com textura alternativa, 2 machados grandes, `Rig_Large`; passiva Frenesi (`HeroData.passive`), Machados Gêmeos, Arremesso de Machado, Grito de Guerra, Ragnarök; seleção, bot, VFX, ícones | ADR-0015 itens 13, 14; GDB §2.2-E, §4.8 |

## Ordem e issues

Issue-pai **[MVP2.7] #193**. Ordem: **F66 → F67 → F68 → F69 → F70 → F71 → F72 → F73 → F74 → F75**. Sem `[INFRA]`: o gerador do roadmap já aceita qualquer marco decimal (#161).

Dependências: F66 depende do F45 (câmera/ataque no botão direito), do F57 (HUD) e do F37 (visão por peer) — entregues. F69 depende do F51 (seleção) e do F15 (FSM). F70 depende do F26 (histórico) e do F52 (tela de fim). F71 depende do F27 (`CatalogService`) e do F62 (`SkillData.description`). F72 depende do F32/F34. F73 depende do F42, F49 (lightmap), F63, F64. F74 e F75 dependem do F66 (alvo), F48 (equipamento), F41 (VFX), F51 (seleção).

## Pendências

- **Gate do MVP2.7:** sem card `[GATE]` (decisão do PI em 2026-10-16, como MVP2.5 e MVP2.6); cada fatia tem aceite visual e, quando mexe em servidor/FSM/input, soak próprio.
- **Textura do Berserker:** decidida — `alt_A` (escolha do PI no aceite visual do F75, 2026-10-18).
- **Distância padrão da câmera (11 u):** decidida — calibrada ao vivo no F67 (2026-10-16); a escala visual dos personagens segue em `FORA-DE-ESCOPO.md`.

## Fora deste MVP

Escala visual dos personagens, silhueta de aliado no mato (2x2), cinemática pulável, alvo que persegue, epíteto/lore da Tela Heróis, cura de aliado da Poção Verde (2x2), realismo fora da ADR-0006 — `FORA-DE-ESCOPO.md`.
