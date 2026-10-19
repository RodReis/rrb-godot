# SPEC-059 — Engenheiro (classe Engenheiro): modelo, Bacamarte, Garra Mecânica, Torreta, Caixa de Dinamite, equipamento, animações, VFX e bot

**Fatia:** F59 / SPEC-059 (MVP2.6, Slice 2.6.2 — depois do F58) · **Issue:** #163 · **Status:** decidida pelo PI em 2026-10-13 (pop-ups: "Depois do [GATE] MVP2"; "Tenho o Extra 2.0"; "Indestrutível, 6 s"; "Aprovar como proposto"; "Classe nova Engenheiro"; "Marco novo MVP2.6"; "Heróis e monstros") · **Entrega:** `finalizado` em 2026-10-15 (#163)
**ADR:** ADR-0013
**Fontes:** GDB §2, §4.6, §7.3 (números — vencem esta spec, ADR-0004) · PRD §4.1, §4.3 · CONVENTION §4.5–§4.7, §4.9 · ADR-0005, ADR-0006 item 7, ADR-0010, ADR-0011 item 3 · SPEC-048 · SPEC-054 (empurrão do Anel, marcação do Meteoro) · SPEC-058 (área temporária, eventos de VFX visíveis por visão) · `game/scripts/net/hero.gd`, `knight.gd`, `fire_wizard.gd`, `projectile_hero.gd`, `concealment.gd`, `vision_director.gd`, `impact_relay.gd` · `game/scripts/core/visibility_rules.gd`, `vision_rules.gd`, `hit_ledger.gd` · `game/scripts/vfx/*` (F41, F54)
**Escopo:** herói jogável completo no Game, escolhível na seleção (F51), jogável pelo bot.

## 1. Motivo

O PI pediu o Engineer do KayKit (ADR-0013). Ele cria a classe **Engenheiro**: dano em cone de perto e controle de área por estrutura (Torreta) e explosivo (Dinamite). A Garra é o que traz o adversário para o cone do bacamarte.

## 2. Dados (`shared/data/heroes/engineer.tres`)

`HeroData` com `id = &"engineer"`, `display_name = "Engenheiro"`, números do GDB §4.6, velocidade 5,9 u/s. Ícones `shared/ui/icons/engineer_{basic,q,e,r}.svg`.

## 3. Habilidades (servidor, rollback — números no GDB §4.6)

| Skill | Comportamento | Reuso esperado |
|---|---|---|
| **Básico — Bacamarte** | cone 40°, raio 4,5 u, instantâneo, 1,2 s; acerta todos os inimigos no cone | mesmo caminho do básico em arco do Cavaleiro/Bárbaro, com `arc_degrees`/`attack_range` do `.tres` |
| **Q — Garra Mecânica** | projétil 20 u/s, 7 u, raio 0,4 u; para no 1º inimigo; **herói** atingido é puxado em 0,3 s até 2,0 u do Engenheiro; monstro e boss só tomam dano; bloqueada pela Muralha | projétil do F14; puxão = `knockback_ticks`/`knockback_velocity` do alvo com direção para o ponto do Engenheiro **no tick do acerto**, aplicado no `_rollback_tick` do próprio alvo; `move_and_slide` para no obstáculo |
| **E — Torreta** | instala no ponto mirado até 3,0 u (para no obstáculo); 6,0 s; a cada 0,75 s acerta o inimigo mais próximo a ≤ 7,0 u **que o Engenheiro vê**; acerto instantâneo; indestrutível; sem colisão; uma por vez | §3.1 |
| **R — Caixa de Dinamite** | caixa no ponto mirado até 6,0 u; explode 1,5 s depois, r 4,5 u, dano único e empurrão radial de 3,0 u | marcação e atraso do Meteoro (F54), empurrão do Anel de Fogo (F54) |

- Toda skill acerta heróis adversários **e monstros** (decisão do PI, inclusive a Torreta). Monstro atingido persegue o Engenheiro (dono do dano), como hoje.
- Efeito em outro node pelo `HitLedger`; nada de `NetworkRollback.mutate`.
- Alvo invulnerável (Rolamento do Arqueiro) recebe a Garra e a Dinamite pela **mesma regra que a Investida e o Anel de Fogo usam hoje** com alvo invulnerável — sem regra nova.
- Muralha: bloqueia a Garra (projétil); Bacamarte, Torreta e Dinamite não são projéteis — o escudo os trata como hoje trata dano que não é projétil.

### 3.1 Torreta

- **Recomendação de implementação:** a Torreta é **estado do Engenheiro** no rollback (posição, tick de fim, tick do próximo disparo), não um node novo de rollback — some o problema de spawn no netfox. O Code pode escolher outra forma se encontrar motivo concreto; registra na PR.
- **Alvo:** a cada disparo, o inimigo (herói ou monstro) mais próximo da Torreta a ≤ 7,0 u que o Engenheiro vê pelas regras do GDB §7.3 (raio de visão 12 u a partir do Engenheiro, mato, fumaça). Sem alvo válido, o disparo não acontece (não acumula).
- **Consequência derivada, aprovada pelo PI em 2026-10-13:** a Torreta não dá visão própria; se o Engenheiro se afasta e deixa de ver o alvo, ela para de atirar nele.
- Disparo da Torreta **não** revela o Engenheiro na moita (não é ação dele). Instalar a Torreta é usar skill: revela, como qualquer skill.
- Nova Torreta substitui a anterior na hora.
- **Visual para o adversário:** a Torreta e os disparos dela chegam ao cliente por evento discreto do servidor (o mesmo caminho do `ImpactRelay`), só para quem tem a Torreta dentro da visão (F37) — o estado do Engenheiro não pode ser o caminho, porque ele some do adversário quando está oculto e a Torreta não.

## 4. Visual do modelo e equipamento (cliente)

- Modelo `Engineer` do **KayKit Adventurers 2.0 Extra** (CC0, tier pago do PI). O Code confere a licença do Extra na pasta do pack (`C:\Desenv\engine\Character\`) e registra no `shared/assets/LICENSES.md` antes do commit. Montado como o Arqueiro: `art/heroes/build_engineer.py` → `art/heroes/engineer.blend` → `shared/assets/rrb/heroes/engineer.glb`, com o bacamarte e as ações do §5. Mochila, óculos e ferramentas fixas ficam como vêm. Escala igual à dos outros heróis, conferida na `_alignment.tscn`.
- **Torreta:** malha do pack Extra como vem, em `shared/assets/kaykit/`; se o pack separa base e cabeça, só a cabeça gira; se não, gira o conjunto no eixo Y (decisão do Code). Orçamento de prop (50–800 tris) conferido; se passar, o Code reduz no Blender.
- **Arma visível (SPEC-048):** comum = bacamarte do pack como vem, nas duas mãos (`handslot.r`); **rara e épica derivadas no Blender** (mesma forma, acabamento por raridade).
- **Elmo não aparece** (óculos e cabelo ficam — ADR-0013 item 7); o atributo vale; `ItemVisuals` registra a exceção. Peitoral e botas do F48 com offset; o peitoral não pode esconder nem atravessar a mochila.

## 5. Animações (clipes do `Rig_Medium`)

Clipes do `Knight.glb` (rig idêntico). Clipe que faltar ou não ler bem na câmera vem do **KayKit Character Animations** (CC0, `Rig_Medium`) — a categoria "Tools" (trabalhar/martelar) é a candidata para instalar a Torreta; troca registrada na PR.

| Momento | Clipe | Laço | Observação |
|---|---|---|---|
| Parado | `Idle` | sim | |
| Correndo | `Running_A` | sim | |
| Básico | `2H_Ranged_Shoot` | não | coice do bacamarte |
| Q — Garra | `Spellcast_Shoot` | não | braço à frente lançando a garra |
| E — Torreta | `Interact` | não | ou clipe de "Tools" do Character Animations |
| R — Dinamite | `Throw` | não | arremesso em arco |
| Atordoado | `Hit_B` | sim | |
| Morte | `Death_A` | não | |
| Alvo puxado pela Garra | (do alvo) `Hit_B` durante os 0,3 s | sim | vale para qualquer herói puxado |

## 6. VFX (Godot + Blender — arquitetura do F41)

Só cliente, só com `is_fresh` ou evento do `HitLedger`/`ImpactRelay`; no `VfxPool`; raios e tempos lidos do `.tres`. VFX sem outline.

| Momento | Godot | Blender (`art/vfx/engineer_vfx.blend` → `shared/assets/rrb/vfx/`) |
|---|---|---|
| Bacamarte | clarão de boca + 10 estilhaços em leque cobrindo o cone 40°/4,5 u (mostra a área) + 2 puffs de fumaça no cano | `muzzle_star.glb` (2 quads cruzados), `shrapnel.glb` (10–20 tris); puffs = `smoke_puff_*` do F58 |
| Garra — voo | malha da garra + cabo fino esticado entre a mão e a garra, atualizado por quadro no cliente (sem física) | `claw_hook.glb` (60–150 tris), derivado da garra-ferramenta do pack |
| Garra — acerto e puxão | faíscas metálicas; o cabo encurta junto com o alvo | — |
| Torreta — instalação | pop de escala 0→1 em 0,25 s + 4 puffs de poeira | — |
| Torreta — disparo | cano gira para o ponto do disparo; traçante reto 0,08 s do cano ao alvo + clarão de boca | — |
| Torreta — fim | encolhe em 0,25 s + puff | — |
| Dinamite — arremesso | caixa voa em arco da mão ao ponto em 0,4 s (só visual; o servidor já posicionou) | caixa = a do pack como vem; se não houver caixa de dinamite utilizável, `dynamite_crate.glb` (≤ 300 tris) |
| Dinamite — pavio | faíscas no pavio, piscar acelerando até a explosão; anel vermelho de raio 4,5 u crescendo em 1,5 s (shader de marcação do Meteoro, cor por parâmetro) | — |
| Dinamite — explosão | clarão + bola de fogo laranja (`FireBurstVfx` do F54 com parâmetros), anel de choque no chão, 8–12 destroços de madeira; tremor de câmera só se já existir no projeto | `debris_wood_a/b.glb` (20–60 tris) |

## 7. Seleção e bot

- Seleção (F51): card do Engenheiro com dados reais (atributos, 4 skills com ícone). Espelho permitido; padrão do timeout não muda.
- Bot: básico com alvo a ≤ 4,5 u; Q com alvo entre 4,5 u e 7 u; E com inimigo (herói ou monstro sendo farmado) a ≤ 7 u, mirando o ponto entre ele e o alvo; R com alvo a ≤ 6 u, mirando a posição atual. Limiares em `bot_profile.tres`.

## 8. Critério de aceite

1. GUT: `engineer.tres` bate com o GDB §4.6 (nível 1 e 10, cooldowns, danos por rank).
2. GUT: Bacamarte acerta todos no cone 40°/4,5 u e ninguém fora; Garra puxa herói até 2,0 u e para no rio/muro; monstro só toma dano; Muralha bloqueia a Garra.
3. GUT: Torreta dispara 8 vezes em 6,0 s com alvo no alcance; não dispara em herói oculto (moita, fumaça) nem fora da visão do Engenheiro; nova Torreta encerra a anterior; disparo não revela o Engenheiro.
4. GUT: Dinamite explode exatamente 1,5 s depois, acerta só quem está no raio 4,5 u naquele tick e empurra 3,0 u parando no obstáculo.
5. 2 clientes contra servidor local a 100 ms (Docker, netem): Engenheiro × cada um dos outros 5 heróis, todas as skills; Torreta visível para o adversário só dentro da visão dele; sem `past the history limit`; 0 `Node not found`; projéteis sem `Reference tick missing` acima do medido no F14.
6. Soak: 50 partidas bot × bot headless (`tools/soak.ps1`) com o Engenheiro em pelo menos um dos lados em todas; nenhuma trava, todas ≤ 10 min, nunca empate.
7. Treino offline `--bot` com o bot de Engenheiro: usa Q/E/R (log) e completa a fase 1 sem travar (3 partidas).
8. Frame time dentro do orçamento do ADR-0006 item 7 com Torreta disparando e Dinamite explodindo.
9. Lint e CI verdes. Verificação visual do PI (modelo, animações, bacamarte nas 3 raridades, Torreta, Garra com cabo, Dinamite, VFX) + screenshot e vídeo curto no roadmap.

## 9. Fora desta spec

Torreta com HP/destrutível e Torreta com visão própria (ADR-0013); textura alternativa do Extra; Druida e `BARBARIAN_LARGE`; Garra puxando monstro; dano contínuo; ajuste de números (F30/MVP4).
