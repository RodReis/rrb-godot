extends GutTest
## Integracao headless do bot na fase 2 (F19): arena + navmesh + bot (time B) + heroi parado (time
## A) + MatchClock. A zona e o adversario vivo vem so do que um cliente tambem sabe (CONVENTION
## §4.6). O bot recebe think(tick); o heroi roda o proprio _rollback_tick.

const ARENA: String = "res://scenes/arena/ilha_arcana.tscn"
const KNIGHT: String = "res://scenes/heroes/knight.tscn"
const RULES: String = "res://shared/data/rules/match_pacing.tres"
const DT: float = 1.0 / 30.0
const RATE: int = 30
const START_TICK: int = 1000
const MAP_FRAMES: int = 30
const PHASE1_END: float = 300.0
## 1 min de fase 2: a zona esta em 26 u (match_pacing.tres) e a base do bot (~34 u) ficou fora.
const ZONE_MIN_1: float = PHASE1_END + 60.0
const STEPS: int = 150

var _arena: Node3D
var _nav: ArenaNav
var _bot: Hero
var _player: Hero


func before_each() -> void:
	_arena = (load(ARENA) as PackedScene).instantiate() as Node3D
	add_child_autofree(_arena)
	var director := SpawnDirector.new()
	director.loot_seed = 37
	add_child_autofree(director)
	_nav = ArenaNav.new()
	add_child_autofree(_nav)
	_nav.bake(_arena, GateRules.gate_layer(GateRules.TEAM_A))
	_player = _spawn(1, GateRules.TEAM_A, false)
	_bot = _spawn(2, GateRules.TEAM_B, true)
	await _await_path(_bot.global_position, Vector3.ZERO)
	_clear()
	_fall_gates()
	await _await_path(_center(), _bot.global_position)


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


## Sem monstro nem bau (so o duelo conta) e portoes caidos (5:00, main.gd): navmesh sem parede.
func _clear() -> void:
	for node: Node in get_tree().get_nodes_in_group(Monster.GROUP):
		(node as Monster).hp = 0
	for node: Node in get_tree().get_nodes_in_group(Chest.GROUP):
		(node as Chest).opened = true


func _fall_gates() -> void:
	for node: Node in get_tree().get_nodes_in_group(Gate.GROUP):
		(node as Gate).fall()
	_nav.bake(_arena)


## Relogio da partida que marca [param elapsed] segundos no START_TICK.
func _start_clock(elapsed: float) -> void:
	var clock := MatchClock.new()
	clock.rules = load(RULES) as MatchRules
	add_child_autofree(clock)
	clock.start(START_TICK, RATE, elapsed)


func _brain() -> BotInput:
	return _bot.input as BotInput


func _center() -> Vector3:
	for node: Node in get_tree().get_nodes_in_group(SpawnMarker.GROUP):
		var marker := node as SpawnMarker
		if marker.kind == SpawnMarker.Kind.BOSS:
			return marker.global_position
	return Vector3.ZERO


func _flat_distance_to_center() -> float:
	return Vector2(_bot.global_position.x, _bot.global_position.z).length()


func _run(ticks: int) -> void:
	for i: int in ticks:
		var tick := START_TICK + i
		_brain().think(tick)
		_bot._rollback_tick(DT, tick, true)


## Direcao a partir do centro sem moita entre 5 e 21 u (o mato decide sozinho no F32).
func _open_direction() -> Vector3:
	for i: int in 16:
		var dir := Vector3.FORWARD.rotated(Vector3.UP, TAU * i / 16.0)
		var clear := true
		for d: float in [6.0, 11.5, 12.5, 20.0]:
			_player.global_position = _center() + dir * d
			clear = clear and not _player.hidden_from(_bot)
		if clear:
			return dir
	return Vector3.FORWARD


func test_fora_da_zona_foge_para_o_centro() -> void:
	_start_clock(ZONE_MIN_1)
	var start := _flat_distance_to_center()
	assert_gt(start, 26.0, "a base fica fora da zona de 26 u")
	_brain().think(START_TICK)
	assert_eq(_brain().state, BotRules.State.FLEE_ZONE)
	_run(STEPS)
	assert_lt(_flat_distance_to_center(), start - 5.0, "andou para o centro")
	assert_ne(_brain().state, BotRules.State.FLEE_ZONE, "dentro da margem, a fuga acaba")


func test_dentro_da_zona_persegue_o_adversario_vivo() -> void:
	_start_clock(ZONE_MIN_1)
	_bot.global_position = _center()
	_player.global_position = _center() + _open_direction() * 6.0
	_brain().think(START_TICK)
	assert_eq(_brain().state, BotRules.State.CHASE, "mesmo nivel e HP: sem vantagem, so persegue")
	var to_enemy := (_player.global_position - _bot.global_position).normalized()
	assert_gt(_bot.input.aim.dot(to_enemy), 0.9)


func test_sem_ver_o_adversario_espera_no_centro_da_zona() -> void:
	_start_clock(ZONE_MIN_1)
	var away := _open_direction()
	_bot.global_position = _center() + away * 10.0
	_player.global_position = _center() - away * 20.0
	var start := _flat_distance_to_center()
	_run(STEPS)
	assert_eq(_brain().state, BotRules.State.CHASE)
	assert_lt(_flat_distance_to_center(), start - 3.0)


func test_adversario_morto_nao_e_perseguido() -> void:
	_start_clock(ZONE_MIN_1)
	_bot.global_position = _center()
	_player.hp = 0
	_brain().think(START_TICK)
	assert_ne(_brain().state, BotRules.State.CHASE)


func test_adversario_fora_da_zona_nao_e_perseguido() -> void:
	_start_clock(ZONE_MIN_1)
	_brain()._hero = _bot
	_bot.global_position = _center() + Vector3(10.0, 0.0, 0.0)
	_player.global_position = _center() + Vector3(30.0, 0.0, 0.0)
	var view := _brain()._view(START_TICK, _player)
	assert_false(view.enemy_in_zone, "26 u de raio, adversario a 30 u")
	assert_true(view.enemy_alive)


func test_view_so_le_o_relogio_replicado() -> void:
	_start_clock(ZONE_MIN_1)
	_brain()._hero = _bot
	_bot.global_position = _center() + Vector3(20.0, 0.0, 0.0)
	var view := _brain()._view(START_TICK, null)
	assert_true(view.phase2)
	assert_almost_eq(view.zone_edge, 6.0, 0.01, "zona de 26 u, bot a 20 u do centro")
	assert_true(view.enemy_in_zone, "sem ver o adversario, supoe que esta na zona")


func test_antes_dos_5_00_nao_ha_zona() -> void:
	_start_clock(PHASE1_END - 1.0)
	_brain()._hero = _bot
	var view := _brain()._view(START_TICK, null)
	assert_false(view.phase2)
	assert_eq(view.zone_edge, INF)
