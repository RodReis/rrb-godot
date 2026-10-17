extends GutTest
## INTRO (F69): enquanto o MatchController trava o input (Hero.input_locked), o servidor nao aplica
## movimento nem skill; destravado, o heroi anda. Nada de rollback novo: so um retorno cedo.

const KNIGHT: String = "res://scenes/heroes/knight.tscn"
const TICK: float = 1.0 / 30.0

var _hero: Hero
var _tick: int = 100


func before_each() -> void:
	_tick = 100
	_hero = (load(KNIGHT) as PackedScene).instantiate() as Hero
	_hero.name = "1"
	_hero.team = GateRules.TEAM_A
	add_child_autofree(_hero)


func _step(count: int = 1) -> void:
	for i: int in count:
		_tick += 1
		_hero._rollback_tick(TICK, _tick, true)


func test_travado_ignora_o_movimento() -> void:
	_hero.input_locked = true
	_hero.input.movement = Vector3.RIGHT
	_step(5)
	assert_eq(_hero.global_position, Vector3.ZERO)
	assert_eq(_hero.velocity, Vector3.ZERO)


func test_travado_ignora_a_mira_e_o_ataque() -> void:
	_hero.input_locked = true
	_hero.input.aim = Vector3.RIGHT
	_hero.input.attack = true
	var facing := _hero.forward()
	_step(3)
	assert_almost_eq(_hero.forward(), facing, Vector3(0.01, 0.01, 0.01), "nao encara a mira")


func test_destravado_anda() -> void:
	_hero.input.movement = Vector3.RIGHT
	_step(5)
	assert_gt(_hero.global_position.x, 0.0)
