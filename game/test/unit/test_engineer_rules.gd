extends GutTest
## EngineerRules (F59, GDB §4.6): puxao da Garra Mecanica e escolha de alvo da Torreta.

const EPS: float = 0.0001


func test_puxao_leva_o_alvo_ate_2_u_do_engenheiro() -> void:
	var push := EngineerRules.pull_push(Vector3.ZERO, Vector3(0, 0, -6), 2.0)
	assert_almost_eq(push.x, 0.0, EPS)
	assert_almost_eq(push.z, 4.0, EPS, "6 u - 2 u de folga")


func test_puxao_ignora_a_altura_e_segue_a_direcao_do_engenheiro() -> void:
	var push := EngineerRules.pull_push(Vector3(1, 0, 1), Vector3(5, 3, 1), 2.0)
	assert_almost_eq(push.x, -2.0, EPS)
	assert_almost_eq(push.y, 0.0, EPS)
	assert_almost_eq(push.z, 0.0, EPS)


func test_puxao_de_quem_ja_esta_perto_demais_e_nulo() -> void:
	assert_eq(EngineerRules.pull_push(Vector3.ZERO, Vector3(0, 0, -1.5), 2.0), Vector3.ZERO)
	assert_eq(EngineerRules.pull_push(Vector3.ZERO, Vector3(0, 0, -2.0), 2.0), Vector3.ZERO)
	assert_eq(EngineerRules.pull_push(Vector3.ZERO, Vector3.ZERO, 2.0), Vector3.ZERO)


func test_torreta_escolhe_o_mais_proximo_dentro_do_alcance() -> void:
	var points := PackedVector3Array([Vector3(0, 0, 6), Vector3(0, 0, 3), Vector3(0, 0, 9)])
	assert_eq(EngineerRules.nearest(Vector3.ZERO, points, 7.0), 1)


func test_torreta_ignora_quem_esta_alem_do_alcance() -> void:
	var points := PackedVector3Array([Vector3(0, 0, 7.5), Vector3(0, 0, 12)])
	assert_eq(EngineerRules.nearest(Vector3.ZERO, points, 7.0), -1)


func test_torreta_alcance_e_inclusivo_e_no_plano() -> void:
	var points := PackedVector3Array([Vector3(0, 5, 7.0)])
	assert_eq(EngineerRules.nearest(Vector3.ZERO, points, 7.0), 0)


func test_torreta_sem_candidato_nao_tem_alvo() -> void:
	assert_eq(EngineerRules.nearest(Vector3.ZERO, PackedVector3Array(), 7.0), -1)


func test_torreta_empate_fica_com_o_primeiro() -> void:
	var points := PackedVector3Array([Vector3(3, 0, 0), Vector3(-3, 0, 0)])
	assert_eq(EngineerRules.nearest(Vector3.ZERO, points, 7.0), 0)


func test_oito_disparos_em_6_segundos_a_cada_0_75_s() -> void:
	var interval := SkillRules.seconds_to_ticks(0.75, 30)
	var window := SkillRules.seconds_to_ticks(6.0, 30)
	var shots := 0
	for elapsed: int in window:
		shots += 1 if EngineerRules.is_turret_shot(elapsed, interval, 8) else 0
	assert_eq(shots, 8)
