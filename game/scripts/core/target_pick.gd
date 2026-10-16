class_name TargetPick
extends RefCounted
## Escolha do alvo no cliente (F66, SPEC-066 §2): o clique do botao direito pega o adversario sob
## o cursor (raio da camera contra uma esfera por corpo); o RT do gamepad pega o mais proximo da
## direcao de mira. So decide quem pedir ao servidor; quem valida e o servidor (TargetRules).

const NOT_FOUND: int = -1


## Indice do alvo que o raio [param origin] + [param ray] (unitario) atravessa primeiro, ou
## NOT_FOUND. [param centers] e [param radii] descrevem uma esfera por candidato.
static func pick(
	origin: Vector3, ray: Vector3, centers: PackedVector3Array, radii: PackedFloat32Array
) -> int:
	var best := NOT_FOUND
	var best_along := INF
	for i: int in centers.size():
		var offset := centers[i] - origin
		var along := offset.dot(ray)
		if along < 0.0 or along >= best_along:
			continue
		if offset.length_squared() - along * along <= radii[i] * radii[i]:
			best = i
			best_along = along
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
			score = flat.dot(dir) / distance - distance * 0.0001
		if score > best_score:
			best = i
			best_score = score
	return best
