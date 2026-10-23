class_name MatchState
extends RefCounted
## Estados da partida (CONVENTION §3), na ordem em que acontecem; nao ha transicao de volta.

## INTRO (F69): cinematica de abertura no cliente; herois no spawn, sem input, relogio parado.
enum State { LOBBY_WAIT, HERO_PICK, INTRO, PHASE1, TRANSITION, PHASE2, SUDDEN_DEATH, ENDED }


## A TRANSITION ja conta como fase 2: o relogio da fase 2 comeca aos 5:00 (PI 2026-10-10).
static func is_phase2(state: State) -> bool:
	return state >= State.TRANSITION and state < State.ENDED


## Da fase 1 a morte subita: a partida corre (herois em campo, relogio andando).
static func is_running(state: State) -> bool:
	return state >= State.PHASE1 and state < State.ENDED
