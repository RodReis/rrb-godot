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
## global (o bau dele aparece para todos). Fase 2 (F19): a zona vem do relogio replicado (ZoneRules,
## o mesmo calculo do cliente) e o adversario, pela morte (aviso global) e por onde o bot o ve.

const PROFILE: BotProfile = preload("res://shared/data/rules/bot_profile.tres")
const LEVELS: BotLevels = preload("res://shared/data/rules/bot_levels.tres")
## Recalcula o caminho a cada este tempo (s) ou quando o alvo muda.
const REPATH_SECONDS: float = 0.5
## Ponto do caminho dado como alcancado (u).
const WAYPOINT_REACHED: float = 0.5
## Folga para entrar no alcance do golpe e do bau (u).
const REACH_MARGIN: float = 0.4

var state: BotRules.State = BotRules.State.FARM

## Nivel do bot (F81, ADR-0021/0027) e o perfil dele; o padrao e o Medio, o bot de antes do F81.
var _level: BotLevel = LEVELS.pick(BotLevels.DEFAULT_NUMBER)
var _profile: BotProfile = BotRules.profile_for(PROFILE, _level)
## Sorteio do erro de mira e das habilidades do nivel (nao entra nos niveis sem erro).
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

var _hero: Hero
var _retreat_spent: bool = false
var _last_danger_tick: int = 0
var _path: PackedVector3Array = PackedVector3Array()
var _path_index: int = 0
var _path_goal: Vector3 = Vector3.INF
var _path_tick: int = 0
var _tapped: bool = false
## Bau que o bot abriu e do qual vai escolher o item (F61); null = nenhum.
var _taking: Chest
## Memoria da neblina: monstro -> vivo e onde estava; bau -> aberto (ultimo estado visto).
var _known_alive: Dictionary[Monster, bool] = {}
var _known_where: Dictionary[Monster, Vector3] = {}
var _known_chest: Dictionary[Chest, bool] = {}
var _tick: int = 0
## Recargas de Q, E e R vistas no think anterior: a que subiu foi usada (log, SPEC-053 §6 item 5).
var _last_cooldowns: Vector3i = Vector3i.ZERO
## Raio da zona no ultimo think da fase 2 (do relogio replicado, igual ao do cliente).
var _zone_radius: float = INF
## O think atual acabou de entrar em FIGHT (Grito de Guerra do Berserker, SPEC-075).
var _entered_fight: bool = false
## HP do heroi no think anterior: caiu = tomou golpe (Retribuicao do Paladino, SPEC-076).
var _last_hp: int = 0


## Nivel numerico (`--bot-difficulty`); ausente ou fora de 1..N = Medio.
func set_difficulty(number: int) -> void:
	_level = LEVELS.pick(number)
	_profile = BotRules.profile_for(PROFILE, _level)


func _gather() -> void:
	if PlayerInput.cinematic:  # --autopilot=bot na cinematica (F69): o servidor segura o heroi
		_gather_idle()
		return
	think(NetworkTime.tick)


## Uma decisao do bot no [param tick] (publico para o teste rodar sem o NetworkTime).
func think(tick: int) -> void:
	_hero = get_parent() as Hero
	_tick = tick
	if not BotRules.is_think_tick(tick, _level):
		_clear_one_shots()  # entre decisoes repete movimento e mira, sem apertar habilidade
		return
	_reset()
	_remember()
	var enemy := _enemy_hero()
	var view := _view(tick, enemy)
	var next := BotRules.next_state(state, view, _profile)
	_retreat_spent = BotRules.retreat_spent_after(
		state, next, view.hp_pct, _retreat_spent, _profile
	)
	if next != state:
		print(
			(
				"[bot %s] %s -> %s (Nv %d, %d XP)"
				% [
					_hero.name,
					BotRules.State.keys()[state],
					BotRules.State.keys()[next],
					_hero.level,
					_hero.xp
				]
			)
		)
	_entered_fight = next == BotRules.State.FIGHT and state != BotRules.State.FIGHT
	state = next
	_learn_points()
	_log_skills()
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
		BotRules.State.CHASE:
			_chase(tick, enemy)
		BotRules.State.FLEE_ZONE:
			_flee_zone(tick)
		_:
			_farm(tick)
	if state == BotRules.State.FARM:
		skill_r = false  # o R fica para heroi e boss; Q e E ajudam no farm (farm_skills)
	_smoke_escape(view, enemy)
	_potion_when_hurt(view)
	_rage_when_needed(view)
	_paladin_reacts(view, enemy)
	_apply_level()


## Erro de mira e habilidades que o nivel nao deixa sair. Niveis sem erro (chance 1, erro 0) nao
## sorteiam nada.
func _apply_level() -> void:
	var casting := skill_q or skill_e or skill_r
	if casting and _level.aim_error_deg > 0.0:
		aim = BotRules.aim_with_error(aim, _level.aim_error_deg, _rng.randf_range(-1.0, 1.0))
	if _level.skill_chance < 1.0:
		skill_q = skill_q and BotRules.keeps_skill(_level, _rng.randf())
		skill_e = skill_e and BotRules.keeps_skill(_level, _rng.randf())
		skill_r = skill_r and BotRules.keeps_skill(_level, _rng.randf())


## Tick sem decisao do bot lento: nada de habilidade, aprender ponto ou escolher item de novo.
func _clear_one_shots() -> void:
	skill_q = false
	skill_e = false
	skill_r = false
	learn = LEARN_NONE
	chest_pick = PICK_NONE


## Ladina: Bomba de Fumaca para fugir do heroi que o bot ve, com HP baixo (SPEC-058 §7).
func _smoke_escape(view: BotView, enemy: Hero) -> void:
	if not _hero is Rogue or enemy == null:
		return
	if BotRules.rogue_skills(view.enemy_distance, view.hp_pct, _profile).y == 1:
		skill_e = true


## Protetor da Selva: Pocao Verde nos pes quando o HP cai abaixo do limiar do perfil com perigo
## perto (SPEC-074). O Pantano, que tambem usa aim_distance, tem a vez na mira dele (_attack).
func _potion_when_hurt(view: BotView) -> void:
	if not _hero is Druid or skill_r or not view.in_danger:
		return
	if BotRules.druid_skills(INF, view.hp_pct, _profile).y == 1 and _skill_ready(SkillRules.SLOT_E):
		skill_e = true
		aim_distance = 0.0


## Berserker: Ragnarok com perigo perto, sob controle (lento, enraizado, atordoado, empurrado ou
## puxado) ou com o HP abaixo do limiar do perfil (SPEC-075 regra 6), em qualquer estado.
func _rage_when_needed(view: BotView) -> void:
	if not _hero is Berserker or not view.in_danger or not _skill_ready(SkillRules.SLOT_R):
		return
	var controlled := _hero.slow_ticks > 0 or _hero.stun_ticks > 0 or _hero.knockback_ticks > 0
	if BotRules.berserker_skills(INF, 0.0, false, view.hp_pct, controlled, _profile).z == 1:
		skill_r = true


## Paladino (SPEC-076 regra 5), em qualquer estado: Retribuicao ao entrar em Lutar ou ao tomar
## golpe com quem bate corpo a corpo ao alcance dela; Bencao com HP baixo ou dentro da zona.
func _paladin_reacts(view: BotView, enemy: Hero) -> void:
	if not _hero is Paladin:
		return
	var reach := _hero.hero_data.skill_e.attack_range
	var struck := _hero.hp < _last_hp and _threat_within(enemy, reach)
	_last_hp = _hero.hp
	var in_zone := _hero.zone_ticks > 0
	var use := BotRules.paladin_skills(INF, _entered_fight, struck, view.hp_pct, in_zone, _profile)
	skill_e = skill_e or (use.y == 1 and _skill_ready(SkillRules.SLOT_E))
	skill_r = skill_r or (use.z == 1 and _skill_ready(SkillRules.SLOT_R))


func _reset() -> void:
	movement = Vector3.ZERO
	aim = Vector3.ZERO
	aim_distance = 0.0
	attack = false
	target_id = TargetRules.NONE
	target_clear = true  # sem alvo novo neste think, solta o anterior (o pedido vence o cancelar)
	skill_q = false
	skill_e = false
	skill_r = false
	learn = LEARN_NONE
	interact_hold = false
	chest_pick = PICK_NONE


func _view(tick: int, enemy: Hero) -> BotView:
	var v := BotView.new()
	v.hp_pct = float(_hero.hp) / _hero.attributes.max_hp
	v.level = _hero.level
	v.retreat_spent = _retreat_spent
	v.can_chase = _level.chases
	v.level_slack = _level.level_slack
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
		_view_zone(v, clock, tick, enemy)
	else:
		v.contest_time = INF
	v.base_monsters_left = _alive_monsters(_hero.team).size()
	v.base_chests_left = 0 if _nearest_chest(_hero.team) == null else 1
	v.can_heal = _fountain() != null and clock != null and v.elapsed < clock.rules.phase1_duration
	return v


## Fase 2 (a partir dos 5:00): a zona sai so do relogio replicado e de ZoneRules, igual ao que o
## cliente calcula (zone_updated); o adversario, pela morte (aviso global) e por onde o bot o ve.
## Sem ve-lo, supoe que esta na zona: ela o empurra ao centro.
func _view_zone(v: BotView, clock: MatchClock, tick: int, enemy: Hero) -> void:
	var t_phase2 := clock.phase2_elapsed(tick)
	v.phase2 = t_phase2 >= 0.0
	if not v.phase2:
		return
	_zone_radius = ZoneRules.radius_at(clock.rules, t_phase2)
	v.zone_edge = _zone_radius - _flat(ZoneController.CENTER).length()
	v.enemy_alive = _enemy_alive()
	var outside := (
		enemy != null
		and ZoneRules.is_outside(enemy.global_position, ZoneController.CENTER, _zone_radius)
	)
	v.enemy_in_zone = not outside


## Fase 2: corre ate o adversario que ve (golpeia ao chegar); sem ve-lo, espera no centro da zona.
func _chase(tick: int, enemy: Hero) -> void:
	if enemy == null:
		_go(tick, _center())
		return
	_attack(tick, enemy, true)


## Fase 2: volta para dentro da zona, no rumo do centro (BotRules.flee_point).
func _flee_zone(tick: int) -> void:
	var point := BotRules.flee_point(
		_hero.global_position, ZoneController.CENTER, _zone_radius, _profile.zone_margin
	)
	_go(tick, point)


func _farm(tick: int) -> void:
	var monster := _nearest(_alive_monsters(_hero.team))
	if monster == null:
		monster = _nearest(_alive_monsters(GateRules.TEAM_NEUTRAL))
	if monster != null:
		_attack(tick, monster, _level.farm_skills)
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


## Chega no alcance do basico e golpeia; [param skills] usa as habilidades (o Hero confere recarga):
## Q de projetil (Arqueira) ja no alcance dele, em linha com a mira; E que nao e avanco (Muralha; o
## Rolamento fica de fora); R com a mira no alvo (Chuva cai nele). Barbaro pelos limiares do perfil
## (BotRules.barbarian_skills): o Salto cai no alvo (aim_distance). Bruxo pelos limiares do perfil
## (BotRules.fire_wizard_skills). Ladina pelos limiares do perfil (BotRules.rogue_skills); a fumaca
## de fuga vale em qualquer estado (_smoke_escape). Engenheiro pelos limiares do perfil
## (BotRules.engineer_skills): Dinamite so com heroi e boss; a Torreta tambem no farm; a mira da
## Dinamite e do alvo, a da Torreta e meio caminho. Protetor da Selva pelos limiares do perfil
## (BotRules.druid_skills): Raizes e Pantano no alvo; a Pocao vale em qualquer estado com HP baixo e
## perigo perto (_potion_when_hurt). Berserker pelo perfil (BotRules.berserker_skills): Arremesso
## para alcancar e Grito ao entrar em Lutar; o Ragnarok vale em qualquer estado (_rage_when_needed).
## Ocultista pelo perfil (BotRules.occultist_skills): o basico acumula marcas, Praga no alvo,
## Circulo se o alvo se aproxima, Servos contra heroi ou boss. Paladino pelo perfil
## (BotRules.paladin_skills): Golpe Consagrado colado; Retribuicao e Bencao em _paladin_reacts.
func _attack(tick: int, target: Combatant, skills: bool) -> void:
	var where := _where(target)
	var to := _flat(where)
	var data := _hero.hero_data
	# So a mira da habilidade antecipa o alvo; alcance e caminho seguem a posicao dele.
	var led := _flat(where + BotRules.lead_offset(target.velocity, _level.lead_seconds))
	aim = led.normalized()
	aim_distance = led.length()
	var q_range := data.skill_q.attack_range
	skill_q = skills and q_range > 0.0 and to.length() <= q_range
	var shooter := _hero as ProjectileHero
	var blocked := shooter != null and shooter.shot_blocked(where)
	skill_q = skill_q and not blocked
	var barbarian := _hero is Barbarian
	var wizard := _hero is FireWizard
	var rogue := _hero is Rogue
	var engineer := _hero is Engineer
	var druid := _hero is Druid
	var berserker := _hero is Berserker
	var occultist := _hero is Occultist
	var paladin := _hero is Paladin
	var use := Vector3i.ZERO
	if barbarian:
		use = BotRules.barbarian_skills(to.length(), data.basic_attack.attack_range, _profile)
		skill_q = skills and use.x == 1
	elif wizard:  # Q e Meteoro ja chegando: o Meteoro cai onde o alvo esta (aim_distance)
		use = BotRules.fire_wizard_skills(to.length(), _profile)
		skill_q = skills and use.x == 1 and not blocked
		skill_r = skills and use.z == 1
	elif rogue:  # Emboscada na direcao do alvo; a fumaca de fuga fica no _smoke_escape
		use = BotRules.rogue_skills(to.length(), 1.0, _profile)
		skill_q = skills and use.x == 1 and not blocked
		skill_r = skills and use.z == 1 and not blocked
	elif engineer:  # Garra fora do cone; Dinamite no alvo; a Torreta tambem ajuda a farmar
		use = BotRules.engineer_skills(to.length(), data.basic_attack.attack_range, _profile)
		skill_q = skills and use.x == 1 and not blocked
		skill_r = skills and use.z == 1 and _skill_ready(SkillRules.SLOT_R)
		skill_e = use.y == 1 and not skill_r and _skill_ready(SkillRules.SLOT_E)
		aim_distance = BotRules.engineer_aim_distance(to.length(), skill_r)
	elif druid:  # Raizes prendem; o Pantano cai no alvo (a Pocao fica no _potion_when_hurt)
		use = BotRules.druid_skills(to.length(), 1.0, _profile)
		skill_q = skills and use.x == 1 and not blocked
		skill_r = skills and use.z == 1 and _skill_ready(SkillRules.SLOT_R)
		aim_distance = BotRules.druid_aim_distance(to.length(), skill_r)
	elif berserker:  # Arremesso para alcancar; Grito ao entrar em Lutar; Ragnarok: _rage_when_needed
		var basic_range := data.basic_attack.attack_range
		use = BotRules.berserker_skills(
			to.length(), basic_range, _entered_fight, 1.0, false, _profile
		)
		skill_q = skills and use.x == 1 and not blocked
		skill_e = skills and use.y == 1
	elif occultist:  # basico sempre (marcas); Praga no alvo; Circulo se ele se aproxima; Servos
		var closing := BotRules.closing_speed(target.velocity, to)
		var worth := target is Hero or Hero._is_boss(target)
		use = BotRules.occultist_skills(to.length(), closing, worth, _profile)
		skill_q = skills and use.x == 1 and not blocked
		skill_e = skills and use.y == 1
		skill_r = skills and use.z == 1 and _skill_ready(SkillRules.SLOT_R)
	elif paladin:  # Golpe Consagrado colado; Retribuicao e Bencao: _paladin_reacts
		use = BotRules.paladin_skills(to.length(), false, false, 1.0, false, _profile)
		skill_q = skills and use.x == 1
	# Sem linha de tiro (Arqueira, Bruxo), segue pelo navmesh ate o obstaculo sair do caminho.
	if to.length() > data.basic_attack.attack_range - REACH_MARGIN or blocked:
		_go(tick, where)
		return
	# Em alcance e com linha de tiro: o heroi golpeia sozinho o alvo travado (F66).
	target_id = target.combat_id()
	if barbarian:  # E e R so parado no alcance do golpe: andando, a Execucao pode errar o cone
		skill_e = skills and use.y == 1
		skill_r = skills and use.z == 1
	elif wizard:
		skill_e = skills and use.y == 1
	elif rogue or engineer or druid or berserker or occultist or paladin:
		pass
	else:
		skill_e = skills and is_zero_approx(data.skill_e.distance)
		skill_r = skills


## O Hero pode usar a habilidade [param slot] (SkillRules.SLOT_*): rank aprendido e recarga zerada.
func _skill_ready(slot: int) -> bool:
	var data := _hero.hero_data
	var skills: Array[SkillData] = [data.skill_q, data.skill_e, data.skill_r]
	var cooldowns := [_hero.q_cooldown, _hero.e_cooldown, _hero.r_cooldown]
	var usable := SkillRules.can_use(skills[slot], _hero.ranks[slot], _hero.level)
	return cooldowns[slot] == 0 and usable


## Recuando: golpeia o monstro ja no alcance do basico, sem parar de andar. O T1 da base
## renasce perto da fonte (F36); parado apanhando, o bot morria em loop.
func _fight_back() -> void:
	var reach := _hero.hero_data.basic_attack.attack_range
	for node: Node in get_tree().get_nodes_in_group(Monster.GROUP):
		var monster := node as Monster
		var to := _flat(monster.global_position)
		if monster.is_alive() and to.length() <= reach:
			aim = to.normalized()
			target_id = monster.combat_id()
			return


## Chega no alcance do bau e toca F (um tick apertado, o seguinte solto). Aberto o bau, escolhe o
## melhor upgrade dos 3 itens (_take).
func _loot(tick: int, chest: Chest) -> void:
	if _taking != null and _take():
		return
	if chest == null:
		_go(tick, _center())
		return
	if _flat(chest.global_position).length() > chest.rules.chest_interact_range - REACH_MARGIN:
		_go(tick, chest.global_position)
		return
	_tapped = not _tapped
	interact_hold = _tapped
	if _tapped:
		_taking = chest


## Depois do toque que abriu: solta o F e, com os itens do menu na mao (bau reservado ao bot),
## clica no melhor upgrade (Inventory.best_choice); sem upgrade nao leva nada. true = ainda
## ocupado com o bau; false = resolvido.
func _take() -> bool:
	var chest := _taking
	if chest == null or not chest.in_reach(_hero.global_position):
		_taking = null
		return false
	if _tapped:
		_tapped = false
		return true
	_taking = null
	if chest.opener != _hero.peer_id or chest.choices.is_empty():
		return false
	chest_pick = Inventory.best_choice(_hero.equipment, chest.choices, chest.catalog)
	return chest_pick != PICK_NONE


func _go(tick: int, goal: Vector3) -> void:
	var map := _nav_map()
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


## Mapa de navegacao do time do bot (ArenaNav com mapa proprio); sem ele, o padrao do mundo.
func _nav_map() -> RID:
	for node: Node in get_tree().get_nodes_in_group(ArenaNav.GROUP):
		var nav := node as ArenaNav
		if nav.team == _hero.team:
			return nav.get_navigation_map()
	return _hero.get_world_3d().navigation_map


## Gasta pontos livres: R, depois Q, depois E (SkillRules.learn recusa o que nao pode).
func _learn_points() -> void:
	if SkillRules.free_points(_hero.level, _hero.ranks) == 0:
		return
	var skills: Array[SkillData] = [
		_hero.hero_data.skill_q, _hero.hero_data.skill_e, _hero.hero_data.skill_r
	]
	var typical := XpTable.typical_ranks(_hero.xp_curve, _hero.level)
	for slot: int in BotRules.learn_order(_hero.ranks, typical):
		if SkillRules.learn(_hero.ranks, slot, skills[slot], _hero.level) != _hero.ranks:
			learn = slot
			return


## Uma linha por habilidade que o heroi do bot acabou de usar (recarga subiu).
func _log_skills() -> void:
	var now := Vector3i(_hero.q_cooldown, _hero.e_cooldown, _hero.r_cooldown)
	for slot: int in [SkillRules.SLOT_Q, SkillRules.SLOT_E, SkillRules.SLOT_R]:
		if now[slot] > _last_cooldowns[slot]:
			print("[bot %s] %s usa %s" % [_hero.name, _hero.hero_data.display_name, "QER"[slot]])
	_last_cooldowns = now


func _in_danger(enemy: Hero) -> bool:
	return _threat_within(enemy, _profile.danger_range)


## O heroi adversario visto ou um monstro engajado esta a ate [param reach] do bot.
func _threat_within(enemy: Hero, reach: float) -> bool:
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
## nela fica com o estado do inicio da partida (1o think). Ponto lembrado a vista e vazio (#238):
## o monstro saiu de la (voltou ao acampamento); procura em casa e, com a casa vazia a vista,
## deixa de contar com ele; senao o bot para no alcance do ponto vazio e "ataca" o nada.
func _remember() -> void:
	for node: Node in get_tree().get_nodes_in_group(Monster.GROUP):
		var monster := node as Monster
		if not _known_alive.has(monster) or _sees(monster):
			_known_alive[monster] = monster.is_alive()
			_known_where[monster] = monster.global_position
		elif _known_alive[monster] and _sees_point(_known_where[monster]):
			var home := monster.home_position()
			if _known_where[monster].is_equal_approx(home):
				_known_alive[monster] = false
			else:
				_known_where[monster] = home
	for node: Node in get_tree().get_nodes_in_group(Chest.GROUP):
		var chest := node as Chest
		if not _known_chest.has(chest) or _sees(chest):
			_known_chest[chest] = chest.opened


func _sees(node: Node3D) -> bool:
	return _sees_point(node.global_position)


func _sees_point(point: Vector3) -> bool:
	var radius := _hero.match_rules.vision_radius
	return VisionRules.in_sight(_hero.global_position, point, radius)


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
