extends GutTest
## DayNightRules (F49, SPEC-049 §2): progresso pelo relogio da partida, `t` por sentido e sorteio
## do sentido pela seed (50/50), com `--daynight` forcando o inicio.

const DURATION: float = 600.0


func test_progresso_zero_antes_da_partida_e_na_selecao() -> void:
	assert_eq(DayNightRules.progress(0.0, DURATION), 0.0)
	assert_eq(DayNightRules.progress(-5.0, DURATION), 0.0)


func test_progresso_meio_e_fim() -> void:
	assert_almost_eq(DayNightRules.progress(300.0, DURATION), 0.5, 0.0001)
	assert_eq(DayNightRules.progress(600.0, DURATION), 1.0)


func test_progresso_depois_dos_600s_fica_em_1() -> void:
	assert_eq(DayNightRules.progress(601.0, DURATION), 1.0)
	assert_eq(DayNightRules.progress(5000.0, DURATION), 1.0)


func test_progresso_com_duracao_invalida_nao_divide_por_zero() -> void:
	assert_eq(DayNightRules.progress(10.0, 0.0), 1.0)


func test_noite_do_dia_para_a_noite_cresce_com_o_progresso() -> void:
	assert_eq(DayNightRules.night_amount(0.0, true), 0.0)
	assert_almost_eq(DayNightRules.night_amount(0.25, true), 0.25, 0.0001)
	assert_eq(DayNightRules.night_amount(1.0, true), 1.0)


func test_noite_da_noite_para_o_dia_decresce_com_o_progresso() -> void:
	assert_eq(DayNightRules.night_amount(0.0, false), 1.0)
	assert_almost_eq(DayNightRules.night_amount(0.25, false), 0.75, 0.0001)
	assert_eq(DayNightRules.night_amount(1.0, false), 0.0)


func test_mesma_seed_mesmo_sentido() -> void:
	for seed_value: int in [1, 42, 123456, 987654321]:
		assert_eq(DayNightRules.starts_at_day(seed_value), DayNightRules.starts_at_day(seed_value))


func test_sorteio_e_aproximadamente_50_50_em_1000_seeds() -> void:
	var days := 0
	for seed_value: int in range(1, 1001):
		if DayNightRules.starts_at_day(seed_value):
			days += 1
	assert_between(days, 450, 550, "partidas que comecam de dia em 1.000 seeds")


func test_forcar_dia_ou_noite_vence_a_seed() -> void:
	for seed_value: int in range(1, 50):
		assert_true(DayNightRules.starts_at_day(seed_value, LaunchArgs.DAYNIGHT_DAY))
		assert_false(DayNightRules.starts_at_day(seed_value, LaunchArgs.DAYNIGHT_NIGHT))


func test_valor_desconhecido_cai_no_sorteio() -> void:
	assert_eq(
		DayNightRules.starts_at_day(7, "tarde"),
		DayNightRules.starts_at_day(7, LaunchArgs.DAYNIGHT_AUTO)
	)
