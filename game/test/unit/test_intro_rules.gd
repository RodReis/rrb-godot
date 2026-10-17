extends GutTest
## Matematica da cinematica de abertura (F69, SPEC-069 §2): fases por tempo, trajeto em spline que
## passa pelo centro, e as poses do voo e do close no proprio heroi.

const BASE_A: Vector3 = Vector3(0.0, 0.0, 30.0)
const CENTER: Vector3 = Vector3.ZERO
const BASE_B: Vector3 = Vector3(0.0, 0.0, -30.0)
const HERO: Vector3 = Vector3(2.0, 0.0, -28.0)
## O heroi olha para o centro (+Z a partir da base B): yaw PI.
const HERO_YAW: float = PI


func test_a_sequencia_dura_5_s_mais_0_5_s_de_blend() -> void:
	assert_eq(IntroRules.FLIGHT_SECONDS, 3.0)
	assert_eq(IntroRules.CLOSE_SECONDS, 2.0)
	assert_eq(IntroRules.BLEND_SECONDS, 0.5)
	assert_eq(IntroRules.READY_AT, 5.5, "ready quando o blend termina")


func test_fases_por_tempo() -> void:
	var phase := IntroRules.Phase
	assert_eq(IntroRules.phase_at(0.0), phase.FLIGHT)
	assert_eq(IntroRules.phase_at(2.99), phase.FLIGHT)
	assert_eq(IntroRules.phase_at(3.0), phase.CLOSE)
	assert_eq(IntroRules.phase_at(4.99), phase.CLOSE)
	assert_eq(IntroRules.phase_at(5.0), phase.BLEND)
	assert_eq(IntroRules.phase_at(5.49), phase.BLEND)
	assert_eq(IntroRules.phase_at(5.5), phase.DONE)
	assert_eq(IntroRules.phase_at(99.0), phase.DONE)


func test_trajeto_passa_pelas_pontas_e_pelo_centro() -> void:
	assert_eq(IntroRules.path_point(BASE_A, CENTER, BASE_B, 0.0), BASE_A)
	assert_eq(IntroRules.path_point(BASE_A, CENTER, BASE_B, 1.0), BASE_B)
	var middle := IntroRules.path_point(BASE_A, CENTER, BASE_B, 0.5)
	assert_almost_eq(middle.distance_to(CENTER), 0.0, 0.001)


func test_progresso_do_voo_e_suave_nas_pontas() -> void:
	assert_eq(IntroRules.flight_progress(0.0), 0.0)
	assert_eq(IntroRules.flight_progress(IntroRules.FLIGHT_SECONDS), 1.0)
	assert_almost_eq(IntroRules.flight_progress(1.5), 0.5, 0.001)
	assert_lt(IntroRules.flight_progress(0.3), 0.3 / 3.0, "parte devagar")
	assert_eq(IntroRules.flight_progress(-1.0), 0.0)
	assert_eq(IntroRules.flight_progress(10.0), 1.0)


func test_voo_fica_acima_da_arena_e_olha_para_baixo() -> void:
	for t: float in [0.0, 1.5, 3.0]:
		var pose := IntroRules.flight_pose(BASE_A, CENTER, BASE_B, t)
		assert_gt(pose.origin.y, IntroRules.FLIGHT_HEIGHT - 0.01, "altura a %.1f s" % t)
		var look := -pose.basis.z
		assert_lt(look.y, -0.3, "inclinada para o chao a %.1f s" % t)


func test_voo_avanca_na_direcao_do_trajeto() -> void:
	var early := IntroRules.flight_pose(BASE_A, CENTER, BASE_B, 0.5)
	var late := IntroRules.flight_pose(BASE_A, CENTER, BASE_B, 2.5)
	assert_lt(late.origin.z, early.origin.z, "A (+Z) para B (-Z)")
	assert_lt((-early.basis.z).z, 0.0, "olha para a frente do trajeto")


func test_close_fica_a_frente_do_heroi_em_angulo_baixo() -> void:
	var pose := IntroRules.close_pose(HERO, HERO_YAW)
	var forward := CameraRig.forward(HERO_YAW)
	var offset := pose.origin - HERO
	assert_almost_eq(offset.dot(forward), IntroRules.CLOSE_DISTANCE, 0.001, "na frente do heroi")
	assert_almost_eq(offset.y, IntroRules.CLOSE_HEIGHT, 0.001)
	assert_lt(IntroRules.CLOSE_HEIGHT, 1.5, "angulo baixo")
	var to_hero := (HERO + Vector3.UP * IntroRules.CLOSE_LOOK_HEIGHT - pose.origin).normalized()
	assert_gt((-pose.basis.z).dot(to_hero), 0.999, "a camera olha o heroi")


func test_pose_no_fim_do_voo_e_a_do_voo_e_no_fim_do_close_e_a_do_close() -> void:
	var flight_end := IntroRules.flight_pose(BASE_A, CENTER, BASE_B, IntroRules.FLIGHT_SECONDS)
	var at_flight_end := IntroRules.pose_at(
		IntroRules.FLIGHT_SECONDS, BASE_A, CENTER, BASE_B, HERO, HERO_YAW
	)
	assert_almost_eq(at_flight_end.origin.distance_to(flight_end.origin), 0.0, 0.001)
	var close := IntroRules.close_pose(HERO, HERO_YAW)
	var at_close_end := IntroRules.pose_at(
		IntroRules.FLIGHT_SECONDS + IntroRules.CLOSE_SECONDS, BASE_A, CENTER, BASE_B, HERO, HERO_YAW
	)
	assert_almost_eq(at_close_end.origin.distance_to(close.origin), 0.0, 0.001)


func test_pose_depois_do_close_continua_no_close() -> void:
	var close := IntroRules.close_pose(HERO, HERO_YAW)
	var held := IntroRules.pose_at(7.0, BASE_A, CENTER, BASE_B, HERO, HERO_YAW)
	assert_almost_eq(held.origin.distance_to(close.origin), 0.0, 0.001)


func test_nome_do_heroi_entra_antes_do_close_e_sai_com_o_blend() -> void:
	assert_eq(IntroRules.overlay_alpha(0.0), 0.0, "esconde durante o voo")
	assert_eq(IntroRules.overlay_alpha(IntroRules.OVERLAY_IN_AT), 0.0)
	assert_gt(IntroRules.overlay_alpha(3.0), 0.0)
	assert_eq(IntroRules.overlay_alpha(4.0), 1.0, "pleno no close")
	assert_lt(IntroRules.overlay_alpha(5.25), 1.0, "sai no blend")
	assert_eq(IntroRules.overlay_alpha(IntroRules.READY_AT), 0.0)


func test_peso_do_blend_sobe_de_0_a_1_no_blend() -> void:
	assert_eq(IntroRules.blend_weight(0.0), 0.0)
	assert_eq(IntroRules.blend_weight(IntroRules.FLIGHT_SECONDS + IntroRules.CLOSE_SECONDS), 0.0)
	assert_almost_eq(IntroRules.blend_weight(5.25), 0.5, 0.001)
	assert_eq(IntroRules.blend_weight(IntroRules.READY_AT), 1.0)
	assert_eq(IntroRules.blend_weight(9.0), 1.0)
	assert_eq(IntroRules.blend_weight(-1.0), 0.0)
