# gdlint: ignore=max-public-methods
extends GutTest
## Base de combate das HUDs (HeroPlate) ligada a um Cavaleiro de verdade: so mostra o estado do
## heroi e dos baus.

const PLATE: PackedScene = preload("res://scenes/ui/hero_plate.tscn")
const KNIGHT: PackedScene = preload("res://scenes/heroes/knight.tscn")
const GUARD_HELM: ItemData = preload("res://shared/data/items/guard_set/guard_helm_t1.tres")
const TMP_SETTINGS: String = "user://test_hero_plate_settings.cfg"

var _hero: Hero
var _spawns: Node3D
var _plate: HeroPlate


func after_each() -> void:
	for bus: StringName in [HeroPlate.BUS_GAME, HeroPlate.BUS_BOSS]:
		AudioServer.set_bus_mute(AudioServer.get_bus_index(bus), false)
	get_tree().root.content_scale_factor = 1.0
	DirAccess.remove_absolute(TMP_SETTINGS)


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


func test_chest_menu_stays_hidden_without_a_chest_in_reach() -> void:
	await _bind_and_wait()
	assert_false((_node("%ChoiceMenu") as ChestChoiceMenu).visible)


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


## SPEC-097 (ADR-0031): o slider da engrenagem abre na escala atual da janela; ao soltar, aplica
## no content_scale_factor e grava so [ui] hud_scale (o zoom ja salvo fica).
func test_slider_de_tamanho_aplica_e_grava_so_a_escala() -> void:
	await _bind_and_wait()
	var saved := UserSettings.defaults()
	saved[UserSettings.CAMERA][UserSettings.DISTANCE] = 13.0
	assert_eq(UserSettings.save_file(saved, TMP_SETTINGS), OK)
	_plate.settings_path = TMP_SETTINGS
	get_tree().root.content_scale_factor = 0.85
	(_node("%GearButton") as Button).pressed.emit()
	var slider := _node("%HudScale") as HSlider
	assert_almost_eq(slider.value, 0.85, 0.0001)
	assert_eq((_node("%HudScaleValue") as Label).text, "85%")
	assert_eq(slider.min_value, UserSettings.HUD_SCALE_MIN)
	assert_eq(slider.max_value, UserSettings.HUD_SCALE_MAX)
	slider.value = 0.7
	assert_eq((_node("%HudScaleValue") as Label).text, "70%")
	assert_almost_eq(get_tree().root.content_scale_factor, 0.85, 0.0001, "arrastando: nao aplica")
	slider.drag_ended.emit(true)
	assert_almost_eq(get_tree().root.content_scale_factor, 0.7, 0.0001)
	var after := UserSettings.load_file(TMP_SETTINGS)
	assert_almost_eq(after[UserSettings.UI][UserSettings.HUD_SCALE], 0.7, 0.0001)
	assert_eq(after[UserSettings.CAMERA][UserSettings.DISTANCE], 13.0)


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


## Clique tambem aprende (PI 2026-10-22): botao com ponto livre ou o selo Ctrl+tecla pedem o
## ponto pelo input; cursor de mao so quando da para aprender.
func test_clique_na_skill_upavel_pede_o_ponto() -> void:
	await _bind_and_wait()
	_hero.level = 2
	_hero.xp = XpTable.xp_for_level(_hero.xp_curve, 2)
	_plate.update()
	var skill_e := _node("%SkillE") as SkillButton
	assert_eq(skill_e.mouse_default_cursor_shape, Control.CURSOR_POINTING_HAND)
	skill_e._gui_input(_left_click())
	assert_eq(_hero.input._pending_learn, SkillRules.SLOT_E)


func test_clique_no_selo_de_aprender_pede_o_ponto() -> void:
	await _bind_and_wait()
	_hero.level = 2
	_hero.xp = XpTable.xp_for_level(_hero.xp_curve, 2)
	_plate.update()
	var badge := _node("%LearnE") as Control
	assert_eq(badge.mouse_default_cursor_shape, Control.CURSOR_POINTING_HAND)
	badge.gui_input.emit(_left_click())
	assert_eq(_hero.input._pending_learn, SkillRules.SLOT_E)


func test_skill_sem_ponto_nao_aprende_no_clique() -> void:
	await _bind_and_wait()
	var skill_q := _node("%SkillQ") as SkillButton
	assert_ne(skill_q.mouse_default_cursor_shape, Control.CURSOR_POINTING_HAND)
	skill_q._gui_input(_left_click())
	assert_eq(_hero.input._pending_learn, PlayerInput.LEARN_NONE)


func _left_click() -> InputEventMouseButton:
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	return click


func test_medidor_de_dor_so_no_carrasco() -> void:
	await _bind_and_wait()
	assert_false((_plate.get_node("%PainMeter") as Control).visible, "Cavaleiro nao tem Dor")


func test_medidor_de_dor_acende_um_ponto_por_dor() -> void:
	var carrasco := (
		(load("res://scenes/heroes/carrasco.tscn") as PackedScene).instantiate() as Carrasco
	)
	carrasco.name = "2"
	add_child_autofree(carrasco)
	_hero = carrasco
	await _bind_and_wait()
	var meter := _plate.get_node("%PainMeter") as Control
	assert_true(meter.visible)
	assert_eq(_plate._pain_pips.size(), 6, "teto da Dor")
	carrasco.pain = 4
	_plate.update()
	var lit := 0
	for pip: ColorRect in _plate._pain_pips:
		lit += int(pip.color == UiTokens.RED)
	assert_eq(lit, 4)


## Alerta de dano (PI 2026-10-22): o switch da engrenagem vale na hora e grava so [ui].
func test_switch_do_alerta_de_dano_aplica_e_grava() -> void:
	_plate.settings_path = TMP_SETTINGS
	await _bind_and_wait()
	(_node("%DamageAlert") as CheckButton).toggled.emit(false)
	assert_false(DamageVignette.enabled)
	var values := UserSettings.load_file(TMP_SETTINGS)
	assert_false(values[UserSettings.UI][UserSettings.DAMAGE_ALERT])
	DamageVignette.enabled = true
