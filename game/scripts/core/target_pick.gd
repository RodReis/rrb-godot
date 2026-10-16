class_name TargetPick
extends RefCounted
## Escolha do alvo no cliente (F66, SPEC-066 §2): o clique do botao direito pega o adversario sob
## o cursor (raio da camera contra a capsula vertical do corpo: dos pes a cabeca); o RT do gamepad
## pega o mais proximo da direcao de mira. So decide quem pedir ao servidor; quem valida e o
## servidor (TargetRules).

const NOT_FOUND: int = -1
## Peso da distancia no desempate de angulos quase iguais (por unidade).
const DISTANCE_TIEBREAK: float = 0.0001
## Paralelismo: abaixo disto o raio e a capsula nao se cruzam num ponto unico.
const PARALLEL_EPSILON: float = 0.000001


## Indice do alvo que o raio [param origin] + [param ray] (unitario) atravessa primeiro, ou
## NOT_FOUND. Cada candidato e a capsula vertical de [param height] acima do pe em [param feet],
## com o raio de [param radii].
static func pick(
	origin: Vector3,
	ray: Vector3,
	feet: PackedVector3Array,
	radii: PackedFloat32Array,
	height: float
) -> int:
	var best := NOT_FOUND
	var best_along := INF
	for i: int in feet.size():
		var along := _closest_along(origin, ray, feet[i], height)
		if along.x >= 0.0 and along.y <= radii[i] * radii[i] and along.x < best_along:
			best = i
			best_along = along.x
	return best


## Indice do candidato de menor angulo com [param dir] (no plano) a partir de [param from]; sem
## direcao (ZERO), o mais proximo. NOT_FOUND se nao ha candidato.
static func nearest_to_direction(from: Vector3, dir: Vector3, points: PackedVector3Array) -> int:
	var best := NOT_FOUND
	var best_score := -INF
	for i: int in points.size():
		var flat := points[i] - from
		flat.y = 0.0
		var distance := flat.length()
		var score := -distance
		if not dir.is_zero_approx() and distance > 0.0:
			score = flat.dot(dir) / distance - distance * DISTANCE_TIEBREAK
		if score > best_score:
			best = i
			best_score = score
	return best


## Ponto mais proximo entre o raio e o segmento vertical [param base] .. base + UP * [param height]:
## x = distancia ao longo do raio (negativa = atras da camera), y = distancia^2 entre os dois.
static func _closest_along(origin: Vector3, ray: Vector3, base: Vector3, height: float) -> Vector2:
	var w := origin - base
	var b := ray.dot(Vector3.UP)
	var d := ray.dot(w)
	var e := Vector3.UP.dot(w)
	var denom := 1.0 - b * b
	var s := clampf(e, 0.0, height)
	if denom > PARALLEL_EPSILON:
		s = clampf((e - d * b) / denom, 0.0, height)
	var t := s * b - d
	if t < 0.0:
		return Vector2(t, INF)
	s = clampf(e + t * b, 0.0, height)
	var gap := base + Vector3.UP * s - (origin + ray * t)
	return Vector2(t, gap.length_squared())
