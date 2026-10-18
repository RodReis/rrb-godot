class_name Occultist
extends ProjectileHero
## Ocultista (GDB §4.10, F77, SPEC-077): basico Projetil Sombrio (projetil que para no 1o alvo e
## soma 1 marca de Maldicao); Q Praga (projetil que para no 1o heroi ou monstro e o corroi por 4 s,
## em 8 pulsos); E Circulo Profano (zona no ponto mirado ate cast_range: lentidao e dano por pulso);
## R Servos do Vazio (F78, SPEC-078): liga os 2 servos do pool da cena (Servants/Servant0 e 1),
## um de cada lado; a IA, o golpe e a visao sao do VoidServant. Maldicao e Praga sao estado do ALVO
## (Hero/Monster: curse_stacks, dot_ticks...), aplicadas por ele a partir do ledger; aqui so se
## monta o HitEffect. A zona e estado do Ocultista (nao node), como o Pantano do Protetor; chega ao
## cliente que nao o ve pelo ImpactRelay (zone_started). Numeros de occultist.tres.

## Servidor: [param kind] (Zone) posta em [param center] no [param tick] (a ressimulacao repete; o
## relay filtra). Mesma forma de Druid.zone_started.
signal zone_started(kind: Zone, center: Vector3, tick: int)

enum Zone { CIRCLE }

# Estado de rollback.
## Ticks restantes do Circulo Profano; o ponto fica onde foi posto.
var circle_ticks: int = 0
var circle_center: Vector3 = Vector3.ZERO

## Pool fixo de servos (filhos de um Node simples: nao herdam posicao nem visibilidade do heroi).
var servants: Array[VoidServant] = []


func _ready() -> void:
	super()
	for node: Node in $Servants.get_children():
		var servant := node as VoidServant
		servant.setup(self, servants.size())
		servants.append(servant)


func _extra_state_properties() -> Array[String]:
	var props := super()
	props.append_array([":circle_ticks", ":circle_center"])
	return props


func _flight_speed(kind: Arrow.Kind = Arrow.Kind.SHADOW) -> float:
	return _flight_skill(kind).speed


func _flight_radius(kind: Arrow.Kind = Arrow.Kind.SHADOW) -> float:
	return _flight_skill(kind).radius


func _kind_speeds() -> Dictionary[int, float]:
	return {
		Arrow.Kind.SHADOW: hero_data.basic_attack.speed,
		Arrow.Kind.PLAGUE: hero_data.skill_q.speed,
	}


func _use_skills(tick: int) -> void:
	var rate := NetworkTime.tickrate
	var data := hero_data
	if input.skill_q and q_cooldown == 0 and SkillRules.can_use(data.skill_q, ranks.x, level):
		q_cooldown = SkillRules.cooldown_ticks(data.skill_q, ranks.x, attributes.intelligence, rate)
		var total := roundi(SkillRules.amount(data.skill_q, ranks.x, attributes))
		_shoot(Arrow.Kind.PLAGUE, data.skill_q.attack_range, total)
	if input.skill_e and e_cooldown == 0 and SkillRules.can_use(data.skill_e, ranks.y, level):
		e_cooldown = SkillRules.cooldown_ticks(data.skill_e, ranks.y, attributes.intelligence, rate)
		_make_circle(tick)
	if input.skill_r and r_cooldown == 0 and SkillRules.can_use(data.skill_r, ranks.z, level):
		r_cooldown = SkillRules.cooldown_ticks(data.skill_r, ranks.z, attributes.intelligence, rate)
		_summon(tick)
	if attack_now and basic_cooldown == 0:
		basic_cooldown = SkillRules.seconds_to_ticks(attributes.attack_interval, rate)
		var basic := data.basic_attack
		_shoot(
			Arrow.Kind.SHADOW, basic.attack_range, roundi(SkillRules.amount(basic, 1, attributes))
		)


func _simulate_effects(tick: int) -> void:
	var flying := _arrows_flying()
	if not flying and circle_ticks == 0:
		return
	_enemies_into(_targets)
	if flying:
		_advance_arrows(tick)
	if circle_ticks > 0:
		_circle(tick)


## O projetil sombrio fere e marca; a praga nao fere: poe a corrosao no alvo. As duas param no 1o
## toque.
func _arrow_struck(arrow: Arrow, other: Combatant, at: Vector3, tick: int) -> bool:
	if not multiplayer.is_server():
		return true
	var rate := NetworkTime.tickrate
	if arrow.kind == Arrow.Kind.PLAGUE:
		var q := hero_data.skill_q
		var plague := HitEffect.new(0, at)
		plague.dot_total = arrow.damage
		plague.dot_pulses = q.pulse_count
		plague.dot_interval_ticks = SkillRules.seconds_to_ticks(q.pulse_interval, rate)
		_struck_q.append(other)
		_hit(other, tick, HitLedger.Slot.Q, plague)
	else:
		var basic := hero_data.basic_attack
		var shadow := HitEffect.new(arrow.damage, at)
		shadow.curse = basic.curse_marks
		# Um tick a mais: o alvo aplica o golpe e desconta o tick no mesmo _rollback_tick.
		var lasts := SkillData.at_rank(basic.duration, 1)
		shadow.curse_ticks = 1 + SkillRules.seconds_to_ticks(lasts, rate)
		_struck_basic.append(other)
		_hit(other, tick, HitLedger.Slot.BASIC, shadow)
	return true


## Circulo no ponto mirado ate cast_range (como o Meteoro e o Pantano, nao para no obstaculo); o
## novo troca o anterior.
func _make_circle(tick: int) -> void:
	var e := hero_data.skill_e
	var distance := InputRules.sanitize_distance(input.aim_distance, e.cast_range)
	circle_center = RangerRules.rain_center(global_position, forward(), distance, e.cast_range)
	circle_ticks = SkillRules.seconds_to_ticks(
		SkillData.at_rank(e.duration, ranks.y), NetworkTime.tickrate
	)
	if multiplayer.is_server():
		zone_started.emit(Zone.CIRCLE, circle_center, tick)


## Servidor: os 2 servos ao lado (direita e esquerda, parando no obstaculo), virados como o
## Ocultista; a invocacao nova substitui a anterior.
func _summon(tick: int) -> void:
	if not multiplayer.is_server():
		return
	var r := hero_data.skill_r
	var lasts := SkillRules.seconds_to_ticks(
		SkillData.at_rank(r.duration, ranks.z), NetworkTime.tickrate
	)
	var right := global_basis.x
	for i: int in servants.size():
		var servant := servants[i]
		var side := VoidServantRules.side_point(global_position, right, servant.data.side_offset, i)
		servant.summon(
			tick, _before_obstacle(side), global_basis, ranks.z, attributes.intelligence, lasts
		)


## Um tick do Circulo: nos pulsos, quem esta na area toma dano e lentidao ate o pulso seguinte.
func _circle(tick: int) -> void:
	var e := hero_data.skill_e
	var rate := NetworkTime.tickrate
	var interval := SkillRules.seconds_to_ticks(e.pulse_interval, rate)
	var window := SkillRules.seconds_to_ticks(SkillData.at_rank(e.duration, ranks.y), rate)
	var pulse := DruidRules.pulse_index(window - circle_ticks, interval, e.pulse_count)
	circle_ticks -= 1
	if not multiplayer.is_server() or pulse < 0:
		return
	var total := roundi(SkillRules.amount(e, ranks.y, attributes))
	var damage := OccultistRules.circle_pulse_damage(total, pulse, e.pulse_count)
	for other: Combatant in _targets:
		if CombatRules.in_radius(circle_center, other.global_position, e.radius):
			var effect := HitEffect.new(damage, circle_center)
			effect.slow = e.slow
			effect.slow_ticks = RangerRules.rain_slow_ticks(interval)
			_hit(other, tick, HitLedger.Slot.E, effect)
		else:
			_miss(other, tick, HitLedger.Slot.E)


## A habilidade de que o projetil [param kind] tira velocidade e raio: a Praga ou o basico.
func _flight_skill(kind: Arrow.Kind) -> SkillData:
	return hero_data.skill_q if kind == Arrow.Kind.PLAGUE else hero_data.basic_attack
