class_name CombatRules
extends RefCounted
## Regras puras de combate. Sem estado, sem nodes: testavel em isolamento.

## Abaixo desta distancia o alvo esta "colado" e e atingido em qualquer direcao.
const MIN_TARGET_DISTANCE: float = 0.001


## Mitigacao pela DEF em Stats (GDB §2.2); dano efetivo arredondado.
static func apply_damage(hp: int, damage: int, defense: int) -> int:
	var effective := roundi(Stats.damage_after_defense(damage, defense))
	return maxi(hp - effective, 0)


static func is_in_melee_arc(
	attacker_pos: Vector3,
	forward: Vector3,
	target_pos: Vector3,
	attack_range: float,
	half_angle_deg: float
) -> bool:
	var to_target := target_pos - attacker_pos
	to_target.y = 0.0
	var dist := to_target.length()
	if dist > attack_range:
		return false
	if dist < MIN_TARGET_DISTANCE:
		return true
	var flat_forward := Vector3(forward.x, 0.0, forward.z).normalized()
	return rad_to_deg(flat_forward.angle_to(to_target / dist)) <= half_angle_deg
