class_name Monster
extends Combatant
## Monstro da fase 1 (GDB §5.1), inclusive o Rei Esqueleto (F11: so dados e cena mudam).
## Heroi morto (F15) nao e alvo.
## IA so no servidor, a cada tick (MonsterRules); posicao, HP e golpe replicados por
## StateSynchronizer + TickInterpolator, fora do rollback. Golpe no heroi vai para o ledger
## dele; golpe de heroi entra aqui na hora, uma vez por tick + fonte. Ao morrer da o XP ao
## matador (com catch-up, GDB §3.3). Renasce no mesmo node (revive) quando o SpawnDirector
## manda (fase 1, F36): HP e posicao ja replicam, sem spawn novo. Fora do mapa (present falso):
## o Rei Esqueleto existe desde o inicio, dormente ate 3:30, e sai aos 5:00 se vivo (F20) — nenhum
## monstro nasce nem some da arvore no meio da partida, entao nenhum estado chega antes do node.
## Lentidao (R da Arqueira, PI 2026-10-10): anda mais devagar enquanto dura.
## Mato alto (F32): heroi escondido nao entra no aggro e, se era o alvo, deixa de ser (volta ao
## marcador como quando o alvo morre).
## Neblina de guerra (F37): so e replicado a quem tem o monstro no raio de visao do heroi
## (seen_by, Concealment); no cliente, fora da visao, some e nao tem colisao.

## Servidor apenas. [param killer_id] = peer_id do golpe final; [param tick] = tick da morte.
signal died(killer_id: int, tick: int)

const GROUP: StringName = &"monsters"

@export var data: MonsterData

## Definido pelo SpawnDirector: negativo, para a chave do ledger nao colidir com peer_id.
var uid: int = 0
## Base onde nasceu (GateRules.TEAM_*; NEUTRAL = centro), do marcador. Igual nos dois lados.
var home_team: int = GateRules.TEAM_NEUTRAL

# Estado replicado.
var hp: int = 0
var attack_cooldown: int = 0
## No mapa. Falso: invisivel e sem HP (boss antes de 3:30 e depois de sair aos 5:00). Definido
## pelo SpawnDirector antes de entrar na arvore.
var present: bool = true

var state: MonsterRules.State = MonsterRules.State.IDLE
var _home: Vector3 = Vector3.ZERO
var _home_basis: Basis = Basis.IDENTITY
var _alive_mask: int = 0
## Camada de colisao da cena; no cliente, monstro fora da visao fica sem ela.
var _layer: int = 0
var _concealment: Concealment
var _stun_ticks: int = 0
var _slow_ticks: int = 0
var _slow_pct: float = 0.0
var _target: Hero
var _seen: HitLedger = HitLedger.new()  # golpes ja aplicados: ressimular o heroi nao duplica

@onready var hp_label: Label3D = $HpLabel
@onready var hp_bar: WorldHealthBar = $HpBar


func _ready() -> void:
	add_to_group(GROUP)
	hp = roundi(data.hp) if present else 0
	_home = global_position
	_home_basis = global_basis
	_alive_mask = collision_mask
	_layer = collision_layer
	if not present:
		collision_mask = 0
	axis_lock_linear_y = true

	var sync := StateSynchronizer.new()
	sync.name = "StateSynchronizer"
	sync.root = self
	sync.properties = [":transform", ":velocity", ":hp", ":attack_cooldown", ":present"]
	add_child(sync)
	_concealment = Concealment.guard(self, seen_by, sync)

	var interpolator := TickInterpolator.new()
	interpolator.name = "TickInterpolator"
	interpolator.root = self
	interpolator.properties = [":transform"]
	add_child(interpolator)

	NetworkTime.on_tick.connect(_on_network_tick)


func _process(_delta: float) -> void:
	var shown := _concealment.is_shown()
	visible = shown
	if not multiplayer.is_server():
		collision_layer = _layer if shown else 0
	hp_label.visible = is_alive()
	hp_bar.visible = is_alive()
	hp_label.text = data.display_name
	hp_bar.set_ratio(hp / data.hp)


func is_alive() -> bool:
	return hp > 0


func combat_id() -> int:
	return uid


## O jogador deste processo ve o monstro (neblina; minimapa).
func is_shown() -> bool:
	return _concealment.is_shown()


## Neblina (F37): o heroi [param observer] (null = ninguem) tem o monstro no raio de visao.
func seen_by(observer: Hero) -> bool:
	return (
		observer != null
		and VisionRules.in_sight(
			observer.global_position, global_position, observer.match_rules.vision_radius
		)
	)


## Servidor apenas (SpawnDirector, F36): volta ao marcador, parado, com HP cheio e colisao.
func revive() -> void:
	present = true
	hp = roundi(data.hp)
	global_transform = Transform3D(_home_basis, _home)
	velocity = Vector3.ZERO
	state = MonsterRules.State.IDLE
	attack_cooldown = 0
	_stun_ticks = 0
	_slow_ticks = 0
	_target = null
	collision_mask = _alive_mask


## Servidor apenas (SpawnDirector, F20): sai do mapa sem morrer — sem XP, sem drop, sem died.
func leave() -> void:
	present = false
	hp = 0
	velocity = Vector3.ZERO
	state = MonsterRules.State.IDLE
	_target = null
	collision_mask = 0


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
	if effect.slow_ticks > 0:
		_slow_pct = maxf(_slow_pct, effect.slow) if _slow_ticks > 0 else effect.slow
		_slow_ticks = maxi(_slow_ticks, effect.slow_ticks)
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
	_slow_ticks = maxi(_slow_ticks - 1, 0)
	if _stun_ticks > 0:
		velocity = Vector3.ZERO
		return
	if (
		state == MonsterRules.State.IDLE
		or not is_instance_valid(_target)
		or not _target.is_alive()
		or _target.hidden_from(self)
	):
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
		if (
			hero.is_alive()
			and CombatRules.in_radius(global_position, hero.global_position, data.area_radius)
		):
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
	died.emit(killer_id, tick)
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
		if hero.is_alive() and dist <= best_dist and not hero.hidden_from(self):
			best = hero
			best_dist = dist
	return best


func _walk_to(point: Vector3) -> void:
	var to := point - global_position
	to.y = 0.0
	var speed := CombatRules.slowed(data.move_speed, _slow_pct if _slow_ticks > 0 else 0.0)
	velocity = to.normalized() * speed if not to.is_zero_approx() else Vector3.ZERO
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
