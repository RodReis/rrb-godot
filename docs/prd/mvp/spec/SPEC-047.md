# SPEC-047 — Baú: F só para item melhor, regra por herói e card de comparação na HUD

**Fatia:** F47 / SPEC-047 (MVP2, Slice 2.13) · **Issue:** #120 · **Status:** decidida pelo PI em 2026-10-11 (pop-up) · **Entrega:** `finalizado` em 2026-10-11 (#120)
**Supera:** decisão do PI de 2026-10-09 "raridade menor também vai para o F" (`ItemRules`, F10) e a troca automática por raridade maior (GDB §6.2, `CONVENTION.md` §4.3). GDB §6.2 e `CONVENTION.md` §4.3 atualizados no mesmo commit desta spec.
**Fontes:** GDB §6.1–6.2 · `CONVENTION.md` §4.3 · PATTERNS P6 · `shared/core/item_rules.gd` · `game/scripts/items/inventory.gd` · `game/scripts/world/chest.gd` · `game/scripts/ui/hero_plate.gd` · `game/scripts/ai/bot_input.gd`

## 1. Motivo

O PI relatou: segurar `F` troca uma armadura rara ou épica por uma comum. Não é bug de código — é a regra aprovada em 2026-10-09 (`ItemRules.swap_mode` manda raridade menor para `CONFIRM`). O PI decidiu que o `F` só aparece para item **melhor**, e que ver o item antes de trocar faz parte da escolha.

## 2. Regra nova (servidor, por herói)

`ItemRules.offer(current, incoming) -> bool` substitui `swap_mode` / `enum Swap`. `current` = item no mesmo slot do herói que interage (nulo = slot vazio).

| Situação | Oferta de troca (`F` segurado 0,4 s) |
|---|---|
| slot vazio | **sim** |
| raridade do novo **maior** | **sim** |
| mesma raridade, **conjunto diferente** (`set_id`, ex.: Guarda ↔ Caçador) | **sim** — escolha lateral (GDB §6.2) |
| mesma raridade, mesmo conjunto (item idêntico; inclui arma × arma) | não |
| raridade do novo **menor** | não |

- **Nada é automático.** Toque em `F` abre o baú; o item só vai para o herói com `F` segurado `swap_hold_time` (0,4 s, `match_pacing.tres`), apertado depois da abertura (como hoje).
- **Por herói, no servidor.** `Chest.interact` avalia `offer` para o herói que segura `F`. Sem oferta para ele → nada acontece. O item continua no baú e outro herói com oferta válida (inclusive o adversário) pode pegá-lo.
- Ao trocar, o item antigo some (regra de 2026-10-09, mantida). O baú fica vazio.
- Cura (`ChestRules.HEAL`): sem mudança — aplicada na abertura, pelo ledger.
- Baú do boss (épico): mesma regra.

## 3. Card de oferta (HUD, só cliente)

Substitui a linha "Segure para trocar…" do `hero_plate`.

1. **Quando aparece:** baú aberto, com item, dentro de `chest_interact_range` do herói local e visível (neblina F37). Aparece logo após a abertura.
2. **Onde:** ancorado ao baú — posição de tela projetada acima do baú, presa às bordas da viewport.
3. **Conteúdo:** ícone (`SlotItem`; ícone real chega no F48 — até lá, placeholder atual DS-06), nome, raridade com cor **e** texto (P6), atributos do item contra o equipado no mesmo slot com diferença `+`/`−` por atributo, e contagem dos conjuntos antes → depois (ex.: Guarda 2/3 → 1/3, Caçador 1/3 → 2/3).
4. **Prompt `Segure F`** com anel de progresso de 0,4 s **só quando `offer` é verdadeiro** para o herói local. Sem oferta: o card mostra o item e a comparação, sem prompt.
5. Componentes do design system (`ItemTooltip`/`SlotItem`), tokens existentes. O cliente avalia `offer` com o mesmo `ItemRules` (só para exibir; o servidor decide).

## 4. Bot

Hoje o bot só **toca** `F` e depende da troca automática — com a regra nova ele nunca equiparia nada. `BotInput._loot`: depois de abrir, se `ItemRules.offer` for verdadeiro para o bot **e a raridade for maior ou o slot estiver vazio**, segura `F` até completar `swap_hold_time`; escolha lateral (mesma raridade) o bot ignora. Depois marca o baú como resolvido e segue.

## 5. Implementação

- `shared/core/item_rules.gd`: `offer()`; remove `Swap`. Testes em `shared/test/test_item_rules.gd`.
- `game/scripts/items/inventory.gd`: `offer(equipment, incoming, catalog)` no lugar de `swap_mode`.
- `game/scripts/world/chest.gd`: `_open` não chama `_give`; `interact` só chama `_give` se `offer` for verdadeiro para o `hero`.
- `game/scripts/ui/`: card novo (`chest_offer_card`), ligado pela HUD dona; remove `_offer` do `hero_plate`.
- `game/scripts/ai/bot_input.gd`: §4.
- `docs/prd/GDB.md` §6.2 e `docs/CONVENTION.md` §4.3: já atualizados por esta spec.

## 6. Critério de aceite

1. GUT: tabela do §2 inteira (vazio, maior, lateral, idêntico, arma × arma, menor).
2. GUT/integração: herói com peça rara segurando `F` num baú com comum → nada muda e o item fica no baú; segundo herói com slot vazio consegue pegar o mesmo item; abrir não equipa nada.
3. Bot: treino offline vs bot — o bot equipa itens melhores (log do servidor); soak curto sem regressão.
4. 2 clientes contra servidor local: card aparece só para quem está no alcance e vê o baú; prompt some quando não há oferta.
5. Lint e CI verdes. Verificação visual do PI (card, comparação, prompt, troca) + screenshot no roadmap.

## 7. Fora desta spec

Visual 3D dos itens e ícones reais (F48); escolha de qual dos dois itens descartar; devolver o item antigo ao baú; ordenar/filtrar itens; bot com preferência de conjunto.
