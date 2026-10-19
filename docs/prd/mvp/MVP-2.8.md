# MVP2.8 — Heróis 9 e 10 (= marco M2.8)

**Objetivo:** dois heróis novos — **Paladino Radiante** (Tanque reativo: atordoa quem chega, devolve dano de perto, imunidade a dano curta) e **Ocultista** (Mago de dano contínuo: maldição, praga, círculo profano e Servos do Vazio) — ADR-0016.
**Módulos:** `game`, `shared`. **Prazo PRD:** sem prazo definido pelo PI.
**Posição:** depois do MVP2.7 (#193) e **antes do `[GATE]` do MVP3** (#87). F28 (#82) e o gate seguem em paralelo quando o PI liberar o VPS (decisão do PI em 2026-10-18).
**Critério de pronto:** as 3 fatias aceitas pelo PI por verificação visual; soak verde (50 partidas bot × bot, ≤ 10 min, nunca empate) em cada fatia; critério de netcode do ADR-0006 item 7 (3/3 conexões a 100 ms sem `past the history limit`).
**Estado:** entregue — #213, 3/3 `finalizado` (F77 em 2026-10-18; F76 e F78 em 2026-10-19); sem `[GATE]`. Soak das 3 fatias 50/50; balanceamento fora do espelho (Ocultista 8/45, Paladino 33/45) vai para o F30.

> Numeração: as fatias deste marco usam `Slice 2.8.n` (três componentes), como no MVP2.5/2.6/2.7.

## Fatias

| Slice | F / SPEC | Mód. | Entrega | Fontes |
|---|---|---|---|---|
| 2.8.1 | F76 / SPEC-076 | game, shared | **Paladino Radiante (Tanque):** `Knight` do Extra `alt_B` sem elmo, escudo do pack (`shield_spikes_color`), maça (Blender, 3 raridades); Maça, Golpe Consagrado (atordoa o 1º alvo), Retribuição (devolve dano de golpe direto ≤ 3 u; o Bacamarte do Engenheiro **não** é golpe direto; durante a imunidade da Bênção devolve só a parte do ATK), Bênção Inviolável (cura + imunidade a todo dano, inclusive zona); seleção, Tela Heróis, bot, VFX, ícones | ADR-0016 itens 3–5, 10; GDB §4.9; CONVENTION §4.5 |
| 2.8.2 | F77 / SPEC-077 | game, shared | **Ocultista (Mago) — base:** `Mage` do Extra com atlas escuro próprio e capuz (Blender), livro + cajado (3 raridades); Projétil Sombrio com **Maldição** (até 3 marcas, −Defesa, piso 0), Praga (dano contínuo 4 s), Círculo Profano (zona com lentidão + pulsos); **R desligado** até o F78; seleção, Tela Heróis, bot, VFX, ícones | ADR-0016 itens 6–8, 10; GDB §2.2-F, §4.10 |
| 2.8.3 | F78 / SPEC-078 | game, shared | **Servos do Vazio (R do Ocultista):** 2 servos móveis à frente do Ocultista por 10 s (R1) / 12 s (R2) — decisão do PI em 2026-10-18; o GDB original era 7 s —, IA de perseguição no servidor (alvo travado → herói → monstro, só o que o Ocultista vê), HP e morte, sem recompensa ao matar, dano/kill para o Ocultista; replicação filtrada por visão como monstro; modelo do servo (Blender); bot usa o R | ADR-0016 item 9; GDB §4.10, §7.3; CONVENTION §2, §4.5 |

## Ordem e issues

Issue-pai **[MVP2.8] #213**. Ordem: **F76 → F77 → F78**. Sem `[INFRA]` (o gerador do roadmap aceita qualquer marco decimal, #161) e sem `[GATE]`.

Dependências: as três dependem do F66 (alvo travado), F48 (equipamento visível), F41 (VFX), F51 (seleção) e F71 (Tela Heróis) — entregues. F76 reaproveita a invulnerabilidade do Rolamento (F14) e o atordoamento do Terremoto (F8). F78 depende do F77 (herói) e do padrão de monstros replicados (F20) e da visão por peer (F37).

## Pendências

- **Gate do MVP2.8:** sem card `[GATE]` (como MVP2.5/2.6/2.7); cada fatia tem aceite visual e soak próprio.
- **Escudo do Paladino:** decidida em 2026-10-19 — `shield_spikes_color` (6 opções mostradas ao PI no aceite visual do F76).
- **Atlas e capuz do Ocultista:** aprovados pelo PI no aceite visual do F77 (2026-10-18), lado a lado com o Bruxo de Fogo a 11 u e 14 u; pentagrama do Círculo Profano mantido.

## Fora deste MVP

Retribuição e Bênção em aliados (2x2), classe Suporte, servos com XP/drop — `FORA-DE-ESCOPO.md`.
