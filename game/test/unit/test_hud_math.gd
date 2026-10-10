extends GutTest
## Contas das HUDs sobre a curva e a zona reais (GDB §3.2, §3.3, §7.1).

const CURVE: XpCurve = preload("res://shared/data/rules/xp_table.tres")
const RULES: MatchRules = preload("res://shared/data/rules/match_pacing.tres")


func test_xp_progress_inside_level() -> void:
	var floor_xp := XpTable.xp_for_level(CURVE, 4)
	var next_xp := XpTable.xp_for_level(CURVE, 5)
	assert_eq(HudMath.xp_progress(CURVE, floor_xp + 10), Vector2i(10, next_xp - floor_xp))


func test_xp_progress_at_level_start_is_empty() -> void:
	var floor_xp := XpTable.xp_for_level(CURVE, 2)
	assert_eq(HudMath.xp_progress(CURVE, floor_xp).x, 0)


func test_xp_progress_at_max_level_is_full() -> void:
	var top := XpTable.xp_for_level(CURVE, XpTable.max_level(CURVE))
	assert_eq(HudMath.xp_progress(CURVE, top + 500), Vector2i.ONE)


func test_until_never_negative() -> void:
	assert_eq(HudMath.until(210.0, 180.0), 30.0)
	assert_eq(HudMath.until(210.0, 250.0), 0.0)


func test_warning_only_in_last_30_seconds() -> void:
	assert_false(HudMath.is_warning(31.0))
	assert_true(HudMath.is_warning(30.0))
	assert_true(HudMath.is_warning(0.5))
	assert_false(HudMath.is_warning(0.0))


func test_catch_up_two_levels_behind() -> void:
	assert_almost_eq(HudMath.catch_up_bonus(CURVE, 3, 5), CURVE.catch_up_bonus, 0.0001)
	assert_eq(HudMath.catch_up_bonus(CURVE, 4, 5), 0.0)


## Vinheta da zona (PATTERNS P8): dano/s / maior dano da tabela (5 %), so com o flag do
## servidor; some aos poucos nos ultimos fade_ticks.
func test_zone_vignette_by_damage_over_the_peak() -> void:
	assert_almost_eq(HudMath.zone_vignette(RULES, 0.05, 45, 15), 1.0, 0.0001)
	assert_almost_eq(HudMath.zone_vignette(RULES, 0.01, 45, 15), 0.2, 0.0001)


func test_zone_vignette_off_without_server_flag() -> void:
	assert_eq(HudMath.zone_vignette(RULES, 0.05, 0, 15), 0.0)


func test_zone_vignette_fades_in_the_last_ticks() -> void:
	assert_almost_eq(HudMath.zone_vignette(RULES, 0.05, 15, 15), 1.0, 0.0001)
	assert_almost_eq(HudMath.zone_vignette(RULES, 0.05, 6, 15), 0.4, 0.0001)


func test_zone_fraction_of_the_first_radius() -> void:
	assert_almost_eq(HudMath.zone_fraction(RULES, 35.0), 1.0, 0.0001)
	assert_almost_eq(HudMath.zone_fraction(RULES, 17.5), 0.5, 0.0001)
	assert_eq(HudMath.zone_fraction(RULES, 0.0), 0.0)


func test_decimal_uses_comma() -> void:
	assert_eq(HudMath.decimal(17.5), "17,5")
	assert_eq(HudMath.decimal(3.0), "3,0")
	assert_eq(HudMath.decimal(0.02 * 100.0), "2,0")
