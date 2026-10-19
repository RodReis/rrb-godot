class_name PaladinVfx
extends HeroVfx
## Paladino Radiante (F76, SPEC-076 regra 4), so cliente: rastro dourado da Maca varrendo o arco do
## basico e faiscas no impacto; Golpe Consagrado (sigilo da faixa a frente no chao, motes e clarao,
## holy_sigil.glb); Retribuicao (aro de espinhos no alcance dela girando no chao e motes subindo
## enquanto dura, retribution_ring.glb; clarao dourado em quem toma o dano devolvido); Bencao
## Inviolavel (coluna de luz no uso; aureola sobre a cabeca, brilho e luz enquanto dura,
## blessing_halo.glb). Arco, alcances e duracoes de paladin.tres; o estado vem do Paladin.

const SPARKS: PackedScene = preload("res://scenes/vfx/sparks.tscn")
const STRIKE: PackedScene = preload("res://scenes/vfx/consecrated_strike.tscn")
const REFLECT: PackedScene = preload("res://scenes/vfx/retribution_flash.tscn")
const BLESSING: PackedScene = preload("res://scenes/vfx/blessing_burst.tscn")
## Altura (u) do golpe e do impacto: peito do heroi.
const STRIKE_HEIGHT: float = 1.0
## Voltas por segundo do aro da Retribuicao e da aureola.
const RING_SPIN: float = 0.1
const HALO_SPIN: float = 0.25

## Duracao da varredura do rastro (a do Cavaleiro).
@export var swing_seconds: float = 0.25
@export var ring_fade_seconds: float = 0.2

var _paladin: Paladin
var _half_arc: float = 0.0
## Idade da varredura; < 0 = parada.
var _swing_age: float = -1.0
var _ring_alpha: float = 0.0
var _ring_meshes: Array[MeshInstance3D] = []

@onready var _swing: Node3D = $Swing
@onready var _swing_tip: Node3D = $Swing/Tip
@onready var _trail: TrailRibbon = $Trail
@onready var _ring: Node3D = $Ring
@onready var _ring_motes: GPUParticles3D = $RingMotes
@onready var _halo: Node3D = $Halo
@onready var _bless_glow: GPUParticles3D = $BlessGlow
@onready var _bless_light: OmniLight3D = $BlessLight


## Basico e Q: faiscas; E (dano devolvido pela Retribuicao): clarao dourado em quem bateu.
func impact(slot: HitLedger.Slot, at: Vector3) -> void:
	var where := Transform3D(Basis.IDENTITY, at + Vector3.UP * STRIKE_HEIGHT)
	if slot == HitLedger.Slot.E:
		pool.spawn(REFLECT, where)
	elif slot == HitLedger.Slot.BASIC or slot == HitLedger.Slot.Q:
		pool.spawn(SPARKS, where)


func _bound() -> void:
	_paladin = hero as Paladin
	var basic := hero.hero_data.basic_attack
	_half_arc = deg_to_rad(basic.arc_degrees / 2.0)
	_swing.position = Vector3.UP * STRIKE_HEIGHT
	_swing_tip.position = Vector3.FORWARD * basic.attack_range
	_trail.target = _swing_tip
	_trail.lifetime = swing_seconds
	var reach := hero.hero_data.skill_e.attack_range
	_ring.scale = Vector3(reach, 1.0, reach)
	(_ring_motes.process_material as ParticleProcessMaterial).emission_ring_radius = reach
	for node: Node in _ring.find_children("*", "MeshInstance3D", true, false):
		_ring_meshes.append(node as MeshInstance3D)


func _refresh(shown: bool, delta: float) -> void:
	if _started(&"basic", hero.basic_cooldown):
		_trail.clear()
		_swing_age = 0.0
	if _started(&"q", hero.q_cooldown):
		pool.spawn(STRIKE, hero.global_transform)
	if _started(&"r", hero.r_cooldown):
		pool.spawn(BLESSING, Transform3D(Basis.IDENTITY, hero.global_position))
	_swing_step(delta)
	var retributing := shown and _paladin.is_retributing()
	_ring_alpha = move_toward(_ring_alpha, float(retributing), delta / ring_fade_seconds)
	_ring.visible = _ring_alpha > 0.0
	for mesh: MeshInstance3D in _ring_meshes:
		mesh.transparency = 1.0 - _ring_alpha
	_ring_motes.emitting = retributing
	if _ring.visible:
		_ring.rotate_y(TAU * RING_SPIN * delta)
	var blessed := shown and _paladin.is_blessed()
	_halo.visible = blessed
	_bless_glow.emitting = blessed
	_bless_light.visible = blessed
	if blessed:
		_halo.rotate_y(TAU * HALO_SPIN * delta)


## Gira a ponta do golpe da direita para a esquerda pelo arco do basico; o rastro a segue.
func _swing_step(delta: float) -> void:
	if _swing_age < 0.0:
		_trail.emitting = false
		return
	var t := minf(_swing_age / swing_seconds, 1.0)
	_swing.rotation.y = lerpf(-_half_arc, _half_arc, t)
	_trail.emitting = t < 1.0
	_swing_age = -1.0 if t >= 1.0 else _swing_age + delta
