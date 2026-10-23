# gdlint: ignore=max-public-methods
extends GutTest

const HERO: int = 1001
const FRAME: float = 1.0 / 60.0
const FRAME_144: float = 1.0 / 144.0

var _detector: TeleportDetector


func before_each() -> void:
	var rules := TeleportRules.new()
	rules.teleport_threshold_u = 1.0
	rules.teleport_cooldown_s = 0.5
	_detector = TeleportDetector.new(rules)


## [param frames] quadros parado em [param at], so para o tempo correr.
func _idle(at: Vector3, frames: int, delta: float = FRAME) -> void:
	for i: int in frames:
		_detector.observe(HERO, at, delta, 0.0, false)


## Move o heroi [param distance] ao longo de X em [param frames] quadros, a partir de [param from].
func _slide(from: float, distance: float, frames: int, delta: float) -> int:
	var counted := 0
	for i: int in range(1, frames + 1):
		var x := from + distance * i / frames
		if _detector.observe(HERO, Vector3(x, 0.0, 0.0), delta, 0.0, false):
			counted += 1
	return counted


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
	# 300 u/s num quadro de 1/60 s = 5 u esperados; 5,5 u andados = 0,5 u de sobra, abaixo do limite.
	_detector.observe(HERO, Vector3.ZERO, FRAME, 300.0, false)
	assert_false(_detector.observe(HERO, Vector3(5.5, 0.0, 0.0), FRAME, 300.0, false))
	_idle(Vector3(5.5, 0.0, 0.0), 10)
	assert_true(_detector.observe(HERO, Vector3(12.0, 0.0, 0.0), FRAME, 300.0, false))


func test_estado_isento_nao_conta_e_marca_a_nova_posicao() -> void:
	_detector.observe(HERO, Vector3.ZERO, FRAME, 0.0, false)
	assert_false(_detector.observe(HERO, Vector3(30.0, 0.0, 0.0), FRAME, 0.0, true))
	# O proximo quadro mede a partir da posicao isenta: andar de la nao e salto.
	assert_false(_detector.observe(HERO, Vector3(30.1, 0.0, 0.0), FRAME, 0.0, false))
	assert_eq(_detector.count(HERO), 0)


func test_o_deslize_depois_do_quadro_isento_tambem_nao_conta() -> void:
	# Respawn: o interpolador desliza o heroi por alguns quadros depois do quadro isento.
	_detector.observe(HERO, Vector3.ZERO, FRAME, 0.0, false)
	_detector.observe(HERO, Vector3(10.0, 0.0, 0.0), FRAME, 0.0, true)
	assert_eq(_slide(10.0, 30.0, 4, FRAME_144), 0, "deslize dentro do assentamento")
	_idle(Vector3(40.0, 0.0, 0.0), 12)
	assert_eq(_slide(40.0, 5.0, 2, FRAME), 1, "passado o assentamento, salto conta")


func test_mesmo_salto_conta_igual_a_60_e_a_144_quadros_por_segundo() -> void:
	_idle(Vector3.ZERO, 3)
	assert_eq(_slide(0.0, 3.0, 2, FRAME), 1, "60 fps: 2 quadros de 1,5 u")
	_idle(Vector3(3.0, 0.0, 0.0), 60)
	assert_eq(_slide(3.0, 3.0, 5, FRAME_144), 1, "144 fps: 5 quadros de 0,6 u")
	assert_eq(_detector.count(HERO), 2)


func test_andar_rapido_a_144_quadros_nao_acumula_excesso() -> void:
	var speed := 8.0
	for i: int in 300:
		_detector.observe(HERO, Vector3(speed * FRAME_144 * i, 0.0, 0.0), FRAME_144, speed, false)
	assert_eq(_detector.count(HERO), 0)


func test_quadro_de_travada_do_cliente_nao_conta() -> void:
	_detector.observe(HERO, Vector3.ZERO, FRAME, 0.0, false)
	assert_false(_detector.observe(HERO, Vector3(1.4, 0.0, 0.0), 0.2, 0.0, false))
	assert_eq(_detector.count(HERO), 0)


func test_mesmo_salto_nao_conta_duas_vezes_dentro_do_cooldown() -> void:
	_detector.observe(HERO, Vector3.ZERO, FRAME, 0.0, false)
	assert_true(_detector.observe(HERO, Vector3(5.0, 0.0, 0.0), FRAME, 0.0, false))
	assert_false(_detector.observe(HERO, Vector3(10.0, 0.0, 0.0), FRAME, 0.0, false))
	assert_eq(_detector.count(HERO), 1)


func test_depois_do_cooldown_um_novo_salto_conta() -> void:
	_detector.observe(HERO, Vector3.ZERO, FRAME, 0.0, false)
	assert_true(_detector.observe(HERO, Vector3(5.0, 0.0, 0.0), FRAME, 0.0, false))
	_idle(Vector3(5.0, 0.0, 0.0), 40)
	assert_true(_detector.observe(HERO, Vector3(10.0, 0.0, 0.0), FRAME, 0.0, false))
	assert_eq(_detector.count(HERO), 2)


func test_cooldown_corre_em_tempo_real_mesmo_com_dois_herois_por_quadro() -> void:
	var other := HERO + 1
	_detector.observe(HERO, Vector3.ZERO, FRAME, 0.0, false)
	_detector.observe(other, Vector3.ZERO, FRAME, 0.0, false)
	assert_true(_detector.observe(HERO, Vector3(5.0, 0.0, 0.0), FRAME, 0.0, false))
	# 0,3 s de tempo real, com o outro heroi observado a cada quadro: ainda dentro do cooldown.
	for i: int in 17:
		_detector.observe(other, Vector3.ZERO, FRAME, 0.0, false)
		_detector.observe(HERO, Vector3(5.0, 0.0, 0.0), FRAME, 0.0, false)
	assert_false(_detector.observe(HERO, Vector3(10.0, 0.0, 0.0), FRAME, 0.0, false))
	assert_eq(_detector.count(HERO), 1)


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


func test_maior_salto_guarda_o_maior_excesso_visto() -> void:
	var gap := 0.06  # fora da janela: os quadros nao se somam
	_detector.observe(HERO, Vector3.ZERO, gap, 0.0, false)
	_detector.observe(HERO, Vector3(0.4, 0.0, 0.0), gap, 0.0, false)
	_detector.observe(HERO, Vector3(3.4, 0.0, 0.0), gap, 0.0, false)
	_detector.observe(HERO, Vector3(3.5, 0.0, 0.0), gap, 0.0, false)
	assert_almost_eq(_detector.max_excess(), 3.0, 0.001)


func test_quadro_isento_nao_entra_no_maior_salto() -> void:
	_detector.observe(HERO, Vector3.ZERO, FRAME, 0.0, false)
	_detector.observe(HERO, Vector3(40.0, 0.0, 0.0), FRAME, 0.0, true)
	assert_almost_eq(_detector.max_excess(), 0.0, 0.001)


func test_heroi_vivo_visivel_andando_nao_e_isento() -> void:
	assert_false(TeleportDetector.is_exempt(true, true, true, true, false, false))


func test_avanco_ou_empurrao_de_habilidade_isenta() -> void:
	assert_true(TeleportDetector.is_exempt(true, true, true, true, true, false))


func test_respawn_isenta_no_quadro_em_que_volta_e_no_que_estava_morto() -> void:
	assert_true(TeleportDetector.is_exempt(true, false, true, true, false, false), "voltou agora")
	assert_true(TeleportDetector.is_exempt(false, false, true, true, false, false), "morto")
	assert_true(TeleportDetector.is_exempt(false, true, true, true, false, false), "morreu agora")


func test_heroi_escondido_isenta_ate_reaparecer() -> void:
	assert_true(TeleportDetector.is_exempt(true, true, false, true, false, false), "sumiu")
	assert_true(TeleportDetector.is_exempt(true, true, true, false, false, false), "reapareceu")


func test_cinematica_isenta_todos() -> void:
	assert_true(TeleportDetector.is_exempt(true, true, true, true, false, true))
