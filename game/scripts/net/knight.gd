class_name Knight
extends Hero
## Cavaleiro (GDB §4.1, F8): basico em arco, Q Investida (avanco que para no primeiro inimigo,
## empurra e fere), E Muralha (escudo frontal que tambem bloqueia projetil, ShieldBlocker) e
## R Terremoto (atordoa em area). Numeros de knight.tres.

## Contato da Investida = soma dos raios das capsulas (geometria, nao balanceamento).
const CHARGE_REACH: float = 0.8


func _use_skills(tick: int) -> void:
	var rate := NetworkTime.tickrate
	var data := hero_data
	if input.skill_q and q_cooldown == 0 and SkillRules.can_use(data.skill_q, ranks.x, level):
		q_cooldown = SkillRules.cooldown_ticks(data.skill_q, ranks.x, attributes.intelligence, rate)
		dash_direction = CombatRules.push_vector(forward(), 1.0)
		dash_speed = data.skill_q.speed
		var seconds := data.skill_q.distance / data.skill_q.speed
		dash_ticks = SkillRules.seconds_to_ticks(seconds, rate)
		return
	if input.skill_e and e_cooldown == 0 and SkillRules.can_use(data.skill_e, ranks.y, level):
		e_cooldown = SkillRules.cooldown_ticks(data.skill_e, ranks.y, attributes.intelligence, rate)
		var duration := SkillData.at_rank(data.skill_e.duration, ranks.y)
		shield_ticks = SkillRules.seconds_to_ticks(duration, rate)
		shield_hp = roundi(SkillRules.amount(data.skill_e, ranks.y, attributes))
	if input.skill_r and r_cooldown == 0 and SkillRules.can_use(data.skill_r, ranks.z, level):
		r_cooldown = SkillRules.cooldown_ticks(data.skill_r, ranks.z, attributes.intelligence, rate)
		_earthquake(tick)
	if input.attack and basic_cooldown == 0:
		basic_cooldown = SkillRules.seconds_to_ticks(attributes.attack_interval, rate)
		_melee(tick)


## Investida: para no primeiro inimigo tocado, empurra e fere (PI 2026-10-09).
func _while_dashing(tick: int) -> void:
	var q := hero_data.skill_q
	for other: Combatant in _enemies():
		if not CombatRules.in_radius(global_position, other.global_position, CHARGE_REACH):
			if multiplayer.is_server():
				_miss(other, tick, HitLedger.Slot.Q)
			continue
		dash_ticks = 0
		if multiplayer.is_server():
			var damage := roundi(SkillRules.amount(q, ranks.x, attributes))
			var push := CombatRules.push_vector(dash_direction, q.knockback)
			_hit(other, tick, HitLedger.Slot.Q, HitEffect.new(damage, global_position, push))
		return


func _melee(tick: int) -> void:
	if not multiplayer.is_server():
		return
	var basic := hero_data.basic_attack
	var damage := roundi(SkillRules.amount(basic, 1, attributes))
	for other: Combatant in _enemies():
		var half_arc := basic.arc_degrees / 2.0
		if CombatRules.is_in_melee_arc(
			global_position, forward(), other.global_position, basic.attack_range, half_arc
		):
			_hit(other, tick, HitLedger.Slot.BASIC, HitEffect.new(damage, global_position))
		else:
			_miss(other, tick, HitLedger.Slot.BASIC)


func _earthquake(tick: int) -> void:
	if not multiplayer.is_server():
		return
	var r := hero_data.skill_r
	var damage := roundi(SkillRules.amount(r, ranks.z, attributes))
	var stun := SkillRules.seconds_to_ticks(
		SkillData.at_rank(r.stun_duration, ranks.z), NetworkTime.tickrate
	)
	for other: Combatant in _enemies():
		if CombatRules.in_radius(global_position, other.global_position, r.radius):
			var effect := HitEffect.new(damage, global_position, Vector3.ZERO, stun)
			_hit(other, tick, HitLedger.Slot.R, effect)
		else:
			_miss(other, tick, HitLedger.Slot.R)
