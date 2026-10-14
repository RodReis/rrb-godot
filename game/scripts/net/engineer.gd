class_name Engineer
extends ProjectileHero
## Engenheiro (GDB §4.6, F59, SPEC-059): basico Bacamarte (cone instantaneo, Hero._melee com o arco
## do engineer.tres); Q Garra Mecanica (projetil do pool que para no 1o alvo: heroi e puxado ate
## distance do Engenheiro, monstro so toma dano); E Torreta (estado do Engenheiro, nao um node: no
## compasso da Chuva de Flechas, atira no inimigo mais proximo do ponto que o Engenheiro ve); R
## Caixa de Dinamite (marca o ponto e explode duration depois, no compasso do Meteoro, ferindo e
## empurrando para fora como o Anel de Fogo). Numeros de engineer.tres; dano e puxao pelo ledger
## do alvo (Hero._hit). A Torreta e a caixa chegam ao cliente que nao ve o Engenheiro pelo
## ImpactRelay (deployed, turret_fired), nao pelo estado dele.

## Servidor: [param kind] (Deploy) posto em [param center] no [param tick] (a ressimulacao repete;
## o relay filtra).
signal deployed(kind: Deploy, center: Vector3, tick: int)
## Servidor: a Torreta de [param from] atirou em [param at] no [param tick].
signal turret_fired(from: Vector3, at: Vector3, tick: int)

enum Deploy { TURRET, CRATE }

## Folga entre a Torreta e o obstaculo em que ela para (geometria, nao balanceamento).
const PLACE_MARGIN: float = 0.3

# Estado de rollback.
## Ticks restantes da Torreta; o ponto fica onde foi instalada.
var turret_ticks: int = 0
var turret_center: Vector3 = Vector3.ZERO
## Ticks ate a caixa explodir (0 = nenhuma); o ponto fica onde foi posta.
var crate_ticks: int = 0
var crate_center: Vector3 = Vector3.ZERO

## Reusados a cada disparo da Torreta (sem alocar): inimigos que o Engenheiro ve e a posicao deles.
var _seen: Array[Combatant] = []
var _seen_points: PackedVector3Array = PackedVector3Array()


func _extra_state_properties() -> Array[String]:
	var props := super()
	props.append_array([":turret_ticks", ":turret_center", ":crate_ticks", ":crate_center"])
	return props


func _flight_speed() -> float:
	return hero_data.skill_q.speed


func _flight_radius() -> float:
	return hero_data.skill_q.radius


func _use_skills(tick: int) -> void:
	var rate := NetworkTime.tickrate
	var data := hero_data
	if input.skill_q and q_cooldown == 0 and SkillRules.can_use(data.skill_q, ranks.x, level):
		q_cooldown = SkillRules.cooldown_ticks(data.skill_q, ranks.x, attributes.intelligence, rate)
		_claw()
	if input.skill_e and e_cooldown == 0 and SkillRules.can_use(data.skill_e, ranks.y, level):
		e_cooldown = SkillRules.cooldown_ticks(data.skill_e, ranks.y, attributes.intelligence, rate)
		_place_turret(tick)
	if input.skill_r and r_cooldown == 0 and SkillRules.can_use(data.skill_r, ranks.z, level):
		r_cooldown = SkillRules.cooldown_ticks(data.skill_r, ranks.z, attributes.intelligence, rate)
		_drop_crate(tick)
	if input.attack and basic_cooldown == 0:
		basic_cooldown = SkillRules.seconds_to_ticks(attributes.attack_interval, rate)
		_melee(tick)


func _simulate_effects(tick: int) -> void:
	var flying := _arrows_flying()
	if not flying and turret_ticks == 0 and crate_ticks == 0:
		return
	_enemies_into(_targets)
	if flying:
		_advance_arrows(tick)
	if turret_ticks > 0:
		_turret(tick)
	if crate_ticks > 0:
		crate_ticks -= 1
		if crate_ticks == 0 and multiplayer.is_server():
			var r := hero_data.skill_r
			var damage := roundi(SkillRules.amount(r, ranks.z, attributes))
			_area_hit(tick, HitLedger.Slot.R, crate_center, r.radius, damage, r.knockback)


## A garra para no 1o toque: o heroi tocado e puxado (empurrao ate distance do Engenheiro, no ponto
## em que ele esta neste tick, em duration); monstro so toma o dano.
func _arrow_struck(arrow: Arrow, other: Combatant, at: Vector3, tick: int) -> bool:
	if not multiplayer.is_server():
		return true
	_struck_q.append(other)
	var q := hero_data.skill_q
	var effect := HitEffect.new(arrow.damage, at)
	if other is Hero:
		effect.push = EngineerRules.pull_push(global_position, other.global_position, q.distance)
		effect.push_ticks = SkillRules.seconds_to_ticks(
			SkillData.at_rank(q.duration, ranks.x), NetworkTime.tickrate
		)
	_hit(other, tick, HitLedger.Slot.Q, effect)
	return true


func _claw() -> void:
	var q := hero_data.skill_q
	_shoot(Arrow.Kind.CLAW, q.attack_range, roundi(SkillRules.amount(q, ranks.x, attributes)))


## Torreta no ponto mirado ate cast_range, parando no obstaculo; a nova substitui a anterior.
func _place_turret(tick: int) -> void:
	var e := hero_data.skill_e
	var distance := InputRules.sanitize_distance(input.aim_distance, e.cast_range)
	var target := RangerRules.rain_center(global_position, forward(), distance, e.cast_range)
	turret_center = _before_obstacle(target)
	turret_ticks = SkillRules.seconds_to_ticks(
		SkillData.at_rank(e.duration, ranks.y), NetworkTime.tickrate
	)
	if multiplayer.is_server():
		deployed.emit(Deploy.TURRET, turret_center, tick)


## Caixa no ponto mirado ate cast_range; explode duration depois (so uma por vez: a nova a troca).
func _drop_crate(tick: int) -> void:
	var r := hero_data.skill_r
	var distance := InputRules.sanitize_distance(input.aim_distance, r.cast_range)
	crate_center = RangerRules.rain_center(global_position, forward(), distance, r.cast_range)
	crate_ticks = SkillRules.seconds_to_ticks(
		SkillData.at_rank(r.duration, ranks.z), NetworkTime.tickrate
	)
	if multiplayer.is_server():
		deployed.emit(Deploy.CRATE, crate_center, tick)


## Um tick da Torreta: nos disparos, fere o inimigo mais proximo dela que o Engenheiro ve. Sem alvo
## valido nao dispara (nao acumula). Instalar revela o Engenheiro (skill); o disparo nao: nao mexe
## em nenhuma recarga (Hero._rollback_tick so revela quando uma sobe).
func _turret(tick: int) -> void:
	var e := hero_data.skill_e
	var rate := NetworkTime.tickrate
	var interval := SkillRules.seconds_to_ticks(e.pulse_interval, rate)
	var window := SkillRules.seconds_to_ticks(SkillData.at_rank(e.duration, ranks.y), rate)
	var elapsed := window - turret_ticks
	turret_ticks -= 1
	if (
		not multiplayer.is_server()
		or not EngineerRules.is_turret_shot(elapsed, interval, e.pulse_count)
	):
		return
	var chosen := _turret_target(e.attack_range)
	var damage := roundi(SkillRules.amount(e, ranks.y, attributes))
	for other: Combatant in _targets:
		if other == chosen:
			_hit(other, tick, HitLedger.Slot.E, HitEffect.new(damage, turret_center))
		else:
			_miss(other, tick, HitLedger.Slot.E)
	if chosen != null:
		turret_fired.emit(turret_center, chosen.global_position, tick)


## Inimigo mais proximo da Torreta a ate [param reach] entre os que o Engenheiro ve (GDB §7.3); nulo
## se nenhum, ou se o Engenheiro morreu (quem morreu nao ve).
func _turret_target(reach: float) -> Combatant:
	if not is_alive():
		return null
	_seen.clear()
	_seen_points.clear()
	for other: Combatant in _targets:
		if other.seen_by(self):
			_seen.append(other)
			_seen_points.append(other.global_position)
	var at := EngineerRules.nearest(turret_center, _seen_points, reach)
	return _seen[at] if at >= 0 else null


## [param target] no plano do Engenheiro, recuado se um muro, pilar ou portao barra o caminho: o
## ponto fica PLACE_MARGIN antes do obstaculo.
func _before_obstacle(target: Vector3) -> Vector3:
	var from := global_position + Vector3.UP * FLIGHT_HEIGHT
	var to := Vector3(target.x, from.y, target.z)
	var fraction := _wall_fraction(from, to)
	if fraction == CombatRules.NO_HIT:
		return target
	var reach := maxf(from.distance_to(to) * fraction - PLACE_MARGIN, 0.0)
	var flat := from.move_toward(to, reach)
	return Vector3(flat.x, target.y, flat.z)
