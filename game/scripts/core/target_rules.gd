class_name TargetRules
extends RefCounted
## Alvo travado com auto-ataque (F66, SPEC-066 §2-3, GDB §7.3). O alvo e o combat_id de um heroi
## adversario ou monstro (NONE = nenhum). O servidor so aceita alvo que existe, e adversario, esta
## vivo e e visivel para quem trava (moita, fumaca, neblina: invariante de honestidade, CONVENTION
## §4.6); o auto-ataque so sai em alcance, sem andar ate o alvo. Regra pura.

const NONE: int = 0


## O alvo pode ser travado/mantido por quem trava.
static func is_valid(exists: bool, is_enemy: bool, alive: bool, visible: bool) -> bool:
	return exists and is_enemy and alive and visible


## Alvo do proximo tick. [param request]: pedido de travar neste tick (NONE = sem pedido);
## [param clear]: cancelar (Esc ou clique no chao). Pedido recusado vale como nenhum alvo; o pedido
## do tick vence o cancelar.
static func resolve(
	current: int, request: int, clear: bool, request_valid: bool, current_valid: bool
) -> int:
	if request != NONE:
		return request if request_valid else NONE
	if clear or not current_valid:
		return NONE
	return current


## Auto-ataque: alvo valido a no maximo [param attack_range] (no plano) de [param from].
static func can_attack(valid: bool, from: Vector3, to: Vector3, attack_range: float) -> bool:
	return valid and CombatRules.in_radius(from, to, attack_range)


## Mira horizontal unitaria de [param from] para [param to]; ZERO se estao no mesmo ponto.
static func aim_to(from: Vector3, to: Vector3) -> Vector3:
	var flat := to - from
	flat.y = 0.0
	return flat.normalized()
