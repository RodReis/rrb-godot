class_name FacingRules
extends RefCounted
## Orientacao do heroi (F66, SPEC-066 §1): encara a direcao em que anda; ao disparar (basico ou
## skill) vira para a mira e a mantem pela janela de encarar (MatchRules.facing_hold_time); parado
## mantem o ultimo yaw. Regra pura: o Hero aplica no _rollback_tick.


## Direcao para a qual olhar neste tick, ou ZERO (mantem o yaw). [param firing]: dispara agora;
## [param hold_ticks]: ticks que ainda restam da janela de encarar.
static func direction(movement: Vector3, aim: Vector3, firing: bool, hold_ticks: int) -> Vector3:
	if firing and not aim.is_zero_approx():
		return aim
	if hold_ticks > 0:
		return Vector3.ZERO
	return movement
