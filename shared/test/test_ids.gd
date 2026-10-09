extends GutTest


func test_every_id_round_trips() -> void:
	for id: StringName in Ids.ALL:
		assert_eq(Ids.to_name(Ids.to_int(id)), id)


func test_ids_are_unique() -> void:
	var seen: Dictionary = {}
	for id: StringName in Ids.ALL:
		assert_false(seen.has(id), "id repetido: %s" % id)
		seen[id] = true


func test_unknown_name_is_minus_one() -> void:
	assert_eq(Ids.to_int(&"nao_existe"), -1)


func test_unknown_int_is_empty_name() -> void:
	assert_eq(Ids.to_name(-1), &"")
	assert_eq(Ids.to_name(Ids.ALL.size()), &"")
