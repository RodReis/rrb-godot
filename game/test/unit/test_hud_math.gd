extends GutTest
## Contas da HUD da fase 1 sobre a curva real (GDB §3.2, §3.3).

const CURVE: XpCurve = preload("res://shared/data/rules/xp_table.tres")


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
