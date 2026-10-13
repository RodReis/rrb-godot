extends GutTest
## Sorteio dos baus (GDB §6.2): comum 70 % item comum / 30 % cura; raro 65 % raro / 25 % comum /
## 10 % epico (PI 2026-10-09); reforcado 50 % raro / 50 % comum, sem epico nem cura (SPEC-055).
## Epico so de armadura; item uniforme na raridade (PI 2026-10-09). F61 (ADR-0014): o bau mostra 3
## itens distintos da raridade sorteada; cura fica sozinha; o do boss mostra 3 epicos com a arma.

const RULES: String = "res://shared/data/rules/match_pacing.tres"
const CATALOG: String = "res://shared/data/items/catalog.tres"
const SAMPLES: int = 10000
const TOLERANCE: float = 0.02
const SEED: int = 20261009

var _rules: MatchRules
var _items: Array[ItemData]


func before_all() -> void:
	_rules = load(RULES) as MatchRules
	_items = (load(CATALOG) as ItemCatalog).items


func _rng(seed_value: int = SEED) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


## Fracao de cada resultado de roll_rarity em SAMPLES sorteios.
func _rarity_share(kind: ChestRules.Kind) -> Dictionary:
	var rng := _rng()
	var counts: Dictionary = {}
	for i: int in SAMPLES:
		var r := ChestRules.roll_rarity(kind, _rules, rng)
		counts[r] = counts.get(r, 0) + 1
	var share: Dictionary = {}
	for key: int in counts:
		share[key] = float(counts[key]) / SAMPLES
	return share


func test_bau_comum_70_item_comum_30_cura() -> void:
	var share := _rarity_share(ChestRules.Kind.COMMON)
	assert_eq(share.size(), 2)
	assert_almost_eq(share[ItemData.Rarity.COMMON], 0.7, TOLERANCE)
	assert_almost_eq(share[ChestRules.HEAL], 0.3, TOLERANCE)


func test_bau_raro_65_raro_25_comum_10_epico_sem_cura() -> void:
	var share := _rarity_share(ChestRules.Kind.RARE)
	assert_eq(share.size(), 3)
	assert_almost_eq(share[ItemData.Rarity.RARE], 0.65, TOLERANCE)
	assert_almost_eq(share[ItemData.Rarity.COMMON], 0.25, TOLERANCE)
	assert_almost_eq(share[ItemData.Rarity.EPIC], 0.1, TOLERANCE)


## SPEC-055 §7 item 3: 10.000 rolagens com seed fixa, 50 % +- 2 % raro, o resto comum.
func test_bau_reforcado_50_raro_50_comum_sem_epico_nem_cura() -> void:
	var share := _rarity_share(ChestRules.Kind.REINFORCED)
	assert_eq(share.size(), 2)
	assert_almost_eq(share[ItemData.Rarity.RARE], 0.5, TOLERANCE)
	assert_almost_eq(share[ItemData.Rarity.COMMON], 0.5, TOLERANCE)
	assert_false(share.has(ItemData.Rarity.EPIC))
	assert_false(share.has(ChestRules.HEAL))


func _rarities(drops: PackedInt32Array, catalog: ItemCatalog) -> Array[int]:
	var result: Array[int] = []
	for drop: int in drops:
		result.append(catalog.find(drop).rarity)
	return result


func test_reforcado_da_3_itens_distintos_raro_ou_comum() -> void:
	var rng := _rng()
	var catalog := load(CATALOG) as ItemCatalog
	for i: int in SAMPLES / 10:
		var drops := ChestRules.roll_choices(ChestRules.Kind.REINFORCED, _rules, _items, rng)
		assert_eq(drops.size(), ChestRules.CHOICES)
		assert_false(drops.has(ChestRules.HEAL))
		var rarities := _rarities(drops, catalog)
		assert_true(rarities[0] in [ItemData.Rarity.RARE, ItemData.Rarity.COMMON], str(rarities))
		assert_eq(rarities.count(rarities[0]), drops.size(), "uma raridade so: %s" % [rarities])


func test_epico_de_bau_e_so_armadura() -> void:
	var epics := ChestRules.pool(_items, ItemData.Rarity.EPIC)
	assert_eq(epics.size(), 6)
	for item: ItemData in epics:
		assert_ne(item.slot, ItemData.Slot.WEAPON, item.id)
		assert_eq(item.rarity, ItemData.Rarity.EPIC, item.id)


func test_comum_e_raro_tem_arma_e_seis_armaduras() -> void:
	for rarity: int in [ItemData.Rarity.COMMON, ItemData.Rarity.RARE]:
		var weapons := 0
		var pool := ChestRules.pool(_items, rarity)
		for item: ItemData in pool:
			if item.slot == ItemData.Slot.WEAPON:
				weapons += 1
		assert_eq(pool.size(), 7)
		assert_eq(weapons, 1)


func test_tres_distintos_e_cada_item_uniforme_na_raridade() -> void:
	var rng := _rng()
	var pool := ChestRules.pool(_items, ItemData.Rarity.COMMON)
	var counts: Dictionary = {}
	for i: int in SAMPLES:
		var drops := ChestRules.choices(pool, ChestRules.CHOICES, rng)
		assert_eq(drops.size(), ChestRules.CHOICES)
		for drop: int in drops:
			assert_eq(drops.count(drop), 1, "repetido em %s" % [drops])
			counts[drop] = counts.get(drop, 0) + 1
	assert_eq(counts.size(), pool.size())
	var expected := float(ChestRules.CHOICES) / pool.size()
	for drop: int in counts:
		assert_almost_eq(float(counts[drop]) / SAMPLES, expected, TOLERANCE, str(drop))


func test_pool_menor_que_3_devolve_os_que_existem() -> void:
	var two: Array[ItemData] = [_items[0], _items[1]]
	var drops := ChestRules.choices(two, ChestRules.CHOICES, _rng())
	assert_eq(drops.size(), 2)
	assert_ne(drops[0], drops[1])


func test_cura_vem_sozinha_e_item_vem_em_3_da_raridade() -> void:
	var rng := _rng()
	var catalog := load(CATALOG) as ItemCatalog
	var heals := 0
	for i: int in SAMPLES / 10:
		var common := ChestRules.roll_choices(ChestRules.Kind.COMMON, _rules, _items, rng)
		if common.has(ChestRules.HEAL):
			assert_eq(common.size(), 1)
			heals += 1
		else:
			assert_eq(_rarities(common, catalog), [0, 0, 0])
		var rare := ChestRules.roll_choices(ChestRules.Kind.RARE, _rules, _items, rng)
		assert_eq(rare.size(), ChestRules.CHOICES)
		assert_false(rare.has(ChestRules.HEAL))
	assert_gt(heals, 0)


func test_boss_da_3_epicos_distintos_com_a_arma_no_sorteio() -> void:
	# Arma Epica (Furia) + 6 armaduras epicas, cada um com 3/7 de chance de aparecer.
	var rng := _rng()
	var catalog := load(CATALOG) as ItemCatalog
	var counts: Dictionary = {}
	for i: int in SAMPLES:
		var drops := ChestRules.boss_choices(_items, rng)
		assert_eq(drops.size(), ChestRules.CHOICES)
		assert_eq(_rarities(drops, catalog), [2, 2, 2])
		for drop: int in drops:
			var id := catalog.find(drop).id
			counts[id] = counts.get(id, 0) + 1
	assert_eq(counts.size(), 7)
	assert_true(counts.has(&"sword_t3_epic"))
	for id: StringName in counts:
		assert_almost_eq(float(counts[id]) / SAMPLES, 3.0 / 7.0, TOLERANCE, id)


func test_mesma_seed_mesmos_drops() -> void:
	var a := _rng(7)
	var b := _rng(7)
	for i: int in 50:
		var kind := ChestRules.Kind.RARE
		assert_eq(
			ChestRules.roll_choices(kind, _rules, _items, a),
			ChestRules.roll_choices(kind, _rules, _items, b)
		)
