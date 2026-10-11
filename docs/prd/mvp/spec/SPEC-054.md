# SPEC-054 — Bruxo de Fogo (Mago): modelo, Bola de Fogo, Explosão de Chamas, Anel de Fogo, Meteoro, bot e VFX

**Fatia:** F54 / SPEC-054 (MVP2, Slice 2.20 — depois do F53, antes do F55) · **Issue:** #136 · **Status:** decidida pelo PI em 2026-10-11 (pop-ups: "Dentro do MVP2, antes do F19"; "Bruxo Mago"; "Aprovar como proposto" — sem queimadura; "Chapéu/capuz fica sempre"; "Antes do F51")
**ADR:** ADR-0011
**Fontes:** GDB §2, §4.4 (números — vencem esta spec, ADR-0004) · PRD §4.1, §4.3 · ADR-0005, ADR-0006 item 7, ADR-0010 · SPEC-048 · SPEC-053 (mesmo padrão de herói novo) · `game/scripts/net/arrow.gd` · `game/scripts/core/ranger_rules.gd` · `shared/data/heroes/ranger.tres`
**Escopo:** herói jogável completo no Game, escolhível no pick, jogável pelo bot. Seleção fiel ao protótipo é do F51.

## 1. Motivo

O PI quer um Bruxo de fogo (ADR-0011). Ele cria a classe **Mago** (dano mágico em área à distância, frágil). Regra do GDB §2.1 mantida: ATK escala básico, Q e E; INT escala só o R.

## 2. Dados (`shared/data/heroes/fire_wizard.tres`)

`HeroData` com `id = &"fire_wizard"`, `display_name = "Bruxo de Fogo"`, números do GDB §4.4, velocidade 6,0 u/s. Ícones `shared/ui/icons/fire_wizard_{basic,q,e,r}.svg`.

## 3. Habilidades (servidor, rollback — números no GDB §4.4)

| Skill | Comportamento | Reuso esperado |
|---|---|---|
| **Básico — Bola de Fogo** | projétil 16 u/s, alcance 8 u, raio 0,4 u, 1,0 s; bloqueado pela Muralha | caminho do projétil da Arqueira (`arrow.gd`, validação no servidor, pooling compatível com o spawn do netfox) |
| **Q — Explosão de Chamas** | projétil 16 u/s, alcance 9 u; explode no primeiro alvo atingido (herói ou monstro), na Muralha ou no fim do alcance; dano em área de raio 2,0 u, uma vez por alvo | mesmo projétil + área no ponto de explosão |
| **E — Anel de Fogo** | área instantânea de raio 3,0 u em volta do Bruxo; empurra os atingidos 2,0 u para fora (radial) | empurrão como a Investida (`knockback_ticks`/`knockback_velocity` do alvo, aplicado no `_rollback_tick` do próprio alvo) |
| **R — Meteoro** | marca área de raio 3,5 u em até 9 u (`cast_range`); cai 1,0 s depois; dano único em área | marcação e atraso como a Chuva de Flechas (F14), com 1 pulso; marcação visível pelas mesmas regras de visão da Chuva |

- Sem queimadura nem dano contínuo (decisão do PI).
- Toda skill acerta heróis adversários **e monstros**. Efeito em outro node pelo `HitLedger`.
- O empurrão do Anel respeita a colisão (não joga ninguém para dentro do rio ou de muro: `move_and_slide` para no obstáculo).

## 4. Visual (cliente)

- Modelo `Mage.glb` do **KayKit Adventurers 1.0** (CC0), como vem, em `shared/assets/kaykit/adventurers/`; entrada no `LICENSES.md`. Escala 0,78. Rig e animações conferidos contra o `Knight.glb` (como no F53 §4).
- Animações mínimas: parado, correndo, básico (lançar), Q, E (conjuração em volta), R (conjuração longa), dano, morte.
- **Equipamento:** arma visível = cajado — comum = `Staff` do pack como vem; rara e épica derivadas no Blender. Peitoral e botas do F48 com offset. **Elmo não aparece** (chapéu fica sempre); `ItemVisuals` registra a exceção como no F53.
- VFX de fogo (arquitetura do F41): bola de fogo com rastro, explosão do Q, anel do E, marcação + queda + impacto do Meteoro. Partículas no pool; luz pontual só se couber no orçamento do ADR-0006 item 7. Toon/outline pelo pós-import do F39.

## 5. Pick e bot

- Bruxo escolhível no pick do F15; espelho permitido; padrão do timeout não muda.
- Bot: Q quando o alvo está a ≤ 9 u; E quando há inimigo a ≤ 3 u; R quando disponível e alvo a ≤ 9 u, mirando a posição atual do alvo. Limiares em `bot_profile.tres`.

## 6. Critério de aceite

1. GUT: `fire_wizard.tres` bate com o GDB §4.4 (nível 1 e 10, cooldowns, danos por rank).
2. GUT/integração: Q explode no primeiro alvo e na Muralha; dano em área atinge todos no raio 2,0 u e ninguém fora; Anel empurra 2,0 u e para no rio/muro; Meteoro cai exatamente 1,0 s depois da marcação e acerta só quem está no raio 3,5 u naquele tick.
3. 2 clientes contra servidor local a 100 ms (Docker, netem): Bruxo × Cavaleiro (Muralha bloqueando Bola de Fogo e Q), Bruxo × Arqueira, Bruxo × Bárbaro; sem `past the history limit`; 0 `Node not found`; projéteis sem `Reference tick missing` acima do medido no F14.
4. Treino offline `--bot` com o bot de Bruxo: usa Q/E/R (log) e completa a fase 1 sem travar (3 partidas).
5. Frame time dentro do orçamento do ADR-0006 item 7 com os VFX de fogo ativos.
6. Lint e CI verdes. Verificação visual do PI (modelo, animações, cajado nas 3 raridades, VFX de fogo) + screenshot e vídeo curto no roadmap.

## 7. Fora desta spec

Queimadura/dano contínuo (rejeitado pelo PI em 2026-10-11); INT escalando Q/E; Necromante (ADR-0011 item 11); seleção fiel ao protótipo (F51); ajuste de números (F30).
