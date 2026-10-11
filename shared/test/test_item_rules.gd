extends GutTest
## Tabela de SPEC-047 §2: o F so e oferecido para item melhor.


func _item(rarity: ItemData.Rarity, set_id: StringName = &"") -> ItemData:
	var item := ItemData.new()
	item.rarity = rarity
	item.set_id = set_id
	return item


func test_empty_slot_is_offered() -> void:
	assert_true(ItemRules.offer(null, _item(ItemData.Rarity.COMMON)))


func test_higher_rarity_is_offered() -> void:
	var current := _item(ItemData.Rarity.COMMON)
	assert_true(ItemRules.offer(current, _item(ItemData.Rarity.RARE)))


func test_same_rarity_other_set_is_a_lateral_offer() -> void:
	var current := _item(ItemData.Rarity.RARE, &"guard")
	assert_true(ItemRules.offer(current, _item(ItemData.Rarity.RARE, &"hunter")))


func test_same_rarity_same_set_is_not_offered() -> void:
	var current := _item(ItemData.Rarity.RARE, &"guard")
	assert_false(ItemRules.offer(current, _item(ItemData.Rarity.RARE, &"guard")))


func test_weapon_against_weapon_of_same_rarity_is_not_offered() -> void:
	var current := _item(ItemData.Rarity.RARE)
	assert_false(ItemRules.offer(current, _item(ItemData.Rarity.RARE)))


func test_lower_rarity_is_not_offered() -> void:
	var current := _item(ItemData.Rarity.EPIC)
	assert_false(ItemRules.offer(current, _item(ItemData.Rarity.COMMON)))
	assert_false(ItemRules.offer(current, _item(ItemData.Rarity.RARE, &"hunter")))


func test_upgrade_is_empty_slot_or_higher_rarity_only() -> void:
	assert_true(ItemRules.is_upgrade(null, _item(ItemData.Rarity.COMMON)))
	assert_true(ItemRules.is_upgrade(_item(ItemData.Rarity.COMMON), _item(ItemData.Rarity.RARE)))
	var current := _item(ItemData.Rarity.RARE, &"guard")
	assert_false(ItemRules.is_upgrade(current, _item(ItemData.Rarity.RARE, &"hunter")))
