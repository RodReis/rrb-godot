extends GutTest

const EPS: float = 0.0001


func _hero() -> HeroData:
	var basic := SkillData.new()
	basic.cooldown = PackedFloat64Array([1.0])
	var hero := HeroData.new()
	hero.base_move_speed = 6.0
	hero.base_hp = 600.0
	hero.hp_per_level = 45.0
	hero.base_defense = 30.0
	hero.defense_per_level = 3.0
	hero.base_attack = 40.0
	hero.attack_per_level = 3.5
	hero.base_intelligence = 10.0
	hero.intelligence_per_level = 1.0
	hero.base_agility = 10.0
	hero.agility_per_level = 1.0
	hero.basic_attack = basic
	return hero


func _item(set_id: StringName, hp: float, defense: float, agility_pct: float) -> ItemData:
	var item := ItemData.new()
	item.set_id = set_id
	item.hp = hp
	item.defense = defense
	item.agility_pct = agility_pct
	return item


func _bonus(set_id: StringName) -> SetBonusData:
	var bonus := SetBonusData.new()
	bonus.set_id = set_id
	bonus.pieces_required = 3
	bonus.max_hp_pct = 0.15
	bonus.defense = 10.0
	bonus.attack_speed_pct = 0.10
	bonus.move_speed_pct = 0.08
	return bonus


func test_mitigation_matches_gdb_examples() -> void:
	assert_almost_eq(Stats.mitigation(10.0), 0.0909, EPS)
	assert_almost_eq(Stats.mitigation(30.0), 0.2308, EPS)
	assert_almost_eq(Stats.mitigation(60.0), 0.375, EPS)
	assert_almost_eq(Stats.mitigation(100.0), 0.5, EPS)


func test_damage_after_defense_scales_raw_damage() -> void:
	assert_almost_eq(Stats.damage_after_defense(120.0, 30.0), 92.3077, EPS)


func test_negative_defense_counts_as_zero() -> void:
	assert_almost_eq(Stats.damage_after_defense(120.0, -50.0), 120.0, EPS)


func test_cdr_is_half_percent_per_int() -> void:
	assert_almost_eq(Stats.cdr_percent(19.0), 9.5, EPS)


func test_cdr_caps_at_thirty_percent() -> void:
	assert_almost_eq(Stats.cdr_percent(60.0), 30.0, EPS)
	assert_almost_eq(Stats.cdr_percent(200.0), 30.0, EPS)


func test_effective_cooldown_applies_cdr() -> void:
	assert_almost_eq(Stats.effective_cooldown(8.0, 24.0), 7.04, EPS)


func test_move_speed_grows_point_four_percent_per_agi() -> void:
	assert_almost_eq(Stats.move_speed(6.0, 25.0, 0.0), 6.6, EPS)


func test_move_speed_bonus_multiplies_final_value() -> void:
	assert_almost_eq(Stats.move_speed(6.0, 25.0, 0.08), 6.6 * 1.08, EPS)


func test_attack_interval_shrinks_point_six_percent_per_agi() -> void:
	assert_almost_eq(Stats.attack_interval(0.8, 50.0, 0.0), 0.8 / 1.3, EPS)


func test_attack_speed_bonus_divides_final_interval() -> void:
	assert_almost_eq(Stats.attack_interval(0.8, 50.0, 0.10), 0.8 / 1.3 / 1.1, EPS)


func test_attributes_at_level_one_are_hero_base() -> void:
	var a := Stats.attributes(_hero(), 1, [], [])
	assert_eq(a.max_hp, 600)
	assert_almost_eq(a.defense, 30.0, EPS)
	assert_almost_eq(a.attack, 40.0, EPS)
	assert_almost_eq(a.intelligence, 10.0, EPS)
	assert_almost_eq(a.agility, 10.0, EPS)


func test_attributes_grow_per_level() -> void:
	var a := Stats.attributes(_hero(), 10, [], [])
	assert_eq(a.max_hp, 1005)
	assert_almost_eq(a.defense, 57.0, EPS)
	assert_almost_eq(a.attack, 71.5, EPS)


func test_level_below_one_counts_as_one() -> void:
	assert_eq(Stats.attributes(_hero(), 0, [], []).max_hp, 600)


func test_items_add_flat_values_and_agility_pct() -> void:
	var items: Array[ItemData] = [_item(&"", 50.0, 5.0, 0.0), _item(&"", 0.0, 0.0, 0.10)]
	var a := Stats.attributes(_hero(), 1, items, [])
	assert_eq(a.max_hp, 650)
	assert_almost_eq(a.defense, 35.0, EPS)
	assert_almost_eq(a.agility, 11.0, EPS)


func test_complete_set_applies_bonus() -> void:
	var items: Array[ItemData] = [
		_item(&"guard", 0.0, 0.0, 0.0),
		_item(&"guard", 0.0, 0.0, 0.0),
		_item(&"guard", 0.0, 0.0, 0.0)
	]
	var bonuses: Array[SetBonusData] = [_bonus(&"guard")]
	var a := Stats.attributes(_hero(), 1, items, bonuses)
	assert_eq(a.max_hp, 690)
	assert_almost_eq(a.defense, 40.0, EPS)
	assert_almost_eq(a.move_speed, 6.0 * 1.04 * 1.08, EPS)
	assert_almost_eq(a.attack_interval, 1.0 / 1.06 / 1.1, EPS)


func test_max_hp_rounds_to_nearest_int() -> void:
	var items: Array[ItemData] = [
		_item(&"guard", 110.0, 0.0, 0.0),
		_item(&"guard", 0.0, 0.0, 0.0),
		_item(&"guard", 0.0, 0.0, 0.0)
	]
	var bonuses: Array[SetBonusData] = [_bonus(&"guard")]
	assert_eq(Stats.attributes(_hero(), 10, items, bonuses).max_hp, 1282)


func test_attributes_expose_cdr_and_mitigation() -> void:
	var a := Stats.attributes(_hero(), 10, [], [])
	assert_almost_eq(a.cdr_percent, 9.5, EPS)
	assert_almost_eq(a.mitigation, 57.0 / 157.0, EPS)
