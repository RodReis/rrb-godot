class_name ChestRules
extends RefCounted
## Sorteio do bau (GDB §6.2). Comum: item comum ou cura. Raro: raro, comum ou epico (10 %, PI
## 2026-10-09). Reforcado (campo de canto, SPEC-055): raro ou comum, sem epico nem cura. Epico de
## bau so de armadura: a arma epica e do boss (boss_drop). Item uniforme entre os da raridade
## sorteada (PI 2026-10-09). RNG injetado: seed por partida.

## Tipo do bau; o SpawnMarker guarda o mesmo enum (valores de COMMON e RARE gravados nas cenas).
enum Kind { COMMON, RARE, REINFORCED }

## Drop de cura (consumivel +heal_amount); nao colide com numero de Ids nem com Ids.NONE.
const HEAL: int = -2


## ItemData.Rarity sorteada, ou HEAL.
static func roll_rarity(kind: Kind, rules: MatchRules, rng: RandomNumberGenerator) -> int:
	var r := rng.randf()
	if kind == Kind.COMMON:
		return ItemData.Rarity.COMMON if r < rules.common_chest_item_chance else HEAL
	if kind == Kind.REINFORCED:
		return (
			ItemData.Rarity.RARE
			if r < rules.reinforced_chest_rare_chance
			else ItemData.Rarity.COMMON
		)
	if r < rules.rare_chest_rare_chance:
		return ItemData.Rarity.RARE
	if r < rules.rare_chest_rare_chance + rules.rare_chest_common_chance:
		return ItemData.Rarity.COMMON
	return ItemData.Rarity.EPIC


## Itens que um bau pode dar na [param rarity].
static func pool(items: Array[ItemData], rarity: int) -> Array[ItemData]:
	var result: Array[ItemData] = []
	for item: ItemData in items:
		if item.rarity != rarity:
			continue
		if rarity == ItemData.Rarity.EPIC and item.slot == ItemData.Slot.WEAPON:
			continue
		result.append(item)
	return result


static func pick(candidates: Array[ItemData], rng: RandomNumberGenerator) -> ItemData:
	return candidates[rng.randi_range(0, candidates.size() - 1)]


## Drop do Rei Esqueleto (GDB §5.1): um epico garantido, uniforme entre todos, arma inclusa
## (PI 2026-10-09, F11).
static func boss_drop(items: Array[ItemData], rng: RandomNumberGenerator) -> int:
	var epics: Array[ItemData] = []
	for item: ItemData in items:
		if item.rarity == ItemData.Rarity.EPIC:
			epics.append(item)
	return Ids.to_int(pick(epics, rng).id)


## Numero de Ids do item sorteado, ou HEAL.
static func roll(
	kind: Kind, rules: MatchRules, items: Array[ItemData], rng: RandomNumberGenerator
) -> int:
	var rarity := roll_rarity(kind, rules, rng)
	if rarity == HEAL:
		return HEAL
	return Ids.to_int(pick(pool(items, rarity), rng).id)
