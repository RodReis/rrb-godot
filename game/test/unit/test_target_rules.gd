extends GutTest
## SPEC-066 §2-3: alvo travado valido so se existe, e adversario, esta vivo e visivel; destrava
## quando deixa de ser; auto-ataque so em alcance.

const OTHER: int = 7
const MONSTER: int = -3


func test_valido_exige_os_quatro() -> void:
	assert_true(TargetRules.is_valid(true, true, true, true))
	assert_false(TargetRules.is_valid(false, true, true, true), "nao existe")
	assert_false(TargetRules.is_valid(true, false, true, true), "aliado")
	assert_false(TargetRules.is_valid(true, true, false, true), "morto")
	assert_false(
		TargetRules.is_valid(true, true, true, false), "fora da visao (moita, fumaca, neblina)"
	)


func test_pedido_valido_trava() -> void:
	assert_eq(TargetRules.resolve(TargetRules.NONE, OTHER, false, true, false), OTHER)


func test_pedido_recusado_vira_nenhum() -> void:
	assert_eq(TargetRules.resolve(TargetRules.NONE, OTHER, false, false, false), TargetRules.NONE)


func test_pedido_recusado_destrava_o_anterior() -> void:
	assert_eq(TargetRules.resolve(MONSTER, OTHER, false, false, true), TargetRules.NONE)


func test_pedido_valido_troca_de_alvo() -> void:
	assert_eq(TargetRules.resolve(MONSTER, OTHER, false, true, true), OTHER)


func test_sem_pedido_mantem_o_alvo_valido() -> void:
	assert_eq(TargetRules.resolve(OTHER, TargetRules.NONE, false, false, true), OTHER)


func test_alvo_que_deixou_de_ser_valido_destrava() -> void:
	assert_eq(TargetRules.resolve(OTHER, TargetRules.NONE, false, false, false), TargetRules.NONE)


func test_cancelar_destrava() -> void:
	assert_eq(TargetRules.resolve(OTHER, TargetRules.NONE, true, false, true), TargetRules.NONE)


func test_pedido_vence_o_cancelar_do_mesmo_tick() -> void:
	assert_eq(TargetRules.resolve(MONSTER, OTHER, true, true, true), OTHER)


func test_revide_trava_o_agressor_quando_nao_ha_alvo() -> void:
	assert_eq(TargetRules.retaliate(TargetRules.NONE, false, OTHER), OTHER)


func test_revide_trava_o_agressor_quando_o_alvo_deixou_de_ser_valido() -> void:
	assert_eq(TargetRules.retaliate(MONSTER, false, OTHER), OTHER)


func test_revide_nao_troca_um_alvo_valido() -> void:
	assert_eq(TargetRules.retaliate(MONSTER, true, OTHER), MONSTER)


func test_revide_sem_agressor_mantem_o_alvo() -> void:
	assert_eq(TargetRules.retaliate(MONSTER, true, TargetRules.NONE), MONSTER)
	assert_eq(TargetRules.retaliate(TargetRules.NONE, false, TargetRules.NONE), TargetRules.NONE)


func test_ataca_so_em_alcance_e_com_alvo_valido() -> void:
	var from := Vector3.ZERO
	assert_true(
		TargetRules.can_attack(true, from, Vector3(0.0, 5.0, 3.0), 3.0),
		"no limite, altura nao conta"
	)
	assert_false(TargetRules.can_attack(true, from, Vector3(0.0, 0.0, 3.1), 3.0), "fora do alcance")
	assert_false(TargetRules.can_attack(false, from, Vector3(0.0, 0.0, 1.0), 3.0), "alvo invalido")


func test_mira_no_alvo_e_horizontal_e_unitaria() -> void:
	var aim := TargetRules.aim_to(Vector3(1.0, 0.0, 1.0), Vector3(1.0, 4.0, 5.0))
	assert_eq(aim, Vector3(0.0, 0.0, 1.0))


func test_mira_no_alvo_em_cima_do_heroi_e_zero() -> void:
	assert_eq(TargetRules.aim_to(Vector3.ONE, Vector3.ONE), Vector3.ZERO)
