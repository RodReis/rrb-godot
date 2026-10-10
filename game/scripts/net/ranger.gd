class_name Ranger
extends Hero
## Arqueira (GDB §4.2, F14). Numeros de ranger.tres; nenhum literal de balanceamento aqui.
## Basico e Q sao flechas do pool (Arrow): voam no estado de rollback do heroi, entao o cliente
## preve o proprio disparo e o servidor decide o acerto (CONVENTION §4.5). A flecha para no muro,
## pilar, rocha, portao que barra a Arqueira e na Muralha ativa do inimigo, nao no rio (PI
## 2026-10-10). Q atravessa alvos perdendo dano (RangerRules.pierce_factor); usa velocidade e raio
## do basico (PI 2026-10-10). E Rolamento: avanco na direcao do movimento, invulnerabilidade e
## reseta o basico. R Chuva de Flechas: area no cursor ate cast_range (PI 2026-10-10), pulsos de
## dano e lentidao em heroi e monstro (PI 2026-10-10). Dano e lentidao pelo ledger do alvo.

## Altura do voo (u): o raio contra muro/pilar corre nessa altura. Geometria, nao balanceamento.
const FLIGHT_HEIGHT: float = 1.0
## Corpos (heroi, monstro) estao na camada WORLD: o raio pula ate este numero deles atras do muro.
const MAX_WALL_PROBES: int = 4
## Folga para dar a flecha como chegada ao alcance (soma de passos em ponto flutuante).
const ARRIVED_EPSILON: float = 0.0001

# Estado de rollback.
## Ticks restantes da Chuva; o centro fica onde caiu.
var rain_ticks: int = 0
var rain_center: Vector3 = Vector3.ZERO

var _arrows: Array[Arrow] = []
var _targets: Array[Combatant] = []
## Reusados a cada tick (sem alocar no _rollback_tick): acertos ordenados e quem foi atingido.
var _hit_fractions: PackedFloat64Array = PackedFloat64Array()
var _hit_targets: Array[Combatant] = []
var _struck_basic: Array[Combatant] = []
var _struck_q: Array[Combatant] = []
var _wall_query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.new()
var _no_exclusion: Array[RID] = []

@onready var _rain_area: Node3D = $RainArea


func _ready() -> void:
	super()
	for arrow: Arrow in _arrows:
		arrow.speed = hero_data.basic_attack.speed
	var radius := hero_data.skill_r.radius  # malha da area tem raio 1
	_rain_area.scale = Vector3(radius, 1.0, radius)


func _process(delta: float) -> void:
	super(delta)
	_rain_area.visible = rain_ticks > 0
	if _rain_area.visible:
		_rain_area.global_position = rain_center


func _extra_state_properties() -> Array[String]:
	var props: Array[String] = [":rain_ticks", ":rain_center"]
	_arrows.clear()
	for node: Node in $Arrows.get_children():
		_arrows.append(node as Arrow)
		for prop: String in Arrow.STATE:
			props.append("Arrows/%s:%s" % [node.name, prop])
	return props


func _use_skills(_tick: int) -> void:
	var rate := NetworkTime.tickrate
	var data := hero_data
	if input.skill_e and e_cooldown == 0 and SkillRules.can_use(data.skill_e, ranks.y, level):
		_roll()
		return
	if input.skill_q and q_cooldown == 0 and SkillRules.can_use(data.skill_q, ranks.x, level):
		q_cooldown = SkillRules.cooldown_ticks(data.skill_q, ranks.x, attributes.intelligence, rate)
		var damage := roundi(SkillRules.amount(data.skill_q, ranks.x, attributes))
		_shoot(Arrow.Kind.PIERCE, data.skill_q.attack_range, damage)
	if input.skill_r and r_cooldown == 0 and SkillRules.can_use(data.skill_r, ranks.z, level):
		r_cooldown = SkillRules.cooldown_ticks(data.skill_r, ranks.z, attributes.intelligence, rate)
		_cast_rain()
	if input.attack and basic_cooldown == 0:
		basic_cooldown = SkillRules.seconds_to_ticks(attributes.attack_interval, rate)
		var basic := data.basic_attack
		_shoot(
			Arrow.Kind.BASIC, basic.attack_range, roundi(SkillRules.amount(basic, 1, attributes))
		)


func _simulate_effects(tick: int) -> void:
	var flying := false
	for arrow: Arrow in _arrows:
		flying = flying or arrow.is_active()
	if not flying and rain_ticks == 0:
		return
	_targets = _enemies()
	if flying:
		_advance_arrows(tick)
	if rain_ticks > 0:
		_rain(tick)


## Rolamento: na direcao do movimento (parada: para a frente), distancia exata em duration.
func _roll() -> void:
	var rate := NetworkTime.tickrate
	var e := hero_data.skill_e
	e_cooldown = SkillRules.cooldown_ticks(e, ranks.y, attributes.intelligence, rate)
	var move := InputRules.sanitize_direction(input.movement)
	dash_direction = CombatRules.push_vector(forward() if move.is_zero_approx() else move, 1.0)
	dash_ticks = SkillRules.seconds_to_ticks(SkillData.at_rank(e.duration, ranks.y), rate)
	dash_speed = SkillRules.dash_speed(e.distance, dash_ticks, rate)
	invuln_ticks = SkillRules.seconds_to_ticks(e.invulnerability, rate)
	if e.resets_basic_attack:
		basic_cooldown = 0


func _cast_rain() -> void:
	var r := hero_data.skill_r
	var distance := InputRules.sanitize_distance(input.aim_distance, r.cast_range)
	rain_center = RangerRules.rain_center(global_position, forward(), distance, r.cast_range)
	var duration := SkillData.at_rank(r.duration, ranks.z)
	rain_ticks = SkillRules.seconds_to_ticks(duration, NetworkTime.tickrate)


## Ocupa um slot livre do pool; cheio, reaproveita a flecha que mais voou.
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


## Servidor: alvo heroi que nenhuma flecha atingiu neste tick tem o golpe desfeito (ressimulacao
## sem acerto, como o _melee do Cavaleiro).
# ponytail: so roda com flecha no ar; golpe gravado numa simulacao em que a flecha ja tinha parado
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


## Um tick de voo: acerta, na ordem do caminho, quem o segmento do tick toca antes do bloqueio.
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
		_strike(arrow, other, p0, tick)
		if arrow.kind == Arrow.Kind.BASIC:
			arrow.stop()
			return
		arrow.pierced += 1
	arrow.traveled += step * reach
	arrow.origin = p0.lerp(p1, reach)
	if block != CombatRules.NO_HIT or arrow.max_range - arrow.traveled <= ARRIVED_EPSILON:
		arrow.stop()


func _strike(arrow: Arrow, other: Combatant, source: Vector3, tick: int) -> void:
	if not multiplayer.is_server():
		return
	var damage := arrow.damage
	var slot := HitLedger.Slot.BASIC
	if arrow.kind == Arrow.Kind.PIERCE:
		var q := hero_data.skill_q
		damage = roundi(
			damage * RangerRules.pierce_factor(arrow.pierced, q.pierce_decay, q.pierce_min)
		)
		slot = HitLedger.Slot.Q
		_struck_q.append(other)
	else:
		_struck_basic.append(other)
	_hit(other, tick, slot, HitEffect.new(damage, source))


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


## Menor fracao do segmento em que muro/pilar/portao ou a Muralha inimiga barram a flecha.
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


## Raio fisico contra o cenario: o que barra a Arqueira, menos o rio. Corpos sao pulados.
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


## Um tick da Chuva: pulsa no intervalo; quem esta na area toma dano e lentidao ate o pulso
## seguinte.
func _rain(tick: int) -> void:
	var r := hero_data.skill_r
	var rate := NetworkTime.tickrate
	var interval := SkillRules.seconds_to_ticks(r.pulse_interval, rate)
	var window := SkillRules.seconds_to_ticks(SkillData.at_rank(r.duration, ranks.z), rate)
	var elapsed := window - rain_ticks
	rain_ticks -= 1
	if (
		not multiplayer.is_server()
		or not RangerRules.is_rain_pulse(elapsed, interval, r.pulse_count)
	):
		return
	var damage := roundi(SkillRules.amount(r, ranks.z, attributes))
	for other: Combatant in _targets:
		if CombatRules.in_radius(rain_center, other.global_position, r.radius):
			var effect := HitEffect.new(damage, rain_center)
			effect.slow = r.slow
			effect.slow_ticks = RangerRules.rain_slow_ticks(interval)
			_hit(other, tick, HitLedger.Slot.R, effect)
		else:
			_miss(other, tick, HitLedger.Slot.R)
