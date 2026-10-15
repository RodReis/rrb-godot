class_name ForgeBuild
extends RefCounted
## Build do simulador da Forja (F27, V-06): heroi, nivel e no maximo um item por slot. Nao tem
## formula propria: atributos, bonus de conjunto e mitigacao saem de shared/core (Stats, SetBonus),
## a mesma conta do servidor (I5).

var hero: HeroData
var level: int = 1

var _slots: Dictionary[ItemData.Slot, ItemData] = {}


func _init(hero_data: HeroData, hero_level: int = 1) -> void:
	hero = hero_data
	level = hero_level


## Poe o item no slot dele; o que estava la sai.
func equip(item: ItemData) -> void:
	_slots[item.slot] = item


func unequip(slot: ItemData.Slot) -> void:
	_slots.erase(slot)


func item_in(slot: ItemData.Slot) -> ItemData:
	return _slots.get(slot)


## Itens equipados, na ordem dos slots (arma, elmo, peitoral, botas).
func items() -> Array[ItemData]:
	var found: Array[ItemData] = []
	for slot: int in ItemData.Slot.values():
		if _slots.has(slot):
			found.append(_slots[slot])
	return found


func clamp_level(max_level: int) -> void:
	level = clampi(level, 1, max_level)


## Pecas do conjunto equipadas agora.
func set_pieces(set_id: StringName) -> int:
	return SetBonus.count_pieces(items(), set_id)


func active_bonuses(bonuses: Array[SetBonusData]) -> Array[SetBonusData]:
	return SetBonus.active(items(), bonuses)


func attributes(bonuses: Array[SetBonusData]) -> HeroAttributes:
	return Stats.attributes(hero, level, items(), bonuses)


## Dano que passa da DEF dos atributos finais (GDB §2.2 A).
func damage_taken(raw_damage: float, attrs: HeroAttributes) -> float:
	return Stats.damage_after_defense(raw_damage, attrs.defense)


## Dano bruto que o heroi aguenta antes de cair: HP maximo sobre a fracao que passa da DEF.
func effective_hp(attrs: HeroAttributes) -> float:
	return attrs.max_hp / Stats.damage_after_defense(1.0, attrs.defense)
