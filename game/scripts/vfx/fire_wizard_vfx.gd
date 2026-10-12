class_name FireWizardVfx
extends HeroVfx
## Bruxo de Fogo (F54): rastro de fogo em cada bola do pool (a bola mostrada ja anda desacoplada da
## rede, Arrow); explosao onde a Explosao de Chamas para (borda EXPLODE -> parada, lida do estado:
## sai mesmo sem alvo); brasas no impacto confirmado da Bola de Fogo; Anel de Fogo no raio do E; o
## Meteoro cai do alto sobre a marcacao (MeteorArea, na cena do heroi) durante o atraso e explode
## com cratera no raio do R. Raios e atraso de fire_wizard.tres.

const BURST: PackedScene = preload("res://scenes/vfx/fire_burst.tscn")
const RING: PackedScene = preload("res://scenes/vfx/fire_ring.tscn")
const SPARKS: PackedScene = preload("res://scenes/vfx/sparks.tscn")
const EARTHQUAKE: PackedScene = preload("res://scenes/vfx/earthquake.tscn")
## Altura (u) do impacto: peito do alvo.
const STRIKE_HEIGHT: float = 1.0
## De onde o Meteoro parte, relativo ao centro da marcacao (u): alto e na diagonal.
const METEOR_DROP: Vector3 = Vector3(-4.0, 14.0, 3.0)

var _wizard: FireWizard
var _arrows: Array[Arrow] = []
var _trails: Array[TrailRibbon] = []
## Chave da borda da explosao por slot do pool (sem montar texto por quadro).
var _blast_keys: Array[StringName] = []

@onready var _arrow_trail: TrailRibbon = $ArrowTrail
@onready var _meteor: Node3D = $Meteor
@onready var _meteor_flames: GPUParticles3D = $Meteor/Flames


func impact(slot: HitLedger.Slot, at: Vector3) -> void:
	if slot == HitLedger.Slot.BASIC:
		pool.spawn(SPARKS, Transform3D(Basis.IDENTITY, at + Vector3.UP * STRIKE_HEIGHT))


func _bound() -> void:
	_wizard = hero as FireWizard
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
		_blast_keys.append(StringName("blast_%s" % arrow.name))


func _refresh(shown: bool, _delta: float) -> void:
	var data := hero.hero_data
	for i: int in _arrows.size():
		var arrow := _arrows[i]
		_trails[i].emitting = shown and arrow.visible
		# Slot reaproveitado por outro disparo no mesmo tick nao explode no ponto novo.
		if _ended(_blast_keys[i], arrow.kind == Arrow.Kind.EXPLODE) and not arrow.is_active():
			pool.spawn(BURST, Transform3D(Basis.IDENTITY, arrow.origin), data.skill_q.radius)
	if _started(&"e", hero.e_cooldown):
		pool.spawn(RING, Transform3D(Basis.IDENTITY, hero.global_position), data.skill_e.radius)
	_meteor_step(shown)


## Queda em linha reta do alto ate o centro, no atraso do R; ao chegar, explosao + cratera.
func _meteor_step(shown: bool) -> void:
	var r := hero.hero_data.skill_r
	var falling := _wizard.meteor_ticks > 0
	if _ended(&"meteor", falling):
		var at := Transform3D(Basis.IDENTITY, _wizard.meteor_center)
		pool.spawn(BURST, at, r.radius)
		pool.spawn(EARTHQUAKE, at, r.radius)
	var visible_now := shown and falling
	_meteor.visible = visible_now
	_meteor_flames.emitting = visible_now
	if not visible_now:
		return
	var rate := NetworkTime.tickrate
	var total := SkillRules.seconds_to_ticks(SkillData.at_rank(r.duration, hero.ranks.z), rate)
	var left := clampf((_wizard.meteor_ticks - NetworkTime.tick_factor) / total, 0.0, 1.0)
	_meteor.global_position = _wizard.meteor_center + METEOR_DROP * left
