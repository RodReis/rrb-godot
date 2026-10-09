extends GutTest

const FWD := Vector3(0, 0, -1)  # -Z e a frente no Godot

func test_dano_com_defesa() -> void:
	# 120 * 100 / 130 = 92.3 -> 92
	assert_eq(CombatRules.apply_damage(600, 120, 30), 508)

func test_dano_sem_defesa_e_integral() -> void:
	assert_eq(CombatRules.apply_damage(600, 120, 0), 480)

func test_defesa_negativa_vale_zero() -> void:
	assert_eq(CombatRules.apply_damage(600, 120, -50), 480)

func test_hp_nao_fica_negativo() -> void:
	assert_eq(CombatRules.apply_damage(50, 120, 0), 0)

func test_alvo_a_frente_no_alcance() -> void:
	assert_true(CombatRules.is_in_melee_arc(Vector3.ZERO, FWD, Vector3(0, 0, -1.5), 2.0, 60.0))

func test_alvo_fora_do_alcance() -> void:
	assert_false(CombatRules.is_in_melee_arc(Vector3.ZERO, FWD, Vector3(0, 0, -3.0), 2.0, 60.0))

func test_alvo_atras() -> void:
	assert_false(CombatRules.is_in_melee_arc(Vector3.ZERO, FWD, Vector3(0, 0, 1.5), 2.0, 60.0))

func test_alvo_dentro_do_angulo() -> void:
	# atan(1.2 / 1.0) = 50 graus
	assert_true(CombatRules.is_in_melee_arc(Vector3.ZERO, FWD, Vector3(1.2, 0, -1.0), 2.0, 60.0))

func test_alvo_fora_do_angulo() -> void:
	# atan(1.5 / 0.5) = 71.6 graus
	assert_false(CombatRules.is_in_melee_arc(Vector3.ZERO, FWD, Vector3(1.5, 0, -0.5), 2.0, 60.0))

func test_altura_e_ignorada() -> void:
	assert_true(CombatRules.is_in_melee_arc(Vector3.ZERO, FWD, Vector3(0, 1.0, -1.5), 2.0, 60.0))

func test_alvo_na_mesma_posicao_e_atingido() -> void:
	assert_true(CombatRules.is_in_melee_arc(Vector3.ZERO, FWD, Vector3.ZERO, 2.0, 60.0))
