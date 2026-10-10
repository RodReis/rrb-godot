extends GutTest
## Base de combate das HUDs (HeroPlate) ligada a um Cavaleiro de verdade: so mostra o estado do
## heroi e dos baus.

const PLATE: PackedScene = preload("res://scenes/ui/hero_plate.tscn")
const KNIGHT: PackedScene = preload("res://scenes/heroes/knight.tscn")
const CHEST: PackedScene = preload("res://scenes/world/chest.tscn")
const GUARD_HELM: ItemData = preload("res://shared/data/items/guard_set/guard_helm_t1.tres")

var _hero: Hero
var _spawns: Node3D
var _plate: HeroPlate


func before_each() -> void:
	_hero = KNIGHT.instantiate() as Hero
	_hero.name = "1"
	add_child_autofree(_hero)
	_spawns = add_child_autofree(Node3D.new())
	_plate = add_child_autofree(PLATE.instantiate())


## Liga e atualiza como a HUD faz no _process.
func _bind_and_wait() -> void:
	var chests: Array[Chest] = []
	for node: Node in _spawns.get_children():
		chests.append(node as Chest)
	_plate.set_chests(chests)
	_plate.bind(_hero)
	_plate.update()
	await wait_process_frames(1)


func _node(path: String) -> Node:
	return _plate.get_node(path)


func test_plate_shows_name_level_and_hp() -> void:
	await _bind_and_wait()
	assert_eq((_node("%HeroName") as Label).text, "CAVALEIRO")
	assert_eq((_node("%HeroLevel") as Label).text, "NÍVEL 1")
	var hp := "%d / %d" % [_hero.hp, _hero.attributes.max_hp]
	assert_eq((_node("%HpBar").get_node("%Numbers") as Label).text, hp)


func test_r_locked_and_q_ready_at_level_1() -> void:
	await _bind_and_wait()
	assert_eq((_node("%SkillR") as SkillButton).state, SkillButton.State.LOCKED)
	assert_eq((_node("%SkillQ") as SkillButton).state, SkillButton.State.READY)


func test_cooldown_from_hero_state() -> void:
	await _bind_and_wait()
	_hero.q_cooldown = 30
	_plate.update()
	assert_eq((_node("%SkillQ") as SkillButton).state, SkillButton.State.COOLING)


func test_new_item_fills_slot_notifies_and_counts_set() -> void:
	await _bind_and_wait()
	_hero.equipment = Inventory.equip(_hero.equipment, GUARD_HELM)
	_plate.update()
	assert_false((_node("%Helm") as SlotItem).is_empty())
	var toast := _node("%Toast") as Toast
	assert_true(toast.visible)
	assert_string_contains((toast.get_child(0) as Label).text, GUARD_HELM.display_name)
	assert_string_contains((_node("%SetText") as Label).text, "Guarda 1/3")


func test_offer_when_chest_in_reach_holds_an_item() -> void:
	var chest := CHEST.instantiate() as Chest
	_spawns.add_child(chest)
	chest.opened = true
	chest.item = Ids.to_int(GUARD_HELM.id)
	await _bind_and_wait()
	var offer := _node("%Offer") as Control
	assert_true(offer.visible)
	assert_string_contains((_node("%OfferText") as Label).text, GUARD_HELM.display_name)
	_hero.global_position = Vector3(50.0, 0.0, 0.0)
	_plate.update()
	assert_false(offer.visible)


## A HUD da fase 2 liga a base de novo aos 5:00: item equipado antes nao vira aviso atrasado.
func test_rebind_does_not_notify_items_already_equipped() -> void:
	await _bind_and_wait()
	_hero.equipment = Inventory.equip(_hero.equipment, GUARD_HELM)
	_plate.bind(_hero)
	_plate.update()
	assert_false((_node("%Toast") as Toast).visible)
	assert_false((_node("%Helm") as SlotItem).is_empty())
