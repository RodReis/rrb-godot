extends GutTest
## Regras puras do Carrasco (GDB §4.11, F98, SPEC-098 §6 item 1): Couraca so no basico de heroi,
## mitigacao da Penitencia, ganho e teto da Dor, raiz x lentidao pela Dor, cura distribuida,
## execucao abaixo de 25 % (bloqueada pela imunidade a dano) e o toque que dispara o recast.

const EPS: float = 0.0001


func test_couraca_so_vale_para_basico_de_heroi() -> void:
	assert_almost_eq(CarrascoRules.taken_factor(true, 0.85, false, 0.4), 0.85, EPS)
	assert_almost_eq(
		CarrascoRules.taken_factor(false, 0.85, false, 0.4), 1.0, EPS, "skill, monstro"
	)


func test_penitencia_mitiga_40_por_cento_de_tudo() -> void:
	assert_almost_eq(CarrascoRules.taken_factor(false, 0.85, true, 0.4), 0.6, EPS)
	assert_almost_eq(
		CarrascoRules.taken_factor(true, 0.85, true, 0.4), 0.85 * 0.6, EPS, "acumula com a Couraca"
	)


func test_dano_tomado_arredonda_e_nao_fica_negativo() -> void:
	assert_eq(CarrascoRules.taken(100, 0.85), 85)
	assert_eq(CarrascoRules.taken(33, 0.6), 20)
	assert_eq(CarrascoRules.taken(0, 0.85), 0)
	assert_eq(CarrascoRules.taken(-5, 0.85), 0)


func test_dor_soma_ate_o_teto() -> void:
	assert_eq(CarrascoRules.gain_pain(0, 1, 6), 1)
	assert_eq(CarrascoRules.gain_pain(5, 3, 6), 6, "teto 6")
	assert_eq(CarrascoRules.gain_pain(6, 1, 6), 6)
	assert_eq(CarrascoRules.gain_pain(2, 0, 6), 2)


func test_pulso_de_dor_a_cada_meio_segundo_canalizando() -> void:
	# 0,5 s a 30 ticks/s = 15 ticks: o 1o pulso no 15o tick de canalizacao, nao no inicio.
	assert_false(CarrascoRules.is_pain_pulse(0, 15))
	assert_false(CarrascoRules.is_pain_pulse(14, 15))
	assert_true(CarrascoRules.is_pain_pulse(15, 15))
	assert_true(CarrascoRules.is_pain_pulse(60, 15))
	assert_false(CarrascoRules.is_pain_pulse(16, 0), "sem intervalo, sem pulso")


func test_explosao_prende_com_4_de_dor_ou_mais() -> void:
	assert_false(CarrascoRules.explosion_roots(3, 4), "lentidao")
	assert_true(CarrascoRules.explosion_roots(4, 4))
	assert_true(CarrascoRules.explosion_roots(6, 4))


func test_cura_e_dano_somam_10_por_dor() -> void:
	# Rank 1, ATK 42, Dor 3: 60 + 0,4 x 42 + 30 = 106,8 -> 107.
	assert_eq(CarrascoRules.with_pain(60.0, 0.4, 42.0, 10.0, 3), 107)
	# Explosao rank 1, Dor 0: 50 + 0,5 x 42 = 71.
	assert_eq(CarrascoRules.with_pain(50.0, 0.5, 42.0, 10.0, 0), 71)


func test_cura_distribuida_pela_canalizacao() -> void:
	# 107 em 60 ticks: no meio, metade (arredondada para baixo); no fim, tudo.
	assert_eq(CarrascoRules.heal_due(107, 0, 60), 0)
	assert_eq(CarrascoRules.heal_due(107, 30, 60), 53)
	assert_eq(CarrascoRules.heal_due(107, 60, 60), 107)
	assert_eq(CarrascoRules.heal_due(107, 80, 60), 107, "nunca passa do total")
	assert_eq(CarrascoRules.heal_due(107, 10, 0), 0, "sem canalizacao, sem cura")


func test_execucao_abaixo_de_25_por_cento() -> void:
	assert_true(CarrascoRules.executes(249, 1000, 0.25, false))
	assert_false(CarrascoRules.executes(250, 1000, 0.25, false), "exatamente 25 % nao")
	assert_false(CarrascoRules.executes(0, 1000, 0.25, false), "ja morto")


func test_bencao_bloqueia_a_execucao() -> void:
	assert_false(CarrascoRules.executes(10, 1000, 0.25, true))


func test_recast_so_no_toque_novo_e_dentro_da_janela() -> void:
	assert_true(CarrascoRules.pressed(true, false), "apertou agora")
	assert_false(CarrascoRules.pressed(true, true), "segurando desde o tick anterior")
	assert_false(CarrascoRules.pressed(false, true))
	assert_true(CarrascoRules.recasts(45, true))
	assert_false(CarrascoRules.recasts(0, true), "janela fechada")
	assert_false(CarrascoRules.recasts(45, false))
