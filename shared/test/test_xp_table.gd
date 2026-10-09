extends GutTest


func _curve() -> XpCurve:
	var curve := XpCurve.new()
	curve.cumulative_xp = PackedInt32Array([0, 90, 225, 440, 740, 1160, 1720, 2440, 3340, 4440])
	curve.catch_up_level_gap = 2
	curve.catch_up_bonus = 0.25
	return curve


func _rules() -> MatchRules:
	var rules := MatchRules.new()
	rules.phase1_kill_xp = 80
	rules.phase2_kill_xp_base = 150
	rules.phase2_kill_xp_per_level = 20
	return rules


func test_level_one_at_zero_xp() -> void:
	assert_eq(XpTable.level_for_xp(_curve(), 0), 1)


func test_level_changes_exactly_at_threshold() -> void:
	assert_eq(XpTable.level_for_xp(_curve(), 89), 1)
	assert_eq(XpTable.level_for_xp(_curve(), 90), 2)
	assert_eq(XpTable.level_for_xp(_curve(), 1160), 6)


func test_level_caps_at_max() -> void:
	assert_eq(XpTable.level_for_xp(_curve(), 4440), 10)
	assert_eq(XpTable.level_for_xp(_curve(), 99999), 10)


func test_negative_xp_is_level_one() -> void:
	assert_eq(XpTable.level_for_xp(_curve(), -5), 1)


func test_max_level_is_curve_size() -> void:
	assert_eq(XpTable.max_level(_curve()), 10)


func test_xp_for_level_is_cumulative() -> void:
	assert_eq(XpTable.xp_for_level(_curve(), 5), 740)
	assert_eq(XpTable.xp_for_level(_curve(), 1), 0)


func test_catch_up_when_two_levels_behind() -> void:
	assert_almost_eq(XpTable.catch_up_multiplier(_curve(), 3, 5), 1.25, 0.0001)


func test_no_catch_up_when_one_level_behind() -> void:
	assert_almost_eq(XpTable.catch_up_multiplier(_curve(), 4, 5), 1.0, 0.0001)


func test_monster_xp_applies_catch_up_and_rounds() -> void:
	assert_eq(XpTable.monster_xp(_curve(), 85, 2, 5), 106)
	assert_eq(XpTable.monster_xp(_curve(), 85, 5, 5), 85)


func test_level_never_drops_as_xp_grows() -> void:
	# I7: XP monotonico -> nivel monotonico.
	var last := 1
	for xp: int in range(0, 5000, 5):
		var level := XpTable.level_for_xp(_curve(), xp)
		assert_true(level >= last, "nivel caiu em %d XP" % xp)
		last = level


func test_farm_de_uma_base_da_nivel_3() -> void:
	# GDB §5.2: 4 x 35 + 85 = 225 -> nivel 3 (curva do .tres, PI 2026-10-09).
	var curve := load("res://shared/data/rules/xp_table.tres") as XpCurve
	assert_eq(XpTable.level_for_xp(curve, 4 * 35 + 85), 3)
	assert_eq(XpTable.level_for_xp(curve, 4 * 35 + 85 - 1), 2)


func test_pvp_kill_xp_phase_one_is_flat() -> void:
	assert_eq(XpTable.pvp_kill_xp(_rules(), false, 7), 80)


func test_pvp_kill_xp_phase_two_scales_with_target_level() -> void:
	assert_eq(XpTable.pvp_kill_xp(_rules(), true, 7), 290)
