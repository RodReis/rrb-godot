# SPEC-098 — Carrasco (Tanque): modelo realista do Tripo, Dor, Espinhos, Penitência, Correntes do Julgamento, animações, VFX e bot

**Fatia:** F98 / SPEC-098 (MVP4, Slice 4.11) · **Issue:** #248 (issue-pai #246; era F93) · **Status:** decidida pelo PI em 2026-10-21 (pop-ups do Cowork: "Gerei no Tripo (plano pago)"; "Herói masculino, como está"; "11º herói completo"; "Tanque"; "Carrasco"; "Só básico de herói, 15%"; "Aprovar como proposto"; "Sim, explode na hora"; "modelo novo, mais realista e moderno, nada do KayKit")
**ADR:** ADR-0032
**Fontes:** GDB §4.11 (números — vencem esta spec, ADR-0004), §2.2 · CONVENTION §4.5–§4.7 · ADR-0001 (ledger), ADR-0010, ADR-0016 (exceção visual), ADR-0027 · SPEC-074 (raiz = lentidão 100 %), SPEC-075 (passiva, lentidão no alvo), SPEC-076 (imunidade da Bênção), SPEC-053 (Execução) · `art/spike/f93/` (arte entregue)
**Escopo:** herói jogável completo no Game, escolhível na seleção (F51) e na Tela Heróis do Launcher (F71), jogável pelo bot.

## 1. Motivo

O PI gerou no Tripo pago um cavaleiro realista, com rig e animações do Mixamo, e decidiu que ele vira o 11º herói com kit próprio (ADR-0032). É o primeiro herói fora do KayKit.

## 2. Dados (`shared/data/heroes/carrasco.tres`)

`HeroData` com `id = &"carrasco"`, `display_name = "Carrasco"`, classe Tanque, números do GDB §4.11, velocidade 5,8 u/s. Ícones `shared/ui/icons/carrasco_{basic,q,e,r}.svg`; retrato 512 px para a Tela Heróis (render do modelo novo).

## 3. Habilidades (servidor, rollback — números no GDB §4.11)

| Skill | Comportamento | Reuso esperado |
|---|---|---|
| **Passiva — Couraça** | dano de **ataque básico de herói** inimigo recebido × 0,85, depois da Defesa. Servo, monstro, skill, projétil de skill e zona não contam | estado e aplicação no `_rollback_tick` do próprio Carrasco, como a Frenesi |
| **Básico — Espada** | cone 70°, 2,2 u, 1,0 s, 100 % ATK; cada acerto em herói, servo ou monstro dá **+1 Dor** | básico em arco do Cavaleiro |
| **Q — Espinhos** | golpe em cone 90°, 3,0 u: dano + lentidão 30 % por 1,5 s em todos os atingidos. Abre janela de **3,0 s** para **recast**: projétil de espinhos (20 u/s, 7 u, raio 0,4 u) que para no 1º alvo, dano sem lentidão, bloqueado pela Muralha. O cooldown conta depois do recast ou do fim da janela | arco do básico; projétil do F14; lentidão do Berserker |
| **E — Penitência** | canaliza até **2,0 s**, **imóvel** (não anda, não ataca, não usa outra skill); mitiga **40 %** do dano recebido; **+1 Dor a cada 0,5 s**; cura distribuída ao longo da canalização. Ao fim (2,0 s ou **E de novo**), explode em raio 3,0 u: dano + **raiz 1,0 s se Dor ≥ 4**, senão **lentidão 40 % por 1,5 s**; consome a Dor. **Atordoamento cancela sem explosão** (a cura já recebida fica) | raiz = lentidão 100 % (SPEC-074); zona de dano do Anel/Pântano |
| **R — Correntes do Julgamento** | projétil 24 u/s, 6 u, para no 1º **herói**, bloqueado pela Muralha: dano + **raiz** e **raio de luz de 2,5 u** fixo no ponto do acerto pela duração da raiz. Enquanto a luz existir, se o alvo estiver dentro dela com **HP < 25 %**, é **executado** (morte, kill do Carrasco). Monstro e boss: não são alvo das correntes (passa direto) | raiz do F74; morte por kill normal |

- **Dor:** máximo 6, estado do Carrasco no rollback; dura 6,0 s fora da Penitência (renova a cada ganho). Visível na HUD dele (contador simples) e como VFX no corpo.
- **Execução** é dano igual ao HP restante, que **ignora Defesa**; **imunidade a dano** (Bênção Inviolável do Paladino) bloqueia. **Imunidade a controle** (Ragnarök do Berserker) impede a raiz, mas a luz e a execução valem enquanto ele estiver dentro dela.
- Efeito em outro node pelo `HitLedger`; nada de `NetworkRollback.mutate` (ADR-0001).
- Usar skill na moita revela (§7.3), como hoje; a canalização revela no início.

## 4. Visual, rig e animações (cliente)

- **Modelo:** o do Tripo em `art/spike/f93/` (versão low, ≤ 6.000 triângulos, com rig Mixamo) vai para `art/heroes/carrasco/` (fonte `.blend`) e `shared/assets/rrb/heroes/carrasco/carrasco.glb`. **Nada do KayKit** (ADR-0032).
- Passa pela cena de alinhamento contra a cápsula de 1,8 u; silhueta conferida a 11 u.
- **Clipes** (Mixamo; os 8 de `art/spike/f93/mixamo/clips/` + os que faltarem, baixados do Mixamo no mesmo rig):

| Papel no `hero_visual.gd` | Clipe |
|---|---|
| idle, run | `Idle`, `Run` |
| básico | `Attack_Basic` |
| Q golpe / Q recast | golpe em arco / arremesso (novo) |
| E canalização (laço) / E explosão | postura de defesa ajoelhada ou `Block` em laço / `Attack_Slam` |
| R lançar correntes | arremesso ou conjuração (novo) |
| atordoado, morte | `Stunned`, `Death` |

- Espada e escudo do modelo; troca visual por item desligada (ADR-0032 item 4).
- **VFX:** espinhos (cone e projétil), aura de Penitência com contador de Dor, explosão com raízes, correntes e o raio de luz no chão (visível para os dois). Só cliente.

## 5. Bot

Usa as quatro habilidades: Q em alcance e recast quando o alvo foge; E quando toma dano em sequência ou está com HP < 60 % e o inimigo perto; R quando o alvo tem HP baixo o bastante para a execução ser provável. Parâmetros no Resource do bot (F81).

## 6. Critério de aceite

1. Testes GUT (regras puras em `scripts/core/`): Couraça só em básico de herói; ganho, teto e expiração da Dor; raiz × lentidão pela Dor; recast e cooldown do Q; cancelamento da Penitência por atordoamento; execução abaixo de 25 % dentro da luz, bloqueada pela Bênção.
2. Soak `soak.ps1 -Count 50 -Parallel 8 -Require carrasco` verde; taxa de vitória registrada para o F30.
3. Critério de netcode do ADR-0006 item 7 (3/3 conexões a 100 ms sem `past the history limit`).
4. Frame time com o Carrasco em campo, registrado em `docs/evidencias/f98/`.
5. Licenças do modelo (Tripo pago) e das animações (Mixamo) em `shared/assets/LICENSES.md`.
6. **Verificação visual do PI**: pick, kit completo contra o bot, animações e VFX; capturas e vídeo curto no roadmap.
7. CI verde.

## 7. Fora

Skins do Carrasco, troca visual de equipamento por item, levar os outros heróis ao estilo realista, mudanças na Tela Heróis além do 11º card.
