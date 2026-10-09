extends GutTest


func _item(set_id: StringName) -> ItemData:
	var item := ItemData.new()
	item.set_id = set_id
	return item


func _bonus(set_id: StringName) -> SetBonusData:
	var bonus := SetBonusData.new()
	bonus.set_id = set_id
	bonus.pieces_required = 3
	return bonus


func test_counts_only_pieces_of_the_set() -> void:
	var items: Array[ItemData] = [_item(&"guard"), _item(&"hunter"), _item(&"guard"), _item(&"")]
	assert_eq(SetBonus.count_pieces(items, &"guard"), 2)


func test_complete_set_is_active() -> void:
	var items: Array[ItemData] = [_item(&""), _item(&"guard"), _item(&"guard"), _item(&"guard")]
	var bonuses: Array[SetBonusData] = [_bonus(&"guard"), _bonus(&"hunter")]
	var active := SetBonus.active(items, bonuses)
	assert_eq(active.size(), 1)
	assert_eq(active[0].set_id, &"guard")


func test_incomplete_set_is_not_active() -> void:
	var items: Array[ItemData] = [_item(&"guard"), _item(&"guard"), _item(&"hunter")]
	var bonuses: Array[SetBonusData] = [_bonus(&"guard"), _bonus(&"hunter")]
	assert_eq(SetBonus.active(items, bonuses).size(), 0)
