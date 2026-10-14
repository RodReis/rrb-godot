extends GutTest
## RogueRules (GDB §4.5, F58): abertura do leque da Rajada e fator da Emboscada oculta.

const EPS: float = 0.0001
const SPREAD: float = 12.0
const AHEAD: Vector3 = Vector3(0, 0, -1)


func test_leque_de_tres_abre_menos_zero_e_mais_a_abertura() -> void:
	assert_almost_eq(RogueRules.fan_angle(0, 3, SPREAD), -12.0, EPS)
	assert_almost_eq(RogueRules.fan_angle(1, 3, SPREAD), 0.0, EPS)
	assert_almost_eq(RogueRules.fan_angle(2, 3, SPREAD), 12.0, EPS)


func test_um_virote_so_vai_reto() -> void:
	assert_almost_eq(RogueRules.fan_angle(0, 1, SPREAD), 0.0, EPS)


func test_leque_de_quatro_e_simetrico() -> void:
	assert_almost_eq(RogueRules.fan_angle(0, 4, SPREAD), -18.0, EPS)
	assert_almost_eq(RogueRules.fan_angle(3, 4, SPREAD), 18.0, EPS)


func test_direcao_sem_angulo_e_a_propria_mira() -> void:
	var dir := RogueRules.fan_direction(AHEAD, 0.0)
	assert_almost_eq(dir.x, 0.0, EPS)
	assert_almost_eq(dir.z, -1.0, EPS)


func test_direcao_gira_no_plano_e_fica_unitaria() -> void:
	var dir := RogueRules.fan_direction(AHEAD, 12.0)
	assert_almost_eq(dir.length(), 1.0, EPS)
	assert_almost_eq(dir.y, 0.0, EPS)
	assert_almost_eq(rad_to_deg(AHEAD.angle_to(dir)), 12.0, EPS)


func test_direcoes_opostas_sao_espelhadas() -> void:
	var left := RogueRules.fan_direction(AHEAD, -12.0)
	var right := RogueRules.fan_direction(AHEAD, 12.0)
	assert_almost_eq(left.x, -right.x, EPS)
	assert_almost_eq(left.z, right.z, EPS)


func test_direcao_ignora_a_altura_da_mira() -> void:
	var dir := RogueRules.fan_direction(Vector3(0, 0.5, -1), 0.0)
	assert_almost_eq(dir.y, 0.0, EPS)
	assert_almost_eq(dir.length(), 1.0, EPS)


func test_mira_nula_nao_gera_direcao() -> void:
	assert_eq(RogueRules.fan_direction(Vector3.ZERO, 12.0), Vector3.ZERO)


func test_emboscada_oculta_multiplica_por_um_virgula_tres() -> void:
	# rank 1, INT 12 e ATK 54: 220 + 1,2 * 12 + 0,6 * 54 = 266,8
	assert_eq(RogueRules.ambush_damage(266.8, true, 1.3), 347)


func test_emboscada_revelada_nao_multiplica() -> void:
	assert_eq(RogueRules.ambush_damage(266.8, false, 1.3), 267)
