extends GutTest
## Ressimular um tick do estado restaurado (transform, velocity) da o mesmo resultado, seja
## qual for o estado interno que o CharacterBody3D guardou do tick anterior (#41).

const ARENA: String = "res://scenes/arena/ilha_arcana.tscn"
const KNIGHT: String = "res://scenes/heroes/knight.tscn"
const AXIS_A: Vector3 = Vector3(-0.70710678, 0, 0.70710678)
const LATERAL: Vector3 = Vector3(0.70710678, 0, 0.70710678)
const TICK: float = 1.0 / 30.0
const PREP_SPEED: float = 600.0
## Canto entre portao A e muro onde a correcao apareceu a 100 ms (#41).
const GATE_CORNER: Vector3 = Vector3(-17.22574, 0.000732, 12.32446)

var _arena: Node3D
var _hero: Hero


func before_all() -> void:
	_arena = (load(ARENA) as PackedScene).instantiate() as Node3D
	add_child(_arena)
	_hero = (load(KNIGHT) as PackedScene).instantiate() as Hero
	_hero.name = "1"
	_hero.team = GateRules.TEAM_A
	_hero.collision_mask = GateRules.hero_mask(GateRules.TEAM_A)
	_arena.add_child(_hero)


func after_all() -> void:
	_arena.free()


## Deixa o corpo com estado interno de chao (velocidade para baixo) ou de ar (para cima),
## restaura o estado de rollback e roda um tick.
func _tick_after(prep_velocity: Vector3, start: Vector3, direction: Vector3) -> Vector3:
	_hero.transform = Transform3D(Basis(), Vector3(0, 3, 0))
	_hero.velocity = prep_velocity
	_hero.move_and_slide()
	_hero.transform = Transform3D(Basis(), start)
	_hero.velocity = Vector3.ZERO
	_hero.input.movement = direction.normalized()
	_hero._rollback_tick(TICK, 0, true)
	return _hero.global_position


func _assert_same_tick(start: Vector3, direction: Vector3) -> void:
	var from_floor := _tick_after(Vector3.DOWN * PREP_SPEED, start, direction)
	var from_air := _tick_after(Vector3.UP * PREP_SPEED, start, direction)
	assert_eq(from_floor, from_air, "tick divergiu partindo de %s" % start)


func test_tick_acima_do_chao_nao_depende_do_estado_interno() -> void:
	await wait_physics_frames(2)
	_assert_same_tick(AXIS_A * 10 + Vector3.UP * 0.05, LATERAL)


func test_tick_no_canto_do_portao_nao_depende_do_estado_interno() -> void:
	await wait_physics_frames(2)
	_assert_same_tick(GATE_CORNER + Vector3.UP * 0.05, AXIS_A - LATERAL * 0.3)


func test_heroi_planar_no_chao_e_no_muro() -> void:
	await wait_physics_frames(2)
	_hero.transform = Transform3D(Basis(), AXIS_A * 20 + LATERAL * 5)
	_hero.input.movement = AXIS_A
	for tick: int in 60:
		_hero._rollback_tick(TICK, tick, true)
		assert_eq(_hero.global_position.y, 0.0, "saiu do plano no tick %d" % tick)


func test_ressimular_do_meio_reproduz_a_travessia_raspando_o_muro() -> void:
	await wait_physics_frames(2)
	var direction := (-AXIS_A + LATERAL * 0.6).normalized()
	var states: Array[Transform3D] = []
	_hero.transform = Transform3D(Basis(), AXIS_A * 26 + LATERAL * 1.5)
	_hero.velocity = Vector3.ZERO
	_hero.input.movement = direction
	for tick: int in 60:
		states.append(_hero.transform)
		_hero._rollback_tick(TICK, tick, true)
	var expected := _hero.global_position
	for k: int in range(0, 60, 10):
		_hero.transform = states[k]
		_hero.velocity = Vector3.ZERO
		for tick: int in range(k, 60):
			_hero._rollback_tick(TICK, tick, false)
		assert_eq(_hero.global_position, expected, "ressimulacao do tick %d divergiu" % k)
