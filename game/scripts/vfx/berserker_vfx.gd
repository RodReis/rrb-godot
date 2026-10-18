class_name BerserkerVfx
extends HeroVfx
## Berserker (F75, SPEC-075 regra 5), so cliente: rastro do machado varrendo o arco do basico, para
## um lado ou para o outro conforme a mao (Berserker.swing_left); faiscas no impacto confirmado;
## machado do Q dando cambalhotas com rastro; onda do Grito de Guerra; brilho do Frenesi que cresce
## com o f (brasas e luz vermelhas, Berserker.frenzy); e, no Ragnarok, explosao no uso e aura de
## fogo enquanto dura (Berserker.is_raging). Arcos e alcances de berserker.tres.

const SPARKS: PackedScene = preload("res://scenes/vfx/sparks.tscn")
const WAR_CRY: PackedScene = preload("res://scenes/vfx/war_cry.tscn")
const RAGE_BURST: PackedScene = preload("res://scenes/vfx/ragnarok_burst.tscn")
## Altura (u) do golpe e do impacto: peito do heroi.
const STRIKE_HEIGHT: float = 1.2

## Duracao da varredura do rastro (como a do Barbaro).
@export var swing_seconds: float = 0.22
## Voltas por segundo do machado no ar.
@export var axe_spin_turns: float = 3.0
## Energia da luz do Frenesi com f = 1 e do Ragnarok.
@export var frenzy_light_energy: float = 2.2
@export var rage_light_energy: float = 3.5

var _berserker: Berserker
var _half_arc: float = 0.0
var _swing_from: float = 0.0
## Idade da varredura; < 0 = parada.
var _swing_age: float = -1.0
var _arrows: Array[Arrow] = []
var _axe_trails: Array[TrailRibbon] = []

@onready var _swing: Node3D = $Swing
@onready var _swing_tip: Node3D = $Swing/Tip
@onready var _trail: TrailRibbon = $Trail
@onready var _axe_trail: TrailRibbon = $AxeTrail
@onready var _embers: GPUParticles3D = $FrenzyEmbers
@onready var _frenzy_light: OmniLight3D = $FrenzyLight
@onready var _aura: GPUParticles3D = $RageAura


func impact(_slot: HitLedger.Slot, at: Vector3) -> void:
	pool.spawn(SPARKS, Transform3D(Basis.IDENTITY, at + Vector3.UP * STRIKE_HEIGHT))


func _bound() -> void:
	_berserker = hero as Berserker
	_swing.position = Vector3.UP * STRIKE_HEIGHT
	_trail.target = _swing_tip
	_trail.lifetime = swing_seconds
	for node: Node in hero.get_node("Arrows").get_children():
		var arrow := node as Arrow
		var trail := _axe_trail
		if not _arrows.is_empty():
			trail = _axe_trail.duplicate() as TrailRibbon
			add_child(trail)
		trail.target = arrow
		arrow.shown_launched.connect(trail.clear)
		_axe_trails.append(trail)
		_arrows.append(arrow)


func _refresh(shown: bool, delta: float) -> void:
	for i: int in _arrows.size():
		var arrow := _arrows[i]
		_axe_trails[i].emitting = shown and arrow.visible
		if arrow.visible:
			(arrow.get_node("Axe") as Node3D).rotate_x(-TAU * axe_spin_turns * delta)
	var f := _berserker.frenzy() if shown else 0.0
	_embers.emitting = f > 0.0
	_embers.amount_ratio = maxf(f, 0.05)
	var raging := shown and _berserker.is_raging()
	_aura.emitting = raging
	_frenzy_light.visible = f > 0.0
	_frenzy_light.light_energy = rage_light_energy if raging else frenzy_light_energy * f
	var feet := Transform3D(Basis.IDENTITY, hero.global_position)
	if _started(&"e", hero.e_cooldown):
		pool.spawn(WAR_CRY, feet)
	if _started(&"r", hero.r_cooldown):
		pool.spawn(RAGE_BURST, feet)
	if _started(&"basic", hero.basic_cooldown):
		_start_swing(hero.hero_data.basic_attack, _berserker.swing_left)
	_swing_step(delta)


## A mao direita varre da direita para a esquerda; a esquerda, ao contrario.
func _start_swing(skill: SkillData, left_hand: bool) -> void:
	_half_arc = deg_to_rad(skill.arc_degrees / 2.0)
	_swing_from = _half_arc if left_hand else -_half_arc
	_swing_tip.position = Vector3.FORWARD * skill.attack_range
	_trail.clear()
	_swing_age = 0.0


func _swing_step(delta: float) -> void:
	if _swing_age < 0.0:
		_trail.emitting = false
		return
	var t := minf(_swing_age / swing_seconds, 1.0)
	_swing.rotation.y = lerpf(_swing_from, -_swing_from, t)
	_trail.emitting = t < 1.0
	_swing_age = -1.0 if t >= 1.0 else _swing_age + delta
