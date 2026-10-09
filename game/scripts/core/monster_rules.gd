class_name MonsterRules
extends RefCounted
## FSM dos monstros nao-boss (ARCHITECTURE-GAME §3.4): parado -> persegue (aggro) -> volta
## (leash) -> parado. O golpe acontece dentro de CHASE, com o alvo no alcance. Regra pura;
## o node so orquestra. Numeros em MonsterData (PI 2026-10-09).

enum State { IDLE, CHASE, RESET }

## Distancia do ponto de spawn em que a volta termina (u; geometria, nao balanceamento).
const HOME_REACHED: float = 0.5


## [param target_dist] = INF quando nao ha alvo.
static func next_state(
	state: State, data: MonsterData, target_dist: float, home_dist: float
) -> State:
	match state:
		State.RESET:
			return State.IDLE if home_dist <= HOME_REACHED else State.RESET
		State.CHASE:
			if home_dist > data.leash_range or is_inf(target_dist):
				return State.RESET
			return State.CHASE
	return State.CHASE if target_dist <= data.aggro_range else State.IDLE


## A distancia (mago) ou corpo a corpo.
static func attack_reach(data: MonsterData) -> float:
	return data.ranged_range if data.ranged_range > 0.0 else data.melee_range
