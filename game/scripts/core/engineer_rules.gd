class_name EngineerRules
extends RefCounted
## Regras puras do Engenheiro (GDB §4.6): puxao da Garra Mecanica e alvo da Torreta.


## Empurrao horizontal que leva [param target] ate [param stop_distance] de [param engineer]
## (Garra Mecanica: o puxado para a 2,0 u). Nulo se ja esta dentro dessa distancia.
static func pull_push(engineer: Vector3, target: Vector3, stop_distance: float) -> Vector3:
	var toward := Vector3(engineer.x - target.x, 0.0, engineer.z - target.z)
	var gap := toward.length() - stop_distance
	if gap <= 0.0:
		return Vector3.ZERO
	return CombatRules.push_vector(toward, gap)


## Indice do ponto de [param points] mais perto de [param origin] a ate [param max_range] (no
## plano), ou -1. Empate fica com o primeiro.
static func nearest(origin: Vector3, points: PackedVector3Array, max_range: float) -> int:
	var best := -1
	var best_distance := INF
	for i: int in points.size():
		var distance := Vector2(points[i].x - origin.x, points[i].z - origin.z).length()
		if distance <= max_range and distance < best_distance:
			best = i
			best_distance = distance
	return best


## A Torreta dispara no tick [param elapsed] desde a instalacao (0 = instalacao): a cada
## [param interval] ticks, ate [param shot_count] disparos. Mesmo compasso da Chuva de Flechas.
static func is_turret_shot(elapsed: int, interval: int, shot_count: int) -> bool:
	return RangerRules.is_rain_pulse(elapsed, interval, shot_count)
