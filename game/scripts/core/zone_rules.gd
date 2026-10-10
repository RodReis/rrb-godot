class_name ZoneRules
extends RefCounted
## Zona da fase 2 (GDB §7.1, ADR-0004 N4), pelo tempo desde o inicio da fase 2 (5:00, a
## TRANSITION ja conta): raio interpolado linearmente entre os pontos de zone_times/zone_radius;
## dano fora do circulo em degrau por minuto (zone_damage_pct, fracao do HP max por segundo).


static func radius_at(rules: MatchRules, t_phase2: float) -> float:
	var times := rules.zone_times
	var radii := rules.zone_radius
	if t_phase2 <= times[0]:
		return radii[0]
	for i: int in range(1, times.size()):
		if t_phase2 < times[i]:
			var weight := (t_phase2 - times[i - 1]) / (times[i] - times[i - 1])
			return lerpf(radii[i - 1], radii[i], weight)
	return radii[radii.size() - 1]


static func damage_pct_at(rules: MatchRules, t_phase2: float) -> float:
	var times := rules.zone_times
	var step := 0
	while step + 1 < times.size() and t_phase2 >= times[step + 1]:
		step += 1
	return rules.zone_damage_pct[step]


## So o plano conta (o heroi e planar).
static func is_outside(position: Vector3, center: Vector3, radius: float) -> bool:
	return Vector2(position.x - center.x, position.z - center.z).length() > radius


## Dano de um pulso (1 por segundo): fracao do HP max, ao menos 1.
static func damage(max_hp: int, pct: float) -> int:
	return maxi(roundi(max_hp * pct), 1)
