extends GutTest
## ArenaNav com mapa proprio (F19): dois bots no mesmo processo (soak bot x bot) tem um navmesh por
## time, cada um com o portao do adversario como parede. O que vale para um nao pode valer para o
## outro, e o bot acha o mapa do proprio time.

const ARENA: String = "res://scenes/arena/ilha_arcana.tscn"
const KNIGHT: String = "res://scenes/heroes/knight.tscn"
const MAP_FRAMES: int = 60
## Folga para dizer que o caminho chegou ao ponto pedido (u).
const REACHED: float = 1.0

var _arena: Node3D
var _nav_a: ArenaNav
var _nav_b: ArenaNav


func before_each() -> void:
	_arena = (load(ARENA) as PackedScene).instantiate() as Node3D
	add_child_autofree(_arena)
	_nav_a = _make_nav(GateRules.TEAM_A)
	_nav_b = _make_nav(GateRules.TEAM_B)
	await _await_maps()


func _make_nav(team: int) -> ArenaNav:
	var nav := ArenaNav.new()
	nav.team = team
	nav.own_map = true
	add_child_autofree(nav)
	var enemy := GateRules.TEAM_B if team == GateRules.TEAM_A else GateRules.TEAM_A
	nav.bake(_arena, GateRules.gate_layer(enemy))
	return nav


## Espera os dois mapas sincronizarem: ate A e B acharem caminho do centro para a propria base.
func _await_maps() -> void:
	for i: int in MAP_FRAMES:
		await wait_physics_frames(1)
		var ready := true
		for nav: ArenaNav in [_nav_a, _nav_b]:
			ready = ready and _gap(nav, Vector3.ZERO, _spawn_of(nav.team)) < REACHED
		if ready:
			return


func _spawn_of(team: int) -> Vector3:
	for node: Node in get_tree().get_nodes_in_group(SpawnMarker.GROUP):
		var marker := node as SpawnMarker
		if marker.kind == SpawnMarker.Kind.HERO and marker.team == team:
			return marker.global_position
	return Vector3.INF


## Quanto falta, no fim do caminho, para chegar em [param to] (u); INF se nao ha caminho.
func _gap(nav: ArenaNav, from: Vector3, to: Vector3) -> float:
	var path := NavigationServer3D.map_get_path(nav.get_navigation_map(), from, to, true)
	return INF if path.is_empty() else path[path.size() - 1].distance_to(to)


func test_cada_time_tem_o_proprio_mapa() -> void:
	assert_true(_nav_a.get_navigation_map().is_valid())
	assert_ne(_nav_a.get_navigation_map(), _nav_b.get_navigation_map())
	assert_ne(_nav_a.get_navigation_map(), get_viewport().world_3d.navigation_map)


func test_o_portao_do_adversario_e_parede_so_no_mapa_do_proprio_time() -> void:
	var base_a := _spawn_of(GateRules.TEAM_A)
	var base_b := _spawn_of(GateRules.TEAM_B)
	assert_lt(_gap(_nav_a, Vector3.ZERO, base_a), REACHED, "A chega na propria base")
	assert_lt(_gap(_nav_b, Vector3.ZERO, base_b), REACHED, "B chega na propria base")
	# Fechada = ha caminho ate o portao, mas ele para antes (INF seria mapa sem sincronizar).
	var closed_b := _gap(_nav_a, Vector3.ZERO, base_b)
	var closed_a := _gap(_nav_b, Vector3.ZERO, base_a)
	assert_between(closed_b, REACHED, 100.0, "no mapa de A a base B e fechada")
	assert_between(closed_a, REACHED, 100.0, "no mapa de B a base A e fechada")


func test_bot_usa_o_mapa_do_proprio_time() -> void:
	var hero := (load(KNIGHT) as PackedScene).instantiate() as Hero
	hero.team = GateRules.TEAM_B
	hero.get_node("Input").set_script(BotInput)
	add_child_autofree(hero)
	var brain := hero.input as BotInput
	brain._hero = hero
	assert_eq(brain._nav_map(), _nav_b.get_navigation_map())
	hero.team = GateRules.TEAM_A
	assert_eq(brain._nav_map(), _nav_a.get_navigation_map())
	hero.team = GateRules.TEAM_NEUTRAL
	assert_eq(brain._nav_map(), hero.get_world_3d().navigation_map, "sem navmesh do time: o padrao")
