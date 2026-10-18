class_name VoidServant
extends Combatant
## Servo do Vazio (R do Ocultista, GDB §4.10, F78, SPEC-078): a entidade movel de um heroi, no
## padrao do Monster. IA so no servidor, a cada tick; posicao, HP e golpe replicados por
## StateSynchronizer + TickInterpolator, fora do rollback. Golpe recebido entra na hora (uma vez por
## tick + fonte); golpe dado vai para o ledger do heroi alvo (ADR-0001), como o do monstro.
## Pool fixo: cada Ocultista nasce com 2, filhos de um Node simples na cena dele (sem spawn no meio
## da partida, compativel com o rollback; e o Node quebra a heranca de visibilidade: o heroi no mato
## nao esconde os servos). Invocar so liga (summon); o fim da duracao ou HP 0 desliga.
## Dano e abate valem para o Ocultista (attacker_id = peer dele, como a Torreta): o abate de heroi,
## o XP de monstro e o aggro do campo vao para ele. Matar o servo nao da nada: sem died, sem XP,
## sem drop, sem kill. O golpe do servo nao mexe em recarga do Ocultista: nao o revela no mato.
## Alvo (§4.10), reavaliado a cada retarget_interval desde a invocacao e na hora em que o atual
## morre ou some: VoidServantRules.choose entre o que o Ocultista ve (§7.3); sem alvo, segue o
## Ocultista. Visao (§7.3): como o monstro (raio de visao do observador); o time do dono sempre ve.
## Inativo (HP 0) fica fora do alcance de todos e sem colisao.

## uid = -(UID_BASE + 2 * peer_id do dono + indice): longe dos uids de monstro e bau (-1, -2...).
const UID_BASE: int = 1000000

## Numeros do servo.
@export var data: ServantData

## Ocultista dono; definido por ele no _ready (setup), nos dois lados.
var summoner: Hero
var uid: int = 0

# Estado replicado.
var hp: int = 0
var max_hp: int = 0
var attack_cooldown: int = 0

var _concealment: Concealment
var _interpolator: TickInterpolator
## Cliente: HP do quadro anterior (0 -> vivo = invocacao: teleporta sem interpolar).
var _last_hp: int = 0
# Servidor.
var _damage: int = 0
## Tick da invocacao (-1 = nunca) e tick em que some.
var _summon_tick: int = -1
var _end_tick: int = 0
var _target: Combatant
var _stun_ticks: int = 0
var _slow_ticks: int = 0
var _slow_pct: float = 0.0
var _alive_mask: int = 0
var _seen: HitLedger = HitLedger.new()  # golpes ja aplicados: ressimular o heroi nao duplica
## Candidatos da escolha do alvo (reusados, sem alocar).
var _heroes: Array[Combatant] = []
var _hero_points: PackedVector3Array = PackedVector3Array()
var _monsters: Array[Combatant] = []
var _monster_points: PackedVector3Array = PackedVector3Array()

@onready var hp_bar: WorldHealthBar = $HpBar


func _ready() -> void:
	_alive_mask = collision_mask
	collision_mask = 0
	axis_lock_linear_y = true

	var sync := StateSynchronizer.new()
	sync.name = "StateSynchronizer"
	sync.root = self
	sync.properties = [":transform", ":velocity", ":hp", ":max_hp", ":attack_cooldown"]
	add_child(sync)
	# Nasce com o heroi, depois da conexao: estado so depois de o peer confirmar o node.
	var ack := SpawnAck.guard(self, [sync.visibility_filter])
	_concealment = Concealment.guard(self, seen_by, sync, ack)

	_interpolator = TickInterpolator.new()
	_interpolator.name = "TickInterpolator"
	_interpolator.root = self
	_interpolator.properties = [":transform"]
	add_child(_interpolator)

	NetworkTime.on_tick.connect(_on_network_tick)


func _process(_delta: float) -> void:
	if _last_hp == 0 and hp > 0:
		_interpolator.teleport()  # invocado longe de onde sumiu
	_last_hp = hp
	visible = _concealment.is_shown()
	hp_bar.visible = is_alive() and not PlayerInput.cinematic
	hp_bar.set_ratio(float(hp) / maxi(max_hp, 1))


## Pelo Ocultista [param hero] no _ready dele, nos dois lados: servo [param index] (0 ou 1).
func setup(hero: Hero, index: int) -> void:
	summoner = hero
	team = hero.team
	uid = -(UID_BASE + 2 * hero.peer_id + index)
	hp_bar.set_friendly(hero.peer_id == multiplayer.get_unique_id())


## Servidor (R do Ocultista): liga o servo em [param at], virado como [param facing], com HP e dano
## do [param rank] e da [param intelligence] do Ocultista, ate [param tick] + [param lasts]. Liga de
## novo se ja estava ativo (a invocacao nova substitui). A ressimulacao do Ocultista repete o tick
## da invocacao: ignorado.
func summon(
	tick: int, at: Vector3, facing: Basis, rank: int, intelligence: float, lasts: int
) -> void:
	if tick == _summon_tick:
		return
	_summon_tick = tick
	_end_tick = tick + lasts
	max_hp = VoidServantRules.max_hp(data, rank, intelligence)
	hp = max_hp
	_damage = VoidServantRules.damage(data, rank, intelligence)
	global_transform = Transform3D(facing, at)
	velocity = Vector3.ZERO
	attack_cooldown = 0
	_stun_ticks = 0
	_slow_ticks = 0
	_target = null
	collision_mask = _alive_mask


func is_alive() -> bool:
	return hp > 0


func missing_hp() -> int:
	return maxi(max_hp - hp, 0)


func effective_damage(raw: int) -> int:
	return mini(CombatRules.mitigated(raw, data.defense), hp) if is_alive() else 0


func combat_id() -> int:
	return uid


## Alvo atual (servidor; null = segue o Ocultista).
func target() -> Combatant:
	return _target


func is_shown() -> bool:
	return _concealment.is_shown()


## O time do dono sempre ve; o adversario, no raio de visao dele (como o monstro, §7.3).
func seen_by(observer: Hero) -> bool:
	if observer == null:
		return false
	if observer.team == team:
		return true
	return VisionRules.in_sight(
		observer.global_position, global_position, observer.match_rules.vision_radius
	)


## Servidor apenas. DEF do servo; ressimular o atacante repete o golpe (mesmo tick + fonte):
## ignorado.
func receive_hit(tick: int, source: int, effect: HitEffect) -> void:
	if not is_alive() or _seen.has_hit(tick, source):
		return
	_seen.set_hit(tick, source, effect)
	_seen.trim_before(tick - NetworkRollback.history_limit)
	var damage := CombatRules.mitigated(effect.damage, data.defense) + maxi(effect.true_damage, 0)
	hp = maxi(hp - damage, 0)
	if not is_alive():
		_vanish()
		return
	if not effect.push.is_zero_approx():
		move_and_collide(effect.push)
	_stun_ticks = maxi(_stun_ticks, effect.stun_ticks)
	if effect.slow_ticks > 0 and CombatRules.slow_applies(_slow_pct, _slow_ticks, effect.slow):
		_slow_pct = effect.slow
		_slow_ticks = maxi(_slow_ticks, effect.slow_ticks)


# ponytail: golpe ja aplicado nao e desfeito se a ressimulacao do atacante errar (como no Monster);
# desfazer exige rollback no servo.
func cancel_hit(_tick: int, _source: int) -> void:
	pass


## IA so no servidor (no _ready o peer ainda e offline e is_server() mente).
func _on_network_tick(_delta: float, tick: int) -> void:
	if not multiplayer.is_server() or not is_alive():
		return
	if tick >= _end_tick:
		_vanish()
		return
	attack_cooldown = maxi(attack_cooldown - 1, 0)
	_stun_ticks = maxi(_stun_ticks - 1, 0)
	_slow_ticks = maxi(_slow_ticks - 1, 0)
	if _stun_ticks > 0:
		velocity = Vector3.ZERO
		return
	var interval := SkillRules.seconds_to_ticks(data.retarget_interval, NetworkTime.tickrate)
	if VoidServantRules.is_retarget_tick(tick - _summon_tick, interval) or not _keeps(_target):
		_target = _choose_target()
	if _target == null:
		_follow()
	else:
		_chase(tick)
	velocity *= NetworkTime.physics_factor
	move_and_slide()
	velocity /= NetworkTime.physics_factor


## O alvo atual ainda vale entre duas reavaliacoes: vivo e visto pelo Ocultista vivo.
func _keeps(other: Combatant) -> bool:
	return (
		is_instance_valid(other)
		and other.is_alive()
		and summoner.is_alive()
		and other.seen_by(summoner)
	)


## Alvo travado do Ocultista, heroi inimigo ou monstro (VoidServantRules.choose), so entre o que o
## Ocultista ve; null se nenhum ou se ele morreu (quem morreu nao ve).
func _choose_target() -> Combatant:
	if not summoner.is_alive():
		return null
	_heroes.clear()
	_hero_points.clear()
	_monsters.clear()
	_monster_points.clear()
	for node: Node in get_tree().get_nodes_in_group(TARGETS_GROUP):
		var other := node as Combatant
		if other.team == team or not other.is_alive() or not other.seen_by(summoner):
			continue
		if other is Hero:
			_heroes.append(other)
			_hero_points.append(other.global_position)
		elif other is Monster:
			_monsters.append(other)
			_monster_points.append(other.global_position)
	var locked := summoner.target()
	var has_locked := locked != null and _keeps(locked) and locked.team != team
	var pick := VoidServantRules.choose(
		global_position,
		has_locked,
		locked.global_position if has_locked else Vector3.ZERO,
		_hero_points,
		_monster_points,
		data.target_reach
	)
	match pick.x:
		VoidServantRules.Pick.LOCKED:
			return locked
		VoidServantRules.Pick.HERO:
			return _heroes[pick.y]
		VoidServantRules.Pick.MONSTER:
			return _monsters[pick.y]
	return null


func _chase(tick: int) -> void:
	if _flat_distance(_target.global_position) > data.attack_reach:
		_walk_to(_target.global_position)
		return
	velocity = Vector3.ZERO
	_face(_target.global_position)
	if attack_cooldown == 0:
		attack_cooldown = SkillRules.seconds_to_ticks(data.attack_interval, NetworkTime.tickrate)
		_attack(tick)


## O heroi aplica no proprio _rollback_tick de tick+1; monstro e servo, na hora.
func _attack(tick: int) -> void:
	var effect := HitEffect.new(_damage, global_position)
	effect.attacker_id = summoner.peer_id
	_target.receive_hit(tick + 1, HitLedger.source_key(uid, HitLedger.Slot.BASIC), effect)


func _follow() -> void:
	if _flat_distance(summoner.global_position) <= data.follow_distance:
		velocity = Vector3.ZERO
		return
	_walk_to(summoner.global_position)


## HP 0 ou fim da duracao: fora do alcance de todos, parado e sem colisao.
func _vanish() -> void:
	hp = 0
	velocity = Vector3.ZERO
	collision_mask = 0
	_target = null
	_stun_ticks = 0
	_slow_ticks = 0


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
