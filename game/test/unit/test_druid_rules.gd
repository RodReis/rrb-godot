extends GutTest
## DruidRules (F74, GDB §4.7): cura por pulso da Pocao Verde, compasso dos pulsos das zonas e o
## chefe que nao fica enraizado.


func test_pulsos_somam_exatamente_a_cura_total() -> void:
	for total: int in [90, 112, 113, 135, 157, 270, 289, 1]:
		var sum := 0
		for pulse: int in 6:
			sum += DruidRules.pulse_heal(total, pulse, 6)
		assert_eq(sum, total, "cura total %d" % total)


func test_pulsos_divisiveis_sao_iguais() -> void:
	for pulse: int in 6:
		assert_eq(DruidRules.pulse_heal(90, pulse, 6), 15)


func test_resto_vai_para_pulsos_diferentes_com_diferenca_de_no_maximo_1() -> void:
	var lo := 1000
	var hi := 0
	for pulse: int in 6:
		var heal := DruidRules.pulse_heal(113, pulse, 6)
		lo = mini(lo, heal)
		hi = maxi(hi, heal)
	assert_lte(hi - lo, 1)


func test_pulso_fora_da_faixa_ou_cura_nula_nao_cura() -> void:
	assert_eq(DruidRules.pulse_heal(90, -1, 6), 0)
	assert_eq(DruidRules.pulse_heal(90, 6, 6), 0)
	assert_eq(DruidRules.pulse_heal(0, 0, 6), 0)
	assert_eq(DruidRules.pulse_heal(-5, 0, 6), 0)
	assert_eq(DruidRules.pulse_heal(90, 0, 0), 0)


func test_seis_pulsos_de_meio_segundo_na_pocao() -> void:
	var interval := SkillRules.seconds_to_ticks(0.5, 30)
	var window := SkillRules.seconds_to_ticks(3.0, 30)
	var pulses := 0
	for elapsed: int in window:
		pulses += 1 if DruidRules.is_pulse(elapsed, interval, 6) else 0
	assert_eq(pulses, 6)


func test_seis_pulsos_de_um_segundo_no_pantano() -> void:
	var interval := SkillRules.seconds_to_ticks(1.0, 30)
	var window := SkillRules.seconds_to_ticks(6.0, 30)
	var pulses := 0
	for elapsed: int in window:
		pulses += 1 if DruidRules.is_pulse(elapsed, interval, 6) else 0
	assert_eq(pulses, 6)


func test_indice_do_pulso() -> void:
	assert_eq(DruidRules.pulse_index(0, 15, 6), 0)
	assert_eq(DruidRules.pulse_index(15, 15, 6), 1)
	assert_eq(DruidRules.pulse_index(75, 15, 6), 5)
	assert_eq(DruidRules.pulse_index(90, 15, 6), -1, "depois do 6o pulso")
	assert_eq(DruidRules.pulse_index(7, 15, 6), -1, "entre pulsos")


func test_so_o_chefe_resiste_as_raizes() -> void:
	assert_true(DruidRules.roots(false))
	assert_false(DruidRules.roots(true))
