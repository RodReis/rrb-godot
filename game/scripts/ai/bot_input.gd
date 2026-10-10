class_name BotInput
extends PlayerInput
## Input do heroi bot (ARCHITECTURE-GAME §3.4): roda no servidor (dono do input = peer 1) e so
## produz os mesmos campos do PlayerInput; nao toca em estado. Le so estado replicado: posicoes,
## HP, nivel, baus abertos, relogio (invariante de honestidade, CONVENTION §4.6) — nunca o drop.
## FSM em BotRules; aqui escolhe o alvo do estado e anda pelo navmesh (ArenaNav).

const PROFILE: BotProfile = preload("res://shared/data/rules/bot_profile.tres")
## Recalcula o caminho a cada este tempo (s) ou quando o alvo muda.
const REPATH_SECONDS: float = 0.5
## Ponto do caminho dado como alcancado (u).
const WAYPOINT_REACHED: float = 0.5
## Folga para entrar no alcance do golpe e do bau (u).
const REACH_MARGIN: float = 0.4

var state: BotRules.State = BotRules.State.FARM

var _hero: Hero
var _retreat_spent: bool = false
var _last_danger_tick: int = 0
var _path: PackedVector3Array = PackedVector3Array()
var _path_index: int = 0
var _path_goal: Vector3 = Vector3.INF
var _path_tick: int = 0
var _tapped: bool = false


func _gather() -> void:
	think(NetworkTime.tick)


## Uma decisao do bot no [param tick] (publico para o teste rodar sem o NetworkTime).
func think(tick: int) -> void:
	_hero = get_parent() as Hero
	_reset()
	var enemy := _enemy_hero()
	var view := _view(tick, enemy)
	var next := BotRules.next_state(state, view, PROFILE)
	_retreat_spent = BotRules.retreat_spent_after(state, next, view.hp_pct, _retreat_spent, PROFILE)
	if next != state:
		print(
			(
				"[bot] %s -> %s (Nv %d, %d XP)"
				% [BotRules.State.keys()[state], BotRules.State.keys()[next], _hero.level, _hero.xp]
			)
		)
	state = next
	_learn_points()
	match state:
		BotRules.State.RETREAT:
			_go(tick, _home())
		BotRules.State.FIGHT:
			_attack(tick, enemy, true)
		BotRules.State.CONTEST:
			_contest(tick)
		BotRules.State.LOOT:
			_loot(tick, _nearest_chest(_hero.team))
		_:
			_farm(tick)


func _reset() -> void:
	movement = Vector3.ZERO
	aim = Vector3.ZERO
	attack = false
	skill_q = false
	skill_e = false
	skill_r = false
	learn = LEARN_NONE
	interact_hold = false


func _view(tick: int, enemy: Hero) -> BotView:
	var v := BotView.new()
	v.hp_pct = float(_hero.hp) / _hero.attributes.max_hp
	v.level = _hero.level
	v.retreat_spent = _retreat_spent
	v.in_danger = _in_danger(enemy)
	if v.in_danger:
		_last_danger_tick = tick
	v.safe_seconds = float(tick - _last_danger_tick) / NetworkTime.tickrate
	if enemy != null:
		v.enemy_distance = _flat(enemy.global_position).length()
		v.enemy_level = enemy.level
		v.enemy_hp_pct = float(enemy.hp) / enemy.attributes.max_hp
	var clock := get_tree().get_first_node_in_group(MatchClock.GROUP) as MatchClock
	if clock != null:
		v.elapsed = clock.elapsed(tick)
		v.contest_time = clock.rules.boss_warning_time
	else:
		v.contest_time = INF
	v.base_monsters_left = _alive_monsters(_hero.team).size()
	v.base_chests_left = 0 if _nearest_chest(_hero.team) == null else 1
	return v


func _farm(tick: int) -> void:
	var monster := _nearest(_alive_monsters(_hero.team))
	if monster == null:
		monster = _nearest(_alive_monsters(GateRules.TEAM_NEUTRAL))
	if monster != null:
		_attack(tick, monster, false)
		return
	var chest := _nearest_chest(GateRules.TEAM_NEUTRAL)
	if chest != null:
		_loot(tick, chest)
		return
	_go(tick, _center())


func _contest(tick: int) -> void:
	var boss := _boss()
	if boss != null:
		_attack(tick, boss, true)
		return
	_farm(tick)


## Chega no alcance do basico e golpeia; [param skills] usa E e R (o Hero confere recarga).
func _attack(tick: int, target: Combatant, skills: bool) -> void:
	var to := _flat(target.global_position)
	aim = to.normalized()
	if to.length() > _hero.hero_data.basic_attack.attack_range - REACH_MARGIN:
		_go(tick, target.global_position)
		return
	attack = true
	skill_e = skills
	skill_r = skills


## Chega no alcance do bau e toca F (um tick apertado, o seguinte solto).
func _loot(tick: int, chest: Chest) -> void:
	if chest == null:
		_go(tick, _center())
		return
	if _flat(chest.global_position).length() > chest.rules.chest_interact_range - REACH_MARGIN:
		_go(tick, chest.global_position)
		return
	_tapped = not _tapped
	interact_hold = _tapped


func _go(tick: int, goal: Vector3) -> void:
	var map := _hero.get_world_3d().navigation_map
	var due := (
		tick - _path_tick >= SkillRules.seconds_to_ticks(REPATH_SECONDS, NetworkTime.tickrate)
	)
	# Antes da 1a sincronizacao do mapa a consulta da erro: anda reto ate o mapa ficar pronto.
	var map_ready := NavigationServer3D.map_get_iteration_id(map) > 0
	# Alvo andando so recalcula quando se afastou do ultimo pedido (sem consulta por frame).
	var moved := goal.distance_to(_path_goal) > WAYPOINT_REACHED
	if map_ready and (due or moved):
		_path = NavigationServer3D.map_get_path(map, _hero.global_position, goal, true)
		_path_index = 0
		_path_goal = goal
		_path_tick = tick
	while _path_index < _path.size() and _flat(_path[_path_index]).length() < WAYPOINT_REACHED:
		_path_index += 1
	var next := goal
	if _path_index < _path.size():
		next = _path[_path_index]
	elif not _path.is_empty():
		var gap := _path[_path.size() - 1] - goal
		gap.y = 0.0
		if gap.length() > WAYPOINT_REACHED * 2:
			next = _hero.global_position  # alvo fora do navmesh (atras do portao): para no mais perto
	movement = _flat(next).normalized()
	if aim.is_zero_approx():
		aim = movement


## Gasta pontos livres: R, depois Q, depois E (SkillRules.learn recusa o que nao pode).
func _learn_points() -> void:
	if SkillRules.free_points(_hero.level, _hero.ranks) == 0:
		return
	var skills: Array[SkillData] = [
		_hero.hero_data.skill_q, _hero.hero_data.skill_e, _hero.hero_data.skill_r
	]
	for slot: int in [SkillRules.SLOT_R, SkillRules.SLOT_Q, SkillRules.SLOT_E]:
		if SkillRules.learn(_hero.ranks, slot, skills[slot], _hero.level) != _hero.ranks:
			learn = slot
			return


func _in_danger(enemy: Hero) -> bool:
	var reach := PROFILE.danger_range
	if enemy != null and _flat(enemy.global_position).length() <= reach:
		return true
	for node: Node in get_tree().get_nodes_in_group(Monster.GROUP):
		var monster := node as Monster
		if monster.is_alive() and _flat(monster.global_position).length() <= reach:
			return true
	return false


func _enemy_hero() -> Hero:
	var best: Hero = null
	for node: Node in get_tree().get_nodes_in_group(Hero.GROUP):
		var hero := node as Hero
		if hero.team == _hero.team:
			continue
		if (
			best == null
			or _flat(hero.global_position).length() < _flat(best.global_position).length()
		):
			best = hero
	return best


## Monstros vivos (sem o boss) da base [param home] (NEUTRAL = centro).
func _alive_monsters(home: int) -> Array[Combatant]:
	var result: Array[Combatant] = []
	for node: Node in get_tree().get_nodes_in_group(Monster.GROUP):
		var monster := node as Monster
		var boss := monster.data.tier == MonsterData.Tier.BOSS
		if monster.is_alive() and not boss and monster.home_team == home:
			result.append(monster)
	return result


func _boss() -> Monster:
	for node: Node in get_tree().get_nodes_in_group(Monster.GROUP):
		var monster := node as Monster
		if monster.data.tier == MonsterData.Tier.BOSS and monster.is_alive():
			return monster
	return null


## Bau fechado mais proximo da base [param home].
func _nearest_chest(home: int) -> Chest:
	var best: Chest = null
	for node: Node in get_tree().get_nodes_in_group(Chest.GROUP):
		var chest := node as Chest
		if chest.opened or chest.home_team != home:
			continue
		var closer := (
			best == null
			or _flat(chest.global_position).length() < _flat(best.global_position).length()
		)
		if closer:
			best = chest
	return best


func _nearest(candidates: Array[Combatant]) -> Combatant:
	var best: Combatant = null
	for c: Combatant in candidates:
		if best == null or _flat(c.global_position).length() < _flat(best.global_position).length():
			best = c
	return best


func _home() -> Vector3:
	for node: Node in get_tree().get_nodes_in_group(SpawnMarker.GROUP):
		var marker := node as SpawnMarker
		if marker.kind == SpawnMarker.Kind.HERO and marker.team == _hero.team:
			return marker.global_position
	return _hero.global_position


func _center() -> Vector3:
	for node: Node in get_tree().get_nodes_in_group(SpawnMarker.GROUP):
		var marker := node as SpawnMarker
		if marker.kind == SpawnMarker.Kind.BOSS:
			return marker.global_position
	return Vector3.ZERO


## Vetor no plano do heroi ate [param point].
func _flat(point: Vector3) -> Vector3:
	var to := point - _hero.global_position
	to.y = 0.0
	return to
