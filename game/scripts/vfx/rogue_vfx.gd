class_name RogueVfx
extends HeroVfx
## Ladina (F58, SPEC-058 §6): rastro curto verde-claro em cada virote do pool (o virote mostrado ja
## anda desacoplado da rede, Arrow); clarao com lascas na ponta da besta no disparo (maior na
## Rajada); faiscas no impacto confirmado do virote; 3 fantasmas no avanco da Emboscada; corte em X
## no golpe confirmado, com clarao roxo se a Ladina estava oculta (x1,3). A nuvem de fumaca nao
## sai do estado da Ladina (ela some de quem esta fora): chega pelo ImpactRelay (smoke). Raio e
## duracao de rogue.tres.

const FLASH: PackedScene = preload("res://scenes/vfx/bolt_flash.tscn")
const SPARKS: PackedScene = preload("res://scenes/vfx/bolt_sparks.tscn")
const SMOKE: PackedScene = preload("res://scenes/vfx/smoke_cloud.tscn")
const GHOST: PackedScene = preload("res://scenes/vfx/ghost.tscn")
const SLASH: PackedScene = preload("res://scenes/vfx/ambush_slash.tscn")
const AMBUSH_FLASH: PackedScene = preload("res://scenes/vfx/ambush_flash.tscn")
## Altura (u) do impacto: peito do alvo.
const STRIKE_HEIGHT: float = 1.0
## Ponta da besta no espaco do heroi (u): mao direita, a frente, na altura do disparo.
const MUZZLE: Vector3 = Vector3(-0.3, 1.0, -0.7)
## Escala do clarao: disparo e Rajada.
const BASIC_FLASH: float = 1.0
const FAN_FLASH: float = 1.8
## Fantasmas do avanco e o intervalo entre eles (s): 3 copias nos ~0,33 s.
const GHOSTS: int = 3
const GHOST_SECONDS: float = 0.09

var _rogue: Rogue
var _arrows: Array[Arrow] = []
var _trails: Array[TrailRibbon] = []
var _ghosts_left: int = 0
var _ghost_wait: float = 0.0

@onready var _bolt_trail: TrailRibbon = $BoltTrail


func impact(slot: HitLedger.Slot, at: Vector3) -> void:
	var where := Transform3D(Basis.IDENTITY, at + Vector3.UP * STRIKE_HEIGHT)
	if slot == HitLedger.Slot.BASIC or slot == HitLedger.Slot.Q:
		pool.spawn(SPARKS, where)
	elif slot == HitLedger.Slot.R:
		pool.spawn(SLASH, Transform3D(hero.global_basis, where.origin))
		if _rogue.ambush_hidden:
			pool.spawn(AMBUSH_FLASH, where)


## Nuvem lancada em [param center] no [param tick] (ImpactRelay): mostra so o que falta dela.
func smoke(center: Vector3, tick: int) -> void:
	var e := hero.hero_data.skill_e
	var total := SkillData.at_rank(e.duration, maxi(hero.ranks.y, 1))
	var left := total - float(NetworkTime.tick - tick) / NetworkTime.tickrate
	if left <= 0.0:
		return
	var cloud := pool.spawn(SMOKE, Transform3D(Basis.IDENTITY, center), e.radius) as SmokeCloudVfx
	cloud.last(minf(left, total))


func _bound() -> void:
	_rogue = hero as Rogue
	for node: Node in hero.get_node("Arrows").get_children():
		var arrow := node as Arrow
		var trail := _bolt_trail
		if not _trails.is_empty():
			trail = _bolt_trail.duplicate() as TrailRibbon
			add_child(trail)
		_trails.append(trail)
		trail.target = arrow
		arrow.shown_launched.connect(trail.clear)
		_arrows.append(arrow)


func _refresh(shown: bool, delta: float) -> void:
	for i: int in _arrows.size():
		_trails[i].emitting = shown and _arrows[i].visible
	var muzzle := hero.global_transform * Transform3D(Basis.IDENTITY, MUZZLE)
	if _started(&"basic", hero.basic_cooldown):
		pool.spawn(FLASH, muzzle, BASIC_FLASH)
	if _started(&"q", hero.q_cooldown):
		pool.spawn(FLASH, muzzle, FAN_FLASH)
	_ghost_step(shown, delta)


## Fantasmas da Emboscada: o 1o no inicio do avanco, os outros a cada GHOST_SECONDS.
func _ghost_step(shown: bool, delta: float) -> void:
	var dashing := _rogue.ambushing and hero.dash_ticks > 0
	if _started(&"ambush", int(dashing)):
		_ghosts_left = GHOSTS
		_ghost_wait = 0.0
	if not shown or not dashing:
		_ghosts_left = 0
		return
	_ghost_wait -= delta
	if _ghosts_left > 0 and _ghost_wait <= 0.0:
		_ghosts_left -= 1
		_ghost_wait = GHOST_SECONDS
		var ghost := pool.spawn(GHOST, hero.global_transform) as GhostVfx
		ghost.capture(hero.get_node("Model") as Node3D)
