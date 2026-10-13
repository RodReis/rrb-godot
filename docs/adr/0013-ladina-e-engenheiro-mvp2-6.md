# ADR-0013 — Ladina (besta) e Engenheiro no marco MVP2.6; classe nova Engenheiro; fumaça como moita temporária; Torreta indestrutível

**Status:** aceito — 2026-10-13
**Decisor:** Rodrigo Reis (PI)
**Supera parcialmente:** PRD §1.3 (linha "4 heróis") e §4.1 (classes da fatia); D6 ("fatia 1x1 com 2 heróis", já ampliada pelo ADR-0011); `FORA-DE-ESCOPO.md` (Ladina do protótipo da seleção, linha do F51).
**Relacionados:** SPEC-058 · SPEC-059 · GDB §4.5, §4.6, §7.3 · CONVENTION §4.5, §4.7 · ADR-0004 · ADR-0005 · ADR-0006 item 7 · ADR-0010 · ADR-0011

## Contexto

- Pedido do PI (2026-10-13): especificar mais 2 personagens — **Rogue com besta** e **Engineer** — com habilidades, equipamentos, efeitos visuais (Godot + Blender) e animações de habilidades e movimento. Referências: KayKit Adventurers 2.0 (`kaylousberg.itch.io/kaykit-adventurers`) e KayKit Character Animations (`kaylousberg.itch.io/kaykit-character-animations`); pack local do PI em `C:\Desenv\engine\Character\`.
- O [GATE] do MVP2 (#69) foi aprovado em 2026-10-13, com o soak (F19) fechado com 4 heróis. O MVP2.5 está com todas as fatias entregues. O MVP3 está em backlog.
- O **Engineer** só existe no tier **Extra** (pago) do Adventurers 2.0; o PI confirmou que tem o Extra 2.0. O Rogue (e `Rogue_Hooded`) está no tier gratuito.
- O rig do Adventurers 2.0 (`Rig_Medium`) é o mesmo do 1.0: 23 ossos, mesmos nomes e pose de repouso — provado no F14 (`art/heroes/build_ranger.py`, que leva as ações do `Knight.glb` para o `Ranger.glb` 2.0 sem retarget). O `Knight.glb` tem 76 clipes, entre eles `1H_Ranged_Shoot`, `2H_Ranged_Shoot`, `Throw`, `Interact`, `Use_Item`, `Dualwield_Melee_Attack_Stab`, `Dodge_Forward`.
- Achados apresentados ao PI antes da decisão: (a) a Torreta é a primeira entidade de jogo que não é herói, monstro nem projétil; a versão com HP traz alvo novo, kill credit e bot que ataca estrutura; (b) pela regra do mato (F32, GDB §7.3), usar skill revela por 1,5 s — lançar a fumaça revelaria a Ladina no mesmo tick em que ela some; (c) a cor da Ladina (verde) e a do Arqueiro (capa azul, roupa bege) já diferem.
- Correção do PI na mesma sessão: o herói Ranger é **homem — "Arqueiro"**; os documentos e o `ranger.tres` o chamavam no feminino.

## Decisão

1. **Dois heróis novos num marco próprio, MVP2.6**, depois do [GATE] do MVP2 e antes do MVP3: **F58 Ladina** → **F59 Engenheiro**. Um `[INFRA]` para o roadmap público aceitar o marco `MVP2.6` vem antes do F58 (como o #100 fez para o MVP2.5).
2. **Ladina** — KayKit Adventurers 2.0 `Rogue_Hooded` (gratuito), **cor original do pack** (sem textura alternativa); classe **Algoz** (dano alto, frágil — aqui à distância curta). Kit: básico **Virote** (besta), Q **Rajada em Leque**, E **Bomba de Fumaça**, R **Emboscada**. Números: GDB §4.5.
3. **Engenheiro** — KayKit Adventurers 2.0 **Extra** `Engineer`; **classe nova Engenheiro** (dano em curta distância + controle de zona por estrutura). Kit: básico **Bacamarte**, Q **Garra Mecânica**, E **Torreta**, R **Caixa de Dinamite**. Números: GDB §4.6.
4. **Bomba de Fumaça = moita temporária.** A nuvem segue a regra do mato alto (CONVENTION §4.7): quem está dentro some para quem está fora; quem está dentro vê quem está dentro; atacar ou usar skill de dentro revela por 1,5 s. **Exceção única: lançar a própria Bomba de Fumaça não revela a Ladina.** A nuvem vale para qualquer herói que entrar nela, inclusive o adversário.
5. **Torreta indestrutível e temporária**: dura 6 s, uma por vez, acerto instantâneo (sem projétil), não é alvo de nada. Acerta **heróis e monstros** (regra geral das skills); só atira em quem o Engenheiro vê (neblina, mato e fumaça — invariante de honestidade, CONVENTION §4.6).
6. Regra do GDB §2.1 mantida para os dois: **ATK escala básico, Q e E; INT escala só o R** (e o CDR).
7. **Elmo não aparece** na Ladina (capuz) nem no Engenheiro (óculos/cabelo) — mesma exceção do ADR-0011 item 3; o elmo dá o atributo. Arma visível por herói em 3 raridades (besta e bacamarte); peitoral e botas do F48 valem com offset por herói.
8. Animações: clipes do `Rig_Medium` já usados no projeto (lista na SPEC-058/059 §5); o KayKit Character Animations (CC0, `Rig_Medium`) é a fonte de clipe que faltar, sem retarget.
9. **Nome do Ranger corrigido para "Arqueiro"** nos documentos de governança nesta data; o código (`ranger.tres` `display_name` e telas) é corrigido pelo Code num `[FIX]`.
10. Kits e números **aprovados pelo PI como proposta**, conferidos no soak de cada fatia (SPEC-058/059 §8) e ajustáveis no F30 (MVP4).

## Alternativas rejeitadas

| Alternativa | Motivo |
|---|---|
| Entrar no MVP2 antes do F19 | o gate e o soak já fecharam com 4 heróis |
| Dentro do MVP2.5 ou no início do MVP3 | PI escolheu marco próprio (MVP2.6) para não misturar herói com bloco visual ou backend |
| Torreta com HP, destrutível | mecânica nova (alvo que não é herói nem monstro, kill credit, bot que ataca estrutura); +1 fatia de risco |
| Torreta só contra heróis | PI manteve a regra geral (heróis e monstros) |
| Engenheiro como Controle ou como 2º Ranger | PI escolheu classe nova Engenheiro |
| `Rogue` sem capuz; textura alternativa do Extra | capuz dá silhueta própria; com o Arqueiro homem de capa azul, a cor original já se distingue |
| Fumaça como invisibilidade total por X s | mecânica nova; a moita temporária reusa o filtro de replicação do F32/F37 |
| Druida e `BARBARIAN_LARGE` do Extra | não pedidos |

## Consequências

- Marco novo com 2 fatias + `[INFRA]`; o MVP3 começa depois.
- **Riscos técnicos aceitos:** (a) Torreta: entidade nova criada e destruída no meio da partida, simulada no servidor e filtrada por visão para cada peer — mesmo cuidado de spawn do projétil (F14) e do filtro do F37; (b) fumaça: o `VisibilityRules` hoje só conhece moitas estáticas (caixas do grupo `tall_grass`) — passa a considerar áreas circulares temporárias; (c) Garra: primeiro **puxão** (empurrão invertido) — mesmo caminho do `knockback` do alvo, aplicado no `_rollback_tick` do próprio alvo.
- Bot passa a jogar com 6 heróis; o soak de cada fatia cobre o herói novo.
- Arte nova: 4 armas derivadas (besta e bacamarte, rara/épica), malhas de VFX (fumaça, estilhaço, destroço, garra/cabo, caixa de dinamite se o pack não tiver), 8 ícones de skill. Torreta e acessórios do Engineer vêm do Extra.
- Assets do Extra (CC0) entram no repositório como os demais KayKit; a licença do pack Extra é conferida pelo Code e registrada no `shared/assets/LICENSES.md` antes do commit.
- Classe nova no PRD §4.1 (Engenheiro); Suporte e Controle continuam no roadmap.
