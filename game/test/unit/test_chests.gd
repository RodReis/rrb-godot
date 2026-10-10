extends GutTest
## Integracao headless: arena + SpawnDirector + Cavaleiro. Baus (GDB §6.2): um por marcador,
## abre uma vez com toque em F a ate chest_interact_range; troca de raridade igual/menor com F
## segurado swap_hold_time, item fica no bau e o antigo some; cura pelo ledger (PI 2026-10-09).

const ARENA: String = "res://scenes/arena/ilha_arcana.tscn"
const KNIGHT: String = "res://scenes/heroes/knight.tscn"
const DT: float = 1.0 / 30.0
const SEED: int = 4242

var _director: SpawnDirector
var _hero: Hero
var _tick: int = 100


func before_each() -> void:
	add_child_autofree((load(ARENA) as PackedScene).instantiate())
	_director = _new_director(SEED)
	_hero = (load(KNIGHT) as PackedScene).instantiate() as Hero
	_hero.name = "1"
	_hero.team = GateRules.TEAM_A
	add_child_autofree(_hero)


func _new_director(loot_seed: int) -> SpawnDirector:
	var director := SpawnDirector.new()
	director.loot_seed = loot_seed
	add_child_autofree(director)
	return director


func _chests(director: SpawnDirector = _director) -> Array[Chest]:
	var result: Array[Chest] = []
	for node: Node in director.get_children():
		if node is Chest:
			result.append(node as Chest)
	return result


## Bau comum de indice [param index], com o [param drop] (numero de Ids ou ChestRules.HEAL) e o
## heroi ao lado.
func _chest_with(drop: int, index: int = 0) -> Chest:
	var commons := _chests().filter(func(c: Chest) -> bool: return not c.rare)
	var chest := commons[index] as Chest
	chest.drop = drop
	_hero.global_position = chest.global_position + Vector3(1.0, 0.0, 0.0)
	return chest


func _number(id: StringName) -> int:
	return Ids.to_int(id)


func _equip(id: StringName) -> void:
	_hero.equipment = Inventory.equip(_hero.equipment, _hero.item_catalog.find(_number(id)))
	_hero._refresh_attributes()


## Roda [param ticks] ticks do heroi com F pressionado ou solto.
func _run(ticks: int, hold: bool) -> void:
	_hero.input.interact_hold = hold
	for i: int in ticks:
		_tick += 1
		_hero._rollback_tick(DT, _tick, true)


func _tap() -> void:
	_run(1, true)
	_run(1, false)


func _hold_ticks(chest: Chest) -> int:
	return SkillRules.seconds_to_ticks(chest.rules.swap_hold_time, NetworkTime.tickrate)


## 12 de base + 8 dos campos laterais (F36) comuns, 4 raros.
func test_um_bau_por_marcador_20_comuns_e_4_raros() -> void:
	var chests := _chests()
	assert_eq(chests.size(), 24)
	assert_eq(chests.filter(func(c: Chest) -> bool: return c.rare).size(), 4)
	for chest: Chest in chests:
		assert_false(chest.opened)
		assert_lt(chest.uid, 0)


func test_uid_de_bau_e_monstro_nao_colidem() -> void:
	var seen: Dictionary = {}
	for node: Node in _director.get_children():
		var uid: int = node.get(&"uid")
		assert_false(seen.has(uid), node.name)
		seen[uid] = true


func test_mesma_seed_mesmos_drops() -> void:
	var other := _new_director(SEED)
	var a := _chests().map(func(c: Chest) -> int: return c.drop)
	var b := _chests(other).map(func(c: Chest) -> int: return c.drop)
	assert_eq(a, b)


func test_toque_em_f_abre_e_equipa_no_slot_vazio() -> void:
	var chest := _chest_with(_number(&"sword_t1"))
	_tap()
	assert_true(chest.opened)
	assert_eq(chest.item, Ids.NONE)
	assert_eq(_hero.equipment[ItemData.Slot.WEAPON], _number(&"sword_t1"))
	assert_almost_eq(_hero.attributes.attack, _hero.hero_data.base_attack + 12.0, 0.0001)


func test_bau_aberto_nao_reabre() -> void:
	var chest := _chest_with(_number(&"sword_t1"))
	_tap()
	chest.drop = _number(&"sword_t2")
	_tap()
	assert_eq(_hero.equipment[ItemData.Slot.WEAPON], _number(&"sword_t1"))


func test_raridade_maior_troca_sozinha() -> void:
	_equip(&"sword_t1")
	var chest := _chest_with(_number(&"sword_t2"))
	_tap()
	assert_eq(_hero.equipment[ItemData.Slot.WEAPON], _number(&"sword_t2"))
	assert_eq(chest.item, Ids.NONE)


func test_raridade_igual_fica_no_bau_ate_segurar_f() -> void:
	_equip(&"guard_helm_t1")
	var chest := _chest_with(_number(&"hunter_helm_t1"))
	_tap()
	assert_true(chest.opened)
	assert_eq(chest.item, _number(&"hunter_helm_t1"))
	assert_eq(_hero.equipment[ItemData.Slot.HELM], _number(&"guard_helm_t1"))
	_run(_hold_ticks(chest), true)
	_run(1, false)
	assert_eq(_hero.equipment[ItemData.Slot.HELM], _number(&"hunter_helm_t1"))
	assert_eq(chest.item, Ids.NONE)


func test_segurar_f_desde_a_abertura_nao_troca_sem_ver_a_oferta() -> void:
	_equip(&"sword_t2")
	var chest := _chest_with(_number(&"sword_t1"))
	_run(_hold_ticks(chest) * 2, true)
	_run(1, false)
	assert_true(chest.opened)
	assert_eq(_hero.equipment[ItemData.Slot.WEAPON], _number(&"sword_t2"))
	assert_eq(chest.item, _number(&"sword_t1"))


func test_soltar_f_antes_de_04_s_nao_troca() -> void:
	_equip(&"sword_t2")
	var chest := _chest_with(_number(&"sword_t1"))
	_tap()
	_run(_hold_ticks(chest) - 1, true)
	_run(1, false)
	assert_eq(_hero.equipment[ItemData.Slot.WEAPON], _number(&"sword_t2"))
	assert_eq(chest.item, _number(&"sword_t1"))


func test_longe_do_bau_nao_abre() -> void:
	var chest := _chest_with(_number(&"sword_t1"))
	var reach := chest.rules.chest_interact_range
	_hero.global_position = chest.global_position + Vector3(reach + 0.5, 0.0, 0.0)
	_tap()
	assert_false(chest.opened)


func test_cura_soma_120_pelo_ledger_ate_o_hp_max() -> void:
	var chest := _chest_with(ChestRules.HEAL)
	_hero.hp = 100
	_tap()
	assert_true(chest.opened)
	assert_eq(_hero.hp, 100 + roundi(chest.rules.heal_amount))
	_chest_with(ChestRules.HEAL, 1)
	_hero.hp = _hero.attributes.max_hp - 10
	_tap()
	assert_eq(_hero.hp, _hero.attributes.max_hp)


func test_fechar_guarda_3_de_3_sobe_hp_max() -> void:
	_equip(&"guard_helm_t1")
	_equip(&"guard_chest_t1")
	var before := _hero.attributes.max_hp
	assert_eq(before, roundi(_hero.hero_data.base_hp + 50.0))
	_chest_with(_number(&"guard_boots_t1"))
	_tap()
	assert_eq(_hero.attributes.max_hp, roundi((_hero.hero_data.base_hp + 50.0) * 1.15))
	assert_almost_eq(_hero.attributes.defense, _hero.hero_data.base_defense + 8 + 5 + 10, 0.0001)


func test_trocar_para_menos_hp_max_corta_o_hp() -> void:
	_equip(&"guard_chest_t2")
	_hero.hp = _hero.attributes.max_hp
	var chest := _chest_with(_number(&"guard_chest_t1"))
	_tap()
	_run(_hold_ticks(chest), true)
	_run(1, false)
	assert_eq(_hero.hp, _hero.attributes.max_hp)
	assert_eq(_hero.attributes.max_hp, roundi(_hero.hero_data.base_hp + 50.0))
