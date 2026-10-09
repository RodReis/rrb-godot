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


func test_to_world_preserva_a_intensidade() -> void:
	assert_almost_eq(CameraRig.to_world(Vector2(0.5, 0), 1.2).length(), 0.5, EPS)
