# ADR-0011 — Quatro heróis no MVP2 (Bárbaro e Bruxo de Fogo) e campos de canto com golem, lobos e baú reforçado

**Status:** aceito — 2026-10-11
**Decisor:** Rodrigo Reis (PI)
**Supera parcialmente:** PRD §1.3 (linhas "2 heróis" e "5 monstros" e a frase "nada do roadmap entra antes do M4") e D6 ("fatia 1x1 com 2 heróis"); PRD §4.1 (Algoz sai do roadmap; classe nova **Mago**); SPEC-046 §2.7 (posição da moita de lagoa) e §3 (contagens).
**Relacionados:** SPEC-053 · SPEC-054 · SPEC-055 · GDB §4.3, §4.4, §5, §6.2 · ADR-0004 · ADR-0005 · ADR-0006 · ADR-0009 · ADR-0010

## Contexto

- Pedido do PI (2026-10-11): especificar mais 2 personagens — Bruxo (fogo) e Bárbaro —, pôr mais monstros "nível 4 a 7" com baús melhorados porque "está difícil matar o boss com a arma e o nível de hoje", e colocar golem + lobo nos cantos do mapa. Referências visuais: KayKit Adventurers (Barbarian, Mage) e KayKit Skeletons Extra (Golem, Necromancer).
- O PRD (§1.3, D6) limitava a fatia vertical a 2 heróis e 5 monstros até o M4.
- Análise apresentada ao PI antes da decisão (números do GDB atual): Cavaleiro nível 5 com arma comum leva ~28 s para matar o Rei Esqueleto e morre em ~23 s (~31 s com a Muralha); o *knockback* do boss (2,5 u) é maior que o alcance do Cavaleiro (2,2 u). O boss surge aos 3:30, mas a meta do GDB (nível 8–9) só é alcançada depois de matá-lo. Mais XP e itens elevam a curva inteira (TTK da fase 2, teto de snowball).
- Os cantos livres da arena (NO e SE, SPEC-046) são a curva dos corredores TOP/BOT; a diagonal entre a lagoa e a curva tem folga máxima de 2 u por causa da lagoa (raio 5) e da moita de lagoa.

## Decisão

1. **Dois heróis novos entram no MVP2**, antes do F19: **Bárbaro** (classe **Algoz**, KayKit Adventurers 1.0 `Barbarian`) e **Bruxo de Fogo** (classe nova **Mago** — dano mágico em área à distância, KayKit Adventurers 1.0 `Mage`). Kits e números aprovados pelo PI como proposta, conferidos no soak (GDB §4.3, §4.4). Sem queimadura contínua: o fogo é visual + dano em área.
2. Mantida a regra do GDB §2.1: **ATK escala básico, Q e E; INT escala só o R** (e o CDR) — também para o Bruxo.
3. **Elmo não aparece no Bárbaro nem no Bruxo:** capuz de urso e chapéu ficam sempre; o elmo dá o atributo sem peça visível (exceção ao F48). Arma visível por herói (machado e cajado em 3 raridades); peitoral e botas do F48 valem.
4. **Boss não muda** (decisão do PI: "só campos e baús novos"). O caminho para matá-lo é mais XP e item antes das 3:30.
5. **Campos de canto (2):** no bolso da curva TOP (NO) e BOT (SE), sobre a diagonal, em `(−27,5, −27,5)` e `(27,5, 27,5)`; alcançáveis pelos dois times sem ponte. Cada um: **1 Golem de canto** (mesmo modelo e números do Golem de Pedra, **sem item**), **2 Lobos** (monstro novo, T2) e **2 Baús Reforçados**. Respawn 90 s na fase 1 (regra do GDB §5).
6. **Lobo** é arte própria no Blender (ADR-0005), estilo KayKit; o golem reusa `rrb/monsters/golem.glb` (CC-BY, já creditado). O Skeletons Extra (pago) não é comprado.
7. **Baú Reforçado** (tipo novo): 50 % Item Raro, 50 % Item Comum; sem épico, sem ouro/consumível. O centro continua a melhor fonte de loot.
8. **Aggro:** Golem de canto 4 u; Lobos 3 u (não puxam quem passa no corredor). Leash 10 u.
9. **Moita de lagoa** muda de `(∓30, ∓26)` para `(∓19, ∓29)` para liberar o bolso; o mato continua com 6 moitas.
10. **Ordem no MVP2:** … → F50 → **F53 (Bárbaro) → F54 (Bruxo) → F55 (campos de canto)** → F51 → F52 → F19 → [GATE]. A seleção (F51) já nasce com 4 heróis reais.
11. **Necromante** (Skeletons Extra) não é usado agora.

## Alternativas rejeitadas

| Alternativa | Motivo |
|---|---|
| Bloco novo depois do [GATE] do MVP2 (recomendação apresentada) | PI quer o soak e o gate já com 4 heróis |
| Ajustar o boss (knockback ≤ alcance melee, HP) | PI escolheu só campos e baús novos |
| Bárbaro Lutador/bruiser; Bruxo Controle | PI escolheu Algoz e Mago |
| Queimadura (dano contínuo) no Q do Bruxo | mecânica nova no rollback; PI aprovou sem |
| Elmo esconde chapéu/capuz; elmos próprios por herói | PI preserva a silhueta dos dois |
| Campo sobre o corredor TOP/BOT | quebra o corredor livre da SPEC-046 §2.3 |
| Remover a moita de lagoa; campo fora da diagonal (−15, −25,6) | PI escolheu mover a moita |
| Golem de canto igual ao do centro (raro garantido) | competiria com o centro |
| Baú reforçado = raro do centro / raro garantido | PI escolheu o intermediário 50/50 |
| Comprar KayKit Skeletons Extra (Golem/Necromante) | PI escolheu golem atual + lobo no Blender |

## Consequências

- **Gate do MVP2 atrasa** três fatias. O soak do F19 passa a cobrir 4 heróis (10 confrontos com espelho); o bot (F12/F19) tem de jogar com os 4.
- **Risco aceito pelo PI:** o boss continua com knockback 2,5 u contra alcance 2,2 u do Cavaleiro; mais XP/itens elevam a curva de poder (TTK da fase 2 de 2,8–4,0 s e teto de snowball < 75 %, GDB §1.1). Medição: nível do bot aos 3:30 antes e depois do F55 (SPEC-055 §7) e o soak do F19; ajuste fica com o F30 (MVP4) se o PI pedir antes.
- Bestiário passa a 7 monstros; mapa a 35 monstros e 28 baús.
- Arte nova: lobo com rig e animação (o item de arte mais caro do bloco), baú reforçado, 4 armas derivadas (machado e cajado raros/épicos), VFX de fogo e do Bárbaro, 8 ícones de skill.
- Os cantos ficam fora da zona desde 5:00 (r ≈ 38,9 u > 35 u); monstros vivos ali seguem a regra da fase 2 (ficam, sem respawn).
