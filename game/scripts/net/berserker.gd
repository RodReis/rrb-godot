class_name Berserker
extends ProjectileHero
## Berserker (GDB §4.8, F75, SPEC-075): passiva Frenesi (§2.2-E: velocidade de ataque e roubo de
## vida do basico sobem com o HP perdido, f = 1 no Ragnarok); basico Machados Gemeos (arco do
## berserker.tres, alterna a mao so no visual); Q Arremesso de Machado (projetil do pool que para
## no 1o heroi ou monstro: dano e lentidao); E Grito de Guerra (DEF e velocidade por duration); R
## Ragnarok (imune a controle por duration — Hero.cc_immune_ticks —, limpa o controle ativo,
## velocidade e Frenesi no maximo). Numeros de berserker.tres; dano e lentidao pelo ledger do alvo
## (Hero._hit); o roubo de vida pelo ledger do proprio Berserker (slot PASSIVE), como qualquer cura.

## Tempo em que o machado arremessado some da mao (so visual; SPEC-075 §Kit).
const AXE_OUT_SECONDS: float = 1.0

# Estado de rollback.
## Ticks restantes do Grito de Guerra.
var shout_ticks: int = 0
## Mao do proximo golpe do basico (visual): alterna a cada golpe.
var swing_left: bool = false
## Ticks em que um machado esta fora da mao depois do Q (visual).
var axe_out_ticks: int = 0


func _extra_state_properties() -> Array[String]:
	var props := super()
	props.append_array([":shout_ticks", ":swing_left", ":axe_out_ticks"])
	return props


## f do Frenesi agora (0..1): 1 no Ragnarok; morto, 0. Sai do estado (HP), entao vale no cliente.
func frenzy() -> float:
	var passive: PassiveData = hero_data.passive
	if passive == null or not is_alive():
		return 0.0
	if is_raging():
		return 1.0
	return BerserkerRules.frenzy(hp, attributes.max_hp, passive.full_at_hp_ratio)


func is_raging() -> bool:
	return cc_immune_ticks > 0


func is_shouting() -> bool:
	return shout_ticks > 0


func _defense_bonus() -> float:
	if shout_ticks == 0:
		return 0.0
	return SkillData.at_rank(hero_data.skill_e.base_amount, ranks.y)


func _move_speed_bonus() -> float:
	var bonus := 0.0
	if shout_ticks > 0:
		bonus += hero_data.skill_e.move_speed_bonus
	if is_raging():
		bonus += hero_data.skill_r.move_speed_bonus
	return bonus


func _flight_speed(_kind: Arrow.Kind = Arrow.Kind.BASIC) -> float:
	return hero_data.skill_q.speed


func _flight_radius(_kind: Arrow.Kind = Arrow.Kind.BASIC) -> float:
	return hero_data.skill_q.radius


func _use_skills(tick: int) -> void:
	var rate := NetworkTime.tickrate
	var data := hero_data
	if input.skill_q and q_cooldown == 0 and SkillRules.can_use(data.skill_q, ranks.x, level):
		q_cooldown = SkillRules.cooldown_ticks(data.skill_q, ranks.x, attributes.intelligence, rate)
		var damage := roundi(SkillRules.amount(data.skill_q, ranks.x, attributes))
		_shoot(Arrow.Kind.AXE, data.skill_q.attack_range, damage)
		axe_out_ticks = SkillRules.seconds_to_ticks(AXE_OUT_SECONDS, rate)
	if input.skill_e and e_cooldown == 0 and SkillRules.can_use(data.skill_e, ranks.y, level):
		e_cooldown = SkillRules.cooldown_ticks(data.skill_e, ranks.y, attributes.intelligence, rate)
		shout_ticks = SkillRules.seconds_to_ticks(
			SkillData.at_rank(data.skill_e.duration, ranks.y), rate
		)
	if input.skill_r and r_cooldown == 0 and SkillRules.can_use(data.skill_r, ranks.z, level):
		r_cooldown = SkillRules.cooldown_ticks(data.skill_r, ranks.z, attributes.intelligence, rate)
		_ragnarok()
	if attack_now and basic_cooldown == 0:
		var interval := attributes.attack_interval
		if data.passive != null:
			interval = BerserkerRules.attack_interval(
				interval, frenzy(), data.passive.attack_speed_bonus
			)
		basic_cooldown = SkillRules.seconds_to_ticks(interval, rate)
		swing_left = not swing_left
		_twin_axes(tick)


func _simulate_effects(tick: int) -> void:
	shout_ticks = maxi(shout_ticks - 1, 0)
	axe_out_ticks = maxi(axe_out_ticks - 1, 0)
	if not is_alive():
		shout_ticks = 0
	if not _arrows_flying():
		return
	_enemies_into(_targets)
	_advance_arrows(tick)


## O machado para no 1o toque: dano e lentidao (heroi, monstro e chefe).
func _arrow_struck(arrow: Arrow, other: Combatant, at: Vector3, tick: int) -> bool:
	if not multiplayer.is_server():
		return true
	var q := hero_data.skill_q
	var effect := HitEffect.new(arrow.damage, at)
	effect.slow = q.slow
	# Um tick a mais: o alvo aplica o golpe e desconta o tick no mesmo _rollback_tick (como a raiz).
	effect.slow_ticks = (
		1
		+ SkillRules.seconds_to_ticks(SkillData.at_rank(q.duration, ranks.x), NetworkTime.tickrate)
	)
	_struck_q.append(other)
	_hit(other, tick, HitLedger.Slot.Q, effect)
	return true


## Imune a controle por duration; o controle ja ativo sai agora.
func _ragnarok() -> void:
	var r := hero_data.skill_r
	cc_immune_ticks = SkillRules.seconds_to_ticks(
		SkillData.at_rank(r.duration, ranks.z), NetworkTime.tickrate
	)
	stun_ticks = 0
	slow_ticks = 0
	slow_pct = 0.0
	knockback_ticks = 0
	knockback_velocity = Vector3.ZERO


## Basico no arco do berserker.tres (Hero._melee) e, no servidor, o roubo de vida do Frenesi. O
## roubo e medido antes do golpe: o monstro tira o HP na hora (Monster.receive_hit), entao
## depois o golpe que o mata ja nao "causaria" nada.
func _twin_axes(tick: int) -> void:
	var passive: PassiveData = hero_data.passive
	if multiplayer.is_server() and passive != null:
		_steal_life(tick, passive)
	_melee(tick)


## Cura do Frenesi sobre o dano que cada golpe do arco causa depois da DEF, pelo ledger do proprio
## Berserker no tick seguinte (como o golpe nos alvos).
# ponytail: ressimular o mesmo tick nunca encolhe a cura ja gravada (o monstro ja tomou o golpe e o
# recalculo sairia menor); o alvo heroi que sai do arco na ressimulacao deixa a cura antiga, como o
# golpe no monstro que nao se desfaz. Guardar o dano real por (tick, fonte) se isso pesar.
func _steal_life(tick: int, passive: PassiveData) -> void:
	var basic := hero_data.basic_attack
	var damage := roundi(SkillRules.amount(basic, 1, attributes))
	var half_arc := basic.arc_degrees / 2.0
	var dealt := 0
	_enemies_into(_targets)
	for other: Combatant in _targets:
		if CombatRules.is_in_melee_arc(
			global_position, forward(), other.global_position, basic.attack_range, half_arc
		):
			dealt += other.effective_damage(damage)
	var source := HitLedger.source_key(peer_id, HitLedger.Slot.PASSIVE)
	var heal: int = BerserkerRules.lifesteal_heal(dealt, frenzy(), passive.lifesteal)
	var recorded := _hits.get_hit(tick + 1, source)
	if heal <= 0 or (recorded != null and recorded.heal >= heal):
		return
	var effect := HitEffect.new()
	effect.heal = heal
	_hits.set_hit(tick + 1, source, effect)
