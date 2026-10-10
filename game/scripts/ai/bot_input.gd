class_name BotInput
extends PlayerInput
## Input do heroi bot (ARCHITECTURE-GAME §3.4): roda no servidor (dono do input = peer 1) e so
## produz os mesmos campos do PlayerInput; nao toca em estado. Le so estado replicado: posicoes,
## HP, nivel, baus abertos, relogio (invariante de honestidade, CONVENTION §4.6) — nunca o drop.
## FSM em BotRules; aqui escolhe o alvo do estado e anda pelo navmesh (ArenaNav).
## Neblina (F37): so enxerga o que o filtro entregaria ao peer dele — heroi adversario no raio de
## visao e fora do mato (Hero.seen_by); de monstro e bau, o ultimo estado que entrou no raio
## (memoria). No 1o think a memoria e o estado do inicio da partida, com que todo cliente carrega
## a arena. Rei Esqueleto pelo que e publico: surge aos 3:30, sai aos 5:00 e a morte dele e aviso
## global (o bau dele aparece para todos).

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
## Memoria da neblina: monstro -> vivo e onde estava; bau -> aberto (ultimo estado visto).
var _known_alive: Dictionary[Monster, bool] = {}
var _known_where: Dictionary[Monster, Vector3] = {}
var _known_chest: Dictionary[Chest, bool] = {}
var _tick: int = 0


func _gather() -> void:
	think(NetworkTime.tick)


## Uma decisao do bot no [param tick] (publico para o teste rodar sem o NetworkTime).
func think(tick: int) -> void:
	_hero = get_parent() as Hero
	_tick = tick
	_reset()
	_remember()
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
			_go(tick, _fountain().global_position if view.can_heal else _home())
			_fight_back()
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
	aim_distance = 0.0
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
	v.can_heal = _fountain() != null and clock != null and v.elapsed < clock.rules.phase1_duration
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
	if _gates_fallen():
		_invade(tick)
		return
	_go(tick, _center())


## Portoes caidos (5:00) e nada do proprio lado: farma o que sobrou na base do jogador e, sem
## monstro, vai ate ele (PI 2026-10-09, #52). Lutar continua com BotRules (FIGHT).
func _invade(tick: int) -> void:
	var monster := _nearest(_alive_monsters(_enemy_team()))
	if monster != null:
		_attack(tick, monster, false)
		return
	var enemy := _enemy_hero()
	if enemy == null:
		# Sem ver o jogador (F37): procura na base dele; morto (aviso global), espera no centro.
		_go(tick, _spawn_of(_enemy_team()) if _enemy_alive() else _center())
		return
	aim = _flat(enemy.global_position).normalized()
	if _flat(enemy.global_position).length() > _hero.hero_data.basic_attack.attack_range:
		_go(tick, enemy.global_position)


func _contest(tick: int) -> void:
	var boss := _boss()
	if boss != null:
		_attack(tick, boss, true)
		return
	_farm(tick)


## Chega no alcance do basico e golpeia; [param skills] usa as habilidades (o Hero confere
## recarga): Q de projetil (Arqueira) ja no alcance dele, em linha com a mira; E que nao e avanco
## (Muralha; o Rolamento fica de fora); R com a mira no alvo (Chuva cai nele).
func _attack(tick: int, target: Combatant, skills: bool) -> void:
	var where := _where(target)
	var to := _flat(where)
	var data := _hero.hero_data
	aim = to.normalized()
	aim_distance = to.length()
	var q_range := data.skill_q.attack_range
	skill_q = skills and q_range > 0.0 and to.length() <= q_range
	var ranger := _hero as Ranger
	var blocked := ranger != null and ranger.shot_blocked(where)
	skill_q = skill_q and not blocked
	# Sem linha de tiro (Arqueira), segue pelo navmesh ate o obstaculo sair do caminho.
	if to.length() > data.basic_attack.attack_range - REACH_MARGIN or blocked:
		_go(tick, where)
		return
	attack = true
	skill_e = skills and is_zero_approx(data.skill_e.distance)
	skill_r = skills


## Recuando: golpeia o monstro ja no alcance do basico, sem parar de andar. O T1 da base
## renasce perto da fonte (F36); parado apanhando, o bot morria em loop.
func _fight_back() -> void:
	var reach := _hero.hero_data.basic_attack.attack_range
	for node: Node in get_tree().get_nodes_in_group(Monster.GROUP):
		var monster := node as Monster
		var to := _flat(monster.global_position)
		if monster.is_alive() and to.length() <= reach:
			aim = to.normalized()
			attack = true
			return


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
	var step := _flat(next)
	# Ja no ponto: parado. Normalizar o resto minusculo inverte a direcao a cada tick (#52).
	movement = Vector3.ZERO if step.length() < WAYPOINT_REACHED else step.normalized()
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
	# Monstro parado (sem aggro) nao e perigo: o T1 da base renasce perto da fonte (F36) e
	# prendia o bot em RETREAT. Engajado = andando ou com golpe em recarga (estado replicado).
	for node: Node in get_tree().get_nodes_in_group(Monster.GROUP):
		var monster := node as Monster
		var engaged := not monster.velocity.is_zero_approx() or monster.attack_cooldown > 0
		if monster.is_alive() and engaged and _flat(monster.global_position).length() <= reach:
			return true
	return false


func _gates_fallen() -> bool:
	for node: Node in get_tree().get_nodes_in_group(Gate.GROUP):
		if (node as Gate).is_fallen():
			return true
	return false


func _enemy_hero() -> Hero:
	var best: Hero = null
	for node: Node in get_tree().get_nodes_in_group(Hero.GROUP):
		var hero := node as Hero
		# Mato alto (F32) e neblina (F37): o que o filtro nao entregaria ao peer do bot, nao ve.
		if hero.team == _hero.team or not hero.is_alive() or not hero.seen_by(_hero):
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
		if _known_alive.get(monster, false) and not boss and monster.home_team == home:
			result.append(monster)
	return result


func _boss() -> Monster:
	for node: Node in get_tree().get_nodes_in_group(Monster.GROUP):
		var monster := node as Monster
		if monster.data.tier != MonsterData.Tier.BOSS:
			continue
		var up := monster.is_alive() if _sees(monster) else _boss_up(monster)
		return monster if up else null
	return null


## Rei Esqueleto pelo que e publico: entre 3:30 e 5:00 do relogio e sem o bau dele no mapa.
func _boss_up(boss: Monster) -> bool:
	var clock := get_tree().get_first_node_in_group(MatchClock.GROUP) as MatchClock
	if clock == null or not clock.is_started():
		return false
	var elapsed := clock.elapsed(_tick)
	var window := elapsed >= clock.rules.boss_spawn_time and elapsed < clock.rules.phase1_duration
	return window and not boss.get_parent().has_node(SpawnDirector.BOSS_CHEST_NAME)


## Bau fechado mais proximo da base [param home].
func _nearest_chest(home: int) -> Chest:
	var best: Chest = null
	for node: Node in get_tree().get_nodes_in_group(Chest.GROUP):
		var chest := node as Chest
		if _known_opened(chest) or chest.home_team != home:
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
		if best == null or _flat(_where(c)).length() < _flat(_where(best)).length():
			best = c
	return best


## Neblina (F37): atualiza a memoria com o que esta no raio de visao do bot; o que nunca entrou
## nela fica com o estado do inicio da partida (1o think).
func _remember() -> void:
	for node: Node in get_tree().get_nodes_in_group(Monster.GROUP):
		var monster := node as Monster
		if not _known_alive.has(monster) or _sees(monster):
			_known_alive[monster] = monster.is_alive()
			_known_where[monster] = monster.global_position
	for node: Node in get_tree().get_nodes_in_group(Chest.GROUP):
		var chest := node as Chest
		if not _known_chest.has(chest) or _sees(chest):
			_known_chest[chest] = chest.opened


func _sees(node: Node3D) -> bool:
	var radius := _hero.match_rules.vision_radius
	return VisionRules.in_sight(_hero.global_position, node.global_position, radius)


## Onde o bot acha que o alvo esta: o agora, se o ve; senao, onde o viu por ultimo.
func _where(target: Combatant) -> Vector3:
	var monster := target as Monster
	if monster == null or _sees(monster):
		return target.global_position
	return _known_where.get(monster, monster.global_position)


func _known_opened(chest: Chest) -> bool:
	return _known_chest.get(chest, chest.opened)


func _enemy_team() -> int:
	return GateRules.TEAM_A if _hero.team == GateRules.TEAM_B else GateRules.TEAM_B


## O adversario esta vivo: a morte e aviso global (player_died) e o respawn tem tempo publico.
func _enemy_alive() -> bool:
	for node: Node in get_tree().get_nodes_in_group(Hero.GROUP):
		var hero := node as Hero
		if hero.team != _hero.team and hero.is_alive():
			return true
	return false


## Fonte da base do bot (#74): recua ate ela enquanto cura (fase 1).
func _fountain() -> Fountain:
	for node: Node in get_tree().get_nodes_in_group(Fountain.GROUP):
		if (node as Fountain).team == _hero.team:
			return node as Fountain
	return null


func _home() -> Vector3:
	return _spawn_of(_hero.team)


## Spawn do time [param team] (marcador HERO).
func _spawn_of(team: int) -> Vector3:
	for node: Node in get_tree().get_nodes_in_group(SpawnMarker.GROUP):
		var marker := node as SpawnMarker
		if marker.kind == SpawnMarker.Kind.HERO and marker.team == team:
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
