extends GutTest
## Sorteio dos baus (GDB §6.2): comum 70 % item comum / 30 % cura; raro 65 % raro / 25 % comum /
## 10 % epico (PI 2026-10-09). Epico so de armadura; item uniforme na raridade (PI 2026-10-09).

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
func _rarity_share(is_rare: bool) -> Dictionary:
	var rng := _rng()
	var counts: Dictionary = {}
	for i: int in SAMPLES:
		var r := ChestRules.roll_rarity(is_rare, _rules, rng)
		counts[r] = counts.get(r, 0) + 1
	var share: Dictionary = {}
	for key: int in counts:
		share[key] = float(counts[key]) / SAMPLES
	return share


func test_bau_comum_70_item_comum_30_cura() -> void:
	var share := _rarity_share(false)
	assert_eq(share.size(), 2)
	assert_almost_eq(share[ItemData.Rarity.COMMON], 0.7, TOLERANCE)
	assert_almost_eq(share[ChestRules.HEAL], 0.3, TOLERANCE)


func test_bau_raro_65_raro_25_comum_10_epico_sem_cura() -> void:
	var share := _rarity_share(true)
	assert_eq(share.size(), 3)
	assert_almost_eq(share[ItemData.Rarity.RARE], 0.65, TOLERANCE)
	assert_almost_eq(share[ItemData.Rarity.COMMON], 0.25, TOLERANCE)
	assert_almost_eq(share[ItemData.Rarity.EPIC], 0.1, TOLERANCE)


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


func test_item_uniforme_dentro_da_raridade() -> void:
	var rng := _rng()
	var pool := ChestRules.pool(_items, ItemData.Rarity.COMMON)
	var counts: Dictionary = {}
	for i: int in SAMPLES:
		var item := ChestRules.pick(pool, rng)
		counts[item.id] = counts.get(item.id, 0) + 1
	assert_eq(counts.size(), pool.size())
	for id: StringName in counts:
		assert_almost_eq(float(counts[id]) / SAMPLES, 1.0 / pool.size(), TOLERANCE, id)


func test_roll_devolve_numero_de_item_da_raridade_ou_cura() -> void:
	var rng := _rng()
	var catalog := load(CATALOG) as ItemCatalog
	for i: int in SAMPLES / 10:
		var common := ChestRules.roll(false, _rules, _items, rng)
		if common != ChestRules.HEAL:
			assert_eq(catalog.find(common).rarity, ItemData.Rarity.COMMON)
		var rare := ChestRules.roll(true, _rules, _items, rng)
		assert_ne(rare, ChestRules.HEAL)
		assert_not_null(catalog.find(rare))


func test_boss_da_um_dos_7_epicos_uniforme_com_a_arma() -> void:
	# Arma Epica (Furia) + 6 armaduras epicas, cada um 1/7 (PI 2026-10-09, F11).
	var rng := _rng()
	var catalog := load(CATALOG) as ItemCatalog
	var counts: Dictionary = {}
	for i: int in SAMPLES:
		var item := catalog.find(ChestRules.boss_drop(_items, rng))
		assert_eq(item.rarity, ItemData.Rarity.EPIC)
		counts[item.id] = counts.get(item.id, 0) + 1
	assert_eq(counts.size(), 7)
	assert_true(counts.has(&"sword_t3_epic"))
	for id: StringName in counts:
		assert_almost_eq(float(counts[id]) / SAMPLES, 1.0 / 7.0, TOLERANCE, id)


func test_mesma_seed_mesmos_drops() -> void:
	var a := _rng(7)
	var b := _rng(7)
	for i: int in 50:
		assert_eq(
			ChestRules.roll(true, _rules, _items, a), ChestRules.roll(true, _rules, _items, b)
		)
