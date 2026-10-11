extends GutTest
## F53 (SPEC-053 §6 item 2): dano da Execucao = base + 1,0 INT + 0,5 ATK + 25 % do HP faltante
## do alvo, antes da DEF (GDB §4.3). Os numeros dos casos sao os do rank 1 com INT 8 e ATK 52.

const AMOUNT: float = 200.0 + 1.0 * 8.0 + 0.5 * 52.0  # 234
const RATIO: float = 0.25


func test_alvo_com_hp_cheio_toma_so_a_parte_fixa() -> void:
	assert_eq(BarbarianRules.execution_damage(AMOUNT, RATIO, 600, 600), 234)


func test_alvo_com_metade_do_hp() -> void:
	assert_eq(BarbarianRules.execution_damage(AMOUNT, RATIO, 300, 600), 234 + 75)


func test_alvo_com_10_por_cento_do_hp() -> void:
	assert_eq(BarbarianRules.execution_damage(AMOUNT, RATIO, 60, 600), 234 + 135)


func test_hp_acima_do_maximo_nao_tira_dano() -> void:
	assert_eq(BarbarianRules.execution_damage(AMOUNT, RATIO, 700, 600), 234)


func test_rodopio_pulsa_tres_vezes_em_meio_segundo() -> void:
	var interval := 15  # 0,5 s a 30 ticks/s
	var pulses: Array[int] = []
	for elapsed: int in 45:  # 1,5 s
		if BarbarianRules.is_spin_pulse(elapsed, interval, 3):
			pulses.append(elapsed)
	assert_eq(pulses, [0, 15, 30] as Array[int])
