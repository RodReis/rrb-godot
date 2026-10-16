extends GutTest
## SPEC-066 (F66): o heroi encara o movimento e vira para a mira ao disparar; alvo travado com
## auto-ataque em alcance. Dois Cavaleiros (alcance do basico 2,2 u); servidor = processo do teste.

const KNIGHT: String = "res://scenes/heroes/knight.tscn"
const SKELETON: String = "res://scenes/monsters/skeleton_t1.tscn"
const TICK: float = 1.0 / 30.0
const ME: int = 1
const FOE: int = 2
const MONSTER_UID: int = -5
## Dentro do raio de visao (12 u) e fora do alcance do basico.
const FAR: Vector3 = Vector3(0.0, 0.0, -6.0)
const IN_REACH: Vector3 = Vector3(2.0, 0.0, 0.0)
const BEYOND_SIGHT: Vector3 = Vector3(0.0, 0.0, -20.0)
const EPS: Vector3 = Vector3(0.01, 0.01, 0.01)

var _me: Hero
var _foe: Hero
var _tick: int = 100


func before_each() -> void:
	_tick = 100
	_me = _spawn(ME, GateRules.TEAM_A, Vector3.ZERO)
	_foe = _spawn(FOE, GateRules.TEAM_B, FAR)


func _spawn(id: int, team: int, at: Vector3) -> Hero:
	var hero := (load(KNIGHT) as PackedScene).instantiate() as Hero
	hero.name = str(id)
	hero.team = team
	hero.transform = Transform3D(Basis(), at)
	add_child_autofree(hero)
	return hero


## [param count] ticks de todos; o pedido de alvo vale so no primeiro (pulso, como no PlayerInput).
func _step(count: int = 1) -> void:
	for i: int in count:
		_tick += 1
		_me._rollback_tick(TICK, _tick, true)
		_foe._rollback_tick(TICK, _tick, true)
		_me.input.target_id = TargetRules.NONE
		_me.input.target_clear = false


func _lock(id: int) -> void:
	_me.input.target_id = id
	_step()


func test_anda_e_encara_o_movimento() -> void:
	_me.input.movement = Vector3.RIGHT
	_step()
	assert_almost_eq(_me.forward(), Vector3.RIGHT, EPS)


func test_parado_mantem_o_yaw_mesmo_com_mira() -> void:
	_me.input.aim = Vector3.RIGHT
	_step(3)
	assert_almost_eq(_me.forward(), Vector3.FORWARD, EPS)


func test_ataque_vira_para_a_mira_e_mantem_pela_janela() -> void:
	_me.input.movement = Vector3.BACK
	_me.input.aim = Vector3.RIGHT
	_me.input.attack = true
	_step()
	assert_almost_eq(_me.forward(), Vector3.RIGHT, EPS, "vira no tick do disparo")
	_me.input.attack = false
	_step(11)
	assert_almost_eq(_me.forward(), Vector3.RIGHT, EPS, "mantem por 0,4 s (12 ticks com o disparo)")
	_step()
	assert_almost_eq(_me.forward(), Vector3.BACK, EPS, "depois volta a encarar o movimento")


func test_basico_em_recarga_nao_vira() -> void:
	_me.basic_cooldown = 50
	_me.input.movement = Vector3.BACK
	_me.input.aim = Vector3.RIGHT
	_me.input.attack = true
	_step()
	assert_almost_eq(_me.forward(), Vector3.BACK, EPS)


func test_skill_pronta_vira_para_a_mira_e_avanca_nela() -> void:
	_me.input.aim = Vector3.RIGHT
	_me.input.skill_q = true
	_step()
	assert_almost_eq(_me.dash_direction, Vector3.RIGHT, EPS)


func test_skill_em_recarga_nao_vira() -> void:
	_me.q_cooldown = 100
	_me.input.aim = Vector3.RIGHT
	_me.input.skill_q = true
	_step()
	assert_almost_eq(_me.forward(), Vector3.FORWARD, EPS)


func test_skill_nao_aprendida_nao_vira() -> void:
	assert_eq(_me.ranks.y, 0, "nivel 1: E ainda sem ponto")
	_me.input.aim = Vector3.RIGHT
	_me.input.skill_e = true
	_step()
	assert_almost_eq(_me.forward(), Vector3.FORWARD, EPS)


func test_empurrado_nao_ataca_sozinho() -> void:
	_foe.global_position = IN_REACH
	_me.knockback_ticks = 3
	_me.knockback_velocity = Vector3.ZERO
	_lock(FOE)
	assert_eq(_me.basic_cooldown, 0, "sem virar, o golpe sairia na direcao antiga")


func test_botao_segurado_sem_alvo_continua_na_mira_do_cursor() -> void:
	_foe.global_position = IN_REACH
	_me.input.aim = Vector3.RIGHT
	_me.input.attack = true
	_step(2)
	assert_eq(_me.target_id, TargetRules.NONE)
	assert_lt(_foe.hp, _foe.attributes.max_hp)


func test_skill_no_mesmo_tick_manda_a_mira_do_cursor() -> void:
	_foe.global_position = IN_REACH
	_me.input.aim = Vector3.BACK
	_me.input.skill_q = true
	_lock(FOE)
	assert_almost_eq(_me.dash_direction, Vector3.BACK, EPS)
