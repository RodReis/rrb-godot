extends GutTest


func _item(rarity: ItemData.Rarity) -> ItemData:
	var item := ItemData.new()
	item.rarity = rarity
	return item


func test_empty_slot_equips_automatically() -> void:
	assert_eq(ItemRules.swap_mode(null, _item(ItemData.Rarity.COMMON)), ItemRules.Swap.AUTO)


func test_higher_rarity_replaces_automatically() -> void:
	var current := _item(ItemData.Rarity.COMMON)
	assert_eq(ItemRules.swap_mode(current, _item(ItemData.Rarity.RARE)), ItemRules.Swap.AUTO)


func test_same_rarity_needs_confirmation() -> void:
	var current := _item(ItemData.Rarity.RARE)
	assert_eq(ItemRules.swap_mode(current, _item(ItemData.Rarity.RARE)), ItemRules.Swap.CONFIRM)


func test_lower_rarity_needs_confirmation() -> void:
	var current := _item(ItemData.Rarity.EPIC)
	assert_eq(ItemRules.swap_mode(current, _item(ItemData.Rarity.COMMON)), ItemRules.Swap.CONFIRM)
