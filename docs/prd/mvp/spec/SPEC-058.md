# SPEC-058 — Ladina (Algoz, besta): modelo, Virote, Rajada em Leque, Bomba de Fumaça, Emboscada, equipamento, animações, VFX e bot

**Fatia:** F58 / SPEC-058 (MVP2.6, Slice 2.6.1 — 1ª fatia do marco, depois do `[INFRA]` do roadmap) · **Issue:** (criada pelo Cowork) · **Status:** decidida pelo PI em 2026-10-13 (pop-ups: "Depois do [GATE] MVP2"; "Marco novo MVP2.6"; "Aprovar como proposto"; "Rogue_Hooded, cor original")
**ADR:** ADR-0013
**Fontes:** GDB §2, §4.5, §7.3 (números — vencem esta spec, ADR-0004) · PRD §4.1, §4.3 · CONVENTION §4.5, §4.6, §4.7 · ADR-0005, ADR-0006 item 7, ADR-0010, ADR-0011 item 3 · SPEC-048 (equipamento visível) · SPEC-053/054 (padrão de herói novo) · `game/scripts/net/hero.gd`, `hero_visual.gd`, `projectile_hero.gd`, `arrow.gd`, `concealment.gd`, `vision_director.gd` · `game/scripts/core/visibility_rules.gd`, `vision_rules.gd`, `hit_ledger.gd` · `game/scripts/vfx/*` (F41) · `art/heroes/build_ranger.py`
**Escopo:** heroína jogável completa no Game (servidor autoritativo + cliente), escolhível na seleção (F51), jogável pelo bot.

## 1. Motivo

O PI pediu um Rogue com besta (ADR-0013). A Ladina é a 2ª heroína da classe **Algoz** (dano alto, frágil), à distância curta: o dano dela é maior quanto mais perto ela chega, e a fumaça e a Emboscada são como ela chega perto.

## 2. Dados (`shared/data/heroes/rogue.tres`)

`HeroData` com `id = &"rogue"`, `display_name = "Ladina"`, atributos, crescimento, velocidade 6,3 u/s e as 4 `SkillData` do GDB §4.5. Nenhum número em código (`lint-gd`, I9). Ícones `shared/ui/icons/rogue_{basic,q,e,r}.svg`, no estilo dos existentes.

## 3. Habilidades (servidor, rollback — números no GDB §4.5)

| Skill | Comportamento | Reuso esperado |
|---|---|---|
| **Básico — Virote** | projétil 24 u/s, alcance 7 u, raio 0,3 u, 1,0 s; bloqueado pela Muralha | caminho do projétil do Arqueiro (`projectile_hero.gd`/`arrow.gd`: validação no servidor, spawn compatível com o netfox) |
| **Q — Rajada em Leque** | 3 virotes no mesmo tick, em −12°, 0° e +12° da mira; cada um para no 1º alvo; o mesmo alvo pode levar os 3 | 3 projéteis do básico, com ids determinísticos por tick |
| **E — Bomba de Fumaça** | nuvem circular r 3,0 u centrada na Ladina, 3,0 s; vale como moita (§3.1); sem dano; **lançar não revela** | regra pura nova em `scripts/core/` (área circular temporária) + filtro de replicação do F32/F37 |
| **R — Emboscada** | avança até 8 u a 24 u/s na direção mirada; para no 1º herói/monstro inimigo ou obstáculo; parando num inimigo, 1 golpe de faca; ×1,3 se oculta no tick do uso | deslocamento da Investida (F8) sem empurrão; dano pelo `HitLedger`; fórmula pura com teste GUT (ex.: `rogue_rules.gd`) |

- Toda skill acerta heróis adversários **e monstros**. Efeito em outro node pelo `HitLedger` (ADR-0001 aprendizado #5); nada de `NetworkRollback.mutate`.
- Muralha do Cavaleiro bloqueia Virote e Rajada (projéteis); a Emboscada é corpo a corpo — o escudo a trata como hoje trata dano corpo a corpo.

### 3.1 Fumaça = moita temporária (CONVENTION §4.7, GDB §7.3)

- O estado da nuvem (centro e tick de fim) é estado de gameplay da Ladina no rollback; no máximo 1 nuvem por Ladina (CD mínimo 10 s > duração 3 s).
- Enquanto a nuvem existe, o `VisibilityRules` a trata como uma moita: herói dentro some para quem está fora; quem está dentro vê quem está dentro; atacar ou usar skill de dentro revela 1,5 s. Vale para **qualquer herói**, inclusive o adversário que entra nela.
- **Exceção:** a subida da recarga do E da Ladina **não** conta como "agir" (`VisibilityRules.acted`). Q, básico e R contam normalmente.
- Monstro e bot seguem a mesma regra (invariante de honestidade, CONVENTION §4.6): monstro não mira quem está oculto na nuvem.
- A Emboscada pergunta ao servidor, no tick do uso, se a Ladina está oculta para o alvo (moita ou fumaça, sem revelação ativa) — esse é o critério do ×1,3.
- **Decisão derivada, aprovada pelo PI em 2026-10-13:** herói dentro de uma moita e de uma nuvem ao mesmo tempo conta como dentro das duas; vê e é visto por quem estiver em qualquer uma delas.

## 4. Visual do modelo e equipamento (cliente)

- Modelo `Rogue_Hooded` do **KayKit Adventurers 2.0** (CC0, gratuito), **cor original**. Montado como o Arqueiro: script `art/heroes/build_rogue.py` (padrão do `build_ranger.py`) monta `art/heroes/rogue.blend` e exporta `shared/assets/rrb/heroes/rogue.glb` com a besta, a faca e as ações do §5. Entrada no `shared/assets/LICENSES.md`. Escala igual à do Arqueiro, conferida na `_alignment.tscn`.
- **Mãos:** besta de 1 mão na mão direita (`handslot.r`); faca na esquerda (`handslot.l`), sempre visíveis. O Code confirma na cena de alinhamento que o `1H_Ranged_Shoot` aponta a besta para a frente; se a mão certa for a esquerda, inverte (decisão do Code, registrada na PR).
- **Arma visível (SPEC-048):** comum = besta de 1 mão do pack como vem (arquivo em `Assets/gltf/` do pack; nome conferido pelo Code); **rara e épica derivadas no Blender** como as do F48 (mesma forma, acabamento por raridade). A besta de 2 mãos do pack não entra.
- **Elmo não aparece** (capuz fica sempre — ADR-0013 item 7); o atributo do elmo vale. `ItemVisuals` registra a exceção como no F53/F54. Peitoral e botas do F48 com offset por herói; a capa do pack não pode atravessar o peitoral (se atravessar, o peitoral cobre — regra do F48).
- Silhueta conferida na distância da câmera do jogo ao lado do Arqueiro (ADR-0013: capuz verde × capa azul/roupa bege).

## 5. Animações (clipes do `Rig_Medium`)

Clipes já presentes no `Knight.glb` (rig idêntico — ADR-0013 contexto). Se um clipe faltar ou não ler bem na câmera, a fonte é o **KayKit Character Animations** (CC0, `Rig_Medium`), sem retarget; troca registrada na PR.

| Momento | Clipe | Laço | Observação |
|---|---|---|---|
| Parado | `Idle` | sim | |
| Correndo | `Running_A` | sim | |
| Básico | `1H_Ranged_Shoot` | não | disparo no quadro do coice |
| Q — Rajada | `1H_Ranged_Shooting` | não | velocidade ajustada para caber na janela do disparo |
| E — Fumaça | `Throw` | não | bomba solta aos pés |
| R — avanço | `Dodge_Forward` | sim (`dash`) | `dash_play_speed` para caber nos ~0,33 s |
| R — golpe | `Dualwield_Melee_Attack_Stab` | não | toca quando o avanço termina num inimigo; o `HeroVisual` ganha esse gancho (forma decidida pelo Code) |
| Atordoada | `Hit_B` | sim | |
| Morte | `Death_A` | não | |

## 6. VFX (Godot + Blender — arquitetura do F41)

Só cliente, só com `is_fresh` ou sinal do `HitLedger`/`ImpactRelay`; instâncias no `VfxPool`; números (raio, duração) lidos do `.tres`, não repetidos no VFX. Toon/outline do modelo pelo pós-import do F39; VFX sem outline.

| Momento | Godot | Blender (`art/vfx/rogue_vfx.blend` → `shared/assets/rrb/vfx/`) |
|---|---|---|
| Virote em voo | `TrailRibbon` curto verde-claro com interpolação visual desacoplada do estado de rede (padrão da flecha do F41) | `rogue_bolt.glb`: virote curto derivado da flecha do pack, 30–80 tris |
| Disparo | `VfxOneShot` de clarão pequeno na ponta da besta + 4 lascas | — |
| Impacto do virote | 6 faíscas + o flash de dano existente no alvo | — |
| Rajada | 3 rastros + 1 clarão maior | — |
| Bomba de Fumaça | bomba solta aos pés quica e estoura; 12–16 puffs em `GPUParticles3D` com malha, crescendo em 0,3 s, deriva lenta, dissolvem nos últimos 0,5 s; anel discreto no chão marcando o raio de 3,0 u. **Sem `FogVolume`** (orçamento) | `smoke_puff_a/b/c.glb` (40–80 tris, faces planas, cor pelo atlas KayKit); bomba = a do pack como vem |
| Visibilidade da nuvem | a nuvem chega ao cliente por evento discreto do servidor (caminho do `ImpactRelay`) e aparece para quem tem o centro dela dentro da visão (F37) — o estado da Ladina não serve de caminho, porque ela some do adversário dentro da nuvem; a Ladina dentro dela some para quem está fora (regra do F32). A própria Ladina dentro da nuvem tem o mesmo tratamento do próprio herói na moita (F32) | — |
| Emboscada — avanço | rastro de sombra com o `GhostVfx` do F41 (3 cópias) | — |
| Emboscada — golpe | corte em X vermelho-escuro, 0,2 s; com o bônus de ocultação, clarão roxo extra no alvo | `slash_x.glb` (2 lâminas curvas, 20–40 tris) |

## 7. Seleção e bot

- Seleção (F51): card da Ladina com dados reais do `HeroData` (atributos e as 4 skills com ícone). O protótipo (`docs/prd/telas/Seleção de Heróis/`) já tinha o slot "Ladina" — ele volta com dado real (`FORA-DE-ESCOPO.md` atualizado). Espelho permitido; herói padrão no timeout não muda (P1 Cavaleiro, P2 Arqueiro).
- Bot (`BotInput`/`bot_rules.gd`), FSM atual. Uso mínimo: básico até 7 u; Q quando o alvo está a ≤ 4 u; E quando HP < 40 % e há inimigo a ≤ 7 u (fuga); R quando disponível e alvo a ≤ 8 u. Limiares em `bot_profile.tres`, não em código. O bot adversário não vê a Ladina oculta (honestidade).

## 8. Critério de aceite

1. GUT: `rogue.tres` bate com o GDB §4.5 (atributos nível 1 e 10, cooldowns e danos por rank).
2. GUT: Rajada a 1,5 u acerta o alvo com os 3 virotes; a 6,5 u, com 1; Muralha bloqueia os 3.
3. GUT: nuvem — herói dentro não é visto de fora; dois heróis dentro se veem; lançar a fumaça não revela; básico de dentro revela 1,5 s; a nuvem some aos 3,0 s.
4. GUT: Emboscada para no 1º inimigo e no obstáculo (rio, muro); dano com e sem o ×1,3 (oculta na moita, oculta na fumaça, revelada).
5. 2 clientes contra servidor local a 100 ms (Docker, netem): Ladina × Cavaleiro, Ladina × Arqueiro, Ladina × Bárbaro, Ladina × Bruxo, todas as skills; o cliente adversário **não recebe estado** da Ladina dentro da nuvem (contador de vazamento do `Concealment` = 0); sem `past the history limit`; 0 `Node not found`.
6. Soak: 50 partidas bot × bot headless (`tools/soak.ps1`) com a Ladina em pelo menos um dos lados em todas; nenhuma trava, todas ≤ 10 min, nunca empate.
7. Treino offline `--bot` com o bot de Ladina: usa Q/E/R (log do servidor) e completa a fase 1 sem travar (3 partidas).
8. Frame time dentro do orçamento do ADR-0006 item 7, medido contra o baseline do F38, com a Ladina equipada e a fumaça ativa.
9. Lint e CI verdes. Verificação visual do PI (modelo, animações, besta nas 3 raridades, peitoral/botas, fumaça, VFX) + screenshot e vídeo curto no roadmap.

## 9. Fora desta spec

Textura alternativa do Extra (PI escolheu a cor original); `Rogue` sem capuz; besta de 2 mãos; veneno/sangramento (dano contínuo); fumaça como invisibilidade total; passiva; ajuste de números (F30/MVP4).
