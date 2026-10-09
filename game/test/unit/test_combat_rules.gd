extends GutTest

const FWD := Vector3(0, 0, -1)  # -Z e a frente no Godot


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


func test_dano_mitigado_pela_def_arredonda() -> void:
	assert_eq(CombatRules.mitigated(120, 30.0), 92)


func test_golpe_pela_frente_e_frontal() -> void:
	assert_true(CombatRules.is_frontal(Vector3.ZERO, FWD, Vector3(0, 0, -3)))


func test_golpe_de_lado_conta_como_frontal_no_limite_de_180_graus() -> void:
	assert_true(CombatRules.is_frontal(Vector3.ZERO, FWD, Vector3(3, 0, 0)))


func test_golpe_pelas_costas_nao_e_frontal() -> void:
	assert_false(CombatRules.is_frontal(Vector3.ZERO, FWD, Vector3(0.5, 0, 3)))


func test_escudo_absorve_ate_esgotar() -> void:
	assert_eq(CombatRules.absorb(50, 210), Vector2i(0, 160))
	assert_eq(CombatRules.absorb(250, 210), Vector2i(40, 0))


func test_sem_escudo_dano_passa_inteiro() -> void:
	assert_eq(CombatRules.absorb(50, 0), Vector2i(50, 0))


func test_contato_da_investida_mede_no_plano() -> void:
	assert_true(CombatRules.in_radius(Vector3.ZERO, Vector3(0.6, 1.0, 0.4), 0.8))
	assert_false(CombatRules.in_radius(Vector3.ZERO, Vector3(0.7, 0, 0.5), 0.8))


func test_empurrao_e_horizontal_com_a_distancia_dada() -> void:
	var push := CombatRules.push_vector(Vector3(0, 0.5, -2), 1.5)
	assert_almost_eq(push, Vector3(0, 0, -1.5), Vector3.ONE * 0.0001)


func test_empurrao_sem_direcao_e_zero() -> void:
	assert_eq(CombatRules.push_vector(Vector3.ZERO, 1.5), Vector3.ZERO)
