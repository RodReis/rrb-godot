extends GutTest
## SPEC-066 §1: o heroi encara o movimento; ao disparar, vira para a mira e a mantem pela janela.

const AIM: Vector3 = Vector3.RIGHT
const MOVE: Vector3 = Vector3.FORWARD


func test_andando_sem_disparar_encara_o_movimento() -> void:
	assert_eq(FacingRules.direction(MOVE, AIM, false, 0), MOVE)


func test_parado_mantem_o_yaw() -> void:
	assert_eq(FacingRules.direction(Vector3.ZERO, AIM, false, 0), Vector3.ZERO)


func test_disparando_vira_para_a_mira_mesmo_andando() -> void:
	assert_eq(FacingRules.direction(MOVE, AIM, true, 0), AIM)


func test_janela_aberta_mantem_o_yaw_andando() -> void:
	assert_eq(FacingRules.direction(MOVE, AIM, false, 5), Vector3.ZERO)


func test_disparar_de_novo_na_janela_vira_para_a_nova_mira() -> void:
	assert_eq(FacingRules.direction(MOVE, AIM, true, 5), AIM)


func test_disparando_sem_mira_cai_no_movimento() -> void:
	assert_eq(FacingRules.direction(MOVE, Vector3.ZERO, true, 0), MOVE)


func test_disparando_sem_mira_na_janela_mantem() -> void:
	assert_eq(FacingRules.direction(MOVE, Vector3.ZERO, true, 3), Vector3.ZERO)
