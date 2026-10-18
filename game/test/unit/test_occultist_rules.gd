extends GutTest
## F77: regras puras do Ocultista (GDB §2.2-F, §4.10) — DEF efetiva com a Maldição, soma de marcas,
## dano por pulso da Praga e do Círculo e o compasso dos pulsos da Praga no alvo.

const EPS: float = 0.0001


func test_def_efetiva_desconta_6_por_marca() -> void:
	assert_almost_eq(OccultistRules.effective_defense(30.0, 0), 30.0, EPS)
	assert_almost_eq(OccultistRules.effective_defense(30.0, 1), 24.0, EPS)
	assert_almost_eq(OccultistRules.effective_defense(30.0, 2), 18.0, EPS)
	assert_almost_eq(OccultistRules.effective_defense(30.0, 3), 12.0, EPS)


func test_def_efetiva_nunca_fica_negativa() -> void:
	assert_almost_eq(OccultistRules.effective_defense(9.0, 3), 0.0, EPS, "9 - 18 vira 0")
	assert_almost_eq(OccultistRules.effective_defense(0.0, 3), 0.0, EPS)


func test_def_efetiva_nao_passa_de_3_marcas() -> void:
	assert_almost_eq(OccultistRules.effective_defense(30.0, 9), 12.0, EPS, "teto de 3")
	assert_almost_eq(OccultistRules.effective_defense(30.0, -2), 30.0, EPS, "negativo = 0 marcas")


func test_marcas_somam_ate_o_teto_de_3() -> void:
	assert_eq(OccultistRules.add_stacks(0, 1), 1)
	assert_eq(OccultistRules.add_stacks(1, 1), 2)
	assert_eq(OccultistRules.add_stacks(2, 1), 3)
	assert_eq(OccultistRules.add_stacks(3, 1), 3, "teto")
	assert_eq(OccultistRules.add_stacks(2, 0), 2, "sem marca nova, igual")


func test_pulsos_da_praga_somam_exatamente_o_total() -> void:
	var interval := 15
	var dot_ticks := OccultistRules.dot_duration_ticks(8, interval)
	var left := 122
	var sum := 0
	var count := 0
	while dot_ticks > 0:
		var raw := OccultistRules.pulse_damage(left, dot_ticks, interval)
		if OccultistRules.is_dot_pulse(dot_ticks, interval):
			count += 1
			assert_between(raw, 15, 16, "122 / 8 = 15,25")
		else:
			assert_eq(raw, 0, "fora do pulso, nada")
		left -= raw
		sum += raw
		dot_ticks -= 1
	assert_eq(count, 8)
	assert_eq(sum, 122, "o ultimo pulso leva o resto")
	assert_eq(OccultistRules.pulse_damage(0, 1, interval), 0, "nada a tirar")
	assert_eq(OccultistRules.pulse_damage(80, 30, 0), 0, "sem intervalo")


func test_pulsos_do_circulo_somam_exatamente_o_total() -> void:
	var sum := 0
	for pulse: int in 6:
		sum += OccultistRules.circle_pulse_damage(100, pulse, 6)
	assert_eq(sum, 100, "100 / 6 nao e exato: o resto vai para alguns pulsos")
	assert_eq(OccultistRules.circle_pulse_damage(100, 6, 6), 0, "alem do ultimo pulso")
	assert_eq(OccultistRules.circle_pulse_damage(100, -1, 6), 0)


func test_praga_pulsa_a_cada_intervalo_e_8_vezes() -> void:
	# Aplicada no tick T com 8 x 15 = 120 ticks; o tick T desconta 1 e os pulsos caem a cada 15.
	var interval := 15
	var left := OccultistRules.dot_duration_ticks(8, interval)
	assert_eq(left, 120)
	left -= 1  # tick T: aplica e desconta
	var pulses: Array[int] = []
	for k: int in range(1, 130):
		if OccultistRules.is_dot_pulse(left, interval):
			pulses.append(k)
		left = maxi(left - 1, 0)
	assert_eq(pulses.size(), 8)
	assert_eq(pulses[0], 14, "1o pulso 15 ticks depois do golpe (T = golpe + 1)")
	assert_eq(pulses[7], 119, "o 8o pulso fecha os 120 ticks")
	assert_eq(left, 0)


func test_praga_parada_nao_pulsa() -> void:
	assert_false(OccultistRules.is_dot_pulse(0, 15))
	assert_false(OccultistRules.is_dot_pulse(30, 0), "sem intervalo")
