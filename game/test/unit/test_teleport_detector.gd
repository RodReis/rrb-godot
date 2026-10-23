extends GutTest

const HERO: int = 1001
const FRAME: float = 1.0 / 60.0

var _detector: TeleportDetector


func before_each() -> void:
	var rules := TeleportRules.new()
	rules.teleport_threshold_u = 1.0
	rules.teleport_cooldown_s = 0.5
	_detector = TeleportDetector.new(rules)


func test_andar_normal_nao_conta() -> void:
	for i: int in 120:
		_detector.observe(HERO, Vector3(5.0 * FRAME * i, 0.0, 0.0), FRAME, 5.0, false)
	assert_eq(_detector.count(HERO), 0)


func test_o_primeiro_quadro_so_marca_a_posicao() -> void:
	assert_false(_detector.observe(HERO, Vector3(50.0, 0.0, 0.0), FRAME, 0.0, false))
	assert_eq(_detector.count(HERO), 0)


func test_salto_acima_do_limite_conta_um() -> void:
	_detector.observe(HERO, Vector3.ZERO, FRAME, 0.0, false)
	assert_true(_detector.observe(HERO, Vector3(2.0, 0.0, 0.0), FRAME, 0.0, false))
	assert_eq(_detector.count(HERO), 1)


func test_salto_no_limite_nao_conta() -> void:
	_detector.observe(HERO, Vector3.ZERO, FRAME, 0.0, false)
	assert_false(_detector.observe(HERO, Vector3(1.0, 0.0, 0.0), FRAME, 0.0, false))
	assert_eq(_detector.count(HERO), 0)


func test_o_que_a_velocidade_explica_e_descontado() -> void:
	# 10 u/s em quadro de 0,5 s = 5 u esperados; 5,5 u andados = 0,5 u de sobra, abaixo do limite.
	_detector.observe(HERO, Vector3.ZERO, 0.5, 10.0, false)
	assert_false(_detector.observe(HERO, Vector3(5.5, 0.0, 0.0), 0.5, 10.0, false))
	assert_true(_detector.observe(HERO, Vector3(12.0, 0.0, 0.0), 0.5, 10.0, false))


func test_estado_isento_nao_conta_e_marca_a_nova_posicao() -> void:
	_detector.observe(HERO, Vector3.ZERO, FRAME, 0.0, false)
	assert_false(_detector.observe(HERO, Vector3(30.0, 0.0, 0.0), FRAME, 0.0, true))
	# O proximo quadro mede a partir da posicao isenta: andar de la nao e salto.
	assert_false(_detector.observe(HERO, Vector3(30.1, 0.0, 0.0), FRAME, 0.0, false))
	assert_eq(_detector.count(HERO), 0)


func test_mesmo_salto_nao_conta_duas_vezes_dentro_do_cooldown() -> void:
	_detector.observe(HERO, Vector3.ZERO, FRAME, 0.0, false)
	assert_true(_detector.observe(HERO, Vector3(5.0, 0.0, 0.0), FRAME, 0.0, false))
	assert_false(_detector.observe(HERO, Vector3(10.0, 0.0, 0.0), FRAME, 0.0, false))
	assert_eq(_detector.count(HERO), 1)


func test_depois_do_cooldown_um_novo_salto_conta() -> void:
	_detector.observe(HERO, Vector3.ZERO, FRAME, 0.0, false)
	assert_true(_detector.observe(HERO, Vector3(5.0, 0.0, 0.0), FRAME, 0.0, false))
	_detector.observe(HERO, Vector3(5.0, 0.0, 0.0), 0.6, 0.0, false)
	assert_true(_detector.observe(HERO, Vector3(10.0, 0.0, 0.0), FRAME, 0.0, false))
	assert_eq(_detector.count(HERO), 2)


func test_cada_heroi_tem_a_propria_conta() -> void:
	_detector.observe(HERO, Vector3.ZERO, FRAME, 0.0, false)
	_detector.observe(HERO + 1, Vector3.ZERO, FRAME, 0.0, false)
	_detector.observe(HERO, Vector3(5.0, 0.0, 0.0), FRAME, 0.0, false)
	assert_eq(_detector.count(HERO), 1)
	assert_eq(_detector.count(HERO + 1), 0)
	assert_eq(_detector.total(), 1)


func test_esquecer_o_heroi_reinicia_a_posicao() -> void:
	_detector.observe(HERO, Vector3.ZERO, FRAME, 0.0, false)
	_detector.forget(HERO)
	assert_false(_detector.observe(HERO, Vector3(40.0, 0.0, 0.0), FRAME, 0.0, false))


func test_o_limite_vem_da_regra_nao_de_um_numero_fixo() -> void:
	var rules := TeleportRules.new()
	rules.teleport_threshold_u = 5.0
	rules.teleport_cooldown_s = 0.5
	var loose := TeleportDetector.new(rules)
	loose.observe(HERO, Vector3.ZERO, FRAME, 0.0, false)
	assert_false(loose.observe(HERO, Vector3(3.0, 0.0, 0.0), FRAME, 0.0, false))
