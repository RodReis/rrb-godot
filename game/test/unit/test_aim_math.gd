extends GutTest


func test_mira_aponta_do_player_para_o_ponto_no_chao() -> void:
	# raio vertical caindo em (0,0,0); player em (0,0,-2) -> direcao +Z
	var aim := AimMath.aim_on_ground(Vector3(0, 10, 0), Vector3(0, -1, 0), Vector3(0, 0, -2))
	assert_almost_eq(aim, Vector3(0, 0, 1), Vector3(0.001, 0.001, 0.001))


func test_mira_e_horizontal_mesmo_com_player_acima_do_chao() -> void:
	var aim := AimMath.aim_on_ground(Vector3(3, 10, 0), Vector3(0, -1, 0), Vector3(0, 1.5, 0))
	assert_almost_eq(aim, Vector3(1, 0, 0), Vector3(0.001, 0.001, 0.001))


func test_raio_paralelo_ao_chao_retorna_zero() -> void:
	assert_eq(
		AimMath.aim_on_ground(Vector3(0, 10, 0), Vector3(1, 0, 0), Vector3.ZERO), Vector3.ZERO
	)


func test_raio_para_cima_retorna_zero() -> void:
	assert_eq(
		AimMath.aim_on_ground(Vector3(0, 10, 0), Vector3(0, 1, 0), Vector3.ZERO), Vector3.ZERO
	)


func test_mouse_em_cima_do_player_retorna_zero() -> void:
	assert_eq(
		AimMath.aim_on_ground(Vector3(0, 10, 0), Vector3(0, -1, 0), Vector3(0.05, 0, 0)),
		Vector3.ZERO
	)


func test_analogico_direito_mira_relativo_a_camera() -> void:
	var aim := AimMath.stick_aim(Vector2(0, -1), 0.0)
	assert_almost_eq(aim, Vector3.FORWARD, Vector3(0.001, 0.001, 0.001))


func test_analogico_direito_mira_normalizada() -> void:
	assert_almost_eq(AimMath.stick_aim(Vector2(0.6, 0), 0.0).length(), 1.0, 0.001)


func test_analogico_dentro_da_zona_morta_nao_mira() -> void:
	assert_eq(AimMath.stick_aim(Vector2(0.1, 0.1), 0.0), Vector3.ZERO)
