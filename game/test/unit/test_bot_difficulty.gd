extends GutTest
## O BotInput aplica o nivel (F81): habilidades que saem, erro de mira e tick sem decisao. Sem
## heroi nem arena: so a saida do input, pelos mesmos passos que o think roda no fim.

const EASY := 1
const MEDIUM := 2
const HARD := 3
const SAMPLES: int = 400
## Chance do Facil em bot_levels.tres (0,4) com folga estatistica para 400 sorteios.
const EASY_MIN_KEPT: float = 0.3
const EASY_MAX_KEPT: float = 0.5

var _input: BotInput


func before_each() -> void:
	_input = BotInput.new()
	_input._rng.seed = 7
	add_child_autofree(_input)


func _press_q(aim: Vector3) -> void:
	_input.aim = aim
	_input.skill_q = true
	_input.skill_e = false
	_input.skill_r = false
	_input._apply_level()


func test_medio_e_dificil_nao_tocam_na_saida_nem_sorteiam() -> void:
	for number: int in [MEDIUM, HARD, 0]:
		_input.set_difficulty(number)
		var state := _input._rng.state
		_press_q(Vector3.FORWARD)
		assert_true(_input.skill_q, "n=%d" % number)
		assert_eq(_input.aim, Vector3.FORWARD, "n=%d" % number)
		assert_eq(_input._rng.state, state, "n=%d nao consome sorteio" % number)


func test_r_fica_para_heroi_e_boss() -> void:
	_input.skill_r = true
	_input._ultimate_ok = false
	_input._hold_ultimate()
	assert_false(_input.skill_r, "contra monstro comum o R e solto")
	_input.skill_r = true
	_input._ultimate_ok = true
	_input._hold_ultimate()
	assert_true(_input.skill_r, "contra heroi ou boss o R fica")


func test_facil_deixa_sair_so_parte_das_habilidades() -> void:
	_input.set_difficulty(EASY)
	var kept := 0
	for i: int in SAMPLES:
		_press_q(Vector3.FORWARD)
		kept += int(_input.skill_q)
	assert_between(float(kept) / SAMPLES, EASY_MIN_KEPT, EASY_MAX_KEPT)


func test_facil_erra_a_mira_dentro_do_maximo() -> void:
	_input.set_difficulty(EASY)
	var max_error := BotInput.LEVELS.pick(EASY).aim_error_deg
	var off := 0
	for i: int in SAMPLES:
		_press_q(Vector3.FORWARD)
		var angle := rad_to_deg(Vector3.FORWARD.angle_to(_input.aim))
		assert_lte(angle, max_error + 0.001)
		off += int(angle > 0.5)
	assert_gt(off, SAMPLES / 2, "na maioria das vezes a mira sai torta")


func test_sem_habilidade_a_mira_nao_gira() -> void:
	_input.set_difficulty(EASY)
	_input.aim = Vector3.FORWARD
	_input._apply_level()
	assert_eq(_input.aim, Vector3.FORWARD)


func test_tick_sem_decisao_repete_movimento_e_solta_habilidade() -> void:
	_input.set_difficulty(EASY)
	_input.movement = Vector3.RIGHT
	_input.skill_q = true
	_input.skill_r = true
	_input.learn = 1
	_input._clear_one_shots()
	assert_eq(_input.movement, Vector3.RIGHT)
	assert_false(_input.skill_q or _input.skill_r)
	assert_eq(_input.learn, PlayerInput.LEARN_NONE)
