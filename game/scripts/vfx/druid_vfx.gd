class_name DruidVfx
extends HeroVfx
## Protetor da Selva (F74, SPEC-074 §VFX), so cliente: rastro verde em cada projetil do pool (seiva
## clara e fina, raiz escura e larga; o corpo do projetil troca por Arrow.kind), clarao de seiva na
## ponta do cajado a cada disparo, respingo no impacto confirmado da seiva, raizes brotando em
## volta do alvo das Raizes Vivas (curtas no chefe, que so toma o dano), estouro de bolha por
## pulso do Pantano. A Pocao Verde e o Pantano nao saem do estado do Protetor (ele some de quem
## esta fora da visao): chegam pelo ImpactRelay (zone), como a fumaca da Ladina. Raios, alcances
## e tempos de druid.tres.

const FLASH: PackedScene = preload("res://scenes/vfx/sap_flash.tscn")
const SPLAT: PackedScene = preload("res://scenes/vfx/sap_splat.tscn")
const ROOTS: PackedScene = preload("res://scenes/vfx/roots_burst.tscn")
const POP: PackedScene = preload("res://scenes/vfx/swamp_pop.tscn")
const POTION: PackedScene = preload("res://scenes/vfx/potion_zone.tscn")
const SWAMP: PackedScene = preload("res://scenes/vfx/swamp_zone.tscn")
## Altura (u) do impacto: peito do alvo.
const STRIKE_HEIGHT: float = 1.0
## Ponta do cajado e mao que arremessa a pocao, no espaco do heroi (u).
const MUZZLE: Vector3 = Vector3(-0.35, 1.7, -0.7)
const HAND: Vector3 = Vector3(-0.3, 1.1, -0.4)
## Escala do clarao da seiva e das raizes.
const BASIC_FLASH: float = 0.8
const ROOT_FLASH: float = 1.3
## Escala das raizes em volta do alvo (a malha tem 1,2 u; o corpo, ~1,8 u).
const ROOTS_SCALE: float = 1.7
## Quanto as raizes duram no chefe (s): ele so toma o dano, entao e um floreio, nao uma prisao.
const BOSS_ROOTS_SECONDS: float = 0.4
## Raio (u) em que o impacto confirmado acha o alvo (a posicao dele no cliente atrasa um pouco).
const TARGET_REACH: float = 1.5

var _druid: Druid
var _arrows: Array[Arrow] = []
var _seed_trails: Array[TrailRibbon] = []
var _root_trails: Array[TrailRibbon] = []

@onready var _seed_trail: TrailRibbon = $SeedTrail
@onready var _root_trail: TrailRibbon = $RootTrail


## Acerto confirmado pelo servidor: respingo (seiva, raiz), raizes (Q) e bolha (pulso do Pantano).
func impact(slot: HitLedger.Slot, at: Vector3) -> void:
	var chest := Transform3D(Basis.IDENTITY, at + Vector3.UP * STRIKE_HEIGHT)
	var feet := Transform3D(Basis.IDENTITY, at)
	match slot:
		HitLedger.Slot.BASIC:
			pool.spawn(SPLAT, chest)
		HitLedger.Slot.Q:
			pool.spawn(SPLAT, chest)
			var seconds := _root_seconds(at)
			var roots := pool.spawn(ROOTS, feet, ROOTS_SCALE) as RootsVfx
			roots.last(seconds)
		HitLedger.Slot.R:
			pool.spawn(POP, feet)


## Zona aberta em [param center] no [param tick] (ImpactRelay): mostra so o que falta dela.
func zone(kind: int, center: Vector3, tick: int) -> void:
	var elapsed := float(NetworkTime.tick - tick) / NetworkTime.tickrate
	if kind == Druid.Zone.POTION:
		var e := hero.hero_data.skill_e
		var total := SkillData.at_rank(e.duration, maxi(hero.ranks.y, 1))
		if elapsed >= total:
			return
		var potion := pool.spawn(POTION, Transform3D(Basis.IDENTITY, center), e.radius)
		var from := hero.global_transform * HAND
		(potion as PotionZoneVfx).last(total - elapsed, e.pulse_interval, from, elapsed)
	else:
		var r := hero.hero_data.skill_r
		var total := SkillData.at_rank(r.duration, maxi(hero.ranks.z, 1))
		if elapsed >= total:
			return
		var swamp := pool.spawn(SWAMP, Transform3D(Basis.IDENTITY, center), r.radius)
		(swamp as SwampZoneVfx).last(total - elapsed, r.pulse_interval)


func _bound() -> void:
	_druid = hero as Druid
	for node: Node in hero.get_node("Arrows").get_children():
		var arrow := node as Arrow
		var seed_trail := _seed_trail
		var root_trail := _root_trail
		if not _arrows.is_empty():
			seed_trail = _seed_trail.duplicate() as TrailRibbon
			root_trail = _root_trail.duplicate() as TrailRibbon
			add_child(seed_trail)
			add_child(root_trail)
		for trail: TrailRibbon in [seed_trail, root_trail]:
			trail.target = arrow
			arrow.shown_launched.connect(trail.clear)
		_seed_trails.append(seed_trail)
		_root_trails.append(root_trail)
		_arrows.append(arrow)


func _refresh(shown: bool, _delta: float) -> void:
	for i: int in _arrows.size():
		var arrow := _arrows[i]
		var seeding := arrow.kind == Arrow.Kind.BASIC
		var rooting := arrow.kind == Arrow.Kind.ROOT
		(arrow.get_node("Seed") as Node3D).visible = seeding
		(arrow.get_node("Root") as Node3D).visible = rooting
		_seed_trails[i].emitting = shown and arrow.visible and seeding
		_root_trails[i].emitting = shown and arrow.visible and rooting
	var muzzle := hero.global_transform * Transform3D(Basis.IDENTITY, MUZZLE)
	if _started(&"basic", hero.basic_cooldown):
		pool.spawn(FLASH, muzzle, BASIC_FLASH)
	if _started(&"q", hero.q_cooldown):
		pool.spawn(FLASH, muzzle, ROOT_FLASH)


## Quanto as raizes duram: o tempo do Q, ou um floreio curto se o alvo mais perto do impacto e o
## chefe (so toma o dano).
func _root_seconds(at: Vector3) -> float:
	var q := hero.hero_data.skill_q
	var nearest: Combatant = null
	var best := TARGET_REACH
	for node: Node in get_tree().get_nodes_in_group(Combatant.TARGETS_GROUP):
		var other := node as Combatant
		var distance := Vector2(other.global_position.x - at.x, other.global_position.z - at.z).length()
		if other != hero and distance <= best:
			nearest = other
			best = distance
	var monster := nearest as Monster
	if monster != null and monster.data.tier == MonsterData.Tier.BOSS:
		return BOSS_ROOTS_SECONDS
	return SkillData.at_rank(q.duration, maxi(hero.ranks.x, 1))
