class_name BotRules
extends RefCounted
## FSM do bot da fase 1 (PRD §3.7; ARCHITECTURE-GAME §3.4). Prioridade: Recuar > Lutar >
## Contestar > Farmar a base > Saquear a base > Farmar o centro (base primeiro, PI 2026-10-09).
## Regra pura sobre BotView; o BotInput so escolhe o alvo do estado e produz input.

enum State { FARM, LOOT, CONTEST, FIGHT, RETREAT }


static func next_state(state: State, view: BotView, profile: BotProfile) -> State:
	if state == State.RETREAT and view.safe_seconds < profile.safe_seconds:
		return State.RETREAT
	if state == State.RETREAT and view.can_heal and view.hp_pct < profile.contest_hp_pct:
		return State.RETREAT  # na fonte ate poder contestar o boss (PI 2026-10-10, #74)
	if wants_retreat(view, profile):
		return State.RETREAT
	if view.enemy_distance <= profile.fight_range and has_advantage(view):
		return State.FIGHT
	if wants_contest(view, profile):
		return State.CONTEST
	if view.base_monsters_left > 0:
		return State.FARM
	if view.base_chests_left > 0:
		return State.LOOT
	return State.FARM


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
	if view.level != view.enemy_level:
		return view.level > view.enemy_level
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


## Recuo terminado (saiu de RETREAT) fica gasto ate o HP passar do limiar de novo.
static func retreat_spent_after(
	previous: State, current: State, hp_pct: float, spent: bool, profile: BotProfile
) -> bool:
	if hp_pct >= profile.retreat_hp_pct:
		return false
	return spent or (previous == State.RETREAT and current != State.RETREAT)
