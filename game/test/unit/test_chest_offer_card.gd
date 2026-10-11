extends GutTest
## Card da oferta do bau (SPEC-047 §3): so aparece com bau aberto, com item, ao alcance e na
## visao do heroi local; o prompt "Segure F" so quando ItemRules.offer vale para ele.

const KNIGHT: PackedScene = preload("res://scenes/heroes/knight.tscn")
const CHEST: PackedScene = preload("res://scenes/world/chest.tscn")

var _hero: Hero
var _chest: Chest
var _card: ChestOfferCard


func before_each() -> void:
	var camera := Camera3D.new()
	add_child_autofree(camera)
	camera.position = Vector3(0.0, 12.0, 6.0)
	camera.look_at(Vector3.ZERO)
	camera.make_current()
	_hero = KNIGHT.instantiate() as Hero
	_hero.name = "1"
	add_child_autofree(_hero)
	_chest = CHEST.instantiate() as Chest
	add_child_autofree(_chest)
	_chest.opened = true
	_hero.global_position = Vector3(1.0, 0.0, 0.0)
	_card = ChestOfferCard.new()
	add_child_autofree(_card)
	var chests: Array[Chest] = [_chest]
	_card.set_chests(chests)
	_card.bind(_hero)
	await wait_process_frames(1)


func _number(id: StringName) -> int:
	return Ids.to_int(id)


func _equip(id: StringName) -> void:
	_hero.equipment = Inventory.equip(_hero.equipment, _hero.item_catalog.find(_number(id)))


func test_sem_item_no_bau_o_card_fica_escondido() -> void:
	_card.update()
	assert_false(_card.visible)


func test_bau_fechado_nao_mostra_o_card() -> void:
	_chest.opened = false
	_chest.item = _number(&"sword_t1")
	_card.update()
	assert_false(_card.visible)


func test_bau_aberto_ao_alcance_mostra_item_e_prompt_com_slot_vazio() -> void:
	_chest.item = _number(&"sword_t1")
	_card.update()
	assert_true(_card.visible)
	assert_eq(_card._name.text, _hero.item_catalog.find(_number(&"sword_t1")).display_name)
	assert_eq(_card._rarity.text, "Comum")
	assert_true(_card._prompt.visible)


func test_sem_oferta_o_card_mostra_a_comparacao_mas_nao_o_prompt() -> void:
	_equip(&"sword_t2")
	_chest.item = _number(&"sword_t1")
	_card.update()
	assert_true(_card.visible)
	assert_false(_card._prompt.visible)
	assert_gt(_card._rows.get_child_count(), 0)


func test_oferta_lateral_mostra_o_prompt_e_a_mudanca_de_conjunto() -> void:
	_equip(&"guard_helm_t1")
	_chest.item = _number(&"hunter_helm_t1")
	_card.update()
	assert_true(_card._prompt.visible)
	assert_string_contains(_card._sets.text, "Guarda 1/3 → 0/3")


func test_longe_do_bau_o_card_some() -> void:
	_chest.item = _number(&"sword_t1")
	_card.update()
	assert_true(_card.visible)
	_hero.global_position = Vector3(50.0, 0.0, 0.0)
	_card.update()
	assert_false(_card.visible)


func test_card_acompanha_a_troca_do_equipamento() -> void:
	_equip(&"sword_t2")
	_chest.item = _number(&"sword_t1")
	_card.update()
	assert_false(_card._prompt.visible)
	_hero.equipment = Inventory.NONE
	_card.update()
	assert_true(_card._prompt.visible)


func test_anel_enche_com_o_f_segurado_depois_da_abertura() -> void:
	_chest.item = _number(&"sword_t1")
	_chest.opened_tick = -50
	_hero.interact_ticks = _chest.hold_ticks() / 2
	_card.update()
	assert_almost_eq(_card._ring.progress, 0.5, 0.1)


func test_anel_ignora_o_f_segurado_desde_antes_da_abertura() -> void:
	_chest.item = _number(&"sword_t1")
	_chest.opened_tick = NetworkTime.tick
	_hero.interact_ticks = _chest.hold_ticks() / 2
	_card.update()
	assert_eq(_card._ring.progress, 0.0)


func test_card_fica_dentro_da_viewport() -> void:
	_chest.item = _number(&"sword_t1")
	_card.update()
	var bounds := Rect2(Vector2.ZERO, get_viewport().get_visible_rect().size)
	assert_true(bounds.encloses(Rect2(_card.position, _card.size)))
