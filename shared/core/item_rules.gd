class_name ItemRules
extends RefCounted
## Substituicao de equipamento no mesmo slot (GDB §6.2; raridade menor: PI 2026-10-09).

## AUTO: o servidor troca sozinho. CONFIRM: troca so com F segurado.
enum Swap { AUTO, CONFIRM }


## [param current] nulo = slot vazio. Os dois itens sao do mesmo slot.
static func swap_mode(current: ItemData, incoming: ItemData) -> Swap:
	if current == null or incoming.rarity > current.rarity:
		return Swap.AUTO
	return Swap.CONFIRM
