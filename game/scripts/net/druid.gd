class_name Druid
extends ProjectileHero
## Protetor da Selva (GDB §4.7, F74, SPEC-074): basico Seiva (projetil que para no 1o alvo); Q
## Raizes Vivas (projetil que para no 1o heroi ou monstro e o enraiza: lentidao de 100 % por
## duration, o `slow` de sempre; o chefe so toma o dano); E Pocao Verde (zona de cura no ponto
## mirado ate cast_range, parando no obstaculo: cura o proprio Protetor, em fatias iguais por
## pulso, sem passar do HP maximo; aliados ficam para o 2x2); R Pantano (zona no ponto mirado ate
## cast_range: a cada pulso, quem esta dentro toma dano e lentidao ate o pulso seguinte, o compasso
## da Chuva de Flechas). As zonas sao estado do Protetor (nao nodes), como a Torreta do Engenheiro;
## chegam ao cliente que nao o ve pelo ImpactRelay (zone_started). Numeros de druid.tres; dano e
## lentidao pelo ledger do alvo (Hero._hit), cura pelo proprio estado.

## Servidor: [param kind] (Zone) posta em [param center] no [param tick] (a ressimulacao repete; o
## relay filtra).
signal zone_started(kind: Zone, center: Vector3, tick: int)

enum Zone { POTION, SWAMP }

# Estado de rollback.
## Ticks restantes da Pocao Verde; o ponto fica onde ela caiu.
var potion_ticks: int = 0
var potion_center: Vector3 = Vector3.ZERO
## Ticks restantes do Pantano; o ponto fica onde foi posto.
var swamp_ticks: int = 0
var swamp_center: Vector3 = Vector3.ZERO


func _extra_state_properties() -> Array[String]:
	var props := super()
	props.append_array([":potion_ticks", ":potion_center", ":swamp_ticks", ":swamp_center"])
	return props


func _flight_speed(kind: Arrow.Kind = Arrow.Kind.BASIC) -> float:
	return _flight_skill(kind).speed


func _flight_radius(kind: Arrow.Kind = Arrow.Kind.BASIC) -> float:
	return _flight_skill(kind).radius


func _kind_speeds() -> Dictionary[int, float]:
	return {
		Arrow.Kind.BASIC: hero_data.basic_attack.speed,
		Arrow.Kind.ROOT: hero_data.skill_q.speed,
	}


func _use_skills(tick: int) -> void:
	var rate := NetworkTime.tickrate
	var data := hero_data
	if input.skill_q and q_cooldown == 0 and SkillRules.can_use(data.skill_q, ranks.x, level):
		q_cooldown = SkillRules.cooldown_ticks(data.skill_q, ranks.x, attributes.intelligence, rate)
		var damage := roundi(SkillRules.amount(data.skill_q, ranks.x, attributes))
		_shoot(Arrow.Kind.ROOT, data.skill_q.attack_range, damage)
	if input.skill_e and e_cooldown == 0 and SkillRules.can_use(data.skill_e, ranks.y, level):
		e_cooldown = SkillRules.cooldown_ticks(data.skill_e, ranks.y, attributes.intelligence, rate)
		_throw_potion(tick)
	if input.skill_r and r_cooldown == 0 and SkillRules.can_use(data.skill_r, ranks.z, level):
		r_cooldown = SkillRules.cooldown_ticks(data.skill_r, ranks.z, attributes.intelligence, rate)
		_make_swamp(tick)
	if attack_now and basic_cooldown == 0:
		basic_cooldown = SkillRules.seconds_to_ticks(attributes.attack_interval, rate)
		var basic := data.basic_attack
		_shoot(Arrow.Kind.BASIC, basic.attack_range, roundi(SkillRules.amount(basic, 1, attributes)))


func _simulate_effects(tick: int) -> void:
	var flying := _arrows_flying()
	if not flying and potion_ticks == 0 and swamp_ticks == 0:
		return
	_enemies_into(_targets)
	if flying:
		_advance_arrows(tick)
	if potion_ticks > 0:
		_potion(tick)
	if swamp_ticks > 0:
		_swamp(tick)


## A seiva fere quem tocou; a raiz fere e enraiza (o chefe so toma o dano). As duas param no 1o toque.
func _arrow_struck(arrow: Arrow, other: Combatant, at: Vector3, tick: int) -> bool:
	if not multiplayer.is_server():
		return true
	var effect := HitEffect.new(arrow.damage, at)
	if arrow.kind == Arrow.Kind.ROOT:
		var q := hero_data.skill_q
		if DruidRules.roots(_is_boss(other)):
			effect.slow = q.slow
			# Um tick a mais: o alvo aplica o golpe e desconta o tick no mesmo _rollback_tick (como a Chuva).
			effect.slow_ticks = 1 + SkillRules.seconds_to_ticks(
				SkillData.at_rank(q.duration, ranks.x), NetworkTime.tickrate
			)
		_struck_q.append(other)
		_hit(other, tick, HitLedger.Slot.Q, effect)
	else:
		_struck_basic.append(other)
		_hit(other, tick, HitLedger.Slot.BASIC, effect)
	return true


## Pocao no ponto mirado ate cast_range, parando no obstaculo; a nova substitui a anterior.
func _throw_potion(tick: int) -> void:
	var e := hero_data.skill_e
	var distance := InputRules.sanitize_distance(input.aim_distance, e.cast_range)
	var target := RangerRules.rain_center(global_position, forward(), distance, e.cast_range)
	potion_center = _before_obstacle(target)
	potion_ticks = SkillRules.seconds_to_ticks(
		SkillData.at_rank(e.duration, ranks.y), NetworkTime.tickrate
	)
	if multiplayer.is_server():
		zone_started.emit(Zone.POTION, potion_center, tick)


## Pantano no ponto mirado ate cast_range (como o Meteoro, nao para no obstaculo); o novo troca o
## anterior.
func _make_swamp(tick: int) -> void:
	var r := hero_data.skill_r
	var distance := InputRules.sanitize_distance(input.aim_distance, r.cast_range)
	swamp_center = RangerRules.rain_center(global_position, forward(), distance, r.cast_range)
	swamp_ticks = SkillRules.seconds_to_ticks(
		SkillData.at_rank(r.duration, ranks.z), NetworkTime.tickrate
	)
	if multiplayer.is_server():
		zone_started.emit(Zone.SWAMP, swamp_center, tick)


## Um tick da Pocao: nos pulsos, cura o Protetor se ele esta na zona (vivo). Cura de verdade sai do
## estado de rollback do proprio heroi, entao o cliente a preve igual ao servidor.
func _potion(_tick: int) -> void:
	var e := hero_data.skill_e
	var rate := NetworkTime.tickrate
	var interval := SkillRules.seconds_to_ticks(e.pulse_interval, rate)
	var window := SkillRules.seconds_to_ticks(SkillData.at_rank(e.duration, ranks.y), rate)
	var pulse := DruidRules.pulse_index(window - potion_ticks, interval, e.pulse_count)
	potion_ticks -= 1
	if pulse < 0 or not is_alive():
		return
	if not CombatRules.in_radius(potion_center, global_position, e.radius):
		return
	var total := roundi(SkillRules.amount(e, ranks.y, attributes))
	hp = mini(hp + DruidRules.pulse_heal(total, pulse, e.pulse_count), attributes.max_hp)


## Um tick do Pantano: nos pulsos, quem esta na area toma dano e lentidao ate o pulso seguinte.
func _swamp(tick: int) -> void:
	var r := hero_data.skill_r
	var rate := NetworkTime.tickrate
	var interval := SkillRules.seconds_to_ticks(r.pulse_interval, rate)
	var window := SkillRules.seconds_to_ticks(SkillData.at_rank(r.duration, ranks.z), rate)
	var elapsed := window - swamp_ticks
	swamp_ticks -= 1
	if not multiplayer.is_server() or not DruidRules.is_pulse(elapsed, interval, r.pulse_count):
		return
	var damage := roundi(SkillRules.amount(r, ranks.z, attributes))
	for other: Combatant in _targets:
		if CombatRules.in_radius(swamp_center, other.global_position, r.radius):
			var effect := HitEffect.new(damage, swamp_center)
			effect.slow = r.slow
			effect.slow_ticks = RangerRules.rain_slow_ticks(interval)
			_hit(other, tick, HitLedger.Slot.R, effect)
		else:
			_miss(other, tick, HitLedger.Slot.R)


## A habilidade de que o projetil [param kind] tira velocidade e raio: Raizes Vivas ou o basico.
func _flight_skill(kind: Arrow.Kind) -> SkillData:
	return hero_data.skill_q if kind == Arrow.Kind.ROOT else hero_data.basic_attack


static func _is_boss(other: Combatant) -> bool:
	var monster := other as Monster
	return monster != null and monster.data.tier == MonsterData.Tier.BOSS
