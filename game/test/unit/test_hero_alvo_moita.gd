extends GutTest
## SPEC-066 §3 (F32 + F66): o servidor recusa travar heroi escondido na moita e solta o alvo que
## entra nela; quem esta na mesma moita ou acabou de atacar (revelado) pode ser travado.

const ARENA: String = "res://scenes/arena/ilha_arcana.tscn"
const KNIGHT: String = "res://scenes/heroes/knight.tscn"
const DT: float = 1.0 / 30.0
const HIDER: int = 7
const SEEKER: int = 8
## Distancia ate um ponto do lado de fora, colado na borda (u).
const EDGE_OUT: float = 0.1

var _grass: Area3D
var _hider: Hero
var _seeker: Hero
var _tick: int = 100


func before_each() -> void:
	add_child_autofree((load(ARENA) as PackedScene).instantiate())
	_grass = get_tree().get_first_node_in_group(VisibilityRules.GROUP) as Area3D
	_hider = _spawn(HIDER, GateRules.TEAM_A)
	_seeker = _spawn(SEEKER, GateRules.TEAM_B)
	_hider.global_position = _center()
	_seeker.global_position = _outside()


func _spawn(id: int, team: int) -> Hero:
	var hero := (load(KNIGHT) as PackedScene).instantiate() as Hero
	hero.name = str(id)
	hero.team = team
	add_child_autofree(hero)
	return hero


func _shape() -> CollisionShape3D:
	return _grass.get_child(0) as CollisionShape3D


func _center() -> Vector3:
	var at := _shape().global_position
	at.y = 0.0
	return at


func _outside() -> Vector3:
	var half := (_shape().shape as BoxShape3D).size.x / 2.0
	return _center() + _shape().global_basis.x.normalized() * (half + EDGE_OUT)


## Um tick do buscador pedindo o alvo [param id] (pulso de um tick).
func _seek(id: int) -> void:
	_tick += 1
	_seeker.input.target_id = id
	_seeker._rollback_tick(DT, _tick, true)
	_seeker.input.target_id = TargetRules.NONE


func test_recusa_alvo_escondido_na_moita() -> void:
	_seek(HIDER)
	assert_eq(_seeker.target_id, TargetRules.NONE)


func test_alvo_que_entra_na_moita_e_solto() -> void:
	_hider.global_position = _outside()
	_seek(HIDER)
	assert_eq(_seeker.target_id, HIDER, "fora da moita o alvo e visivel")
	_hider.global_position = _center()
	_seek(TargetRules.NONE)
	assert_eq(_seeker.target_id, TargetRules.NONE)


func test_na_mesma_moita_pode_travar() -> void:
	_seeker.global_position = _center()
	_seek(HIDER)
	assert_eq(_seeker.target_id, HIDER)


func test_revelado_por_atacar_pode_travar() -> void:
	_hider.reveal_ticks = 30
	_seek(HIDER)
	assert_eq(_seeker.target_id, HIDER)
