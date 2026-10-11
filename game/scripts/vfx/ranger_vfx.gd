class_name RangerVfx
extends HeroVfx
## Arqueira (F41): rastro em fita em cada flecha do pool (a flecha visual ja anda desacoplada da
## rede, Arrow), espiral emissiva na Flecha Perfurante e pulso em cada alvo atravessado, 2 tufos de
## poeira e um fantasma no Rolamento, e saraivada na area da Chuva de Flechas enquanto ela dura
## (o indicador da area e o RainArea da cena do heroi). Raio da Chuva de ranger.tres.

const SPARKS: PackedScene = preload("res://scenes/vfx/sparks.tscn")
const PULSE: PackedScene = preload("res://scenes/vfx/pierce_pulse.tscn")
const DUST: PackedScene = preload("res://scenes/vfx/dust_puff.tscn")
const GHOST: PackedScene = preload("res://scenes/vfx/ghost.tscn")
## Altura (u) do impacto: peito do alvo.
const STRIKE_HEIGHT: float = 1.0
## De onde caem as flechas da saraivada (u acima do centro da Chuva).
const VOLLEY_HEIGHT: float = 7.0

## Espiral da Flecha Perfurante: raio (u) e voltas por segundo.
@export var spiral_radius: float = 0.18
@export var spiral_turns: float = 7.0

var _ranger: Ranger
var _arrows: Array[Arrow] = []
var _trails: Array[TrailRibbon] = []
var _spiral_arrow: Arrow = null
var _spiral_phase: float = 0.0

@onready var _arrow_trail: TrailRibbon = $ArrowTrail
@onready var _spiral: TrailRibbon = $Spiral
@onready var _spiral_point: Node3D = $SpiralPoint
@onready var _volley: GPUParticles3D = $Volley


func impact(slot: HitLedger.Slot, at: Vector3) -> void:
	var where := Transform3D(Basis.IDENTITY, at + Vector3.UP * STRIKE_HEIGHT)
	if slot == HitLedger.Slot.Q:
		pool.spawn(PULSE, where)
	elif slot == HitLedger.Slot.BASIC:
		pool.spawn(SPARKS, where)


func _bound() -> void:
	_ranger = hero as Ranger
	for node: Node in hero.get_node("Arrows").get_children():
		var arrow := node as Arrow
		var trail := _arrow_trail
		if not _trails.is_empty():
			trail = _arrow_trail.duplicate() as TrailRibbon
			add_child(trail)
		_trails.append(trail)
		trail.target = arrow
		arrow.shown_launched.connect(trail.clear)
		_arrows.append(arrow)
	_spiral.target = _spiral_point
	var rain := _volley.process_material as ParticleProcessMaterial
	rain.emission_ring_radius = hero.hero_data.skill_r.radius


func _refresh(shown: bool, delta: float) -> void:
	for i: int in _arrows.size():
		_trails[i].emitting = shown and _arrows[i].visible
	_spiral_step(shown, delta)
	var rolling := hero.dash_ticks > 0
	if _started(&"dash_start", int(rolling)):
		pool.spawn(DUST, hero.global_transform)
		var ghost := pool.spawn(GHOST, hero.global_transform) as GhostVfx
		ghost.capture(hero.get_node("Model") as Node3D)
	if _ended(&"dash_end", rolling):
		pool.spawn(DUST, hero.global_transform)
	var raining := shown and _ranger.rain_ticks > 0
	_volley.emitting = raining
	if raining:
		_volley.global_position = _ranger.rain_center + Vector3.UP * VOLLEY_HEIGHT


## A ponta da espiral gira em volta da Flecha Perfurante em voo; flecha nova recomeca a espiral.
func _spiral_step(shown: bool, delta: float) -> void:
	var pierce: Arrow = null
	for arrow: Arrow in _arrows:
		if arrow.visible and arrow.kind == Arrow.Kind.PIERCE:
			pierce = arrow
			break
	if pierce != _spiral_arrow:
		_spiral_arrow = pierce
		_spiral.clear()
	_spiral.emitting = shown and pierce != null
	if pierce == null:
		return
	_spiral_phase = wrapf(_spiral_phase + delta * TAU * spiral_turns, 0.0, TAU)
	var side := pierce.direction.cross(Vector3.UP).normalized()
	var up := side.cross(pierce.direction).normalized()
	var offset := (side * cos(_spiral_phase) + up * sin(_spiral_phase)) * spiral_radius
	_spiral_point.global_position = pierce.global_position + offset
