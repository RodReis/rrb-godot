extends GutTest
## Animacao de status sobre a cabeca (PI 2026-10-22): um status por vez, atordoado > preso > lento.


func test_sem_controle_nada() -> void:
	assert_eq(StatusRules.shown(0, 0, 0.0), StatusRules.Status.NONE)
	assert_eq(StatusRules.shown(0, 0, 0.5), StatusRules.Status.NONE, "lentidao ja acabou")


func test_atordoado_vence_os_outros() -> void:
	assert_eq(StatusRules.shown(10, 30, 1.0), StatusRules.Status.STUN)


func test_lentidao_total_e_preso() -> void:
	assert_eq(StatusRules.shown(0, 30, 1.0), StatusRules.Status.ROOT)


func test_lentidao_parcial_e_lento() -> void:
	assert_eq(StatusRules.shown(0, 30, 0.4), StatusRules.Status.SLOW)
