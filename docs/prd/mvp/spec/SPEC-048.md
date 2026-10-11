# SPEC-048 — Equipamento visível: armas e armaduras no herói 3D e ícones dos itens

**Fatia:** F48 / SPEC-048 (MVP2, Slice 2.14) · **Issue:** #121 · **Status:** decidida pelo PI em 2026-10-11 (pop-up: "Arma + armadura modeladas no Blender agora")
**ADR:** ADR-0010 (equipamento visível no herói; ciclo dia/noite)
**Fontes:** GDB §6.1 · ADR-0005 (pipeline Blender) · ADR-0006 (toon/outline por pós-import) · PATTERNS P6 · `DEBITO.md` DS-06 · `game/scripts/net/hero_visual.gd` · `game/scenes/heroes/knight.tscn`, `ranger.tscn` · `shared/resources/item_data.gd`, `item_catalog.gd` · `shared/ui/components/slot_item.gd`
**Escopo:** só cliente e arte. Servidor, rollback, regras e números não mudam.

## 1. Motivo

O PI quer ver o equipamento no herói e nos baús. O KayKit Adventurers (versão gratuita no repo) traz armas, mas **nenhuma peça de elmo, peitoral ou bota** — os personagens têm roupa fixa. Armadura visível é arte própria no Blender (ADR-0005), produzida pelo Claude via Blender MCP; o PI verifica.

## 2. Inventário de arte

| Grupo | Peças base (forma) | Variantes de raridade | Total de malhas |
|---|---|---|---|
| Arma do Cavaleiro | espada (comum = `1H_Sword` do pack, como vem) | rara e épica derivadas no Blender (gema/fio colorido; guarda dourada + gema) | 2 novas |
| Arma da Arqueira | arco (comum = arco atual do `ranger.glb`) | rara e épica derivadas | 2 novas |
| Conjunto Guarda (placa de metal) | elmo, peitoral (com ombreiras), par de botas | comum / rara / épica | 9 |
| Conjunto Caçador (couro/capuz) | elmo, peitoral, par de botas | comum / rara / épica | 9 |

- **Raridade = mesma forma, acabamento diferente:** comum liso; raro com friso na cor de raridade; épico com friso dourado e detalhe na cor épica. Cores de raridade dos tokens (P6), via atlas KayKit — sem textura nova.
- Estilo `CLAUDE.md` (Assets 3D): faces planas, sem subdivisão nem bevel (bevel do ADR-0006 vale só para cenário). Orçamento: 50–800 triângulos por peça. Toon/outline pelo pós-import do F39.
- Fonte em `art/heroes/equipment/`; export `.glb` em `shared/assets/rrb/equipment/`.

## 3. Encaixe no herói

- Peças **rígidas** presas a ossos por `BoneAttachment3D` (elmo → cabeça; peitoral → tronco; botas → cada pé/canela). Sem skinning novo.
- O Cavaleiro e a Arqueira usam o rig do KayKit; o Code confirma os nomes de osso nos dois `.glb` antes de modelar. Se diferirem, um offset por herói num Resource.
- Peça do pack que colide com a armadura (ex.: capacete do Cavaleiro, capuz da Arqueira) é escondida quando o slot correspondente está equipado, se for malha separada; se não for, a peça nova cobre a original sem atravessar na distância da câmera do jogo.
- Clipping nas animações (`Idle`, `Running_A/B`, ataques, `Death_A`): aceito se invisível na câmera do jogo (14 u, 45°) — critério visual do PI.

## 4. Troca no herói (cliente)

- `HeroVisual` lê `equipment` (Vector4i do estado de rollback, já replicado) e, quando muda, mostra/esconde as peças. Só lê estado (como hoje).
- Mapeamento item → peça num Resource em `shared/data/` (`ItemVisuals`): `id` do item → cena da peça **por herói** (arma difere por herói; armadura é a mesma cena com offset por herói).
- Neblina (F37) e mato alto (F32): sem regra nova — o herói não replicado não aparece, com ou sem peças.
- Tela de seleção de heróis e galeria: herói base, sem itens.

## 5. Ícones

- Um ícone por item do catálogo; para a arma, um por herói. Renderizados no Blender a partir das próprias peças (mesma luz e ângulo), exportados em `shared/ui/icons/items/`.
- `SlotItem` passa a mostrar o ícone (fecha `DEBITO.md` DS-06). Com isso, o card de oferta do baú (F47), a HUD de equipamento e o tooltip ganham o ícone sem mudança extra.

## 6. Critério de aceite

1. GUT: todo item do `ItemCatalog` tem peça para os dois heróis no `ItemVisuals` e ícone existente (teste falha se faltar).
2. GUT: `HeroVisual` com `equipment` trocado mostra só as peças dos slots equipados.
3. 2 clientes contra servidor local: troca de item aparece no herói nos dois clientes; sem `past the history limit`; servidor headless sem nada novo carregado.
4. Frame time dentro do orçamento do ADR-0006 item 7, medido contra o baseline do F38, com os dois heróis com 4 peças.
5. Lint e CI verdes. Verificação visual do PI: as 21 combinações de item nos dois heróis (cena de alinhamento, PRD §11) + screenshot no roadmap.

## 7. Fora desta spec

Escudo do Cavaleiro como item; VFX de passiva (Fúria); peças com skinning; pintura por jogador; skins (monetização); versão Extra do KayKit.
