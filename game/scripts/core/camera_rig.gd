class_name CameraRig
extends RefCounted
## Matematica da camera em 3a pessoa alta (PRD §3.6): atras do heroi, inclinacao fixa,
## distancia fixa, yaw fixo do time (olhando o centro a partir do spawn; PI 2026-10-09).
## yaw em radianos, mesma convencao de Node3D.rotation.y (0 = olhando -Z).


static func forward(yaw: float) -> Vector3:
	return Vector3(-sin(yaw), 0.0, -cos(yaw))


static func right(yaw: float) -> Vector3:
	return Vector3(cos(yaw), 0.0, -sin(yaw))


## Yaw que faz a camera olhar de [param from] para [param target] no plano.
static func yaw_towards(from: Vector3, target: Vector3) -> float:
	var dir := target - from
	return atan2(-dir.x, -dir.z)


## Posicao da camera relativa ao alvo: atras (contra a frente) e acima.
static func offset(yaw: float, pitch_deg: float, distance: float) -> Vector3:
	var pitch := deg_to_rad(pitch_deg)
	return -forward(yaw) * distance * cos(pitch) + Vector3.UP * distance * sin(pitch)


## Vetor 2D de Input.get_vector (y negativo = frente) para o mundo, relativo a camera.
static func to_world(input: Vector2, yaw: float) -> Vector3:
	return right(yaw) * input.x - forward(yaw) * input.y
