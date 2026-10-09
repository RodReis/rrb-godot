class_name Hero
extends Combatant
## Heroi autoritativo no servidor, generico: atributos e habilidades vem de HeroData
## (GDB §4) e do nivel; nenhum numero de balanceamento aqui. O node se chama str(peer_id).
## Efeito sobre outro heroi (dano, empurrao, atordoamento, XP de abate) vai para o ledger do
## alvo, que o aplica no proprio _rollback_tick (ARCHITECTURE-GAME §3.2); monstro aplica o
## golpe na hora (Monster). Nivel = XP pela curva (GDB §3.2); pontos gastos por input (F9).
## Habilidades do Cavaleiro (F8): Q Investida, E Muralha, R Terremoto.

const GROUP: StringName = &"heroes"
## Contato da Investida = soma dos raios das capsulas (geometria, nao balanceamento).
const CHARGE_REACH: float = 0.8

@export var hero_data: HeroData
@export var xp_curve: XpCurve

## Definido por quem spawna, antes de entrar na arvore (MultiplayerSpawner). Nivel inicial
## (--level de dev); depois o nivel sai do XP.
var level: int = LaunchArgs.DEFAULT_LEVEL
var peer_id: int = 0
var attributes: HeroAttributes

# Estado de rollback.
var xp: int = 0
## Ranks de Q, E e R (indice SkillRules.SLOT_*).
var ranks: Vector3i = Vector3i.ZERO
var hp: int = 0
var shield_hp: int = 0
var shield_ticks: int = 0
var stun_ticks: int = 0
var dash_ticks: int = 0
var dash_direction: Vector3 = Vector3.ZERO
var basic_cooldown: int = 0
var q_cooldown: int = 0
var e_cooldown: int = 0
var r_cooldown: int = 0

var _rollback: RollbackSynchronizer
var _hits: HitLedger = HitLedger.new()  # so no servidor; fora do estado de rollback

@onready var input: PlayerInput = $Input
@onready var hp_label: Label3D = $HpLabel
@onready var _shield_blocker: Area3D = $ShieldBlocker


func _ready() -> void:
	peer_id = name.to_int()
	add_to_group(GROUP)
	level = clampi(level, LaunchArgs.DEFAULT_LEVEL, XpTable.max_level(xp_curve))
	xp = XpTable.xp_for_level(xp_curve, level)
	attributes = Stats.attributes(hero_data, level, [], [])
	ranks = XpTable.typical_ranks(xp_curve, level)
	hp = attributes.max_hp
	set_multiplayer_authority(1)
	input.set_multiplayer_authority(peer_id)

	# Heroi planar (#41): perto de muro a despenetracao mexia no y e o encaixe no chao do
	# move_and_slide() passava a depender de is_on_floor() do tick anterior, que fica fora do
	# rollback; servidor e cliente divergiam. Com y travado o encaixe nao tem o que mover.
	axis_lock_linear_y = true

	_rollback = RollbackSynchronizer.new()
	_rollback.name = "RollbackSynchronizer"
	_rollback.root = self
	_rollback.state_properties = [
		":transform",
		":xp",
		":ranks",
		":velocity",
		":hp",
		":shield_hp",
		":shield_ticks",
		":stun_ticks",
		":dash_ticks",
		":dash_direction",
		":basic_cooldown",
		":q_cooldown",
		":e_cooldown",
		":r_cooldown",
	]
	_rollback.input_properties = [
		"Input:movement",
		"Input:aim",
		"Input:attack",
		"Input:skill_q",
		"Input:skill_e",
		"Input:skill_r",
		"Input:learn",
	]
	_rollback.enable_input_broadcast = false
	add_child(_rollback)

	var interpolator := TickInterpolator.new()
	interpolator.name = "TickInterpolator"
	interpolator.root = self
	interpolator.properties = [":transform"]
	add_child(interpolator)

	_rollback.process_settings()


func _rollback_tick(_delta: float, tick: int, _is_fresh: bool) -> void:
	if multiplayer.is_server() and not _hits.is_empty():
		_apply_hits(tick)
	_refresh_level()
	_learn()
	_tick_timers()

	# Input vem do cliente: nunca confiar no valor recebido.
	var movement := InputRules.sanitize_direction(input.movement)
	var aim := InputRules.sanitize_direction(input.aim)
	if stun_ticks > 0:
		velocity = Vector3.ZERO
	elif dash_ticks > 0:
		velocity = dash_direction * hero_data.skill_q.speed
	else:
		if not aim.is_zero_approx():
			look_at(global_position + aim, Vector3.UP)
		velocity = movement * attributes.move_speed
	velocity *= NetworkTime.physics_factor
	move_and_slide()
	velocity /= NetworkTime.physics_factor
	_shield_blocker.collision_layer = PhysicsLayers.SHIELD if shield_ticks > 0 else 0

	if stun_ticks > 0:
		return
	if dash_ticks > 0:
		_charge_contact(tick)
		return
	_use_skills(tick)


func _process(_delta: float) -> void:
	_refresh_level()
	var status := " +%d" % shield_hp if shield_ticks > 0 else ""
	if stun_ticks > 0:
		status += " (atordoado)"
	var points := SkillRules.free_points(level, ranks)
	var learn := "  +%d (Ctrl+Q/E/R)" % points if points > 0 else ""
	hp_label.text = "Nv %d  %d XP%s\n%d / %d%s" % [level, xp, learn, hp, attributes.max_hp, status]


func receive_hit(tick: int, source: int, effect: HitEffect) -> void:
	_hits.set_hit(tick, source, effect)


func cancel_hit(tick: int, source: int) -> void:
	_hits.clear_hit(tick, source)


func forward() -> Vector3:
	return -global_transform.basis.z


## Nivel e atributos seguem o XP do estado (inclusive quando o rollback volta o XP).
func _refresh_level() -> void:
	var new_level := XpTable.level_for_xp(xp_curve, xp)
	if new_level != level:
		level = new_level
		attributes = Stats.attributes(hero_data, level, [], [])


## Gasta um ponto no slot pedido pelo input (Ctrl+Q/E/R). Valor do cliente: validado aqui.
func _learn() -> void:
	var slot := input.learn
	if slot < SkillRules.SLOT_Q or slot > SkillRules.SLOT_R:
		return
	var skills: Array[SkillData] = [hero_data.skill_q, hero_data.skill_e, hero_data.skill_r]
	ranks = SkillRules.learn(ranks, slot, skills[slot], level)


func _tick_timers() -> void:
	basic_cooldown = maxi(basic_cooldown - 1, 0)
	q_cooldown = maxi(q_cooldown - 1, 0)
	e_cooldown = maxi(e_cooldown - 1, 0)
	r_cooldown = maxi(r_cooldown - 1, 0)
	stun_ticks = maxi(stun_ticks - 1, 0)
	dash_ticks = maxi(dash_ticks - 1, 0)
	shield_ticks = maxi(shield_ticks - 1, 0)
	if shield_ticks == 0:
		shield_hp = 0


func _use_skills(tick: int) -> void:
	var rate := NetworkTime.tickrate
	var data := hero_data
	if input.skill_q and q_cooldown == 0 and SkillRules.can_use(data.skill_q, ranks.x, level):
		q_cooldown = SkillRules.cooldown_ticks(data.skill_q, ranks.x, attributes.intelligence, rate)
		dash_direction = CombatRules.push_vector(forward(), 1.0)
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


## Heroi do outro time e monstro vivo.
func _enemies() -> Array[Combatant]:
	var result: Array[Combatant] = []
	for node: Node in get_tree().get_nodes_in_group(TARGETS_GROUP):
		var other := node as Combatant
		if other != self and other.team != team and other.is_alive():
			result.append(other)
	return result


## O alvo aplica no proprio _rollback_tick de tick+1, lendo o ledger; ressimular o alvo
## (input dele atrasado) nao apaga o efeito. Servidor apenas: o cliente nunca altera HP.
func _hit(other: Combatant, tick: int, slot: HitLedger.Slot, effect: HitEffect) -> void:
	effect.attacker_id = peer_id
	other.receive_hit(tick + 1, HitLedger.source_key(peer_id, slot), effect)
	# Forca ressimular o alvo a partir de tick+1 se ele ja foi simulado.
	NetworkRollback.mutate(other, tick + 1)


func _miss(other: Combatant, tick: int, slot: HitLedger.Slot) -> void:
	other.cancel_hit(tick + 1, HitLedger.source_key(peer_id, slot))


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


## Investida: para no primeiro inimigo tocado, empurra e fere (PI 2026-10-09).
func _charge_contact(tick: int) -> void:
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


## DEF reduz primeiro; a Muralha absorve o que sobrou se o golpe veio pela frente
## (PI 2026-10-09); o resto vai ao HP. XP so soma (I7).
func _apply_hits(tick: int) -> void:
	for effect: HitEffect in _hits.effects_at(tick):
		xp += maxi(effect.xp, 0)
		var damage := CombatRules.mitigated(effect.damage, attributes.defense)
		if shield_ticks > 0 and CombatRules.is_frontal(global_position, forward(), effect.source):
			var split := CombatRules.absorb(damage, shield_hp)
			damage = split.x
			shield_hp = split.y
		hp = maxi(hp - damage, 0)
		if hp == 0:
			hp = attributes.max_hp  # sem morte ate o respawn (F15): so reinicia o HP
		if not effect.push.is_zero_approx():
			move_and_collide(effect.push)
		stun_ticks = maxi(stun_ticks, effect.stun_ticks)
	_hits.trim_before(tick - NetworkRollback.history_limit)
