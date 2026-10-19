class_name Paladin
extends Hero
## Paladino Radiante (GDB §4.9, F76, SPEC-076): tanque reativo. Basico Maca (arco do paladin.tres,
## Hero._melee); Q Golpe Consagrado (1o heroi, servo ou monstro na faixa a frente: dano e
## atordoamento, chefe so o dano); E Retribuicao (por duration, golpe direto recebido de ate
## attack_range volta ao atacante pelo ledger dele, ADR-0001); R Bencao Inviolavel (cura com teto e
## imunidade a todo dano — Hero.invuln_ticks, que ja barra a zona —; controle continua valendo).
## Numeros de paladin.tres. No 1x1 Retribuicao e Bencao valem so nele (aliados no 2x2: fora).

# Estado de rollback.
## Ticks restantes da Retribuicao.
var retribution_ticks: int = 0
## Ticks restantes da Bencao (visual; quem barra o dano e invuln_ticks).
var blessing_ticks: int = 0

## Servidor: dano bruto a devolver no tick, combat_id do atacante -> dano. Refeito a cada
## _apply_hits, entao ressimular o tick devolve o mesmo (o ledger do atacante sobrescreve).
var _reflections: Dictionary[int, int] = {}
## Ultimo atacante achado (cache proprio: o do alvo travado, Hero._lookup_target, fica intacto).
var _striker_cache: Combatant


func _extra_state_properties() -> Array[String]:
	var props := super()
	props.append_array([":retribution_ticks", ":blessing_ticks"])
	return props


func is_retributing() -> bool:
	return retribution_ticks > 0


func is_blessed() -> bool:
	return blessing_ticks > 0


func _use_skills(tick: int) -> void:
	var rate := NetworkTime.tickrate
	var data := hero_data
	if input.skill_q and q_cooldown == 0 and SkillRules.can_use(data.skill_q, ranks.x, level):
		q_cooldown = SkillRules.cooldown_ticks(data.skill_q, ranks.x, attributes.intelligence, rate)
		_consecrated_strike(tick)
	if input.skill_e and e_cooldown == 0 and SkillRules.can_use(data.skill_e, ranks.y, level):
		e_cooldown = SkillRules.cooldown_ticks(data.skill_e, ranks.y, attributes.intelligence, rate)
		var duration := SkillData.at_rank(data.skill_e.duration, ranks.y)
		retribution_ticks = SkillRules.seconds_to_ticks(duration, rate)
	if input.skill_r and r_cooldown == 0 and SkillRules.can_use(data.skill_r, ranks.z, level):
		r_cooldown = SkillRules.cooldown_ticks(data.skill_r, ranks.z, attributes.intelligence, rate)
		_blessing()
	if attack_now and basic_cooldown == 0:
		basic_cooldown = SkillRules.seconds_to_ticks(attributes.attack_interval, rate)
		_melee(tick)


func _simulate_effects(_tick: int) -> void:
	retribution_ticks = maxi(retribution_ticks - 1, 0)
	blessing_ticks = maxi(blessing_ticks - 1, 0)


func _die(effect: HitEffect) -> void:
	super(effect)
	retribution_ticks = 0
	blessing_ticks = 0


## So o 1o alvo da faixa toma o golpe; os outros, se acertados numa simulacao anterior, saem.
func _consecrated_strike(tick: int) -> void:
	if not multiplayer.is_server():
		return
	var q := hero_data.skill_q
	var enemies := _enemies()
	var points := PackedVector3Array()
	for other: Combatant in enemies:
		points.append(other.global_position)
	var first := PaladinRules.first_in_strip(
		global_position, forward(), points, q.attack_range, q.strip_width
	)
	var damage := roundi(SkillRules.amount(q, ranks.x, attributes))
	# Um tick a mais: o alvo aplica o golpe e desconta o tick no mesmo _rollback_tick.
	var stun := (
		1
		+ SkillRules.seconds_to_ticks(
			SkillData.at_rank(q.stun_duration, ranks.x), NetworkTime.tickrate
		)
	)
	for i: int in enemies.size():
		var other := enemies[i]
		if i != first:
			_miss(other, tick, HitLedger.Slot.Q)
			continue
		var effect := _direct(HitEffect.new(damage, global_position))
		if PaladinRules.stuns(_is_boss(other)):
			effect.stun_ticks = stun
		_hit(other, tick, HitLedger.Slot.Q, effect)


## Cura com teto no HP maximo e imunidade a dano por duration (a zona inclusive).
func _blessing() -> void:
	var r := hero_data.skill_r
	hp = mini(hp + roundi(SkillRules.amount(r, ranks.z, attributes)), attributes.max_hp)
	var ticks := SkillRules.seconds_to_ticks(
		SkillData.at_rank(r.duration, ranks.z), NetworkTime.tickrate
	)
	invuln_ticks = maxi(invuln_ticks, ticks)
	blessing_ticks = ticks


func _apply_hits(tick: int) -> void:
	_reflections.clear()
	super(tick)
	for striker_id: int in _reflections:
		var striker := _striker(striker_id)
		if striker == null or not striker.is_alive():
			continue
		var effect := HitEffect.new(_reflections[striker_id], global_position)
		_hit(striker, tick, HitLedger.Slot.E, effect)


## Mede o dano tomado depois da DEF (0 imune: so o que tomou volta, PI 2026-10-19) e, com a
## Retribuicao, guarda o que volta. O golpe que mata o Paladino nao volta (morto nao retribui).
func _apply_effect(effect: HitEffect, tick: int, blockable: bool = true) -> int:
	var taken := 0 if invuln_ticks > 0 else CombatRules.mitigated(effect.damage, _defense())
	var heal := super(effect, tick, blockable)
	var e := hero_data.skill_e
	var flat := effect.source - global_position
	flat.y = 0.0
	var direct := effect.striker_id != TargetRules.NONE
	if PaladinRules.reflects(
		is_retributing() and is_alive(), direct, flat.length(), e.attack_range
	):
		var amount := PaladinRules.reflected_damage(
			taken, SkillData.at_rank(e.reflect_ratio, ranks.y), attributes.attack, e.attack_ratio
		)
		_reflections[effect.striker_id] = _reflections.get(effect.striker_id, 0) + amount
	return heal


# ponytail: percorre o grupo so quando o atacante muda; cacheia o ultimo achado.
func _striker(id: int) -> Combatant:
	if is_instance_valid(_striker_cache) and _striker_cache.combat_id() == id:
		return _striker_cache
	for node: Node in get_tree().get_nodes_in_group(TARGETS_GROUP):
		var other := node as Combatant
		if other.combat_id() == id:
			_striker_cache = other
			return other
	return null
