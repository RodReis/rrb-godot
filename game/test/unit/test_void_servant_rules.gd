extends GutTest
## F78: regras puras do Servo do Vazio (GDB §4.10): HP e dano pelo rank e pela INT do Ocultista,
## prioridade do alvo (travado -> heroi -> monstro, todos a ate o alcance), ponto de nascimento ao
## lado e o compasso da reavaliacao do alvo.

const DATA: String = "res://shared/data/servants/void_servant.tres"
const REACH: float = 9.0

var _data: ServantData


func before_each() -> void:
	_data = load(DATA) as ServantData


func test_numeros_do_gdb() -> void:
	assert_eq(Array(_data.base_hp), [180.0, 280.0])
	assert_almost_eq(_data.hp_intelligence_ratio, 2.0, 0.0001)
	assert_almost_eq(_data.defense, 10.0, 0.0001)
	assert_almost_eq(_data.move_speed, 5.5, 0.0001)
	assert_almost_eq(_data.attack_reach, 1.2, 0.0001)
	assert_almost_eq(_data.attack_interval, 1.0, 0.0001)
	assert_eq(Array(_data.base_damage), [22.0, 34.0])
	assert_almost_eq(_data.damage_intelligence_ratio, 0.25, 0.0001)
	assert_almost_eq(_data.target_reach, REACH, 0.0001)
	assert_almost_eq(_data.retarget_interval, 0.25, 0.0001)


func test_hp_e_dano_somam_a_int_do_ocultista() -> void:
	assert_eq(VoidServantRules.max_hp(_data, 1, 48.0), 276, "180 + 2 * 48")
	assert_eq(VoidServantRules.max_hp(_data, 2, 60.8), 402, "280 + 2 * 60,8 = 401,6")
	assert_eq(VoidServantRules.damage(_data, 1, 48.0), 34, "22 + 0,25 * 48")
	assert_eq(VoidServantRules.damage(_data, 2, 60.8), 49, "34 + 0,25 * 60,8 = 49,2")


func test_alvo_travado_no_alcance_vence_heroi_e_monstro_mais_perto() -> void:
	var heroes := PackedVector3Array([Vector3(2, 0, 0)])
	var monsters := PackedVector3Array([Vector3(1, 0, 0)])
	var pick := VoidServantRules.choose(
		Vector3.ZERO, true, Vector3(8, 0, 0), heroes, monsters, REACH
	)
	assert_eq(pick, Vector2i(VoidServantRules.Pick.LOCKED, 0))


func test_alvo_travado_longe_cai_para_o_heroi_mais_perto() -> void:
	var heroes := PackedVector3Array([Vector3(6, 0, 0), Vector3(3, 0, 4)])
	var monsters := PackedVector3Array([Vector3(1, 0, 0)])
	var pick := VoidServantRules.choose(
		Vector3.ZERO, true, Vector3(9.5, 0, 0), heroes, monsters, REACH
	)
	assert_eq(pick, Vector2i(VoidServantRules.Pick.HERO, 1), "heroi antes do monstro, o mais perto")


func test_sem_heroi_no_alcance_o_monstro_mais_perto() -> void:
	var heroes := PackedVector3Array([Vector3(0, 0, 9.5)])
	var monsters := PackedVector3Array([Vector3(7, 0, 0), Vector3(-4, 0, 0)])
	var pick := VoidServantRules.choose(Vector3.ZERO, false, Vector3.ZERO, heroes, monsters, REACH)
	assert_eq(pick, Vector2i(VoidServantRules.Pick.MONSTER, 1))


func test_nada_no_alcance_sem_alvo() -> void:
	var far := PackedVector3Array([Vector3(9.1, 0, 0)])
	var pick := VoidServantRules.choose(Vector3.ZERO, false, Vector3.ZERO, far, far, REACH)
	assert_eq(pick.x, VoidServantRules.Pick.NONE)
	assert_eq(VoidServantRules.choose(Vector3.ZERO, false, Vector3.ZERO, [], [], REACH).x, 0)


func test_alcance_e_inclusivo_e_no_plano() -> void:
	var edge := PackedVector3Array([Vector3(9, 5, 0)])
	var pick := VoidServantRules.choose(Vector3.ZERO, false, Vector3.ZERO, edge, [], REACH)
	assert_eq(pick, Vector2i(VoidServantRules.Pick.HERO, 0), "9 u no plano; a altura nao conta")


func test_os_dois_servos_nascem_a_frente_um_de_cada_lado() -> void:
	var right := Vector3(1, 0, 0)
	var ahead := Vector3(0, 0, -1)
	var at := Vector3(5, 0, 5)
	assert_eq(VoidServantRules.spawn_point(at, ahead, right, 1.5, 1.0, 0), Vector3(6, 0, 3.5))
	assert_eq(VoidServantRules.spawn_point(at, ahead, right, 1.5, 1.0, 1), Vector3(4, 0, 3.5))


func test_reavalia_o_alvo_a_cada_intervalo_desde_a_invocacao() -> void:
	assert_true(VoidServantRules.is_retarget_tick(0, 8), "na invocacao")
	assert_false(VoidServantRules.is_retarget_tick(7, 8))
	assert_true(VoidServantRules.is_retarget_tick(8, 8))
	assert_true(VoidServantRules.is_retarget_tick(16, 8))
	assert_true(VoidServantRules.is_retarget_tick(3, 1), "intervalo de 1 tick: todo tick")
