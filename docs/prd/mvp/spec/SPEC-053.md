# SPEC-053 — Bárbaro (Algoz): modelo, ataque básico, Salto Brutal, Rodopio, Execução, bot e VFX

**Fatia:** F53 / SPEC-053 (MVP2, Slice 2.19 — depois do F50, antes do F54) · **Issue:** #135 · **Status:** decidida pelo PI em 2026-10-11 (pop-ups: "Dentro do MVP2, antes do F19"; "Bárbaro Algoz"; "Aprovar como proposto"; "Chapéu/capuz fica sempre"; "Antes do F51") · **Entrega:** `finalizado` em 2026-10-12 (#135)
**ADR:** ADR-0011
**Fontes:** GDB §2, §4.3 (números — vencem esta spec, ADR-0004) · PRD §4.1, §4.3 · ADR-0005, ADR-0006 item 7, ADR-0010 · SPEC-048 (equipamento visível) · `shared/resources/hero_data.gd`, `skill_data.gd` · `shared/data/heroes/knight.tres` · `game/scenes/heroes/knight.tscn` · `game/scripts/net/hero.gd`, `hero_visual.gd` · `game/scripts/ai/bot_input.gd`, `game/scripts/core/bot_rules.gd` · `game/scripts/core/pick_rules.gd`
**Escopo:** herói jogável completo no Game (servidor autoritativo + cliente), escolhível no pick do F15, jogável pelo bot. Seleção fiel ao protótipo é do F51.

## 1. Motivo

O PI quer mais heróis na partida (ADR-0011). O Bárbaro preenche a classe **Algoz** do PRD §4.1: dano alto corpo a corpo, frágil.

## 2. Dados (`shared/data/heroes/barbarian.tres`)

`HeroData` com `id = &"barbarian"`, `display_name = "Bárbaro"`, atributos, crescimento, velocidade 6,0 u/s e as 4 `SkillData` do GDB §4.3. Nenhum número em código (`lint-gd`, I9). Ícones das 4 skills em `shared/ui/icons/barbarian_{basic,q,e,r}.svg`, no estilo dos do Cavaleiro.

## 3. Habilidades (servidor, rollback — números no GDB §4.3)

| Skill | Comportamento | Reuso esperado |
|---|---|---|
| **Básico — Machado** | cone 90°, raio 2,4 u, 0,9 s | mesmo caminho do básico do Cavaleiro (arco), com `arc_degrees`/`attack_range` do `.tres` |
| **Q — Salto Brutal** | desloca até 7 u ao ponto mirado (`cast_range`) em 0,45 s; **para no primeiro obstáculo** (rio, muro, pilar, borda — o rio só se cruza pelas pontes, SPEC-046 §6 item 2); dano em área de raio 2,5 u na aterrissagem, uma vez por alvo | deslocamento como a Investida (F8), sem empurrão; dano em área pelo `HitLedger` |
| **E — Rodopio** | 3 pulsos em 1,5 s (`pulse_count`, `pulse_interval`), raio 2,5 u em volta do Bárbaro; anda normalmente; básico bloqueado durante o giro | pulsos como a Chuva de Flechas (F14), centrados no próprio herói |
| **R — Execução** | golpe frontal único, cone 60°, raio 2,5 u; dano = base + 1,0 INT + 0,5 ATK + 25 % do HP faltante do alvo, calculado antes da mitigação por DEF | fórmula pura nova em `scripts/core/` (ex.: `barbarian_rules.gd`) com teste GUT |

- Toda skill acerta heróis adversários **e monstros** (como as dos heróis atuais). A Execução usa o HP faltante do alvo, seja herói ou monstro.
- Efeito em outro node pelo `HitLedger` (ADR-0001 aprendizado #5); nada de `NetworkRollback.mutate`.
- Muralha do Cavaleiro: Machado, Salto, Rodopio e Execução não são projéteis; a Muralha os trata como trata qualquer dano corpo a corpo hoje (escudo absorvente, GDB §4.1) — sem regra nova.

## 4. Visual (cliente)

- Modelo `Barbarian.glb` do **KayKit Adventurers 1.0** (CC0, `github.com/KayKit-Game-Assets/KayKit-Character-Pack-Adventures-1.0`), como vem, em `shared/assets/kaykit/adventurers/`; entrada no `shared/assets/LICENSES.md`. Escala 0,78 (mesma do Knight; conferir em `_alignment.tscn`).
- O Code confirma que o rig e as animações do `Barbarian.glb` batem com os do `Knight.glb` (23 ossos, mesmos nomes) antes de reusar o `HeroVisual`; se faltar animação, monta como foi feito no Arqueiro (`art/heroes/build_ranger.py`).
- Animações mínimas: parado, correndo, básico, salto (Q), giro (E), Execução (R), dano, morte.
- **Equipamento (SPEC-048, ADR-0011 item 3):** arma visível = machado — comum = `1H_Axe` (ou `2H_Axe`, à escolha do Code pela leitura na câmera) do pack como vem; rara e épica derivadas no Blender como as do F48; peitoral e botas do F48 com offset por herói. **Elmo não aparece** (capuz de urso fica sempre); o atributo do elmo vale normalmente. `ItemVisuals` registra a exceção e o teste do F48 passa a aceitar "sem peça de elmo" para este herói.
- VFX (arquitetura do F41: pool, só cliente, só com `is_fresh`/sinal do `HitLedger`): rastro do machado, impacto do Salto, giro do Rodopio, golpe da Execução. Toon/outline pelo pós-import do F39.

## 5. Pick e bot

- `PickRules`/seleção do F15: Bárbaro escolhível; espelho permitido; herói padrão no timeout não muda (P1 Cavaleiro, P2 Arqueiro).
- Bot (`BotInput`/`bot_rules.gd`): joga de Bárbaro com a FSM atual. Uso mínimo de skills: Q quando o alvo está a ≤ 7 u e fora do alcance do básico; E quando há inimigo a ≤ 2,5 u; R quando disponível e alvo a ≤ 2,5 u. Limiares em `bot_profile.tres`, não em código.

## 6. Critério de aceite

1. GUT: `barbarian.tres` bate com o GDB §4.3 (atributos nível 1 e nível 10, cooldowns e danos por rank).
2. GUT: fórmula da Execução (base + INT + ATK + 25 % do HP faltante) em casos de HP cheio, metade e 10 %.
3. GUT/integração: Salto contra o rio e contra um muro para no obstáculo (0 travessias); Rodopio aplica exatamente 3 pulsos por alvo; básico bloqueado durante o giro.
4. 2 clientes contra servidor local a 100 ms (Docker, netem): Bárbaro × Cavaleiro e Bárbaro × Arqueiro, todas as skills; sem `past the history limit`; 0 `Node not found`.
5. Treino offline `--bot` com o bot de Bárbaro: o bot usa Q/E/R (log do servidor) e completa a fase 1 sem travar (3 partidas).
6. Frame time dentro do orçamento do ADR-0006 item 7, medido contra o baseline do F38, com o Bárbaro equipado e os VFX ativos.
7. Lint e CI verdes. Verificação visual do PI (modelo, animações, machado nas 3 raridades, peitoral/botas, VFX) + screenshot no roadmap.

## 7. Fora desta spec

Tela de seleção fiel ao protótipo (F51); números de balanceamento além do GDB (ajuste no F30/MVP4); passiva; skins; Bárbaro da versão Extra do KayKit; escudo/caneca do pack como item.
