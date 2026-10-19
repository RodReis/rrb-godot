class_name Rogue
extends ProjectileHero
## Ladina (GDB §4.5, F58, SPEC-058): basico Virote (projetil do pool que para no 1o alvo); Q Rajada
## em Leque (3 virotes no mesmo tick, abertos pela RogueRules; cada um para no 1o alvo e o mesmo
## alvo pode levar os 3 — os do mesmo tick vao somados num golpe so, porque o ledger guarda um
## efeito por fonte e por tick); E Bomba de Fumaca (nuvem no lugar da Ladina que vale como moita
## para qualquer heroi, Hero.zones_at; lancar nao revela, _reveals_on_e); R Emboscada (avanco que
## para no 1o heroi ou monstro inimigo — pelo caminho do tick, para nao atravessar a 24 u/s — ou no
## obstaculo, e golpeia uma vez com a faca; x1,3 se a Ladina estava oculta no tick do uso). Numeros
## de rogue.tres; dano pelo ledger do alvo (Hero._hit). A nuvem chega ao cliente que nao ve a
## Ladina pelo ImpactRelay (smoked), nao pelo estado dela.

## Servidor: nuvem lancada em [param center] no [param tick] (a ressimulacao repete; o relay
## filtra).
signal smoked(center: Vector3, tick: int)

## Folga do contato da Emboscada alem da soma dos raios dos corpos: a colisao para a capsula um
## pouco antes do toque exato (geometria, nao balanceamento).
const CONTACT_MARGIN: float = 0.05
## Ticks em que o golpe da Emboscada fica marcado (animacao e VFX leem a subida).
const STRIKE_TICKS: int = 6

# Estado de rollback.
## Ticks restantes da nuvem; o centro fica onde foi lancada.
var smoke_ticks: int = 0
var smoke_center: Vector3 = Vector3.ZERO
## O avanco em curso e a Emboscada; a Ladina estava oculta no tick do uso (x1,3).
var ambushing: bool = false
var ambush_hidden: bool = false
## Ticks restantes do golpe da faca (dash_strike_ticks).
var stab_ticks: int = 0

## Reusados no _rollback_tick (sem alocar): dano dos virotes da Rajada por alvo no tick e a ordem
## em que os alvos foram tocados.
var _fan_damage: Dictionary = {}  # Combatant -> int
var _fan_order: Array[Combatant] = []
var _fan_at: Dictionary = {}  # Combatant -> Vector3


func _enter_tree() -> void:
	super()
	_smoke_casters.append(self)


func _exit_tree() -> void:
	_smoke_casters.erase(self)


func smoke_covers(point: Vector3) -> bool:
	return (
		smoke_ticks > 0
		and VisibilityRules.smoke_covers(smoke_center, point, hero_data.skill_e.radius)
	)


func dash_strike_ticks() -> int:
	return stab_ticks


func _extra_state_properties() -> Array[String]:
	var props := super()
	props.append_array(
		[":smoke_ticks", ":smoke_center", ":ambushing", ":ambush_hidden", ":stab_ticks"]
	)
	return props


func _reveals_on_e() -> bool:
	return false


func _use_skills(tick: int) -> void:
	ambushing = false
	var rate := NetworkTime.tickrate
	var data := hero_data
	if input.skill_r and r_cooldown == 0 and SkillRules.can_use(data.skill_r, ranks.z, level):
		r_cooldown = SkillRules.cooldown_ticks(data.skill_r, ranks.z, attributes.intelligence, rate)
		_ambush()
		return
	if input.skill_e and e_cooldown == 0 and SkillRules.can_use(data.skill_e, ranks.y, level):
		e_cooldown = SkillRules.cooldown_ticks(data.skill_e, ranks.y, attributes.intelligence, rate)
		_smoke(tick)
	if input.skill_q and q_cooldown == 0 and SkillRules.can_use(data.skill_q, ranks.x, level):
		q_cooldown = SkillRules.cooldown_ticks(data.skill_q, ranks.x, attributes.intelligence, rate)
		_fan()
	if attack_now and basic_cooldown == 0:
		basic_cooldown = SkillRules.seconds_to_ticks(attributes.attack_interval, rate)
		var basic := data.basic_attack
		_shoot(
			Arrow.Kind.BASIC, basic.attack_range, roundi(SkillRules.amount(basic, 1, attributes))
		)


## Emboscada: o move_and_slide do tick ja andou. Toca o 1o inimigo no caminho do tick (para ali e
## golpeia) ou para no obstaculo. Fim do avanco sem toque = sem golpe.
func _while_dashing(tick: int) -> void:
	if not ambushing:
		return
	var to := global_position
	var from := to - get_position_delta()
	var first: Combatant = null
	var first_t := INF
	_enemies_into(_targets)
	for other: Combatant in _targets:
		var reach := body_radius() + other.body_radius() + CONTACT_MARGIN
		var t := CombatRules.segment_circle_fraction(from, to, other.global_position, reach)
		if t != CombatRules.NO_HIT and t < first_t:
			first = other
			first_t = t
	if multiplayer.is_server():
		for other: Combatant in _targets:
			if other != first:
				_miss(other, tick, HitLedger.Slot.R)
	if first != null:
		global_position = from.lerp(to, first_t)
		_stab(first, tick)
	elif is_on_wall():
		dash_ticks = 0
	if dash_ticks == 0:
		ambushing = false


func _simulate_effects(tick: int) -> void:
	smoke_ticks = maxi(smoke_ticks - 1, 0)
	stab_ticks = maxi(stab_ticks - 1, 0)
	if not _arrows_flying():
		return
	_enemies_into(_targets)
	_fan_order.clear()
	_fan_damage.clear()
	_fan_at.clear()
	_advance_arrows(tick)
	if not multiplayer.is_server():
		return
	for other: Combatant in _fan_order:
		_hit(other, tick, HitLedger.Slot.Q, HitEffect.new(_fan_damage[other], _fan_at[other]))


## Virote do basico fere quem tocou; o da Rajada soma no tick (golpe unico em _simulate_effects).
## Os dois param no 1o toque.
func _arrow_struck(arrow: Arrow, other: Combatant, at: Vector3, tick: int) -> bool:
	if not multiplayer.is_server():
		return true
	if arrow.kind == Arrow.Kind.FAN:
		_struck_q.append(other)
		if not _fan_damage.has(other):
			_fan_order.append(other)
			_fan_damage[other] = 0
			_fan_at[other] = at
		_fan_damage[other] += arrow.damage
	else:
		_struck_basic.append(other)
		_hit(other, tick, HitLedger.Slot.BASIC, HitEffect.new(arrow.damage, at))
	return true


## Rajada em Leque: projectile_count virotes abertos de spread_degrees em volta da mira.
func _fan() -> void:
	var q := hero_data.skill_q
	var damage := roundi(SkillRules.amount(q, ranks.x, attributes))
	for i: int in q.projectile_count:
		var angle := RogueRules.fan_angle(i, q.projectile_count, q.spread_degrees)
		_shoot(Arrow.Kind.FAN, q.attack_range, damage, RogueRules.fan_direction(forward(), angle))


## Bomba de Fumaca: nuvem no lugar da Ladina por duration (a nova substitui a anterior).
func _smoke(tick: int) -> void:
	var e := hero_data.skill_e
	smoke_center = global_position
	smoke_ticks = SkillRules.seconds_to_ticks(
		SkillData.at_rank(e.duration, ranks.y), NetworkTime.tickrate
	)
	if multiplayer.is_server():
		smoked.emit(smoke_center, tick)


## Emboscada na direcao da mira, distance a speed. Oculta = na moita ou na fumaca, sem revelacao
## (escondida de quem esta fora de toda zona), no tick do uso.
func _ambush() -> void:
	var r := hero_data.skill_r
	ambush_hidden = VisibilityRules.is_hidden_in(zones_at(global_position), NO_ZONES, reveal_ticks)
	dash_direction = CombatRules.push_vector(forward(), 1.0)
	dash_speed = r.speed
	dash_ticks = SkillRules.seconds_to_ticks(r.distance / r.speed, NetworkTime.tickrate)
	ambushing = true


func _stab(target: Combatant, tick: int) -> void:
	dash_ticks = 0
	stab_ticks = STRIKE_TICKS
	if not multiplayer.is_server():
		return
	var r := hero_data.skill_r
	var amount := SkillRules.amount(r, ranks.z, attributes)
	var damage := RogueRules.ambush_damage(amount, ambush_hidden, r.ambush_multiplier)
	_hit(target, tick, HitLedger.Slot.R, _direct(HitEffect.new(damage, global_position)))
