class_name KnightVfx
extends HeroVfx
## Cavaleiro (F41): rastro do basico varrendo o arco do golpe (fita de swing_seconds), faiscas no
## impacto, linhas de velocidade durante a Investida e poeira no fim, Muralha com fresnel e favo
## enquanto dura, e Terremoto (rachadura no raio do GDB, fragmentos, onda de choque com refracao).
## Alcance e arco do basico e raio do Terremoto vem de knight.tres; a Muralha toma a forma do
## ShieldBlocker da cena do heroi.

const SPARKS: PackedScene = preload("res://scenes/vfx/sparks.tscn")
const DUST: PackedScene = preload("res://scenes/vfx/dust_puff.tscn")
const EARTHQUAKE: PackedScene = preload("res://scenes/vfx/earthquake.tscn")
## Altura (u) do golpe e do impacto: peito do heroi.
const STRIKE_HEIGHT: float = 1.0
## Espessura da Muralha (u) sobre a caixa do ShieldBlocker (que e fina, 0,4 u).
const SHIELD_DEPTH: float = 0.9

## Duracao da varredura do rastro (spec F41: 0,25 s).
@export var swing_seconds: float = 0.25
@export var shield_fade_seconds: float = 0.15

var _half_arc: float = 0.0
## Idade da varredura; < 0 = parada.
var _swing_age: float = -1.0
var _shield_alpha: float = 0.0

@onready var _swing: Node3D = $Swing
@onready var _swing_tip: Node3D = $Swing/Tip
@onready var _trail: TrailRibbon = $Trail
@onready var _speed_lines: GPUParticles3D = $SpeedLines
@onready var _shield: MeshInstance3D = $Shield


func impact(slot: HitLedger.Slot, at: Vector3) -> void:
	if slot == HitLedger.Slot.BASIC or slot == HitLedger.Slot.Q:
		pool.spawn(SPARKS, Transform3D(Basis.IDENTITY, at + Vector3.UP * STRIKE_HEIGHT))


func _bound() -> void:
	var basic := hero.hero_data.basic_attack
	_half_arc = deg_to_rad(basic.arc_degrees / 2.0)
	_swing.position = Vector3.UP * STRIKE_HEIGHT
	_swing_tip.position = Vector3.FORWARD * basic.attack_range
	_trail.target = _swing_tip
	_trail.lifetime = swing_seconds
	var shape := hero.get_node("ShieldBlocker/Shape") as CollisionShape3D
	var size := (shape.shape as BoxShape3D).size
	_shield.position = shape.position
	_shield.scale = Vector3(size.x, size.y, SHIELD_DEPTH)


func _refresh(shown: bool, delta: float) -> void:
	var dashing := hero.dash_ticks > 0
	_speed_lines.emitting = shown and dashing
	if _ended(&"dash_end", dashing):
		pool.spawn(DUST, hero.global_transform)
	if _started(&"basic", hero.basic_cooldown):
		_trail.clear()
		_swing_age = 0.0
	if _started(&"r", hero.r_cooldown):
		var at := Transform3D(Basis.IDENTITY, hero.global_position)
		pool.spawn(EARTHQUAKE, at, hero.hero_data.skill_r.radius)
	_swing_step(delta)
	var shield_on := shown and hero.shield_ticks > 0
	_shield_alpha = move_toward(_shield_alpha, float(shield_on), delta / shield_fade_seconds)
	_shield.visible = _shield_alpha > 0.0
	_shield.transparency = 1.0 - _shield_alpha


## Gira a ponta do golpe da direita para a esquerda pelo arco do basico; o rastro a segue.
func _swing_step(delta: float) -> void:
	if _swing_age < 0.0:
		_trail.emitting = false
		return
	var t := minf(_swing_age / swing_seconds, 1.0)
	_swing.rotation.y = lerpf(-_half_arc, _half_arc, t)
	_trail.emitting = t < 1.0
	_swing_age = -1.0 if t >= 1.0 else _swing_age + delta
