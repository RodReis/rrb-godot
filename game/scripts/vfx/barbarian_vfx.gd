class_name BarbarianVfx
extends HeroVfx
## Barbaro (F53): rastro do machado varrendo o arco do basico e o da Execucao (fita de
## swing_seconds), faiscas no impacto confirmado, linhas de velocidade no Salto e rachadura com
## onda de choque na aterrissagem (raio do Salto), e o Rodopio: a ponta do rastro da a volta no
## raio do E enquanto o heroi gira. Arcos, alcances e raios vem de barbarian.tres.

const SPARKS: PackedScene = preload("res://scenes/vfx/sparks.tscn")
const EARTHQUAKE: PackedScene = preload("res://scenes/vfx/earthquake.tscn")
## Altura (u) do golpe e do impacto: peito do heroi.
const STRIKE_HEIGHT: float = 1.0

## Duracao da varredura do rastro (como a do Cavaleiro, F41).
@export var swing_seconds: float = 0.25
## Uma volta do rastro por laco da animacao do giro (2H_Melee_Attack_Spinning).
@export var spin_turn_seconds: float = 0.667

var _half_arc: float = 0.0
## Idade da varredura; < 0 = parada.
var _swing_age: float = -1.0

@onready var _swing: Node3D = $Swing
@onready var _swing_tip: Node3D = $Swing/Tip
@onready var _trail: TrailRibbon = $Trail
@onready var _speed_lines: GPUParticles3D = $SpeedLines


func impact(_slot: HitLedger.Slot, at: Vector3) -> void:
	pool.spawn(SPARKS, Transform3D(Basis.IDENTITY, at + Vector3.UP * STRIKE_HEIGHT))


func _bound() -> void:
	_swing.position = Vector3.UP * STRIKE_HEIGHT
	_trail.target = _swing_tip
	_trail.lifetime = swing_seconds


func _refresh(shown: bool, delta: float) -> void:
	var data := hero.hero_data
	var leaping := hero.dash_ticks > 0
	_speed_lines.emitting = shown and leaping
	if _ended(&"dash_end", leaping):
		var at := Transform3D(Basis.IDENTITY, hero.global_position)
		pool.spawn(EARTHQUAKE, at, data.skill_q.radius)
	if _started(&"basic", hero.basic_cooldown):
		_start_swing(data.basic_attack)
	if _started(&"r", hero.r_cooldown):
		_start_swing(data.skill_r)
	if shown and hero.is_channeling():
		_spin(delta, data.skill_e.radius)
	else:
		_swing_step(delta)


func _start_swing(skill: SkillData) -> void:
	_half_arc = deg_to_rad(skill.arc_degrees / 2.0)
	_swing_tip.position = Vector3.FORWARD * skill.attack_range
	_trail.clear()
	_swing_age = 0.0


## Gira a ponta do golpe da direita para a esquerda pelo arco; o rastro a segue.
func _swing_step(delta: float) -> void:
	if _swing_age < 0.0:
		_trail.emitting = false
		return
	var t := minf(_swing_age / swing_seconds, 1.0)
	_swing.rotation.y = lerpf(-_half_arc, _half_arc, t)
	_trail.emitting = t < 1.0
	_swing_age = -1.0 if t >= 1.0 else _swing_age + delta


func _spin(delta: float, radius: float) -> void:
	_swing_age = -1.0
	_swing_tip.position = Vector3.FORWARD * radius
	_swing.rotation.y = wrapf(_swing.rotation.y + TAU * delta / spin_turn_seconds, -PI, PI)
	_trail.emitting = true
