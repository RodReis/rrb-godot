class_name ProjectileHero
extends Hero
## Heroi que atira projeteis do pool Arrow (Arqueira F14, Bruxo de Fogo F54). Os projeteis voam no
## estado de rollback do heroi, entao o cliente preve o proprio disparo e o servidor decide o
## acerto (CONVENTION §4.5). O projetil para no muro, pilar, rocha, portao que barra o heroi e na
## Muralha ativa do inimigo, nao no rio (PI 2026-10-10). Voa na velocidade e no raio do basico (PI
## 2026-10-10). A subclasse decide o que o toque faz (_arrow_struck) e o que acontece onde o voo
## acaba (_arrow_stopped); dano em outro node pelo ledger do alvo (Hero._hit).

## Altura do voo (u): o raio contra muro/pilar corre nessa altura. Geometria, nao balanceamento.
const FLIGHT_HEIGHT: float = 1.0
## Corpos (heroi, monstro) estao na camada WORLD: o raio pula ate este numero deles atras do muro.
const MAX_WALL_PROBES: int = 4
## Folga para dar o projetil como chegado ao alcance (soma de passos em ponto flutuante).
const ARRIVED_EPSILON: float = 0.0001

var _arrows: Array[Arrow] = []
## Inimigos vivos do tick (preenchido pela subclasse antes de _advance_arrows).
var _targets: Array[Combatant] = []
## Reusados a cada tick (sem alocar no _rollback_tick): acertos ordenados e quem foi atingido
## pelo basico e pelo Q neste tick (o resto tem o golpe desfeito).
var _hit_fractions: PackedFloat64Array = PackedFloat64Array()
var _hit_targets: Array[Combatant] = []
var _struck_basic: Array[Combatant] = []
var _struck_q: Array[Combatant] = []
var _wall_query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.new()
var _no_exclusion: Array[RID] = []


func _ready() -> void:
	super()
	for arrow: Arrow in _arrows:
		arrow.speed = hero_data.basic_attack.speed


## Muro, pilar ou portao entre o heroi e [param target] (o bot nao atira na parede).
func shot_blocked(target: Vector3) -> bool:
	var from := global_position + Vector3.UP * FLIGHT_HEIGHT
	var to := Vector3(target.x, from.y, target.z)
	return _wall_fraction(from, to) != CombatRules.NO_HIT


func _extra_state_properties() -> Array[String]:
	var props: Array[String] = []
	_arrows.clear()
	for node: Node in $Arrows.get_children():
		_arrows.append(node as Arrow)
		for prop: String in Arrow.STATE:
			props.append("Arrows/%s:%s" % [node.name, prop])
	return props


## Algum projetil no ar.
func _arrows_flying() -> bool:
	for arrow: Arrow in _arrows:
		if arrow.is_active():
			return true
	return false


## Ocupa um slot livre do pool; cheio, reaproveita o projetil que mais voou.
func _shoot(kind: Arrow.Kind, max_range: float, damage: int) -> void:
	var slot: Arrow = null
	for arrow: Arrow in _arrows:
		if not arrow.is_active():
			slot = arrow
			break
		if slot == null or arrow.traveled > slot.traveled:
			slot = arrow
	var from := global_position + Vector3.UP * FLIGHT_HEIGHT
	slot.launch(kind, from, CombatRules.push_vector(forward(), 1.0), max_range, damage)


## Servidor: alvo heroi que nenhum projetil atingiu neste tick tem o golpe desfeito (ressimulacao
## sem acerto, como o _melee do Cavaleiro).
# ponytail: so roda com projetil no ar; golpe gravado numa simulacao em que ele ja tinha parado
# fica. Raro (input atrasado no servidor) e o servidor segue autoritativo.
func _advance_arrows(tick: int) -> void:
	_struck_basic.clear()
	_struck_q.clear()
	for arrow: Arrow in _arrows:
		if arrow.is_active():
			_advance(arrow, tick)
	if not multiplayer.is_server():
		return
	for other: Combatant in _targets:
		if not _struck_basic.has(other):
			_miss(other, tick, HitLedger.Slot.BASIC)
		if not _struck_q.has(other):
			_miss(other, tick, HitLedger.Slot.Q)


## O projetil tocou [param _other] ([param _at] = ponta no inicio do tick, origem do golpe).
## Subclasse: aplica o efeito; true = o projetil para nesse toque.
func _arrow_struck(_arrow: Arrow, _other: Combatant, _at: Vector3, _tick: int) -> bool:
	return true


## O voo acabou em arrow.origin (toque que parou, bloqueio ou fim do alcance), antes do stop().
func _arrow_stopped(_arrow: Arrow, _tick: int) -> void:
	pass


## Um tick de voo: toca, na ordem do caminho, quem o segmento do tick alcanca antes do bloqueio.
func _advance(arrow: Arrow, tick: int) -> void:
	var basic := hero_data.basic_attack
	var step := RangerRules.flight_step(
		basic.speed, arrow.max_range, arrow.traveled, NetworkTime.tickrate
	)
	var p0 := arrow.origin
	var p1 := p0 + arrow.direction * step
	var block := _block_fraction(p0, p1)
	var reach := 1.0 if block == CombatRules.NO_HIT else block
	_collect_hits(arrow, p0, p1, reach, basic.radius)
	for i: int in _hit_targets.size():
		var other := _hit_targets[i]
		arrow.mark_hit(other.combat_id())
		if _arrow_struck(arrow, other, p0, tick):
			_end_flight(arrow, p0.lerp(p1, _hit_fractions[i]), tick)
			return
	arrow.traveled += step * reach
	arrow.origin = p0.lerp(p1, reach)
	if block != CombatRules.NO_HIT or arrow.max_range - arrow.traveled <= ARRIVED_EPSILON:
		_end_flight(arrow, arrow.origin, tick)


func _end_flight(arrow: Arrow, at: Vector3, tick: int) -> void:
	arrow.origin = at
	_arrow_stopped(arrow, tick)
	arrow.stop()


## Alvos ainda nao atingidos que o segmento toca ate [param reach], do mais perto ao mais longe.
func _collect_hits(arrow: Arrow, p0: Vector3, p1: Vector3, reach: float, radius: float) -> void:
	_hit_fractions.clear()
	_hit_targets.clear()
	for other: Combatant in _targets:
		if arrow.has_hit(other.combat_id()):
			continue
		var t := CombatRules.segment_circle_fraction(
			p0, p1, other.global_position, radius + other.body_radius()
		)
		if t == CombatRules.NO_HIT or t > reach:
			continue
		var at := _hit_fractions.bsearch(t)
		_hit_fractions.insert(at, t)
		_hit_targets.insert(at, other)


## Menor fracao do segmento em que muro/pilar/portao ou a Muralha inimiga barram o projetil.
func _block_fraction(p0: Vector3, p1: Vector3) -> float:
	var block := _wall_fraction(p0, p1)
	for other: Combatant in _targets:
		var hero := other as Hero
		if hero == null:
			continue
		var shield := hero.projectile_block_fraction(p0, p1)
		if shield != CombatRules.NO_HIT and (block == CombatRules.NO_HIT or shield < block):
			block = shield
	return block


## Raio fisico contra o cenario: o que barra o heroi, menos o rio. Corpos sao pulados.
func _wall_fraction(p0: Vector3, p1: Vector3) -> float:
	var length := p0.distance_to(p1)
	if length <= ARRIVED_EPSILON:
		return CombatRules.NO_HIT
	_wall_query.from = p0
	_wall_query.to = p1
	_wall_query.collision_mask = collision_mask & ~PhysicsLayers.RIVER
	var space := get_world_3d().direct_space_state
	var skipped: Array[RID] = _no_exclusion
	for probe: int in MAX_WALL_PROBES:
		_wall_query.exclude = skipped
		var hit := space.intersect_ray(_wall_query)
		if hit.is_empty():
			return CombatRules.NO_HIT
		if hit["collider"] is Combatant:
			if skipped == _no_exclusion:
				skipped = []
			skipped.append(hit["rid"])
			continue
		return p0.distance_to(hit["position"]) / length
	return CombatRules.NO_HIT
