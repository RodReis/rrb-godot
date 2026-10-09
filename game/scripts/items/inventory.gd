class_name Inventory
extends RefCounted
## Os 4 slots do heroi (indice = ItemData.Slot) como numeros de Ids num Vector4i, que vai no
## estado de rollback (ARCHITECTURE-GAME §3.5). Atributos finais por Stats.attributes, o mesmo
## codigo da Forja (I5). Equipar devolve um novo Vector4i.

const EMPTY: int = Ids.NONE
const NONE: Vector4i = Vector4i(EMPTY, EMPTY, EMPTY, EMPTY)
const SLOTS: int = 4


## Nulo se o slot esta vazio.
static func item_at(equipment: Vector4i, slot: int, catalog: ItemCatalog) -> ItemData:
	return catalog.find(equipment[slot])


## Itens equipados, na ordem dos slots, sem os vazios.
static func items(equipment: Vector4i, catalog: ItemCatalog) -> Array[ItemData]:
	var result: Array[ItemData] = []
	for slot: int in SLOTS:
		var item := item_at(equipment, slot, catalog)
		if item != null:
			result.append(item)
	return result


static func equip(equipment: Vector4i, item: ItemData) -> Vector4i:
	var result := equipment
	result[item.slot] = Ids.to_int(item.id)
	return result


static func swap_mode(
	equipment: Vector4i, incoming: ItemData, catalog: ItemCatalog
) -> ItemRules.Swap:
	return ItemRules.swap_mode(item_at(equipment, incoming.slot, catalog), incoming)


static func attributes(
	hero: HeroData, level: int, equipment: Vector4i, catalog: ItemCatalog
) -> HeroAttributes:
	return Stats.attributes(hero, level, items(equipment, catalog), catalog.set_bonuses)
