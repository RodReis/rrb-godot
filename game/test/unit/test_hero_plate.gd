extends GutTest
## Base de combate das HUDs (HeroPlate) ligada a um Cavaleiro de verdade: so mostra o estado do
## heroi e dos baus.

const PLATE: PackedScene = preload("res://scenes/ui/hero_plate.tscn")
const KNIGHT: PackedScene = preload("res://scenes/heroes/knight.tscn")
const GUARD_HELM: ItemData = preload("res://shared/data/items/guard_set/guard_helm_t1.tres")

var _hero: Hero
var _spawns: Node3D
var _plate: HeroPlate


func after_each() -> void:
	for bus: StringName in [HeroPlate.BUS_GAME, HeroPlate.BUS_BOSS]:
		AudioServer.set_bus_mute(AudioServer.get_bus_index(bus), false)


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


func test_offer_card_stays_hidden_without_a_chest_in_reach() -> void:
	await _bind_and_wait()
	assert_false((_node("%OfferCard") as ChestOfferCard).visible)


## A HUD da fase 2 liga a base de novo aos 5:00: item equipado antes nao vira aviso atrasado.
func test_rebind_does_not_notify_items_already_equipped() -> void:
	await _bind_and_wait()
	_hero.equipment = Inventory.equip(_hero.equipment, GUARD_HELM)
	_plate.bind(_hero)
	_plate.update()
	assert_false((_node("%Toast") as Toast).visible)
	assert_false((_node("%Helm") as SlotItem).is_empty())


## Grade de atributos (F57): valores reais do heroi (Stats), nao os do prototipo.
func test_attributes_show_real_hero_values() -> void:
	await _bind_and_wait()
	var attributes := _hero.attributes
	assert_eq((_node("%AttrAttack") as Label).text, "ATQ %d" % roundi(attributes.attack))
	assert_eq((_node("%AttrDefense") as Label).text, "DEF %d" % roundi(attributes.defense))
	assert_eq(
		(_node("%AttrSpeed") as Label).text, "VEL %s" % HudMath.decimal(attributes.move_speed)
	)
	assert_eq((_node("%AttrCdr") as Label).text, "RCG %d%%" % roundi(attributes.cdr_percent))


func test_equipment_count_follows_slots() -> void:
	await _bind_and_wait()
	assert_eq((_node("%EquipCount") as Label).text, "0 / 4")
	_hero.equipment = Inventory.equip(_hero.equipment, GUARD_HELM)
	_plate.update()
	assert_eq((_node("%EquipCount") as Label).text, "1 / 4")


func test_gear_button_toggles_menu() -> void:
	await _bind_and_wait()
	var menu := _node("%GearMenu") as Control
	assert_false(menu.visible)
	(_node("%GearButton") as Button).pressed.emit()
	assert_true(menu.visible)
	(_node("%GearButton") as Button).pressed.emit()
	assert_false(menu.visible)


## Switches da engrenagem (decisao do PI 2026-10-12): som do jogo muta o Master; aviso do
## chefao muta so o barramento Boss. Desligar = switch solto.
func test_sound_switches_mute_their_bus() -> void:
	await _bind_and_wait()
	var game_bus := AudioServer.get_bus_index(HeroPlate.BUS_GAME)
	var boss_bus := AudioServer.get_bus_index(HeroPlate.BUS_BOSS)
	assert_true(boss_bus > 0, "default_bus_layout tem o barramento Boss")
	(_node("%SoundBoss") as CheckButton).button_pressed = false
	assert_true(AudioServer.is_bus_mute(boss_bus))
	assert_false(AudioServer.is_bus_mute(game_bus))
	(_node("%SoundGame") as CheckButton).button_pressed = false
	assert_true(AudioServer.is_bus_mute(game_bus))
	(_node("%SoundGame") as CheckButton).button_pressed = true
	assert_false(AudioServer.is_bus_mute(game_bus))


## As duas HUDs tem a sua engrenagem: ao abrir, o switch mostra o estado real do barramento.
func test_menu_reads_bus_state_when_opened() -> void:
	await _bind_and_wait()
	AudioServer.set_bus_mute(AudioServer.get_bus_index(HeroPlate.BUS_BOSS), true)
	(_node("%GearButton") as Button).pressed.emit()
	assert_false((_node("%SoundBoss") as CheckButton).button_pressed)
	assert_true((_node("%SoundGame") as CheckButton).button_pressed)


## Subiu de nivel com ponto livre: aviso de aprender (PI 2026-10-12); ao ligar, nao avisa.
func test_level_up_with_free_point_notifies() -> void:
	await _bind_and_wait()
	var toast := _node("%Toast") as Toast
	assert_false(toast.visible)
	_hero.level = 2
	_hero.xp = XpTable.xp_for_level(_hero.xp_curve, 2)
	_plate.update()
	assert_true(toast.visible)
	assert_string_contains((toast.get_child(0) as Label).text, "Ctrl+")
	assert_eq((_node("%SkillE").get_node("%Cooldown") as Label).text, "Ctrl+E")
