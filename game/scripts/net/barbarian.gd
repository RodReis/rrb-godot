class_name Barbarian
extends Hero
## Barbaro (GDB §4.3, F53): basico Machado em arco; Q Salto Brutal (avanco ate o ponto mirado, ate
## cast_range, que para no primeiro obstaculo — rio, muro, pilar, borda, corpo — e fere em area uma
## vez na aterrissagem); E Rodopio (pulsos em volta do heroi; anda normalmente e nao usa o basico
## enquanto gira); R Execucao (golpe frontal que soma uma fracao do HP faltante do alvo, antes da
## DEF). Numeros de barbarian.tres; dano em outro node pelo ledger do alvo (Hero._hit).

# Estado de rollback.
## O avanco em curso e o Salto: aterrissa com dano. Avanco interrompido (empurrao, atordoamento,
## morte) nao aterrissa; o proximo _use_skills limpa.
var leaping: bool = false
## Ticks restantes do Rodopio.
var spin_ticks: int = 0

## Reusado a cada pulso do Rodopio (sem alocar no _rollback_tick).
var _targets: Array[Combatant] = []


func is_channeling() -> bool:
	return spin_ticks > 0


func _extra_state_properties() -> Array[String]:
	var props: Array[String] = [":leaping", ":spin_ticks"]
	return props


func _use_skills(tick: int) -> void:
	leaping = false
	var rate := NetworkTime.tickrate
	var data := hero_data
	if input.skill_q and q_cooldown == 0 and SkillRules.can_use(data.skill_q, ranks.x, level):
		q_cooldown = SkillRules.cooldown_ticks(data.skill_q, ranks.x, attributes.intelligence, rate)
		_leap()
		return
	if input.skill_e and e_cooldown == 0 and SkillRules.can_use(data.skill_e, ranks.y, level):
		e_cooldown = SkillRules.cooldown_ticks(data.skill_e, ranks.y, attributes.intelligence, rate)
		spin_ticks = SkillRules.seconds_to_ticks(
			SkillData.at_rank(data.skill_e.duration, ranks.y), rate
		)
	if input.skill_r and r_cooldown == 0 and SkillRules.can_use(data.skill_r, ranks.z, level):
		r_cooldown = SkillRules.cooldown_ticks(data.skill_r, ranks.z, attributes.intelligence, rate)
		_execute(tick)
	if attack_now and basic_cooldown == 0 and spin_ticks == 0:
		basic_cooldown = SkillRules.seconds_to_ticks(attributes.attack_interval, rate)
		_melee(tick)


## Salto: o move_and_slide do tick ja andou; encostou em algo, para ali. Fim do avanco = aterrissa.
func _while_dashing(tick: int) -> void:
	if not leaping:
		return
	if is_on_wall():
		dash_ticks = 0
	if dash_ticks == 0:
		leaping = false
		_land(tick)


func _simulate_effects(tick: int) -> void:
	if spin_ticks == 0:
		return
	if not is_alive():
		spin_ticks = 0
		return
	var e := hero_data.skill_e
	var rate := NetworkTime.tickrate
	var interval := SkillRules.seconds_to_ticks(e.pulse_interval, rate)
	var window := SkillRules.seconds_to_ticks(SkillData.at_rank(e.duration, ranks.y), rate)
	var elapsed := window - spin_ticks
	spin_ticks -= 1
	if (
		not multiplayer.is_server()
		or not BarbarianRules.is_spin_pulse(elapsed, interval, e.pulse_count)
	):
		return
	_area_hit(tick, HitLedger.Slot.E, e.radius, roundi(SkillRules.amount(e, ranks.y, attributes)))


## Na direcao da mira ate o ponto mirado (sem mira: no lugar), distancia exata em duration.
func _leap() -> void:
	var q := hero_data.skill_q
	var rate := NetworkTime.tickrate
	var distance := InputRules.sanitize_distance(input.aim_distance, q.cast_range)
	dash_direction = CombatRules.push_vector(forward(), 1.0)
	dash_ticks = SkillRules.seconds_to_ticks(SkillData.at_rank(q.duration, ranks.x), rate)
	dash_speed = SkillRules.dash_speed(distance, dash_ticks, rate)
	leaping = true


func _land(tick: int) -> void:
	if not multiplayer.is_server():
		return
	var q := hero_data.skill_q
	_area_hit(tick, HitLedger.Slot.Q, q.radius, roundi(SkillRules.amount(q, ranks.x, attributes)))


## Fere quem esta a ate [param radius] do Barbaro.
func _area_hit(tick: int, slot: HitLedger.Slot, radius: float, damage: int) -> void:
	_enemies_into(_targets)
	for other: Combatant in _targets:
		if CombatRules.in_radius(global_position, other.global_position, radius):
			_hit(other, tick, slot, HitEffect.new(damage, global_position))
		else:
			_miss(other, tick, slot)


func _execute(tick: int) -> void:
	if not multiplayer.is_server():
		return
	var r := hero_data.skill_r
	var amount := SkillRules.amount(r, ranks.z, attributes)
	var half_arc := r.arc_degrees / 2.0
	for other: Combatant in _enemies():
		if CombatRules.is_in_melee_arc(
			global_position, forward(), other.global_position, r.attack_range, half_arc
		):
			var damage := BarbarianRules.execution_damage(
				amount, r.missing_hp_ratio, other.missing_hp()
			)
			_hit(other, tick, HitLedger.Slot.R, _direct(HitEffect.new(damage, global_position)))
		else:
			_miss(other, tick, HitLedger.Slot.R)
