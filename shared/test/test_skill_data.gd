extends GutTest


func test_value_at_rank_uses_rank_index() -> void:
	var values := PackedFloat64Array([50.0, 80.0, 110.0])
	assert_eq(SkillData.at_rank(values, 1), 50.0)
	assert_eq(SkillData.at_rank(values, 3), 110.0)


func test_rank_beyond_array_uses_last_value() -> void:
	assert_eq(SkillData.at_rank(PackedFloat64Array([8.0]), 5), 8.0)


func test_rank_below_one_uses_first_value() -> void:
	assert_eq(SkillData.at_rank(PackedFloat64Array([8.0, 9.0]), 0), 8.0)


func test_empty_values_are_zero() -> void:
	assert_eq(SkillData.at_rank(PackedFloat64Array(), 2), 0.0)
