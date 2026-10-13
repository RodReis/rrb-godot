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


## O heroi com [param equipment] pode trocar o item do slot por [param incoming] (ItemRules.offer).
static func offer(equipment: Vector4i, incoming: ItemData, catalog: ItemCatalog) -> bool:
	return ItemRules.offer(item_at(equipment, incoming.slot, catalog), incoming)


## Indice do melhor upgrade entre [param choices] (numeros de Ids do menu do bau, F61): o de maior
## raridade entre os que ocupam slot vazio ou sobem a raridade; empate = o primeiro. -1 = nenhum
## upgrade (o bot nao troca por pior).
static func best_choice(
	equipment: Vector4i, choices: PackedInt32Array, catalog: ItemCatalog
) -> int:
	var best := -1
	var best_rarity := -1
	for i: int in choices.size():
		var item := catalog.find(choices[i])
		if item != null and is_upgrade(equipment, item, catalog) and item.rarity > best_rarity:
			best = i
			best_rarity = item.rarity
	return best


## Slot vazio ou raridade maior (ItemRules.is_upgrade).
static func is_upgrade(equipment: Vector4i, incoming: ItemData, catalog: ItemCatalog) -> bool:
	return ItemRules.is_upgrade(item_at(equipment, incoming.slot, catalog), incoming)


static func attributes(
	hero: HeroData, level: int, equipment: Vector4i, catalog: ItemCatalog
) -> HeroAttributes:
	return Stats.attributes(hero, level, items(equipment, catalog), catalog.set_bonuses)
