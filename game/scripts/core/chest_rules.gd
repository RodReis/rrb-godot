class_name ChestRules
extends RefCounted
## Sorteio do bau (GDB §6.2). Comum: item comum ou cura. Raro: raro, comum ou epico (10 %, PI
## 2026-10-09). Reforcado (campo de canto, SPEC-055): raro ou comum, sem epico nem cura. Epico de
## bau so de armadura: a arma epica e do boss (boss_choices). F61 (ADR-0014): o bau mostra
## CHOICES itens distintos da raridade sorteada (uma raridade por bau, item uniforme dentro dela);
## a cura vem sozinha. RNG injetado: seed por partida.

## Tipo do bau; o SpawnMarker guarda o mesmo enum (valores de COMMON e RARE gravados nas cenas).
enum Kind { COMMON, RARE, REINFORCED }

## Drop de cura (consumivel +heal_amount); nao colide com numero de Ids nem com Ids.NONE.
const HEAL: int = -2
## Itens que o menu do bau mostra (PI 2026-10-13).
const CHOICES: int = 3


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


## Ate [param count] numeros de Ids distintos de [param candidates], sem repetir (embaralhamento
## parcial de Fisher-Yates); menos se o pool for menor.
static func choices(
	candidates: Array[ItemData], count: int, rng: RandomNumberGenerator
) -> PackedInt32Array:
	var left := candidates.duplicate()
	var result := PackedInt32Array()
	while result.size() < count and not left.is_empty():
		var item: ItemData = left.pop_at(rng.randi_range(0, left.size() - 1))
		result.append(Ids.to_int(item.id))
	return result


## Drops do bau: [HEAL] ou CHOICES itens distintos da raridade sorteada.
static func roll_choices(
	kind: Kind, rules: MatchRules, items: Array[ItemData], rng: RandomNumberGenerator
) -> PackedInt32Array:
	var rarity := roll_rarity(kind, rules, rng)
	if rarity == HEAL:
		return PackedInt32Array([HEAL])
	return choices(pool(items, rarity), CHOICES, rng)


## Bau do Rei Esqueleto (GDB §5.1): CHOICES epicos distintos, arma inclusa (PI 2026-10-09, F11).
static func boss_choices(items: Array[ItemData], rng: RandomNumberGenerator) -> PackedInt32Array:
	var epics: Array[ItemData] = []
	for item: ItemData in items:
		if item.rarity == ItemData.Rarity.EPIC:
			epics.append(item)
	return choices(epics, CHOICES, rng)
