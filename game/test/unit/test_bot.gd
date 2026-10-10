extends GutTest
## Integracao headless: arena + SpawnDirector + ArenaNav + bot (time B) + heroi parado (time A).
## O bot so recebe think(tick); os monstros e o heroi rodam o proprio tick. Base primeiro
## (PI 2026-10-09): limpa a base B (225 XP -> nivel 3, GDB §5.2) e passa a saquear.

const ARENA: String = "res://scenes/arena/arena.tscn"
const KNIGHT: String = "res://scenes/heroes/knight.tscn"
const DT: float = 1.0 / 30.0
## Teto de ticks para limpar a base (~3 min de jogo).
const MAX_TICKS: int = 5400
const MAP_FRAMES: int = 30
## XP do ultimo abate entra pelo ledger no tick seguinte.
const SETTLE_TICKS: int = 5

var _arena: Node3D
var _director: SpawnDirector
var _nav: ArenaNav
var _bot: Hero
var _player: Hero
var _tick: int = 0


func before_each() -> void:
	_arena = (load(ARENA) as PackedScene).instantiate() as Node3D
	add_child_autofree(_arena)
	_director = SpawnDirector.new()
	_director.loot_seed = 37
	add_child_autofree(_director)
	_nav = ArenaNav.new()
	add_child_autofree(_nav)
	_nav.bake(_arena, GateRules.gate_layer(GateRules.TEAM_A))
	_player = _spawn(1, GateRules.TEAM_A, false)
	_bot = _spawn(2, GateRules.TEAM_B, true)
	await _await_path(_bot.global_position, Vector3.ZERO)


## O mapa de navegacao fica pronto depois de algumas iteracoes assincronas.
func _await_path(from: Vector3, to: Vector3) -> void:
	var map := _bot.get_world_3d().navigation_map
	for i: int in MAP_FRAMES:
		await wait_physics_frames(1)
		if NavigationServer3D.map_get_iteration_id(map) == 0:
			continue
		var path := NavigationServer3D.map_get_path(map, from, to, true)
		if not path.is_empty() and path[path.size() - 1].distance_to(to) < 1.0:
			return


func _spawn(id: int, team: int, bot: bool) -> Hero:
	var hero := (load(KNIGHT) as PackedScene).instantiate() as Hero
	hero.name = str(id)
	hero.team = team
	hero.is_bot = bot
	hero.collision_mask = GateRules.hero_mask(team)
	if bot:
		hero.get_node("Input").set_script(BotInput)
	for node: Node in get_tree().get_nodes_in_group(SpawnMarker.GROUP):
		var marker := node as SpawnMarker
		if marker.kind == SpawnMarker.Kind.HERO and marker.team == team:
			hero.transform = marker.global_transform
	add_child_autofree(hero)
	return hero


func _brain() -> BotInput:
	return _bot.input as BotInput


func _base_monsters_alive() -> int:
	var alive := 0
	for node: Node in get_tree().get_nodes_in_group(Monster.GROUP):
		var monster := node as Monster
		if monster.home_team == GateRules.TEAM_B and monster.is_alive():
			alive += 1
	return alive


func _step() -> void:
	_tick += 1
	_brain().think(_tick)
	for node: Node in get_tree().get_nodes_in_group(Monster.GROUP):
		(node as Monster)._on_network_tick(DT, _tick)
	_bot._rollback_tick(DT, _tick, true)


func test_input_do_bot_e_do_servidor() -> void:
	assert_true(_bot.input is BotInput)
	assert_eq(_bot.input.get_multiplayer_authority(), 1)
	assert_eq(_player.input.get_multiplayer_authority(), 1)


func test_navmesh_tem_caminho_da_base_ao_centro() -> void:
	var map := _bot.get_world_3d().navigation_map
	var path := NavigationServer3D.map_get_path(map, _bot.global_position, Vector3.ZERO, true)
	assert_gt(path.size(), 1)
	assert_lt(path[path.size() - 1].length(), 1.0)


func test_jogador_atras_do_portao_inimigo_nao_faz_o_bot_empurrar_o_portao() -> void:
	# Jogador no patio da base A, bot do lado de fora do portao A: o navmesh do bot tem o
	# portao A como parede, entao ele para no ponto alcancavel em vez de andar reto.
	var gate_a: Gate = null
	for node: Node in get_tree().get_nodes_in_group(Gate.GROUP):
		if (node as Gate).team == GateRules.TEAM_A:
			gate_a = node as Gate
	var inward := (_home_a() - gate_a.global_position).normalized()
	_player.global_position = gate_a.global_position + inward * 3.0
	_bot.global_position = gate_a.global_position - inward * 1.5
	_bot.level = 5
	_bot.xp = 740
	_brain().think(1)
	assert_eq(_brain().state, BotRules.State.FIGHT)
	assert_true(_bot.input.movement.is_zero_approx())


func _home_a() -> Vector3:
	for node: Node in get_tree().get_nodes_in_group(SpawnMarker.GROUP):
		var marker := node as SpawnMarker
		if marker.kind == SpawnMarker.Kind.HERO and marker.team == GateRules.TEAM_A:
			return marker.global_position
	return Vector3.ZERO


func test_comeca_farmando_e_anda_ate_o_monstro_da_base() -> void:
	var start := _bot.global_position
	for i: int in 30:
		_step()
	assert_eq(_brain().state, BotRules.State.FARM)
	assert_gt(_bot.global_position.distance_to(start), 1.0)


func test_limpa_a_base_chega_ao_nivel_3_e_saqueia() -> void:
	while _tick < MAX_TICKS and _base_monsters_alive() > 0:
		_step()
	for i: int in SETTLE_TICKS:
		_step()
	gut.p("base limpa no tick %d (%.0f s): Nv %d, %d XP" % [_tick, _tick * DT, _bot.level, _bot.xp])
	assert_eq(_base_monsters_alive(), 0)
	assert_gte(_bot.xp, 225)
	assert_gte(_bot.level, 3)
	assert_eq(_brain().state, BotRules.State.LOOT)
	var limit := _tick + MAX_TICKS
	while _tick < limit and _opened_base_chests() < 6:
		_step()
	gut.p("baus da base abertos no tick %d" % _tick)
	assert_eq(_opened_base_chests(), 6)
	_step()
	assert_ne(_brain().state, BotRules.State.LOOT)


func _opened_base_chests() -> int:
	var opened := 0
	for node: Node in get_tree().get_nodes_in_group(Chest.GROUP):
		var chest := node as Chest
		if chest.home_team == GateRules.TEAM_B and chest.opened:
			opened += 1
	return opened


## Mata os monstros (menos os da base [param keep]) e abre todos os baus.
func _clear(keep: int = -1) -> void:
	for node: Node in get_tree().get_nodes_in_group(Monster.GROUP):
		var monster := node as Monster
		if monster.home_team != keep:
			monster.hp = 0
	for node: Node in get_tree().get_nodes_in_group(Chest.GROUP):
		(node as Chest).opened = true


## 5:00 no servidor (main.gd): portoes caem e o navmesh do bot e refeito sem eles.
func _fall_gates() -> void:
	for node: Node in get_tree().get_nodes_in_group(Gate.GROUP):
		(node as Gate).fall()
	_nav.bake(_arena)
	await _await_path(_center(), _home_a())


func _center() -> Vector3:
	for node: Node in get_tree().get_nodes_in_group(SpawnMarker.GROUP):
		var marker := node as SpawnMarker
		if marker.kind == SpawnMarker.Kind.BOSS:
			return marker.global_position
	return Vector3.ZERO


func _nearest_alive_distance(team: int) -> float:
	var best := INF
	for node: Node in get_tree().get_nodes_in_group(Monster.GROUP):
		var monster := node as Monster
		if monster.home_team == team and monster.is_alive():
			best = minf(best, _bot.global_position.distance_to(monster.global_position))
	return best


func test_sem_alvo_no_centro_o_bot_para_e_nao_gira() -> void:
	# #52: boss morto, sem monstro nem bau do lado do bot; ja no ponto de espera ele para.
	_clear()
	_bot.global_position = _center() + Vector3(0.2, 0.0, 0.1)
	for i: int in 10:
		_step()
		assert_true(_bot.input.movement.is_zero_approx(), "tick %d: %s" % [i, _bot.input.movement])


func test_portoes_caidos_sem_alvo_proprio_farma_a_base_do_jogador() -> void:
	# PI 2026-10-09 (#52): depois dos 5:00 o bot vem farmar o que sobrou na base do jogador.
	_clear(GateRules.TEAM_A)
	await _fall_gates()
	_bot.global_position = _center()
	var start := _nearest_alive_distance(GateRules.TEAM_A)
	for i: int in 150:
		_step()
	assert_eq(_brain().state, BotRules.State.FARM)
	assert_lt(_nearest_alive_distance(GateRules.TEAM_A), start - 5.0)


func test_portoes_caidos_sem_monstro_vai_ate_o_jogador() -> void:
	_clear()
	await _fall_gates()
	_bot.global_position = _center()
	var start := _bot.global_position.distance_to(_player.global_position)
	for i: int in 150:
		_step()
	assert_lt(_bot.global_position.distance_to(_player.global_position), start - 5.0)
