class_name Carrasco
extends ProjectileHero
## Carrasco (GDB §4.11, F98, SPEC-098, ADR-0032): tanque que pune quem fica perto. Passiva Couraca
## (dano de basico de heroi x taken_factor, depois da DEF) e a Dor (recurso: +1 por alvo do basico e
## a cada pulso da Penitencia, teto e duracao na PassiveData). Basico Espada (arco do carrasco.tres,
## Hero._melee); Q Espinhos (golpe em cone com lentidao que abre a janela do recast: Q de novo lanca
## o projetil THORNS, que para no 1o alvo; a recarga conta depois do recast ou do fim da janela); E
## Penitencia (canaliza imovel: mitiga, cura aos poucos e soma Dor; no fim ou com E de novo explode
## com raiz ou lentidao pela Dor; atordoamento cancela sem explosao); R Correntes do Julgamento
## (projetil CHAINS que passa por monstro e para no 1o heroi: dano, raiz e um raio de luz no ponto
## do acerto; o heroi preso nele com HP abaixo de execute_hp_ratio e executado). Numeros de
## carrasco.tres; efeito em outro node pelo ledger do alvo (Hero._hit, ADR-0001); a execucao vai
## pelo slot PASSIVE do Carrasco, sem VFX de golpe (nao e golpe). O input chega segurado: o recast e
## o "E de novo" so valem no toque (CarrascoRules.pressed).

## Servidor: as Correntes acenderam o raio de luz em [param center] no [param tick] (o ImpactRelay o
## mostra aos dois jogadores, mesmo com o Carrasco escondido). [param kind] e sempre Zone.LIGHT.
signal zone_started(kind: int, center: Vector3, tick: int)

enum Zone { LIGHT }

# Estado de rollback.
## Dor (0..pain_max) e ticks ate ela cair toda fora da Penitencia (renova a cada ganho).
var pain: int = 0
var pain_ticks: int = 0
## Ticks restantes da janela do recast dos Espinhos (> 0 = Q de novo lanca o projetil).
var q_window_ticks: int = 0
## Q e E segurados no tick anterior (o toque e a borda: CarrascoRules.pressed).
var q_held: bool = false
var e_held: bool = false
## Ticks restantes da Penitencia e cura ja dada nela.
var penance_ticks: int = 0
var penance_healed: int = 0
## Raio de luz das Correntes: ticks restantes, centro e combat_id do heroi preso.
var light_ticks: int = 0
var light_at: Vector3 = Vector3.ZERO
var light_target: int = TargetRules.NONE
## Contadores para o visual (sobem a cada golpe dos Espinhos, recast e explosao da Penitencia): a
## recarga do Q nao sobe no golpe, entao o HeroVisual nao o veria pelos cooldowns.
var q_casts: int = 0
var recasts: int = 0
var blasts: int = 0

## Toque de Q e de E neste tick (derivado do input e do estado no _simulate_effects; fora do
## estado).
var _q_tap: bool = false
var _e_tap: bool = false


func _extra_state_properties() -> Array[String]:
	var props := super()
	(
		props
		. append_array(
			[
				":pain",
				":pain_ticks",
				":q_window_ticks",
				":q_held",
				":e_held",
				":penance_ticks",
				":penance_healed",
				":light_ticks",
				":light_at",
				":light_target",
				":q_casts",
				":recasts",
				":blasts",
			]
		)
	)
	return props


## Canalizando a Penitencia: imovel, mitiga e o HeroVisual mostra o laco dela.
func is_channeling() -> bool:
	return penance_ticks > 0


## Janela do recast dos Espinhos aberta (HUD e bot).
func can_recast() -> bool:
	return q_window_ticks > 0


## Raio de luz das Correntes ativo (VFX).
func light_on() -> bool:
	return light_ticks > 0


func _taken_factor(hero_basic: bool) -> float:
	var passive: PassiveData = hero_data.passive
	var cuirass := passive.taken_factor if passive != null else 1.0
	return CarrascoRules.taken_factor(
		hero_basic, cuirass, is_channeling(), hero_data.skill_e.mitigation
	)


## Canalizando nao anda (o empurrao ainda move: Hero aplica knockback_velocity direto).
func _move_speed_bonus() -> float:
	return -1.0 if is_channeling() else 0.0


func _flight_speed(kind: Arrow.Kind = Arrow.Kind.BASIC) -> float:
	if kind == Arrow.Kind.CHAINS:
		return hero_data.skill_r.speed
	return hero_data.skill_q.speed


func _flight_radius(kind: Arrow.Kind = Arrow.Kind.BASIC) -> float:
	if kind == Arrow.Kind.CHAINS:
		return hero_data.skill_r.radius
	return hero_data.skill_q.radius


func _kind_speeds() -> Dictionary[int, float]:
	return {
		Arrow.Kind.THORNS: hero_data.skill_q.speed,
		Arrow.Kind.CHAINS: hero_data.skill_r.speed,
	}


func _use_skills(tick: int) -> void:
	if is_channeling():
		if _e_tap:
			_explode(tick)  # E de novo encerra antes
		return  # imovel: sem basico nem outra skill
	var rate := NetworkTime.tickrate
	var data := hero_data
	if CarrascoRules.recasts(q_window_ticks, _q_tap):
		_recast()
	elif (
		input.skill_q
		and q_cooldown == 0
		and q_window_ticks == 0
		and SkillRules.can_use(data.skill_q, ranks.x, level)
	):
		_thorns(tick)
	if input.skill_e and e_cooldown == 0 and SkillRules.can_use(data.skill_e, ranks.y, level):
		e_cooldown = SkillRules.cooldown_ticks(data.skill_e, ranks.y, attributes.intelligence, rate)
		penance_ticks = _penance_total()
		penance_healed = 0
		return  # comecou a canalizar: nada mais neste tick
	if input.skill_r and r_cooldown == 0 and SkillRules.can_use(data.skill_r, ranks.z, level):
		r_cooldown = SkillRules.cooldown_ticks(data.skill_r, ranks.z, attributes.intelligence, rate)
		var damage := roundi(SkillRules.amount(data.skill_r, ranks.z, attributes))
		_shoot(Arrow.Kind.CHAINS, data.skill_r.distance, damage)
	if attack_now and basic_cooldown == 0:
		basic_cooldown = SkillRules.seconds_to_ticks(attributes.attack_interval, rate)
		_gain_pain(_arc_count())
		_melee(tick)


func _simulate_effects(tick: int) -> void:
	_q_tap = CarrascoRules.pressed(input.skill_q, q_held)
	_e_tap = CarrascoRules.pressed(input.skill_e, e_held)
	q_held = input.skill_q
	e_held = input.skill_e
	_count_recast_window()
	if is_channeling():
		_channel(tick)
	elif pain_ticks > 0:
		pain_ticks -= 1
		if pain_ticks == 0:
			pain = 0
	_enemies_into(_targets)
	_judge(tick)
	if _arrows_flying():
		_advance_arrows(tick)


func _die(effect: HitEffect) -> void:
	super(effect)
	if q_window_ticks > 0:
		_start_q_cooldown()  # a janela acaba com a morte
	q_window_ticks = 0
	penance_ticks = 0
	penance_healed = 0
	pain = 0
	pain_ticks = 0


## Espinhos, 1o toque: golpe em cone (dano e lentidao em todos os atingidos) e abre a janela do
## recast. A recarga ainda nao conta: revela no mato aqui (VisibilityRules.acted ve recargas).
func _thorns(tick: int) -> void:
	var q := hero_data.skill_q
	var rate := NetworkTime.tickrate
	q_window_ticks = SkillRules.seconds_to_ticks(q.recast_window, rate)
	q_casts += 1
	reveal_ticks = VisibilityRules.reveal_ticks(match_rules, rate)
	if not multiplayer.is_server():
		return
	var damage := roundi(SkillRules.amount(q, ranks.x, attributes))
	var half_arc := q.arc_degrees / 2.0
	for other: Combatant in _enemies():
		if CombatRules.is_in_melee_arc(
			global_position, forward(), other.global_position, q.attack_range, half_arc
		):
			var effect := _direct(HitEffect.new(damage, global_position))
			_slow(effect, q.slow, q.slow_duration)
			_hit(other, tick, HitLedger.Slot.Q, effect)
		else:
			_miss(other, tick, HitLedger.Slot.Q)


## Espinhos, recast: projetil que para no 1o alvo (sem lentidao) e fecha a janela; a recarga conta.
func _recast() -> void:
	var q := hero_data.skill_q
	var damage := roundi(
		SkillData.at_rank(q.recast_amount, ranks.x) + q.recast_attack_ratio * attributes.attack
	)
	_shoot(Arrow.Kind.THORNS, q.distance, damage)
	q_window_ticks = 0
	recasts += 1
	_start_q_cooldown()


func _start_q_cooldown() -> void:
	q_cooldown = SkillRules.cooldown_ticks(
		hero_data.skill_q, ranks.x, attributes.intelligence, NetworkTime.tickrate
	)


## Janela do recast corre; acabou sem recast = a recarga do Q comeca.
func _count_recast_window() -> void:
	if q_window_ticks == 0:
		return
	q_window_ticks -= 1
	if q_window_ticks == 0:
		_start_q_cooldown()


## Um tick da Penitencia: atordoado cancela sem explodir (a cura dada fica); senao soma Dor no
## pulso, da a fatia da cura e, no ultimo tick, explode.
func _channel(tick: int) -> void:
	if not is_alive() or stun_ticks > 0:
		penance_ticks = 0
		penance_healed = 0
		return
	var e := hero_data.skill_e
	var total_ticks := _penance_total()
	var elapsed := total_ticks - penance_ticks + 1
	penance_ticks -= 1
	var interval := SkillRules.seconds_to_ticks(e.pulse_interval, NetworkTime.tickrate)
	if CarrascoRules.is_pain_pulse(elapsed, interval):
		_gain_pain(1)
	var total := CarrascoRules.with_pain(
		SkillData.at_rank(e.heal_amount, ranks.y),
		e.heal_attack_ratio,
		attributes.attack,
		e.per_pain,
		pain
	)
	var slice := maxi(CarrascoRules.heal_due(total, elapsed, total_ticks) - penance_healed, 0)
	penance_healed += slice
	hp = mini(hp + slice, attributes.max_hp)
	if penance_ticks == 0:
		_explode(tick)


## Fim da Penitencia: fere quem esta no raio (raiz com Dor suficiente, senao lentidao) e consome a
## Dor.
func _explode(tick: int) -> void:
	var e := hero_data.skill_e
	if multiplayer.is_server():
		var damage := CarrascoRules.with_pain(
			SkillData.at_rank(e.base_amount, ranks.y),
			e.attack_ratio,
			attributes.attack,
			e.per_pain,
			pain
		)
		var roots := CarrascoRules.explosion_roots(pain, e.root_min_pain)
		_enemies_into(_targets)
		for other: Combatant in _targets:
			if CombatRules.in_radius(global_position, other.global_position, e.radius):
				var effect := HitEffect.new(damage, global_position)
				if roots:
					_slow(effect, 1.0, e.root_duration)
				else:
					_slow(effect, e.slow, e.slow_duration)
				_hit(other, tick, HitLedger.Slot.E, effect)
			else:
				_miss(other, tick, HitLedger.Slot.E)
	penance_ticks = 0
	penance_healed = 0
	pain = 0
	pain_ticks = 0
	blasts += 1


## Servidor: o heroi preso na luz das Correntes, dentro dela, e marcado para execucao no tick
## seguinte (Hero._apply_effect decide pelo HP dele); fora dela, a marca sai.
func _judge(tick: int) -> void:
	if light_ticks == 0:
		return
	light_ticks -= 1
	if not multiplayer.is_server():
		return
	var r := hero_data.skill_r
	for other: Combatant in _targets:
		if other.combat_id() != light_target:
			continue
		var source := HitLedger.source_key(peer_id, HitLedger.Slot.PASSIVE)
		if (
			light_ticks > 0
			and CombatRules.in_radius(light_at, other.global_position, r.light_radius)
		):
			var effect := HitEffect.new(0, light_at)
			effect.attacker_id = peer_id
			effect.execute_below = r.execute_hp_ratio
			other.receive_hit(tick + 1, source, effect)
			NetworkRollback.mutate(other, tick + 1)
		else:
			other.cancel_hit(tick + 1, source)


## Espinhos (recast) param no 1o alvo, sem lentidao; as Correntes passam por monstro e servo e param
## no 1o heroi: dano, raiz e a luz no ponto do acerto (nos dois lados: o VFX le o estado).
func _arrow_struck(arrow: Arrow, other: Combatant, at: Vector3, tick: int) -> bool:
	if arrow.kind == Arrow.Kind.CHAINS:
		if not other is Hero:
			return false
		var r := hero_data.skill_r
		var duration := SkillData.at_rank(r.duration, ranks.z)
		light_ticks = SkillRules.seconds_to_ticks(duration, NetworkTime.tickrate)
		light_at = Vector3(other.global_position.x, global_position.y, other.global_position.z)
		light_target = other.combat_id()
		if multiplayer.is_server():
			var effect := HitEffect.new(arrow.damage, at)
			_slow(effect, 1.0, duration)
			_hit(other, tick, HitLedger.Slot.R, effect)
			zone_started.emit(Zone.LIGHT, light_at, tick)
		return true
	if multiplayer.is_server():
		_struck_q.append(other)
		_hit(other, tick, HitLedger.Slot.Q, HitEffect.new(arrow.damage, at))
	return true


## Lentidao (raiz = 1.0) de [param seconds]; um tick a mais: o alvo aplica e desconta no mesmo
## _rollback_tick.
func _slow(effect: HitEffect, pct: float, seconds: float) -> void:
	effect.slow = pct
	effect.slow_ticks = 1 + SkillRules.seconds_to_ticks(seconds, NetworkTime.tickrate)


func _gain_pain(gain: int) -> void:
	var passive: PassiveData = hero_data.passive
	if passive == null or gain <= 0:
		return
	pain = CarrascoRules.gain_pain(pain, gain, passive.pain_max)
	pain_ticks = SkillRules.seconds_to_ticks(passive.pain_seconds, NetworkTime.tickrate)


## Alvos no arco do basico (heroi, servo e monstro vivos): conta nos dois lados pela geometria, como
## o roubo de vida do Berserker, para o cliente prever a Dor.
func _arc_count() -> int:
	var basic := hero_data.basic_attack
	var half_arc := basic.arc_degrees / 2.0
	var count := 0
	_enemies_into(_targets)
	for other: Combatant in _targets:
		if CombatRules.is_in_melee_arc(
			global_position, forward(), other.global_position, basic.attack_range, half_arc
		):
			count += 1
	return count


func _penance_total() -> int:
	return SkillRules.seconds_to_ticks(
		SkillData.at_rank(hero_data.skill_e.duration, ranks.y), NetworkTime.tickrate
	)
