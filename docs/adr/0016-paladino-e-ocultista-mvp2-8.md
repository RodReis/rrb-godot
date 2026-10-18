# ADR-0016 — Marco MVP2.8 "Heróis 9 e 10": Paladino Radiante (Tanque reativo) e Ocultista (Mago de dano contínuo) com Servos do Vazio

**Status:** aceito — 2026-10-18
**Decisor:** Rodrigo Reis (PI)
**Supera parcialmente:** PRD §1.3 (linha "8 heróis"), §4.3 ("Números dos 6 heróis"); ADR-0006 regra "heróis KayKit como vêm" — **exceção só para o Ocultista** (atlas próprio + capuz no lugar do chapéu); `FORA-DE-ESCOPO.md` linha "Heróis Suporte" (nota: o Paladino entra como Tanque, Suporte segue no roadmap).
**Mantém:** ADR-0001 (efeito no alvo via ledger) · ADR-0004 (GDB vence o PRD) · ADR-0005 (Blender) · ADR-0006 para todos os outros heróis e monstros · ADR-0015 (controle v2, alvo travado, regra ATK/INT do GDB §2.1) · CONVENTION §4.6 (honestidade), §4.7 (mato alto), §4.9 (neblina) · SPEC-032/F37.
**Relacionados:** `docs/prd/mvp/MVP-2.8.md` · GDB §2.2-F, §4.9, §4.10 · CONVENTION §2, §4.5 · F76–F78 (o corpo de cada issue vale como spec, como no ADR-0014/0015).

## Contexto

- Estado em 2026-10-18: MVP2.7 com 9 de 10 fatias fechadas (F75 Berserker em `doing`); MVP3 aguarda o VPS do PI (F28 parcial, [GATE] #87).
- O PI pediu dois heróis novos:
  - **Ocultista** — mago de dano ao longo do tempo (DoT), maldições que reduzem a resistência, invocação de pequenas unidades ou zonas de dano. Base: modelo `Mage` com textura alternativa escura (roxo/preto), livro de magias e cajado diferente do Bruxo. Refs.: Malzahar/Veigar (LoL), Warlock/Pugna (Dota).
  - **Paladino Radiante** — suporte tanque de linha de frente que protege e fortalece o time: escudos, imunidade a dano curta, maça que atordoa quem pula no atirador. Base: modelo `Knight` com textura clara/dourada, maça e escudo. Refs.: Omniknight/Abaddon (Dota), Taric/Leona (LoL).
- Achados apresentados ao PI antes da decisão (pop-ups de 2026-10-18):
  1. **Paladino é Suporte e o jogo é 1x1 até o M4** (PRD §4.1: "sem sentido no 1x1" — mesmo motivo do redesenho do Protetor, ADR-0015 item 12). Sem aliado, o kit de time vira escudo + atordoamento = o Cavaleiro (Muralha + Terremoto) **no mesmo corpo `Knight`**.
  2. Pack do PI (`C:\Desenv\engine\Character\KayKit_Adventurers_2.0_EXTRA`, CC0): existem `knight_texture_alt_A/B/C` (B = cinza/dourado) e `mage_texture_alt_A/B/C` (laranja/azul, oliva, azul/amarelo). **Não existe Mage escuro**, e o Bruxo de Fogo **já usa a textura padrão do Mage, que é roxa/azul-marinho**. **Não existe maça** (nem no `Knight` 1.0 do repo nem nos Assets do Extra); existem escudos, `staff`, `wand`, `spellbook_open/closed`.
  3. Mesmo corpo com outra textura é ilegível a 11–14 u (motivo do `Barbarian_Large` no Berserker, ADR-0015 achado 6). O chapéu do Mage e o elmo do Knight são o que se lê na câmera.
  4. **Invocação móvel é a parte mais cara:** entidade nova com IA, perseguição, rollback, visão (SPEC-032) e ledger. A Torreta (F59) é parada; o padrão mais próximo são os monstros replicados (F20).
  5. "Zona de dano no chão" se sobrepõe a Chuva de Flechas, Pântano e Meteoro; DoT puro perde para burst num duelo curto se o kit não segura o alvo na área.
  6. "Reduzir resistência": o jogo tem **só Defesa** (GDB §2.1), sem resistência mágica.
  7. "Imunidade a dano" + escudo no 1x1 pode travar a disputa da zona na fase 2 — vai a número no GDB.
  8. As imagens de referência trazem traços de marca de personagens de terceiros (rosto na sombra com olhos brilhantes sob chapéu roxo; armadura dourada com escudo solar). Servem como conceito de jogabilidade, não como briefing de arte — a base KayKit é o que garante originalidade, ainda mais com a intenção de F2P comercial.

## Decisão (pop-ups de 2026-10-18)

1. **Marco novo MVP2.8 — "Heróis 9 e 10"**, issue-pai própria, **depois do MVP2.7** e **antes do [GATE] MVP3** (#87), que segue em paralelo quando o VPS liberar. Sem card `[GATE]` (como MVP2.5/2.6/2.7): aceite visual do PI e soak por fatia.
2. **Três fatias, nesta ordem:** **F76** Paladino Radiante → **F77** Ocultista (básico, Q, E e Maldição; R entra desligado) → **F78** Servos do Vazio (R do Ocultista). A invocação foi **partida em fatia própria** por decisão do PI.
3. **Paladino Radiante — Tanque reativo (redesenho para valer no 1x1).** Classe **Tanque** (2º herói da classe, como o Algoz tem 2). O Cavaleiro **inicia** a luta (Investida, Terremoto em área); o Paladino **responde** a quem chega nele (atordoamento de alvo único, dano devolvido, imunidade). As habilidades que no pedido eram "do time" valem **em si mesmo e em aliados no raio** — no 1x1, só ele (padrão da Poção Verde, ADR-0015).
   - Modelo: KayKit Adventurers 2.0 Extra `Knight` com **`knight_texture_alt_B`** (cinza/dourado), **sem elmo** (exceção do ADR-0011 item 3) — a cabeça descoberta separa a silhueta da do Cavaleiro; **escudo do pack** diferente do usado pelo Cavaleiro; **maça modelada no Blender** (arte própria, ADR-0005) em **3 raridades** (F48).
   - Kit: básico **Maça** (corpo a corpo, mais lento e mais forte que o do Cavaleiro); Q **Golpe Consagrado** (atordoa o 1º alvo à frente); E **Retribuição** (por alguns segundos, golpe direto recebido de perto devolve dano ao atacante); R **Bênção Inviolável** (imunidade a dano curta + cura). Números: GDB §4.9.
4. **Retribuição vale contra heróis, servos e monstros** (decisão do PI): qualquer golpe **direto** a até 3,0 u que não seja projétil nem zona/pulso.
5. **Bênção Inviolável bloqueia todo dano, inclusive o da zona da fase 2** (decisão do PI). Controles (atordoamento, lentidão, empurrão, puxão) **continuam** valendo — é imunidade a dano, não a controle (o Ragnarök é que é imunidade a controle).
6. **Ocultista — Mago de dano contínuo.** Classe **Mago** (2º herói da classe). Kit: básico **Projétil Sombrio** (aplica marca de Maldição); Q **Praga** (dano contínuo); E **Círculo Profano** (zona que segura o alvo: dano por pulso + lentidão); R **Servos do Vazio**. Números: GDB §4.10.
7. **Maldição (decisão do PI): até 3 marcas, Defesa nunca negativa.** Cada marca tira Defesa por um tempo; a marca nova renova a duração de todas; `DEF efetiva = max(0, DEF − marcas × redução)`. Só o básico do Ocultista aplica marca. Fórmula: GDB §2.2-F.
8. **Visual do Ocultista (decisão do PI): textura própria + silhueta nova** — **exceção à ADR-0006 só para este herói**: KayKit Adventurers 2.0 Extra `Mage` com **atlas próprio escuro (preto/roxo)** pintado no Blender sobre o `mage_texture` (mesmo layout de UV, cores planas como no atlas KayKit), e **capuz modelado no Blender no lugar do chapéu** (arte própria, 50–800 triângulos); `spellbook_open` na mão esquerda e `staff` do pack (≠ cajado do Bruxo) na direita, cajado em 3 raridades (F48). Contraste com o Bruxo conferido na cena de alinhamento a 11 u e 14 u; aceite do PI.
9. **Servos do Vazio — invocação móvel com IA (decisão do PI).** Atacam **heróis e monstros** inimigos que o Ocultista vê (inclusive o boss); têm HP e podem ser mortos; **matar um servo não dá nada** (sem XP, sem drop, não conta kill); **kill feito por servo conta para o Ocultista** (dano do servo é dano do dono, como a Torreta). Uma invocação por vez (a nova substitui). Entidade simulada no servidor no padrão dos monstros replicados (F20), visão pelas regras dos monstros (GDB §7.3), efeitos via ledger (ADR-0001). Números: GDB §4.10.
10. Regra do GDB §2.1 mantida para os dois: **ATK escala básico, Q e E; INT escala só o R** (e o CDR).
11. Kits e números **aprovados pelo PI como proposta** (pop-up "Aprovo os dois"), conferidos no soak de cada fatia e ajustáveis no F30 (MVP4).

## Alternativas rejeitadas

| Alternativa | Motivo |
|---|---|
| Paladino como Suporte já (kit de time sem aliado) | no 1x1 vira um Cavaleiro mais fraco; PRD §4.1 |
| Adiar o Paladino para o 2x2 | PI quis o herói agora, redesenhado para o 1x1 |
| Paladino no `Knight` com elmo e só a textura `alt_B` | mesma silhueta do Cavaleiro a 11–14 u |
| Ocultista sem invocação (só DoT, maldição e zona) | PI escolheu invocação móvel |
| Invocação parada (padrão da Torreta) | PI escolheu invocação móvel com IA |
| Ocultista numa fatia só | PR grande demais (`CI-PR.md`); PI partiu em base + Servos |
| Ocultista com textura alternativa do pack como vem | nenhuma é escura; mantém o chapéu do Bruxo |
| Ocultista em outro corpo (ex.: `Rogue` sem capuz) | PI manteve o `Mage` com textura e silhueta próprias |
| Maldição de 1 marca só / acúmulo ilimitado | PI escolheu até 3 marcas com piso 0 |
| Bênção Inviolável sem bloquear a zona | PI escolheu imunidade total, inclusive zona |
| Retribuição só contra heróis | PI incluiu servos e monstros (ajuda no farm) |
| Servo morto dar XP | mexe na economia da fase 1; PI escolheu "nada" |
| Kill por servo sem matador | PI escolheu crédito ao Ocultista, como a Torreta |
| Marco MVP2.8 depois do [GATE] MVP3 / backlog | PI escolheu MVP2.8 logo após o MVP2.7 |

## Consequências

- Marco com 3 fatias; o [GATE] MVP3 continua em paralelo (depende do VPS do PI). São 10 heróis sem playtest externo ainda — o balanceamento real vem do M4 (F30).
- **Riscos técnicos aceitos:** (a) **F78** cria a primeira entidade **móvel** controlada por um herói: spawn/despawn compatível com o rollback do netfox (confirmar no addon antes — `CLAUDE.md`), IA de perseguição no servidor, replicação filtrada por visão, agro dos monstros, crédito de kill; soak obrigatório. (b) **F77** cria o primeiro **dano contínuo preso ao alvo** (Praga) e o primeiro **debuff acumulável** (Maldição): estado no próprio alvo, aplicado no `_rollback_tick` dele (ledger, ADR-0001) — mais estado de rollback por herói/monstro. (c) **F76**: imunidade a dano reaproveita a invulnerabilidade do Rolamento (GDB §4.2); Retribuição gera dano de volta pelo ledger — sem laço (dano devolvido não é devolvido de novo). (d) **Bênção bloqueia a zona:** 1,5–2,0 s a cada 50–60 s não muda a morte súbita das 10:00 (decide por vida percentual, GDB §7.2); vigiar no soak a duração média das partidas com o Paladino.
- `CONVENTION.md` §2 ganha a entidade **Servo** (dono: Game server); §4.5 ganha Maldição, Praga, Retribuição, Bênção e Servos. GDB §2.2-F, §4.9, §4.10. PRD §1.3 ("10 heróis"), §4.1 (Tanque e Mago com 2 heróis cada), §4.3 (tabelas dos heróis 9 e 10).
- `FORA-DE-ESCOPO.md`: Bênção e Retribuição em aliados (2x2); classe Suporte continua no roadmap.
- **Exceção à ADR-0006** registrada só para o Ocultista (atlas próprio + capuz); todos os outros heróis seguem "como vêm".
- Arte nova: maça em 3 raridades; capuz e atlas escuro do Ocultista; cajado do Ocultista em 3 raridades; modelo do Servo (Blender, 50–800 triângulos, toon/outline como os monstros); VFX (golpe consagrado, aura de retribuição, bênção dourada; projétil sombrio, marcas de maldição, praga, círculo profano, invocação/morte dos servos); 8 ícones de skill; 2 retratos 512 px (F71).
- Bot passa a jogar com 10 heróis; o soak de cada fatia cobre o que ela muda.
