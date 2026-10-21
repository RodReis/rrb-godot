class_name CarrascoVfx
extends HeroVfx
## Carrasco (F98, SPEC-098 §4), so cliente: espinhos rompem do chao pelo cone a cada golpe dos
## Espinhos (Carrasco.q_casts) e o feixe de espinhos com rastro vermelho-escuro voa no recast
## (Arrow.Kind.THORNS); as Correntes do Julgamento voam como um grilhao puxando uma corrente de
## elos desde o peito do Carrasco (Arrow.Kind.CHAINS) e prendem o alvo em aneis de elos pela raiz;
## o raio de luz chega pelo ImpactRelay (zone, visivel aos dois mesmo com o Carrasco escondido).
## Penitencia: aro de espinhos vermelho no chao e brasas subindo enquanto canaliza
## (is_channeling); a explosao (Carrasco.blasts) solta a onda vermelha no raio e, se a Dor de
## antes era >= root_min_pain, raizes em quem tomou o golpe. A Dor (0..6) aparece como contas de
## sangue girando na cintura, para todos que o veem. Raios, tempos e limiares de carrasco.tres; o
## estado vem do Carrasco.

const THORN_CONE: PackedScene = preload("res://scenes/vfx/thorns_cone.tscn")
const BLOOD_BURST: PackedScene = preload("res://scenes/vfx/blood_burst.tscn")
const PENANCE_BLAST: PackedScene = preload("res://scenes/vfx/penance_blast.tscn")
const ROOTS: PackedScene = preload("res://scenes/vfx/thorn_roots.tscn")
const SHACKLES: PackedScene = preload("res://scenes/vfx/shackles.tscn")
const LIGHT_PILLAR: PackedScene = preload("res://scenes/vfx/light_pillar.tscn")
const LINK: PackedScene = preload("res://shared/assets/rrb/vfx/chain_link.glb")
## Altura (u) do impacto: peito do alvo.
const STRIKE_HEIGHT: float = 1.0
## Mao que arremessa e peito de onde sai a corrente, no espaco do heroi (u; frente = -Z).
const HAND: Vector3 = Vector3(-0.35, 1.45, -0.45)
const CHEST: Vector3 = Vector3(0.0, 1.25, -0.3)
## Escala do estouro no alvo e do clarao na mao.
const HIT_BURST: float = 1.0
const HAND_FLASH: float = 0.6
## Elos da corrente: passo entre eles (u) e quantos cabem no maximo (alcance de 6 u).
const LINK_STEP: float = 0.2
const MAX_LINKS: int = 36
## Contas da Dor: raio, altura e voltas por segundo; pulsar das contas.
const PIP_RADIUS: float = 0.78
const PIP_HEIGHT: float = 1.15
const PIP_SPIN: float = 0.35
const PIP_PULSE: float = 3.0
## Voltas por segundo do aro da Penitencia.
const AURA_SPIN: float = 0.12

## Material do aro de espinhos da Penitencia (o retribution_ring.glb vem dourado, do Paladino).
@export var aura_material: Material

var _carrasco: Carrasco
var _arrows: Array[Arrow] = []
var _thorn_bodies: Array[Node3D] = []
var _shackle_bodies: Array[Node3D] = []
var _thorn_trails: Array[TrailRibbon] = []
## Dor no quadro anterior (a explosao consome a Dor: a raiz depende da de antes).
var _last_pain: int = 0
## A ultima explosao prendeu (Dor >= root_min_pain): o impacto do E confirmado vira raizes.
var _blast_rooted: bool = false
var _pip_angle: float = 0.0
var _pip_age: float = 0.0
var _link_basis: Basis = Basis.IDENTITY

@onready var _thorn_trail: TrailRibbon = $ThornTrail
@onready var _thorn_template: Node3D = $ThornBody
@onready var _shackle_template: Node3D = $ShackleBody
@onready var _chain: MultiMeshInstance3D = $Chain
@onready var _aura: Node3D = $Aura
@onready var _embers: GPUParticles3D = $Aura/Embers
@onready var _pips: Node3D = $Pips


## Acerto confirmado pelo servidor: Q (golpe ou recast) = estouro de sangue; E = raizes se a
## explosao prendeu, senao estouro; R = grilhoes no alvo pela raiz das Correntes.
func impact(slot: HitLedger.Slot, at: Vector3) -> void:
	var chest := Transform3D(Basis.IDENTITY, at + Vector3.UP * STRIKE_HEIGHT)
	match slot:
		HitLedger.Slot.Q:
			pool.spawn(BLOOD_BURST, chest, HIT_BURST)
		HitLedger.Slot.E:
			if _blast_rooted:
				var roots := pool.spawn(ROOTS, Transform3D(Basis.IDENTITY, at), 1.0)
				(roots as RootsVfx).last(hero.hero_data.skill_e.root_duration)
			else:
				pool.spawn(BLOOD_BURST, chest, HIT_BURST)
		HitLedger.Slot.R:
			var shackles := pool.spawn(SHACKLES, Transform3D(Basis.IDENTITY, at))
			(shackles as ShacklesVfx).last(_root_seconds())


## Raio de luz aberto em [param center] no [param tick] (ImpactRelay): mostra so o que falta dele.
func zone(_kind: int, center: Vector3, tick: int) -> void:
	var elapsed := float(NetworkTime.tick - tick) / NetworkTime.tickrate
	var total := _root_seconds()
	if elapsed >= total:
		return
	var pillar := pool.spawn(
		LIGHT_PILLAR, Transform3D(Basis.IDENTITY, center), hero.hero_data.skill_r.light_radius
	)
	(pillar as LightPillarVfx).last(total - elapsed)


func _bound() -> void:
	_carrasco = hero as Carrasco
	_last_pain = _carrasco.pain
	for node: Node in hero.get_node("Arrows").get_children():
		var arrow := node as Arrow
		for child: Node in arrow.get_children():  # corpo provisorio da cena do heroi, se houver
			if child is MeshInstance3D:
				(child as MeshInstance3D).visible = false
		var trail := _thorn_trail
		if not _arrows.is_empty():
			trail = _thorn_trail.duplicate() as TrailRibbon
			add_child(trail)
		trail.target = arrow
		arrow.shown_launched.connect(trail.clear)
		_thorn_trails.append(trail)
		_thorn_bodies.append(OccultistVfx._attach_body(_thorn_template, arrow))
		_shackle_bodies.append(OccultistVfx._attach_body(_shackle_template, arrow))
		_arrows.append(arrow)
	_thorn_template.queue_free()  # os modelos so serviam ao warm-up e de molde dos corpos
	_shackle_template.queue_free()
	for mesh: Node in _aura.find_children("*", "MeshInstance3D", true, false):
		(mesh as MeshInstance3D).material_override = aura_material
	_chain.top_level = true
	_chain.global_transform = Transform3D.IDENTITY
	var link := LINK.instantiate()
	_chain.multimesh.mesh = (
		(link.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D).mesh
	)
	link.free()
	_chain.multimesh.instance_count = MAX_LINKS
	_chain.multimesh.visible_instance_count = 0


func _refresh(shown: bool, delta: float) -> void:
	_projectiles(shown)
	if _started(&"q_casts", _carrasco.q_casts):
		var cone := pool.spawn(
			THORN_CONE, hero.global_transform, hero.hero_data.skill_q.attack_range
		)
		(cone as ThornsConeVfx).set_arc(hero.hero_data.skill_q.arc_degrees)
	if _started(&"recasts", _carrasco.recasts):
		pool.spawn(
			BLOOD_BURST, hero.global_transform * Transform3D(Basis.IDENTITY, HAND), HAND_FLASH
		)
	if _started(&"blasts", _carrasco.blasts):
		var e := hero.hero_data.skill_e
		_blast_rooted = CarrascoRules.explosion_roots(_last_pain, e.root_min_pain)
		pool.spawn(PENANCE_BLAST, Transform3D(Basis.IDENTITY, hero.global_position), e.radius)
	_last_pain = _carrasco.pain
	var channeling := shown and _carrasco.is_channeling()
	_aura.visible = channeling
	_embers.emitting = channeling
	if channeling:
		_aura.rotate_y(TAU * AURA_SPIN * delta)
	_pain_pips(shown, delta)


## Corpo e rastro de cada projetil pelo tipo; a corrente liga o peito ao grilhao em voo.
func _projectiles(shown: bool) -> void:
	var chained: Arrow = null
	for i: int in _arrows.size():
		var arrow := _arrows[i]
		var thorns := arrow.kind == Arrow.Kind.THORNS
		var chains := arrow.kind == Arrow.Kind.CHAINS
		_thorn_bodies[i].visible = thorns
		_shackle_bodies[i].visible = chains
		_thorn_trails[i].emitting = shown and arrow.visible and thorns
		if chains and arrow.visible and chained == null:
			chained = arrow
	_chain_to(chained if shown else null)


## Elos enfileirados do peito do Carrasco ate o grilhao (null = sem corrente).
func _chain_to(arrow: Arrow) -> void:
	var multimesh := _chain.multimesh
	if arrow == null:
		multimesh.visible_instance_count = 0
		return
	var from := hero.global_transform * CHEST
	var to := arrow.global_position
	var span := to - from
	var length := span.length()
	if length < LINK_STEP:
		multimesh.visible_instance_count = 0
		return
	var count := mini(int(length / LINK_STEP), MAX_LINKS)
	var ahead := span / length
	_link_basis = Basis.looking_at(ahead, Vector3.UP)
	var twisted := _link_basis * Basis(Vector3.FORWARD, PI / 2.0)
	for i: int in count:
		var at := from + ahead * (LINK_STEP * (i + 0.5))
		multimesh.set_instance_transform(i, Transform3D(twisted if i % 2 else _link_basis, at))
	multimesh.visible_instance_count = count


## Uma conta de sangue por ponto de Dor, girando na cintura e pulsando; some sem Dor.
func _pain_pips(shown: bool, delta: float) -> void:
	var pain := _carrasco.pain if shown else 0
	_pips.visible = pain > 0
	if pain == 0:
		return
	_pip_angle = fmod(_pip_angle + TAU * PIP_SPIN * delta, TAU)
	_pip_age += delta
	var pulse := 1.0 + 0.15 * sin(TAU * PIP_PULSE * _pip_age)
	for i: int in _pips.get_child_count():
		var pip := _pips.get_child(i) as Node3D
		pip.visible = i < pain
		var angle := _pip_angle + TAU * i / pain  # espacadas igual pelas que aparecem
		pip.position = Vector3(cos(angle) * PIP_RADIUS, PIP_HEIGHT, sin(angle) * PIP_RADIUS)
		pip.scale = Vector3.ONE * pulse


## Raiz e luz das Correntes no rank atual (no minimo o 1).
func _root_seconds() -> float:
	return SkillData.at_rank(hero.hero_data.skill_r.duration, maxi(hero.ranks.z, 1))
