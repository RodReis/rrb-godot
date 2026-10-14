class_name RogueRules
extends RefCounted
## Regras puras da Ladina (GDB §4.5): leque da Rajada em Leque e fator da Emboscada oculta.

## Metade (centro do leque: o virote do meio vai na mira).
const HALF: float = 0.5


## Angulo (graus) do virote [param index] de [param count] abertos de [param spread_degrees] em
## [param spread_degrees]: 3 virotes = -12, 0 e +12; 1 virote = reto.
static func fan_angle(index: int, count: int, spread_degrees: float) -> float:
	return (index - (count - 1) * HALF) * spread_degrees


## [param forward] no plano, girada [param angle_degrees] em volta do eixo vertical (unitaria);
## mira nula = ZERO.
static func fan_direction(forward: Vector3, angle_degrees: float) -> Vector3:
	var flat := Vector3(forward.x, 0.0, forward.z)
	if flat.is_zero_approx():
		return Vector3.ZERO
	return flat.normalized().rotated(Vector3.UP, deg_to_rad(angle_degrees))


## Dano da Emboscada ([param amount], ja com INT e ATK): x[param multiplier] se a Ladina estava
## oculta no tick do uso.
static func ambush_damage(amount: float, hidden: bool, multiplier: float) -> int:
	return roundi(amount * multiplier) if hidden else roundi(amount)
