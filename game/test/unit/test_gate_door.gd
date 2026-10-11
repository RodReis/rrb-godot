extends GutTest
## FIX #124: a porta do portao abre (so visual) quando um heroi do time dono chega perto e fecha
## quando ele sai. Colisao e GateRules.can_pass nao mudam; aos 5:00 a porta some (fall()).

const GATE_SCENE: String = "res://scenes/world/gate.tscn"
const NEAR: float = 2.0
const FAR: float = 9.0

var _gate: Gate


func before_each() -> void:
	_gate = (load(GATE_SCENE) as PackedScene).instantiate() as Gate
	_gate.team = GateRules.TEAM_A
	add_child_autofree(_gate)


func _hero(team: int, at: Vector3) -> Combatant:
	var hero := Combatant.new()
	hero.team = team
	add_child_autofree(hero)
	hero.add_to_group(Hero.GROUP)
	hero.global_position = at
	return hero


func _leaf(side: String) -> Node3D:
	return _gate.get_node("Door/Leaf%s" % side) as Node3D


func test_grupo_dos_herois_e_o_do_heroi() -> void:
	assert_eq(Gate.HEROES_GROUP, Hero.GROUP)


func test_so_heroi_do_time_dono_perto_quer_abrir() -> void:
	assert_true(GateRules.door_wants_open(GateRules.TEAM_A, GateRules.TEAM_A, NEAR))
	assert_false(GateRules.door_wants_open(GateRules.TEAM_A, GateRules.TEAM_B, NEAR))
	assert_false(GateRules.door_wants_open(GateRules.TEAM_A, GateRules.TEAM_A, FAR))


func test_abertura_anda_ate_o_alvo_sem_passar() -> void:
	var half := GateRules.door_open_amount(0.0, true, GateRules.DOOR_SECONDS / 2.0)
	assert_almost_eq(half, 0.5, 0.001)
	assert_eq(GateRules.door_open_amount(0.9, true, 10.0), 1.0)
	assert_eq(GateRules.door_open_amount(0.1, false, 10.0), 0.0)


func test_porta_abre_para_dentro_com_heroi_do_time() -> void:
	_hero(GateRules.TEAM_A, Vector3(0, 0, NEAR))
	_gate.update_door(GateRules.DOOR_SECONDS)
	assert_almost_eq(_leaf("L").rotation.y, deg_to_rad(GateRules.DOOR_OPEN_DEG), 0.001)
	assert_almost_eq(_leaf("R").rotation.y, -deg_to_rad(GateRules.DOOR_OPEN_DEG), 0.001)


func test_porta_continua_fechada_para_o_adversario() -> void:
	_hero(GateRules.TEAM_B, Vector3(0, 0, NEAR))
	_gate.update_door(GateRules.DOOR_SECONDS)
	assert_eq(_leaf("L").rotation.y, 0.0)
	assert_eq(_leaf("R").rotation.y, 0.0)


func test_porta_fecha_quando_o_heroi_sai() -> void:
	var hero := _hero(GateRules.TEAM_A, Vector3(0, 0, NEAR))
	_gate.update_door(GateRules.DOOR_SECONDS)
	hero.global_position = Vector3(0, 0, FAR)
	_gate.update_door(GateRules.DOOR_SECONDS)
	assert_eq(_leaf("L").rotation.y, 0.0)


func test_queda_do_portao_esconde_a_porta() -> void:
	_gate.fall()
	assert_false(_gate.get_node("Door").visible)
	assert_true(_gate.is_fallen())
