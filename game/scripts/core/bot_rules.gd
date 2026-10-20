class_name BotRules
extends RefCounted
## FSM do bot (PRD §3.7; ARCHITECTURE-GAME §3.4). Fase 1, prioridade: Recuar > Lutar > Contestar >
## Farmar a base > Saquear a base > Farmar o centro (base primeiro, PI 2026-10-09). Fase 2 (F19, a
## partir dos 5:00): Fugir da zona > Lutar > Perseguir > o resto; sem Recuar (a fonte fecha) e o
## recuo da fase 1 acaba. Regra pura sobre BotView; o BotInput so escolhe o alvo do estado e
## produz input.

enum State { FARM, LOOT, CONTEST, FIGHT, RETREAT, CHASE, FLEE_ZONE }

## O ponto de fuga fica a esta quantidade de margens da borda, para nao reentrar na faixa de fuga.
const FLEE_DEPTH_MARGINS: float = 2.0
## A Torreta do Engenheiro mira a meio caminho entre ele e o alvo.
const HALFWAY: float = 0.5


static func next_state(state: State, view: BotView, profile: BotProfile) -> State:
	if view.phase2:
		return _next_in_phase2(view, profile)
	if state == State.RETREAT and view.safe_seconds < profile.safe_seconds:
		return State.RETREAT
	if state == State.RETREAT and view.can_heal and view.hp_pct < profile.contest_hp_pct:
		return State.RETREAT  # na fonte ate poder contestar o boss (PI 2026-10-10, #74)
	if wants_retreat(view, profile):
		return State.RETREAT
	if view.enemy_distance <= profile.fight_range and has_advantage(view):
		return State.FIGHT
	return _phase1_rest(view, profile)


## Contestar, farmar e saquear (o que sobra quando nada mais pede o bot).
static func _phase1_rest(view: BotView, profile: BotProfile) -> State:
	if wants_contest(view, profile):
		return State.CONTEST
	if view.base_monsters_left > 0:
		return State.FARM
	if view.base_chests_left > 0:
		return State.LOOT
	return State.FARM


## Fase 2: Fugir da zona > Lutar > Perseguir > o resto da fase 1 (sem Recuar).
static func _next_in_phase2(view: BotView, profile: BotProfile) -> State:
	if wants_flee_zone(view, profile):
		return State.FLEE_ZONE
	if view.enemy_distance <= profile.fight_range and has_advantage(view):
		return State.FIGHT
	if wants_chase(view):
		return State.CHASE
	return _phase1_rest(view, profile)


## Fase 2: a menos de zone_margin da borda da zona (ou fora dela).
static func wants_flee_zone(view: BotView, profile: BotProfile) -> bool:
	return view.phase2 and view.zone_edge < profile.zone_margin


## Fase 2: adversario vivo e dentro da zona (fora dela ele toma dano sozinho).
static func wants_chase(view: BotView) -> bool:
	return view.phase2 and view.can_chase and view.enemy_alive and view.enemy_in_zone


## Para onde correr ao fugir da zona: no rumo do centro, a FLEE_DEPTH_MARGINS margens dentro da
## borda; zona menor que isso (ou heroi no centro) = o proprio centro. So o plano conta.
static func flee_point(position: Vector3, center: Vector3, radius: float, margin: float) -> Vector3:
	var out := Vector3(position.x - center.x, 0.0, position.z - center.z)
	var depth := radius - margin * FLEE_DEPTH_MARGINS
	if depth <= 0.0 or out.is_zero_approx():
		return center
	return center + out.normalized() * depth


## Sem regeneracao de HP: recua uma vez por queda abaixo do limiar, so com perigo perto.
static func wants_retreat(view: BotView, profile: BotProfile) -> bool:
	return not view.retreat_spent and view.in_danger and view.hp_pct < profile.retreat_hp_pct


## A partir de 3:00, com nivel igual ou maior e HP alto: sem cura passiva, voltar ao boss com HP
## baixo era morrer em loop (PI 2026-10-10, #74).
static func wants_contest(view: BotView, profile: BotProfile) -> bool:
	var time_to_contest := view.elapsed >= view.contest_time
	return (
		time_to_contest and view.level >= view.enemy_level and view.hp_pct >= profile.contest_hp_pct
	)


## Nivel maior, ou nivel igual com HP% maior (PI 2026-10-09).
static func has_advantage(view: BotView) -> bool:
	var level := view.level + view.level_slack
	if level != view.enemy_level:
		return level > view.enemy_level
	return view.hp_pct > view.enemy_hp_pct


## Habilidades do Barbaro (SPEC-053 §5) contra um alvo a [param distance]: Q (x) para encurtar,
## fora do [param basic_range] e ate leap_range; E (y) com o alvo perto; R (z) no alcance da
## Execucao. 1 = usa (o Hero ainda confere recarga e rank).
static func barbarian_skills(distance: float, basic_range: float, profile: BotProfile) -> Vector3i:
	return Vector3i(
		int(distance > basic_range and distance <= profile.leap_range),
		int(distance <= profile.spin_range),
		int(distance <= profile.execute_range),
	)


## Habilidades do Bruxo de Fogo (SPEC-054 §5) contra um alvo a [param distance]: Q (x) ate
## blast_range, Anel (y) ate ring_range, Meteoro (z) ate meteor_range, mirando o alvo. 1 = usa (o
## Hero ainda confere recarga e rank).
static func fire_wizard_skills(distance: float, profile: BotProfile) -> Vector3i:
	return Vector3i(
		int(distance <= profile.blast_range),
		int(distance <= profile.ring_range),
		int(distance <= profile.meteor_range),
	)


## Habilidades da Ladina (SPEC-058 §7) contra um inimigo a [param distance], com [param hp_pct] do
## HP: Rajada (x) ate fan_range; Bomba de Fumaca (y) para fugir, com HP abaixo de smoke_hp_pct e o
## inimigo a ate smoke_range; Emboscada (z) ate ambush_range. 1 = usa (o Hero ainda confere
## recarga e rank).
static func rogue_skills(distance: float, hp_pct: float, profile: BotProfile) -> Vector3i:
	return Vector3i(
		int(distance <= profile.fan_range),
		int(hp_pct < profile.smoke_hp_pct and distance <= profile.smoke_range),
		int(distance <= profile.ambush_range),
	)


## Habilidades do Engenheiro (SPEC-059 §7) contra um alvo a [param distance]: Garra (x) com o alvo
## fora do [param basic_range] e ate claw_range; Torreta (y) ate turret_range; Dinamite (z) ate
## dynamite_range. 1 = usa (o Hero ainda confere recarga e rank).
static func engineer_skills(distance: float, basic_range: float, profile: BotProfile) -> Vector3i:
	return Vector3i(
		int(distance > basic_range and distance <= profile.claw_range),
		int(distance <= profile.turret_range),
		int(distance <= profile.dynamite_range),
	)


## Distancia de mira (u) do bot de Engenheiro: a Dinamite cai no alvo; a Torreta, a meio caminho
## entre o Engenheiro e o alvo (o Hero limita ao alcance de cada uma).
static func engineer_aim_distance(distance: float, dynamite_ready: bool) -> float:
	return distance if dynamite_ready else distance * HALFWAY


## Habilidades do Protetor da Selva (SPEC-074 §bot) contra um alvo a [param distance], com
## [param hp_pct] do HP: Raizes (x) ate root_range; Pocao Verde (y) com HP abaixo de potion_hp_pct;
## Pantano (z) ate swamp_range. 1 = usa (o Hero ainda confere recarga e rank).
static func druid_skills(distance: float, hp_pct: float, profile: BotProfile) -> Vector3i:
	return Vector3i(
		int(distance <= profile.root_range),
		int(hp_pct < profile.potion_hp_pct),
		int(distance <= profile.swamp_range),
	)


## Distancia de mira (u) do bot de Protetor: o Pantano cai no alvo; a Pocao, nos pes dele.
static func druid_aim_distance(distance: float, swamp_ready: bool) -> float:
	return distance if swamp_ready else 0.0


## Habilidades do Berserker (SPEC-075 regra 6) contra um alvo a [param distance]: Arremesso (x) para
## alcancar (fora do [param basic_range] e ate throw_range); Grito de Guerra (y) ao entrar em Lutar
## ([param entered_fight]); Ragnarok (z) sob controle ([param controlled]) ou com [param hp_pct]
## abaixo de rage_hp_pct. 1 = usa (o Hero ainda confere recarga e rank).
static func berserker_skills(
	distance: float,
	basic_range: float,
	entered_fight: bool,
	hp_pct: float,
	controlled: bool,
	profile: BotProfile
) -> Vector3i:
	return Vector3i(
		int(distance > basic_range and distance <= profile.throw_range),
		int(entered_fight),
		int(controlled or hp_pct < profile.rage_hp_pct),
	)


## Habilidades do Ocultista (SPEC-077) contra um alvo a [param distance] que se aproxima a
## [param closing_speed] u/s (negativo = afasta): Praga (x) ate plague_range; Circulo Profano (y)
## ate circle_range com o alvo se aproximando; Servos do Vazio (z, F78) ate servants_range se o
## alvo e heroi ou boss ([param worth_servants]: nao gasta o R no farm). O basico, que acumula as
## marcas, sai sozinho no alcance. 1 = usa (o Hero ainda confere recarga e rank).
static func occultist_skills(
	distance: float, closing_speed: float, worth_servants: bool, profile: BotProfile
) -> Vector3i:
	return Vector3i(
		int(distance <= profile.plague_range),
		int(distance <= profile.circle_range and closing_speed >= profile.circle_approach_speed),
		int(worth_servants and distance <= profile.servants_range),
	)


## Habilidades do Paladino (SPEC-076 regra 5) contra um alvo a [param distance]: Golpe Consagrado
## (x) ate consecrate_range; Retribuicao (y) ao entrar em Lutar ([param entered_fight]) ou ao tomar
## golpe corpo a corpo ([param struck_melee]); Bencao Inviolavel (z) com [param hp_pct] abaixo de
## blessing_hp_pct ou dentro da zona ([param in_zone]). 1 = usa (o Hero ainda confere recarga e
## rank).
static func paladin_skills(
	distance: float,
	entered_fight: bool,
	struck_melee: bool,
	hp_pct: float,
	in_zone: bool,
	profile: BotProfile
) -> Vector3i:
	return Vector3i(
		int(distance <= profile.consecrate_range),
		int(entered_fight or struck_melee),
		int(in_zone or hp_pct < profile.blessing_hp_pct),
	)


## Velocidade (u/s) com que [param target_velocity] encurta a distancia ate o bot: projecao no eixo
## do bot ao alvo ([param to_target]); positivo = se aproximando.
static func closing_speed(target_velocity: Vector3, to_target: Vector3) -> float:
	var flat := Vector3(to_target.x, 0.0, to_target.z)
	if flat.is_zero_approx():
		return 0.0
	return -Vector3(target_velocity.x, 0.0, target_velocity.z).dot(flat.normalized())


## Habilidade em que o bot gasta o proximo ponto: a primeira de R, Q, E abaixo do rank tipico do
## nivel ([param typical], GDB §3.2 — E1 no nivel 2); todas no tipico = R, Q, E na ordem. A
## validade do ponto (nivel minimo, rank maximo) e do SkillRules.learn.
static func learn_order(ranks: Vector3i, typical: Vector3i) -> PackedInt32Array:
	var order := PackedInt32Array([SkillRules.SLOT_R, SkillRules.SLOT_Q, SkillRules.SLOT_E])
	var behind := PackedInt32Array()
	for slot: int in order:
		if ranks[slot] < typical[slot]:
			behind.append(slot)
	for slot: int in order:
		if not behind.has(slot):
			behind.append(slot)
	return behind


## Recuo terminado (saiu de RETREAT) fica gasto ate o HP passar do limiar de novo.
static func retreat_spent_after(
	previous: State, current: State, hp_pct: float, spent: bool, profile: BotProfile
) -> bool:
	if hp_pct >= profile.retreat_hp_pct:
		return false
	return spent or (previous == State.RETREAT and current != State.RETREAT)


## Perfil do bot neste nivel (F81): copia do [param base] com o recuo e a distancia de briga do
## nivel; o .tres compartilhado nao muda.
static func profile_for(base: BotProfile, level: BotLevel) -> BotProfile:
	var profile := base.duplicate() as BotProfile
	profile.retreat_hp_pct = level.retreat_hp_pct
	profile.fight_range = level.fight_range
	return profile


## O bot decide neste [param tick] (a cada reaction_ticks; entre decisoes repete o ultimo input).
static func is_think_tick(tick: int, level: BotLevel) -> bool:
	return tick % maxi(level.reaction_ticks, 1) == 0


## A mira [param aim] girada no plano por [param roll] (-1 a 1) do erro maximo do nivel.
static func aim_with_error(aim: Vector3, error_deg: float, roll: float) -> Vector3:
	return aim.rotated(Vector3.UP, deg_to_rad(error_deg * roll))


## Deslocamento (plano) que o alvo faz em [param seconds] com [param velocity]; o nivel que antecipa
## mira nesse ponto (lead_seconds).
static func lead_offset(velocity: Vector3, seconds: float) -> Vector3:
	return Vector3(velocity.x, 0.0, velocity.z) * seconds


## A habilidade pedida sai se o [param roll] (0 a 1) cai abaixo da chance do nivel.
static func keeps_skill(level: BotLevel, roll: float) -> bool:
	return roll < level.skill_chance
