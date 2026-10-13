extends GutTest
## Menu do bau (F61, ADR-0014): F perto do bau abre o menu com os 3 itens quando o bau e do heroi
## local; o clique manda a escolha pelo input e fecha; Esc fecha sem pegar e o F reabre; bau de
## outro heroi, de cura ou longe nao abre. Heroi parado enquanto o menu esta aberto.

const KNIGHT: PackedScene = preload("res://scenes/heroes/knight.tscn")
const CHEST: PackedScene = preload("res://scenes/world/chest.tscn")
const THREE: Array[StringName] = [&"sword_t1", &"guard_helm_t1", &"hunter_boots_t1"]

var _hero: Hero
var _chest: Chest
var _menu: ChestChoiceMenu


func before_each() -> void:
	_hero = KNIGHT.instantiate() as Hero
	_hero.name = "1"
	add_child_autofree(_hero)
	_chest = CHEST.instantiate() as Chest
	add_child_autofree(_chest)
	_hero.global_position = Vector3(1.0, 0.0, 0.0)
	_menu = ChestChoiceMenu.new()
	add_child_autofree(_menu)
	var chests: Array[Chest] = [_chest]
	_menu.set_chests(chests)
	_menu.bind(_hero)
	await wait_process_frames(1)


func after_each() -> void:
	PlayerInput.suspended = false


func _number(id: StringName) -> int:
	return Ids.to_int(id)


## O servidor abriu o bau para [param opener] com os [param ids].
func _opened_by(opener: int, ids: Array[StringName]) -> void:
	_chest.opened = true
	_chest.opener = opener
	_chest.choices = PackedInt32Array()
	for id: StringName in ids:
		_chest.choices.append(_number(id))


func _cards() -> Array[ChestChoiceCard]:
	var result: Array[ChestChoiceCard] = []
	for node: Node in _menu.find_children("*", "", true, false):
		if node is ChestChoiceCard and not node.is_queued_for_deletion():
			result.append(node as ChestChoiceCard)
	return result


func test_sem_bau_ao_alcance_o_menu_fica_fechado() -> void:
	_hero.global_position = Vector3(50.0, 0.0, 0.0)
	_menu.request_open()
	_opened_by(_hero.peer_id, THREE)
	_menu.update()
	assert_false(_menu.visible)


func test_f_espera_o_servidor_e_abre_com_os_3_itens() -> void:
	_menu.request_open()
	_menu.update()
	assert_false(_menu.visible, "bau ainda fechado")
	_opened_by(_hero.peer_id, THREE)
	_menu.update()
	assert_true(_menu.visible)
	assert_eq(_cards().size(), 3)
	assert_eq(
		_cards()[1]._name.text, _hero.item_catalog.find(_number(&"guard_helm_t1")).display_name
	)
	assert_true(PlayerInput.suspended)


func test_bau_de_outro_heroi_ou_de_cura_nao_abre() -> void:
	_opened_by(2, THREE)
	_menu.request_open()
	_menu.update()
	assert_false(_menu.visible)
	_opened_by(_hero.peer_id, [])
	_menu.request_open()
	_menu.update()
	assert_false(_menu.visible)


func test_clique_manda_a_escolha_e_fecha() -> void:
	_opened_by(_hero.peer_id, THREE)
	_menu.request_open()
	_menu.update()
	_cards()[2].chosen.emit(2)
	assert_false(_menu.visible)
	assert_false(PlayerInput.suspended)
	assert_eq(_hero.input._pending_pick, 2)


func test_esc_fecha_sem_pegar_e_o_f_reabre_o_mesmo_menu() -> void:
	_opened_by(_hero.peer_id, THREE)
	_menu.request_open()
	_menu.update()
	_menu.close()
	assert_false(_menu.visible)
	assert_eq(_hero.input._pending_pick, PlayerInput.PICK_NONE)
	_menu.request_open()
	_menu.update()
	assert_true(_menu.visible)
	assert_eq(_cards().size(), 3)


func test_item_pior_mostra_a_comparacao_negativa() -> void:
	_hero.equipment = Inventory.equip(
		_hero.equipment, _hero.item_catalog.find(_number(&"sword_t2"))
	)
	_opened_by(_hero.peer_id, THREE)
	_menu.request_open()
	_menu.update()
	var rows := _cards()[0]._rows
	assert_gt(rows.get_child_count(), 0)
	var delta := (rows.get_child(0) as HBoxContainer).get_child(1) as Label
	assert_string_starts_with(delta.text, "−")


func test_longe_ou_escolhido_o_menu_fecha() -> void:
	_opened_by(_hero.peer_id, THREE)
	_menu.request_open()
	_menu.update()
	_chest.choices = PackedInt32Array()
	_menu.update()
	assert_false(_menu.visible)
	_opened_by(_hero.peer_id, THREE)
	_menu.request_open()
	_menu.update()
	_hero.global_position = Vector3(50.0, 0.0, 0.0)
	_menu.update()
	assert_false(_menu.visible)
	assert_false(PlayerInput.suspended)
