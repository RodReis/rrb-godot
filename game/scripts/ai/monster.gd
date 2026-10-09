class_name Monster
extends Combatant
## Monstro da fase 1 (GDB §5.1), inclusive o Rei Esqueleto (F11: so dados e cena mudam). IA so
## no servidor, a cada tick (MonsterRules); posicao, HP e golpe replicados por StateSynchronizer + TickInterpolator, fora do rollback. Golpe no heroi
## vai para o ledger dele; golpe de heroi entra aqui na hora, uma vez por tick + fonte. Ao
## morrer da o XP ao matador (com catch-up, GDB §3.3). Nao respawna (GDB §5).

## Servidor apenas. [param killer_id] = peer_id de quem deu o golpe final.
signal died(killer_id: int)

const GROUP: StringName = &"monsters"

@export var data: MonsterData

## Definido pelo SpawnDirector: negativo, para a chave do ledger nao colidir com peer_id.
var uid: int = 0

# Estado replicado.
var hp: int = 0
var attack_cooldown: int = 0

var state: MonsterRules.State = MonsterRules.State.IDLE
var _home: Vector3 = Vector3.ZERO
var _stun_ticks: int = 0
var _target: Hero
var _seen: HitLedger = HitLedger.new()  # golpes ja aplicados: ressimular o heroi nao duplica

@onready var hp_label: Label3D = $HpLabel


func _ready() -> void:
	add_to_group(GROUP)
	hp = roundi(data.hp)
	_home = global_position
	axis_lock_linear_y = true

	var sync := StateSynchronizer.new()
	sync.name = "StateSynchronizer"
	sync.root = self
	sync.properties = [":transform", ":velocity", ":hp", ":attack_cooldown"]
	add_child(sync)

	var interpolator := TickInterpolator.new()
	interpolator.name = "TickInterpolator"
	interpolator.root = self
	interpolator.properties = [":transform"]
	add_child(interpolator)

	NetworkTime.on_tick.connect(_on_network_tick)


func _process(_delta: float) -> void:
	hp_label.visible = is_alive()
	hp_label.text = "%s %d / %d" % [data.display_name, hp, roundi(data.hp)]


func is_alive() -> bool:
	return hp > 0


## Servidor apenas. Ressimular o heroi repete o golpe com o mesmo tick + fonte: ignorado.
func receive_hit(tick: int, source: int, effect: HitEffect) -> void:
	if not is_alive() or _seen.has_hit(tick, source):
		return
	_seen.set_hit(tick, source, effect)
	_seen.trim_before(tick - NetworkRollback.history_limit)
	hp = maxi(hp - effect.damage, 0)
	if not effect.push.is_zero_approx():
		move_and_collide(effect.push)
	_stun_ticks = maxi(_stun_ticks, effect.stun_ticks)
	if not is_alive():
		_die(tick, effect.attacker_id)


# ponytail: golpe ja aplicado nao e desfeito se a ressimulacao do heroi errar; raro (input
# atrasado no servidor) e o servidor segue autoritativo.
func cancel_hit(_tick: int, _source: int) -> void:
	pass


## IA so no servidor (no _ready o peer ainda e offline e is_server() mente).
func _on_network_tick(_delta: float, tick: int) -> void:
	if not multiplayer.is_server() or not is_alive():
		return
	attack_cooldown = maxi(attack_cooldown - 1, 0)
	_stun_ticks = maxi(_stun_ticks - 1, 0)
	if _stun_ticks > 0:
		velocity = Vector3.ZERO
		return
	if state == MonsterRules.State.IDLE or not is_instance_valid(_target):
		_target = _nearest_hero()
	var target_dist := INF if _target == null else _flat_distance(_target.global_position)
	var next := MonsterRules.next_state(state, data, target_dist, _flat_distance(_home))
	if next == MonsterRules.State.RESET and state != MonsterRules.State.RESET:
		hp = roundi(data.hp)  # leash: volta com HP cheio (PI 2026-10-09)
		_target = null
	state = next
	match state:
		MonsterRules.State.CHASE:
			_chase(tick, target_dist)
		MonsterRules.State.RESET:
			_walk_to(_home)
		_:
			velocity = Vector3.ZERO
	velocity *= NetworkTime.physics_factor
	move_and_slide()
	velocity /= NetworkTime.physics_factor


func _chase(tick: int, target_dist: float) -> void:
	if target_dist > MonsterRules.attack_reach(data):
		_walk_to(_target.global_position)
		return
	velocity = Vector3.ZERO
	_face(_target.global_position)
	if attack_cooldown == 0:
		attack_cooldown = SkillRules.seconds_to_ticks(data.attack_interval, NetworkTime.tickrate)
		_attack(tick)


## O heroi aplica no proprio _rollback_tick de tick+1 (ARCHITECTURE-GAME §3.2). Empurrao
## (knockback) para longe do monstro.
func _attack(tick: int) -> void:
	var source := HitLedger.source_key(uid, HitLedger.Slot.BASIC)
	if not data.area_attack:
		_target.receive_hit(tick + 1, source, _effect_on(_target))
		return
	for node: Node in get_tree().get_nodes_in_group(Hero.GROUP):
		var hero := node as Hero
		if CombatRules.in_radius(global_position, hero.global_position, data.area_radius):
			hero.receive_hit(tick + 1, source, _effect_on(hero))


func _effect_on(hero: Hero) -> HitEffect:
	var away := hero.global_position - global_position
	away.y = 0.0
	var push := CombatRules.push_vector(away.normalized(), data.knockback)
	return HitEffect.new(roundi(data.damage), global_position, push)


## XP de monstro com catch-up contra o heroi do outro time de maior nivel.
func _die(tick: int, killer_id: int) -> void:
	state = MonsterRules.State.IDLE
	velocity = Vector3.ZERO
	collision_mask = 0
	died.emit(killer_id)
	var heroes := get_tree().get_nodes_in_group(Hero.GROUP)
	var killer: Hero = null
	for node: Node in heroes:
		if (node as Hero).peer_id == killer_id:
			killer = node as Hero
	if killer == null:
		return
	var opponent_level := killer.level
	for node: Node in heroes:
		var hero := node as Hero
		if hero.team != killer.team:
			opponent_level = maxi(opponent_level, hero.level)
	var reward := HitEffect.new()
	reward.xp = XpTable.monster_xp(killer.xp_curve, data.xp, killer.level, opponent_level)
	killer.receive_hit(tick, HitLedger.source_key(uid, HitLedger.Slot.REWARD), reward)


func _nearest_hero() -> Hero:
	var best: Hero = null
	var best_dist := data.aggro_range
	for node: Node in get_tree().get_nodes_in_group(Hero.GROUP):
		var hero := node as Hero
		var dist := _flat_distance(hero.global_position)
		if dist <= best_dist:
			best = hero
			best_dist = dist
	return best


func _walk_to(point: Vector3) -> void:
	var to := point - global_position
	to.y = 0.0
	velocity = to.normalized() * data.move_speed if not to.is_zero_approx() else Vector3.ZERO
	_face(point)


func _face(point: Vector3) -> void:
	var to := point - global_position
	to.y = 0.0
	if not to.is_zero_approx():
		look_at(global_position + to, Vector3.UP)


func _flat_distance(point: Vector3) -> float:
	var to := point - global_position
	to.y = 0.0
	return to.length()
