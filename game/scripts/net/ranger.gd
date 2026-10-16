class_name Ranger
extends ProjectileHero
## Arqueira (GDB §4.2, F14). Numeros de ranger.tres; nenhum literal de balanceamento aqui.
## Basico e Q sao flechas do pool (voo e bloqueio em ProjectileHero). Q atravessa alvos perdendo
## dano (RangerRules.pierce_factor). E Rolamento: avanco na direcao do movimento,
## invulnerabilidade e reseta o basico. R Chuva de Flechas: area no cursor ate cast_range (PI
## 2026-10-10), pulsos de dano e lentidao em heroi e monstro (PI 2026-10-10). Dano e lentidao pelo
## ledger do alvo.

# Estado de rollback.
## Ticks restantes da Chuva; o centro fica onde caiu.
var rain_ticks: int = 0
var rain_center: Vector3 = Vector3.ZERO

@onready var _rain_area: Node3D = $RainArea


func _ready() -> void:
	super()
	var radius := hero_data.skill_r.radius  # malha da area tem raio 1
	_rain_area.scale = Vector3(radius, 1.0, radius)


func _process(delta: float) -> void:
	super(delta)
	_rain_area.visible = rain_ticks > 0
	if _rain_area.visible:
		_rain_area.global_position = rain_center


func _extra_state_properties() -> Array[String]:
	var props := super()
	props.append_array([":rain_ticks", ":rain_center"])
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
	if attack_now and basic_cooldown == 0:
		basic_cooldown = SkillRules.seconds_to_ticks(attributes.attack_interval, rate)
		var basic := data.basic_attack
		_shoot(
			Arrow.Kind.BASIC, basic.attack_range, roundi(SkillRules.amount(basic, 1, attributes))
		)


func _simulate_effects(tick: int) -> void:
	var flying := _arrows_flying()
	if not flying and rain_ticks == 0:
		return
	_enemies_into(_targets)
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


## Basico para no 1o alvo; Q atravessa perdendo dano a cada alvo.
func _arrow_struck(arrow: Arrow, other: Combatant, at: Vector3, tick: int) -> bool:
	if multiplayer.is_server():
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
		_hit(other, tick, slot, HitEffect.new(damage, at))
	if arrow.kind == Arrow.Kind.BASIC:
		return true
	arrow.pierced += 1
	return false


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
