class_name EngineerVfx
extends HeroVfx
## Engenheiro (F59, SPEC-059 §6), so cliente: clarao de boca em estrela, estilhacos em leque no
## cone do GDB (40 graus, 4,5 u) e fumaca no cano a cada tiro do Bacamarte; a Garra voa com um cabo
## fino esticado da mao ate ela (por quadro, sem fisica) e, ao parar, o cabo encurta ate o ponto de
## parada do puxao; faiscas metalicas no acerto. A Torreta e a caixa nao saem do estado do
## Engenheiro (ele some de quem esta fora da visao): chegam pelo ImpactRelay (deployed,
## turret_shot). Raios, alcances e tempos de engineer.tres.

const BLAST: PackedScene = preload("res://scenes/vfx/blunder_blast.tscn")
const SPARKS: PackedScene = preload("res://scenes/vfx/sparks.tscn")
const TURRET: PackedScene = preload("res://scenes/vfx/turret_vfx.tscn")
const TRACER: PackedScene = preload("res://scenes/vfx/turret_tracer.tscn")
const CRATE: PackedScene = preload("res://scenes/vfx/dynamite_crate.tscn")
## Altura (u) do impacto: peito do alvo.
const STRIKE_HEIGHT: float = 1.0
## Boca do bacamarte e mao que lanca a garra, no espaco do heroi (u).
const MUZZLE: Vector3 = Vector3(-0.3, 1.1, -0.9)
const HAND: Vector3 = Vector3(-0.3, 1.0, -0.4)
## Altura (u) da boca do cano da Torreta acima do ponto dela.
const TURRET_MUZZLE_HEIGHT: float = 0.96
## Espessura do cabo da Garra (u).
const CABLE_WIDTH: float = 0.04

var _engineer: Engineer
var _claw: Arrow
var _turret: TurretVfx
## Cabo recolhendo depois da parada da garra: de onde (ponto de parada) e quanto tempo falta.
var _retract_from: Vector3 = Vector3.ZERO
var _retract_to: Vector3 = Vector3.ZERO
var _retract_left: float = 0.0

@onready var _cable: MeshInstance3D = $Cable
@onready var _claw_end: Node3D = $ClawEnd


## Acerto confirmado pelo servidor: faiscas no alvo (bacamarte, garra, Torreta).
func impact(slot: HitLedger.Slot, at: Vector3) -> void:
	var where := Transform3D(Basis.IDENTITY, at + Vector3.UP * STRIKE_HEIGHT)
	if slot != HitLedger.Slot.R:  # a Dinamite tem a explosao dela
		pool.spawn(SPARKS, where)


## Torreta ou caixa posta em [param center] no [param tick] (ImpactRelay): mostra so o que falta.
func deployed(kind: int, center: Vector3, tick: int) -> void:
	if kind == Engineer.Deploy.TURRET:
		_install_turret(center, tick)
	else:
		_throw_crate(center, tick)


## A Torreta atirou em [param at] (ImpactRelay): cabeca gira, clarao e tracante reto.
func turret_shot(from: Vector3, at: Vector3) -> void:
	if _turret != null and _turret.is_up_for(hero.peer_id):
		_turret.shoot(at)
	var muzzle := from + Vector3.UP * TURRET_MUZZLE_HEIGHT
	var target := Vector3(at.x, muzzle.y, at.z)
	var length := muzzle.distance_to(target)
	if length < CombatRules.MIN_TARGET_DISTANCE:
		return
	var basis := Basis.looking_at(target - muzzle, Vector3.UP)
	pool.spawn(TRACER, Transform3D(basis, muzzle), length)


func _bound() -> void:
	_engineer = hero as Engineer
	_claw = hero.get_node("Arrows/Arrow0") as Arrow
	_cable.top_level = true
	_claw_end.top_level = true


func _refresh(shown: bool, delta: float) -> void:
	var data := hero.hero_data
	if _started(&"basic", hero.basic_cooldown):
		var muzzle := hero.global_transform * Transform3D(Basis.IDENTITY, MUZZLE)
		pool.spawn(BLAST, muzzle, data.basic_attack.attack_range)
	var flying := _claw.is_active()
	if _ended(&"claw", flying):
		_retract_from = _claw.origin
		_retract_to = _stop_point(_claw.origin)
		_retract_left = SkillData.at_rank(data.skill_q.duration, 1)
	var hand := hero.global_transform * HAND
	_cable.visible = false
	_claw_end.visible = false
	if not shown:
		_retract_left = 0.0
		return
	if flying:
		_stretch(hand, _claw.global_position)
	elif _retract_left > 0.0:
		_retract_left = maxf(_retract_left - delta, 0.0)
		var total := SkillData.at_rank(data.skill_q.duration, 1)
		var t := 1.0 - _retract_left / maxf(total, 0.001)
		_stretch(hand, _retract_from.lerp(_retract_to, t))


## O ponto a distance do heroi na reta ate [param stop]: onde o puxado fica (engineer.tres).
func _stop_point(stop: Vector3) -> Vector3:
	var distance := hero.hero_data.skill_q.distance
	var flat := Vector3(stop.x - hero.global_position.x, 0.0, stop.z - hero.global_position.z)
	if flat.length() <= distance:
		return stop
	var point := hero.global_position + flat.normalized() * distance
	return Vector3(point.x, stop.y, point.z)


## Cabo e garra entre [param from] e [param to]: cilindro fino esticado no comprimento.
func _stretch(from: Vector3, to: Vector3) -> void:
	var length := from.distance_to(to)
	if length < CombatRules.MIN_TARGET_DISTANCE:
		return
	var basis := Basis.looking_at(to - from, Vector3.UP)
	_cable.visible = true
	_cable.global_transform = Transform3D(basis.scaled_local(Vector3(1.0, 1.0, length)), from)
	_claw_end.visible = not _claw.is_active()
	_claw_end.global_transform = Transform3D(basis, to)


func _install_turret(center: Vector3, tick: int) -> void:
	var e := hero.hero_data.skill_e
	var total := SkillData.at_rank(e.duration, maxi(hero.ranks.y, 1))
	var left := total - float(NetworkTime.tick - tick) / NetworkTime.tickrate
	if _turret != null and _turret.is_up_for(hero.peer_id):
		_turret.retire()  # a nova substitui a anterior na hora
	if left <= 0.0:
		return
	_turret = pool.spawn(TURRET, Transform3D(Basis.IDENTITY, center)) as TurretVfx
	_turret.last(minf(left, total), hero.peer_id)


func _throw_crate(center: Vector3, tick: int) -> void:
	var r := hero.hero_data.skill_r
	var total := SkillData.at_rank(r.duration, maxi(hero.ranks.z, 1))
	var left := total - float(NetworkTime.tick - tick) / NetworkTime.tickrate
	if left <= 0.0:
		return
	var crate := pool.spawn(CRATE, Transform3D(Basis.IDENTITY, center), r.radius)
	(crate as DynamiteCrateVfx).arm(hero.global_transform * HAND, minf(left, total), pool)
