extends GutTest

const EPS: float = 0.0001


func test_yaw_aponta_do_heroi_para_o_alvo() -> void:
	# Base A (sudoeste) olhando o centro: frente = nordeste.
	var yaw := CameraRig.yaw_towards(Vector3(-24, 0, 24), Vector3.ZERO)
	assert_almost_eq(CameraRig.forward(yaw), Vector3(1, 0, -1).normalized(), Vector3.ONE * EPS)


func test_yaw_zero_olha_para_o_norte() -> void:
	assert_almost_eq(CameraRig.forward(0.0), Vector3.FORWARD, Vector3.ONE * EPS)


func test_offset_fica_atras_e_acima_a_45_graus() -> void:
	var offset := CameraRig.offset(0.0, 45.0, 10.0)
	assert_almost_eq(offset.length(), 10.0, EPS)
	assert_almost_eq(offset.y, 10.0 * sin(deg_to_rad(45.0)), EPS)
	assert_almost_eq(offset.z, 10.0 * cos(deg_to_rad(45.0)), EPS)
	assert_almost_eq(offset.x, 0.0, EPS)


func test_offset_gira_com_o_yaw() -> void:
	var yaw := CameraRig.yaw_towards(Vector3(-24, 0, 24), Vector3.ZERO)
	var flat := CameraRig.offset(yaw, 45.0, 10.0)
	flat.y = 0.0
	assert_almost_eq(flat.normalized(), -CameraRig.forward(yaw), Vector3.ONE * EPS)


func test_stick_para_frente_anda_para_a_frente_da_camera() -> void:
	var yaw := CameraRig.yaw_towards(Vector3(-24, 0, 24), Vector3.ZERO)
	# Input.get_vector: frente = y negativo.
	var world := CameraRig.to_world(Vector2(0, -1), yaw)
	assert_almost_eq(world, CameraRig.forward(yaw), Vector3.ONE * EPS)


func test_stick_para_a_direita_anda_para_a_direita_da_camera() -> void:
	assert_almost_eq(CameraRig.to_world(Vector2(1, 0), 0.0), Vector3.RIGHT, Vector3.ONE * EPS)


func test_giro_soma_delta_vezes_sensibilidade() -> void:
	assert_almost_eq(CameraRig.orbit(0.5, -10.0, 0.01), 0.6, EPS)


func test_mouse_para_a_direita_gira_a_camera_para_a_direita() -> void:
	# Frente sai do norte (yaw 0) e vai para leste (+X).
	var yaw := CameraRig.orbit(0.0, 20.0, 0.01)
	assert_gt(CameraRig.forward(yaw).x, 0.0)


func test_giro_normaliza_em_menos_pi_ate_pi() -> void:
	var yaw := CameraRig.orbit(PI - 0.1, -0.3, 1.0)
	assert_almost_eq(yaw, -PI + 0.2, EPS)
	for dx: float in [-1000.0, -7.0, 7.0, 1000.0]:
		var y := CameraRig.orbit(3.0, dx, 1.0)
		assert_true(y >= -PI and y < PI, "%f" % y)


func test_giro_de_volta_completa_volta_ao_mesmo_yaw() -> void:
	assert_almost_eq(CameraRig.orbit(1.0, TAU, 1.0), 1.0, EPS)


func test_w_continua_para_longe_da_camera_com_yaw_girado() -> void:
	var yaw := CameraRig.orbit(
		CameraRig.yaw_towards(Vector3(-24, 0, 24), Vector3.ZERO), 137.0, 0.01
	)
	var world := CameraRig.to_world(Vector2(0, -1), yaw)
	var behind := CameraRig.offset(yaw, 45.0, 14.0)
	behind.y = 0.0
	assert_almost_eq(world, -behind.normalized(), Vector3.ONE * EPS)


func test_to_world_preserva_a_intensidade() -> void:
	assert_almost_eq(CameraRig.to_world(Vector2(0.5, 0), 1.2).length(), 0.5, EPS)
