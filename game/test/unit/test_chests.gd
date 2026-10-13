extends GutTest
## Integracao headless: arena + SpawnDirector + Cavaleiro. Baus (GDB §6.2): um por marcador,
## abre uma vez com toque em F a ate chest_interact_range (abrir nao equipa) e mostra 3 itens a
## quem abriu (F61, ADR-0014); o clique (input chest_pick) leva 1, mesmo pior que o equipado, e
## fecha o bau; o adversario nao abre nem escolhe; o item antigo some; cura pelo ledger.

const ARENA: String = "res://scenes/arena/ilha_arcana.tscn"
const KNIGHT: String = "res://scenes/heroes/knight.tscn"
const DT: float = 1.0 / 30.0
const SEED: int = 4242
const THREE: Array[StringName] = [&"sword_t1", &"guard_helm_t1", &"hunter_boots_t1"]

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


## Bau comum de indice [param index], com os [param drops] (numeros de Ids ou [HEAL]) e o heroi
## ao lado.
func _chest_with(drops: Array[StringName], index: int = 0) -> Chest:
	var numbers := PackedInt32Array()
	for id: StringName in drops:
		numbers.append(Ids.to_int(id))
	return _chest_with_numbers(numbers, index)


func _chest_with_numbers(drops: PackedInt32Array, index: int = 0) -> Chest:
	var commons := _chests().filter(func(c: Chest) -> bool: return c.kind == ChestRules.Kind.COMMON)
	var chest := commons[index] as Chest
	chest.drops = drops
	_hero.global_position = chest.global_position + Vector3(1.0, 0.0, 0.0)
	return chest


func _number(id: StringName) -> int:
	return Ids.to_int(id)


func _equip(id: StringName) -> void:
	_hero.equipment = Inventory.equip(_hero.equipment, _hero.item_catalog.find(_number(id)))
	_hero._refresh_attributes()


## Roda [param ticks] ticks de [param hero] com F pressionado ou solto.
func _run(ticks: int, hold: bool, hero: Hero = _hero) -> void:
	hero.input.interact_hold = hold
	for i: int in ticks:
		_tick += 1
		hero._rollback_tick(DT, _tick, true)


func _tap(hero: Hero = _hero) -> void:
	_run(1, true, hero)
	_run(1, false, hero)


## Clique no item [param index] do menu: o input leva a escolha por um tick; o heroi aplica o
## item do ledger no tick seguinte.
func _pick(index: int, hero: Hero = _hero) -> void:
	hero.input.chest_pick = index
	_run(1, false, hero)
	hero.input.chest_pick = PlayerInput.PICK_NONE
	_run(1, false, hero)


func _other() -> Hero:
	var other := (load(KNIGHT) as PackedScene).instantiate() as Hero
	other.name = "2"
	other.team = GateRules.TEAM_B
	add_child_autofree(other)
	return other


func _of_kind(kind: ChestRules.Kind) -> Array[Chest]:
	var result: Array[Chest] = []
	for chest: Chest in _chests():
		if chest.kind == kind:
			result.append(chest)
	return result


## 12 de base + 8 dos campos laterais (F36) comuns, 4 reforcados dos cantos (F55), 4 raros.
func test_um_bau_por_marcador_20_comuns_4_reforcados_e_4_raros() -> void:
	var chests := _chests()
	assert_eq(chests.size(), 28)
	assert_eq(_of_kind(ChestRules.Kind.COMMON).size(), 20)
	assert_eq(_of_kind(ChestRules.Kind.REINFORCED).size(), 4)
	assert_eq(_of_kind(ChestRules.Kind.RARE).size(), 4)
	for chest: Chest in chests:
		assert_false(chest.opened)
		assert_lt(chest.uid, 0)


## SPEC-055 §4: variacao do bau comum com cantoneiras; cintas na cor do reforcado; mesma
## dobradica (a tampa continua no node Lid que o bau gira).
func test_bau_reforcado_usa_o_modelo_reforcado() -> void:
	for chest: Chest in _of_kind(ChestRules.Kind.REINFORCED):
		var body := chest.get_node("Body") as Node3D
		var lid := chest.get_node("Lid/Mesh") as Node3D
		assert_eq(body.scene_file_path, chest.reinforced_body.resource_path)
		assert_eq(lid.scene_file_path, chest.reinforced_lid.resource_path)
		var painted := false
		for node: Node in body.find_children("*", "MeshInstance3D", true, false):
			var mi := node as MeshInstance3D
			for i: int in range(mi.get_surface_override_material_count()):
				painted = (
					painted or mi.get_surface_override_material(i) == chest.reinforced_material
				)
		assert_true(painted, chest.name)
	var common := _of_kind(ChestRules.Kind.COMMON)[0]
	assert_ne(
		(common.get_node("Body") as Node3D).scene_file_path, common.reinforced_body.resource_path
	)


func test_uid_de_bau_e_monstro_nao_colidem() -> void:
	var seen: Dictionary = {}
	for node: Node in _director.get_children():
		var uid: int = node.get(&"uid")
		assert_false(seen.has(uid), node.name)
		seen[uid] = true


func test_mesma_seed_mesmos_drops() -> void:
	var other := _new_director(SEED)
	var a := _chests().map(func(c: Chest) -> PackedInt32Array: return c.drops)
	var b := _chests(other).map(func(c: Chest) -> PackedInt32Array: return c.drops)
	assert_eq(a, b)


func test_bau_comum_sorteia_3_itens_ou_cura() -> void:
	for chest: Chest in _of_kind(ChestRules.Kind.COMMON):
		var heal := chest.drops == PackedInt32Array([ChestRules.HEAL])
		assert_true(heal or chest.drops.size() == ChestRules.CHOICES, str(chest.drops))


func test_abrir_mostra_3_itens_a_quem_abriu_e_nao_equipa() -> void:
	var chest := _chest_with(THREE)
	_tap()
	assert_true(chest.opened)
	assert_eq(chest.opener, _hero.peer_id)
	assert_eq(chest.choices, chest.drops)
	assert_eq(_hero.equipment, Inventory.NONE)


func test_clique_leva_o_item_escolhido_e_fecha_o_bau() -> void:
	var chest := _chest_with(THREE)
	_tap()
	_pick(1)
	assert_eq(_hero.equipment[ItemData.Slot.HELM], _number(&"guard_helm_t1"))
	assert_eq(_hero.equipment[ItemData.Slot.WEAPON], Ids.NONE)
	assert_true(chest.choices.is_empty())
	_pick(0)
	assert_eq(_hero.equipment[ItemData.Slot.WEAPON], Ids.NONE, "leva so 1")


func test_pode_escolher_item_pior_que_o_equipado() -> void:
	_equip(&"sword_t2")
	_chest_with(THREE)
	_tap()
	_pick(0)
	assert_eq(_hero.equipment[ItemData.Slot.WEAPON], _number(&"sword_t1"))


func test_bau_aberto_nao_reabre_nem_sorteia_de_novo() -> void:
	var chest := _chest_with(THREE)
	_tap()
	chest.drops = PackedInt32Array([_number(&"sword_t2")])
	_tap()
	assert_eq(chest.choices.size(), 3)
	assert_eq(chest.choices[0], _number(&"sword_t1"))


## Esc fecha o menu sem pegar: o bau segue reservado e o F reabre o mesmo menu (so cliente).
func test_sem_escolha_o_bau_fica_reservado_a_quem_abriu() -> void:
	var chest := _chest_with(THREE)
	_tap()
	var other := _other()
	other.global_position = chest.global_position + Vector3(-1.0, 0.0, 0.0)
	_tap(other)
	_pick(2, other)
	assert_eq(other.equipment, Inventory.NONE)
	assert_eq(chest.opener, _hero.peer_id)
	assert_eq(chest.choices.size(), 3)
	_pick(2)
	assert_eq(_hero.equipment[ItemData.Slot.BOOTS], _number(&"hunter_boots_t1"))


func test_indice_invalido_ou_fora_do_alcance_nao_leva() -> void:
	var chest := _chest_with(THREE)
	_tap()
	for index: int in [-1, 3, 99]:
		_pick(index)
	assert_eq(_hero.equipment, Inventory.NONE)
	_hero.global_position = (
		chest.global_position + Vector3(chest.rules.chest_interact_range + 1, 0, 0)
	)
	_pick(0)
	assert_eq(_hero.equipment, Inventory.NONE)
	assert_eq(chest.choices.size(), 3)


func test_longe_do_bau_nao_abre() -> void:
	var chest := _chest_with(THREE)
	var reach := chest.rules.chest_interact_range
	_hero.global_position = chest.global_position + Vector3(reach + 0.5, 0.0, 0.0)
	_tap()
	assert_false(chest.opened)


func test_cura_soma_120_pelo_ledger_ate_o_hp_max_sem_menu() -> void:
	var chest := _chest_with_numbers(PackedInt32Array([ChestRules.HEAL]))
	_hero.hp = 100
	_tap()
	assert_true(chest.opened)
	assert_true(chest.choices.is_empty())
	assert_eq(_hero.hp, 100 + roundi(chest.rules.heal_amount))
	_chest_with_numbers(PackedInt32Array([ChestRules.HEAL]), 1)
	_hero.hp = _hero.attributes.max_hp - 10
	_tap()
	assert_eq(_hero.hp, _hero.attributes.max_hp)


func test_fechar_guarda_3_de_3_sobe_hp_max() -> void:
	_equip(&"guard_helm_t1")
	_equip(&"guard_chest_t1")
	var before := _hero.attributes.max_hp
	assert_eq(before, roundi(_hero.hero_data.base_hp + 50.0))
	_chest_with([&"sword_t1", &"guard_boots_t1", &"hunter_helm_t1"])
	_tap()
	_pick(1)
	assert_eq(_hero.attributes.max_hp, roundi((_hero.hero_data.base_hp + 50.0) * 1.15))
	assert_almost_eq(_hero.attributes.defense, _hero.hero_data.base_defense + 8 + 5 + 10, 0.0001)


func test_trocar_para_menos_hp_max_corta_o_hp() -> void:
	_equip(&"guard_chest_t2")
	_hero.hp = _hero.attributes.max_hp
	_chest_with([&"hunter_chest_t2", &"sword_t2", &"guard_helm_t2"])
	_tap()
	_pick(0)
	assert_eq(_hero.hp, _hero.attributes.max_hp)
	assert_eq(_hero.attributes.max_hp, roundi(_hero.hero_data.base_hp + 75.0))
