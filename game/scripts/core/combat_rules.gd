class_name CombatRules
extends RefCounted
## Regras puras de combate. Sem estado, sem nodes: testavel em isolamento.

## Abaixo desta distancia o alvo esta "colado" e e atingido em qualquer direcao.
const MIN_TARGET_DISTANCE: float = 0.001
## Duracao do empurrao em heroi (s): deslize no estado de rollback em vez de salto, para o
## cliente ressimular e corrigir so o trecho da latencia (F11). Netcode, nao balanceamento.
const KNOCKBACK_SECONDS: float = 0.25


## Dano bruto depois da DEF (Stats, GDB §2.2), arredondado.
static func mitigated(raw_damage: int, defense: float) -> int:
	return roundi(Stats.damage_after_defense(raw_damage, defense))


## Golpe de [param source] e frontal para quem esta em [param target_pos] olhando
## [param target_forward]: semicirculo de 180 graus a frente (PI 2026-10-09).
static func is_frontal(target_pos: Vector3, target_forward: Vector3, source: Vector3) -> bool:
	var to_source := source - target_pos
	to_source.y = 0.0
	var flat_forward := Vector3(target_forward.x, 0.0, target_forward.z)
	return to_source.length() < MIN_TARGET_DISTANCE or flat_forward.dot(to_source) >= 0.0


## Escudo absorve o dano (ja mitigado pela DEF; PI 2026-10-09): (dano no HP, escudo restante).
static func absorb(damage: int, shield: int) -> Vector2i:
	var absorbed := mini(damage, shield)
	return Vector2i(damage - absorbed, shield - absorbed)


## [param target] a no maximo [param radius] de [param center], no plano.
static func in_radius(center: Vector3, target: Vector3, radius: float) -> bool:
	return Vector2(target.x - center.x, target.z - center.z).length() <= radius


## Empurrao horizontal de [param distance] na direcao dada; direcao nula = sem empurrao.
## Ticks do deslize do empurrao ([constant KNOCKBACK_SECONDS]); pelo menos 1.
static func knockback_ticks(tickrate: int) -> int:
	return maxi(roundi(KNOCKBACK_SECONDS * tickrate), 1)


static func push_vector(direction: Vector3, distance: float) -> Vector3:
	var flat := Vector3(direction.x, 0.0, direction.z)
	if flat.length() < MIN_TARGET_DISTANCE:
		return Vector3.ZERO
	return flat.normalized() * distance


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
