extends GutTest
## F61 (ADR-0014): o bot toca F, recebe os 3 itens do bau e clica no melhor upgrade (slot vazio
## ou raridade maior, a maior raridade primeiro); sem upgrade nao leva nada (nunca troca por pior
## nem pela lateral). So o saque (_loot), sem navmesh.

const ARENA: String = "res://scenes/arena/ilha_arcana.tscn"
const KNIGHT: String = "res://scenes/heroes/knight.tscn"
const DT: float = 1.0 / 30.0
## Toque, solta, escolhe (sobra de folga).
const LOOT_TICKS: int = 10

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


## Bau comum da base B com os [param drops] e o bot ao lado, rodando o saque LOOT_TICKS ticks.
func _loot_chest(drops: Array[StringName]) -> Chest:
	var chest: Chest = null
	for node: Node in get_tree().get_nodes_in_group(Chest.GROUP):
		var candidate := node as Chest
		if candidate.home_team == GateRules.TEAM_B and candidate.kind != ChestRules.Kind.RARE:
			chest = candidate
			break
	chest.drops = PackedInt32Array()
	for id: StringName in drops:
		chest.drops.append(Ids.to_int(id))
	_bot.global_position = chest.global_position + Vector3(1.0, 0.0, 0.0)
	_brain()._hero = _bot
	for i: int in LOOT_TICKS:
		_tick += 1
		_brain()._reset()
		_brain()._loot(_tick, chest)
		_bot._rollback_tick(DT, _tick, true)
	return chest


func test_bot_equipa_item_em_slot_vazio() -> void:
	var chest := _loot_chest([&"sword_t1", &"guard_helm_t1", &"hunter_boots_t1"])
	assert_true(chest.opened)
	assert_eq(_bot.equipment[ItemData.Slot.WEAPON], Ids.to_int(&"sword_t1"))
	assert_true(chest.choices.is_empty())


func test_bot_escolhe_a_maior_raridade_entre_os_upgrades() -> void:
	_equip(&"sword_t1")
	var chest := _loot_chest([&"guard_helm_t1", &"sword_t2", &"hunter_boots_t1"])
	assert_eq(_bot.equipment[ItemData.Slot.WEAPON], Ids.to_int(&"sword_t2"))
	assert_eq(_bot.equipment[ItemData.Slot.HELM], Ids.NONE)
	assert_true(chest.choices.is_empty())


func test_bot_ignora_a_lateral_e_a_raridade_menor() -> void:
	_equip(&"guard_helm_t1")
	_equip(&"sword_t2")
	var chest := _loot_chest([&"hunter_helm_t1", &"sword_t1"])
	assert_true(chest.opened)
	assert_eq(_bot.equipment[ItemData.Slot.HELM], Ids.to_int(&"guard_helm_t1"))
	assert_eq(_bot.equipment[ItemData.Slot.WEAPON], Ids.to_int(&"sword_t2"))
	assert_eq(chest.choices.size(), 2)
