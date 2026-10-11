extends GutTest
## SPEC-047 §4: o F nao troca sozinho; o bot segura F no bau aberto quando o item e slot vazio ou
## raridade maior, e ignora a escolha lateral e a raridade menor. So o saque (_loot), sem navmesh.

const ARENA: String = "res://scenes/arena/ilha_arcana.tscn"
const KNIGHT: String = "res://scenes/heroes/knight.tscn"
const DT: float = 1.0 / 30.0
## Toque, solta, segura swap_hold_time e solta (sobra de folga).
const LOOT_TICKS: int = 30

var _bot: Hero
var _tick: int = 0


func before_each() -> void:
	add_child_autofree((load(ARENA) as PackedScene).instantiate())
	var director := SpawnDirector.new()
	director.loot_seed = 37
	add_child_autofree(director)
	_bot = (load(KNIGHT) as PackedScene).instantiate() as Hero
	_bot.name = "2"
	_bot.team = GateRules.TEAM_B
	_bot.is_bot = true
	_bot.get_node("Input").set_script(BotInput)
	add_child_autofree(_bot)


func _brain() -> BotInput:
	return _bot.input as BotInput


func _equip(id: StringName) -> void:
	_bot.equipment = Inventory.equip(_bot.equipment, _bot.item_catalog.find(Ids.to_int(id)))


## Bau comum da base B com o [param drop] e o bot ao lado, rodando o saque [param ticks] ticks.
func _loot_chest(drop: StringName) -> Chest:
	var chest: Chest = null
	for node: Node in get_tree().get_nodes_in_group(Chest.GROUP):
		var candidate := node as Chest
		if candidate.home_team == GateRules.TEAM_B and not candidate.rare:
			chest = candidate
			break
	chest.drop = Ids.to_int(drop)
	_bot.global_position = chest.global_position + Vector3(1.0, 0.0, 0.0)
	_brain()._hero = _bot
	for i: int in LOOT_TICKS:
		_tick += 1
		_brain()._reset()
		_brain()._loot(_tick, chest)
		_bot._rollback_tick(DT, _tick, true)
	return chest


func test_bot_equipa_item_em_slot_vazio_segurando_f() -> void:
	var chest := _loot_chest(&"sword_t1")
	assert_true(chest.opened)
	assert_eq(_bot.equipment[ItemData.Slot.WEAPON], Ids.to_int(&"sword_t1"))
	assert_eq(chest.item, Ids.NONE)


func test_bot_equipa_raridade_maior() -> void:
	_equip(&"sword_t1")
	var chest := _loot_chest(&"sword_t2")
	assert_eq(_bot.equipment[ItemData.Slot.WEAPON], Ids.to_int(&"sword_t2"))
	assert_eq(chest.item, Ids.NONE)


func test_bot_ignora_a_escolha_lateral() -> void:
	_equip(&"guard_helm_t1")
	var chest := _loot_chest(&"hunter_helm_t1")
	assert_true(chest.opened)
	assert_eq(_bot.equipment[ItemData.Slot.HELM], Ids.to_int(&"guard_helm_t1"))
	assert_eq(chest.item, Ids.to_int(&"hunter_helm_t1"))


func test_bot_ignora_raridade_menor() -> void:
	_equip(&"sword_t2")
	var chest := _loot_chest(&"sword_t1")
	assert_eq(_bot.equipment[ItemData.Slot.WEAPON], Ids.to_int(&"sword_t2"))
	assert_eq(chest.item, Ids.to_int(&"sword_t1"))
