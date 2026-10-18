class_name OccultistVfx
extends HeroVfx
## Ocultista (F77, SPEC-077 §VFX), so cliente: orbe sombria com fiapos e rastro roxo no Projetil
## Sombrio, aglomerado de bolhas e rastro verde-doente na Praga (o corpo de cada projetil do pool
## troca por Arrow.kind; os corpos nascem aqui, a cena do heroi nao os traz), clarao na ponta do
## cajado a cada disparo, estouro no impacto confirmado (roxo no basico e no pulso do Circulo, verde
## na Praga). O Circulo Profano nao sai do estado do Ocultista (ele some de quem esta fora da
## visao): chega pelo ImpactRelay (zone), como o Pantano. As marcas de Maldicao e a nuvem da Praga
## sobre o alvo sao do CurseMarks, que le o estado do alvo. Raios e tempos de occultist.tres.

const SHADOW_BURST: PackedScene = preload("res://scenes/vfx/shadow_burst.tscn")
const PLAGUE_BURST: PackedScene = preload("res://scenes/vfx/plague_burst.tscn")
const CIRCLE: PackedScene = preload("res://scenes/vfx/profane_circle.tscn")
## Altura (u) do impacto: peito do alvo.
const STRIKE_HEIGHT: float = 1.0
## Ponta do cajado (na mao direita), no espaco do heroi (u).
const MUZZLE: Vector3 = Vector3(-0.35, 1.7, -0.7)
## Escala do clarao do disparo e do estouro do pulso do Circulo.
const MUZZLE_FLASH: float = 0.6
const PULSE_BURST: float = 0.7

var _arrows: Array[Arrow] = []
var _shadow_bodies: Array[Node3D] = []
var _plague_bodies: Array[Node3D] = []
var _shadow_trails: Array[TrailRibbon] = []
var _plague_trails: Array[TrailRibbon] = []

@onready var _shadow_trail: TrailRibbon = $ShadowTrail
@onready var _plague_trail: TrailRibbon = $PlagueTrail
@onready var _shadow_template: Node3D = $ShadowBody
@onready var _plague_template: Node3D = $PlagueBody


## Acerto confirmado pelo servidor: estouro roxo (basico, pulso do Circulo) ou verde (Praga).
func impact(slot: HitLedger.Slot, at: Vector3) -> void:
	var chest := Transform3D(Basis.IDENTITY, at + Vector3.UP * STRIKE_HEIGHT)
	match slot:
		HitLedger.Slot.BASIC:
			pool.spawn(SHADOW_BURST, chest, 1.0)
		HitLedger.Slot.Q:
			pool.spawn(PLAGUE_BURST, chest, 1.0)
		HitLedger.Slot.E:
			pool.spawn(SHADOW_BURST, chest, PULSE_BURST)


## Circulo aberto em [param center] no [param tick] (ImpactRelay): mostra so o que falta dele.
func zone(_kind: int, center: Vector3, tick: int) -> void:
	var elapsed := float(NetworkTime.tick - tick) / NetworkTime.tickrate
	var e := hero.hero_data.skill_e
	var total := SkillData.at_rank(e.duration, maxi(hero.ranks.y, 1))
	if elapsed >= total:
		return
	var circle := pool.spawn(CIRCLE, Transform3D(Basis.IDENTITY, center), e.radius)
	(circle as ProfaneCircleVfx).last(total - elapsed, e.pulse_interval)


func _bound() -> void:
	for node: Node in hero.get_node("Arrows").get_children():
		var arrow := node as Arrow
		for child: Node in arrow.get_children():  # corpo provisorio da cena do heroi, se houver
			if child is MeshInstance3D:
				(child as MeshInstance3D).visible = false
		var shadow_trail := _shadow_trail
		var plague_trail := _plague_trail
		if not _arrows.is_empty():
			shadow_trail = _shadow_trail.duplicate() as TrailRibbon
			plague_trail = _plague_trail.duplicate() as TrailRibbon
			add_child(shadow_trail)
			add_child(plague_trail)
		for trail: TrailRibbon in [shadow_trail, plague_trail]:
			trail.target = arrow
			arrow.shown_launched.connect(trail.clear)
		_shadow_trails.append(shadow_trail)
		_plague_trails.append(plague_trail)
		_shadow_bodies.append(_attach_body(_shadow_template, arrow))
		_plague_bodies.append(_attach_body(_plague_template, arrow))
		_arrows.append(arrow)
	_shadow_template.queue_free()  # os modelos so serviam ao warm-up e de molde dos corpos
	_plague_template.queue_free()


func _refresh(shown: bool, _delta: float) -> void:
	for i: int in _arrows.size():
		var arrow := _arrows[i]
		var shadowing := arrow.kind == Arrow.Kind.SHADOW
		var plaguing := arrow.kind == Arrow.Kind.PLAGUE
		_shadow_bodies[i].visible = shadowing
		_plague_bodies[i].visible = plaguing
		_shadow_trails[i].emitting = shown and arrow.visible and shadowing
		_plague_trails[i].emitting = shown and arrow.visible and plaguing
	var muzzle := hero.global_transform * Transform3D(Basis.IDENTITY, MUZZLE)
	if _started(&"basic", hero.basic_cooldown):
		pool.spawn(SHADOW_BURST, muzzle, MUZZLE_FLASH)
	if _started(&"q", hero.q_cooldown):
		pool.spawn(PLAGUE_BURST, muzzle, MUZZLE_FLASH)


## Copia o molde para dentro do projetil (ele o carrega: top_level, anda com a flecha).
static func _attach_body(template: Node3D, arrow: Arrow) -> Node3D:
	var body := template.duplicate() as Node3D
	body.visible = false
	arrow.add_child(body)
	for node: Node in body.find_children("*", "MeshInstance3D", true, false):
		(node as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return body
