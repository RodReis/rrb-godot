extends GutTest

## FIX #287: camera do jogo (45 graus, distancia 11) atras do heroi na origem, olhando -Z; alvo de
## lado na tela, a 6 u. O cursor sobre o tronco do alvo (1 u de altura) tem de mirar o alvo.
const CAMERA: Vector3 = Vector3(0.0, 7.778, 7.778)
const TARGET_FEET: Vector3 = Vector3(6.0, 0.0, 0.0)
const BODY_RADIUS: float = 0.4
const BODY_HEIGHT: float = 1.8
## Tolerancia de acerto do basico do Arqueiro: raio do projetil (0,3) + capsula do corpo (0,4).
const HIT_TOLERANCE: float = 0.7


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


func _ray_to(point: Vector3) -> Vector3:
	return (point - CAMERA).normalized()


## Distancia (no plano) do centro do alvo ate a linha de tiro que sai da origem em [param dir].
func _miss(dir: Vector3) -> float:
	var flat := Vector3(TARGET_FEET.x, 0.0, TARGET_FEET.z)
	return (flat - dir * flat.dot(dir)).length()


func _one(point: Vector3) -> PackedVector3Array:
	return PackedVector3Array([point])


func _radius() -> PackedFloat32Array:
	return PackedFloat32Array([BODY_RADIUS])


func test_cursor_no_tronco_projetado_no_chao_erra_o_alvo_de_lado() -> void:
	var ray := _ray_to(TARGET_FEET + Vector3.UP)
	var aim := AimMath.aim_on_ground(CAMERA, ray, Vector3.ZERO)
	assert_gt(_miss(aim), HIT_TOLERANCE, "o chao fica ~1 u atras do corpo: e o erro do #287")


func test_cursor_sobre_o_corpo_mira_o_pe_do_alvo() -> void:
	var ray := _ray_to(TARGET_FEET + Vector3.UP)
	var offset := AimMath.offset_at_cursor(
		CAMERA, ray, Vector3.ZERO, _one(TARGET_FEET), _radius(), BODY_HEIGHT
	)
	assert_almost_eq(offset, TARGET_FEET, Vector3(0.001, 0.001, 0.001))
	assert_lt(_miss(AimMath.direction(offset)), 0.001)


func test_cursor_na_borda_da_cabeca_ainda_mira_o_alvo() -> void:
	var ray := _ray_to(TARGET_FEET + Vector3(0.3, 1.7, 0.0))
	var offset := AimMath.offset_at_cursor(
		CAMERA, ray, Vector3.ZERO, _one(TARGET_FEET), _radius(), BODY_HEIGHT
	)
	assert_almost_eq(offset, TARGET_FEET, Vector3(0.001, 0.001, 0.001))


func test_cursor_fora_de_qualquer_corpo_mira_o_chao_como_antes() -> void:
	var ground := Vector3(2.0, 0.0, -4.0)
	var ray := _ray_to(ground)
	var offset := AimMath.offset_at_cursor(
		CAMERA, ray, Vector3.ZERO, _one(TARGET_FEET), _radius(), BODY_HEIGHT
	)
	assert_almost_eq(
		offset, AimMath.offset_on_ground(CAMERA, ray, Vector3.ZERO), Vector3.ONE * 0.001
	)
	assert_almost_eq(offset, ground, Vector3(0.001, 0.001, 0.001))


func test_sem_corpos_mira_o_chao() -> void:
	var ray := _ray_to(TARGET_FEET + Vector3.UP)
	var offset := AimMath.offset_at_cursor(
		CAMERA, ray, Vector3.ZERO, PackedVector3Array(), PackedFloat32Array(), BODY_HEIGHT
	)
	assert_almost_eq(
		offset, AimMath.offset_on_ground(CAMERA, ray, Vector3.ZERO), Vector3.ONE * 0.001
	)


func test_corpo_mais_perto_da_camera_vence() -> void:
	# Dois corpos na mesma linha do cursor: o da frente (mais perto da camera) e o mirado.
	var front := TARGET_FEET + (CAMERA - TARGET_FEET).normalized() * 1.5
	front.y = 0.0
	var ray := _ray_to(TARGET_FEET + Vector3.UP)
	var feet := PackedVector3Array([TARGET_FEET, front])
	var radii := PackedFloat32Array([BODY_RADIUS, BODY_RADIUS])
	var offset := AimMath.offset_at_cursor(CAMERA, ray, Vector3.ZERO, feet, radii, BODY_HEIGHT)
	assert_almost_eq(offset, front, Vector3(0.001, 0.001, 0.001))


func test_mira_do_corpo_e_relativa_ao_heroi_e_horizontal() -> void:
	var player := Vector3(1.0, 0.5, 1.0)
	var ray := _ray_to(TARGET_FEET + Vector3.UP)
	var offset := AimMath.offset_at_cursor(
		CAMERA, ray, player, _one(TARGET_FEET), _radius(), BODY_HEIGHT
	)
	assert_almost_eq(offset, Vector3(5.0, 0.0, -1.0), Vector3(0.001, 0.001, 0.001))


func test_direcao_dentro_da_zona_morta_e_zero() -> void:
	assert_eq(AimMath.direction(Vector3(0.05, 0.0, 0.0)), Vector3.ZERO)
	assert_almost_eq(
		AimMath.direction(Vector3(3.0, 0.0, 4.0)), Vector3(0.6, 0.0, 0.8), Vector3.ONE * 0.001
	)
