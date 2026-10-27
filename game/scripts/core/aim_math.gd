class_name AimMath
extends RefCounted
## Direcao horizontal de mira: raio do mouse (camera) projetado no chao, ou analogico direito.
## Cursor sobre o corpo de alguem (capsula vertical, como no toque de travar, TargetPick) mira o pe
## dele: projetado no chao, o tronco cairia ~1 u atras do corpo com a camera a 45 graus (#287).

const GROUND: Plane = Plane(Vector3.UP, 0.0)
## Mouse mais perto do player que isto (no chao) nao muda a mira.
const DEFAULT_AIM_DEADZONE: float = 0.1
## Analogico com intensidade abaixo disto nao mira.
const STICK_DEADZONE: float = 0.25


static func aim_on_ground(
	ray_origin: Vector3,
	ray_dir: Vector3,
	player_pos: Vector3,
	deadzone: float = DEFAULT_AIM_DEADZONE
) -> Vector3:
	return direction(offset_on_ground(ray_origin, ray_dir, player_pos), deadzone)


## Direcao unitaria de [param offset] (no chao); ZERO dentro de [param deadzone].
static func direction(offset: Vector3, deadzone: float = DEFAULT_AIM_DEADZONE) -> Vector3:
	if offset.length() < deadzone:
		return Vector3.ZERO
	return offset.normalized()


## Vetor no chao do player ate onde o cursor aponta: o pe do 1o corpo que o raio atravessa (capsulas
## de [param height] acima de [param feet], com [param radii]; TargetPick.pick) ou, sem corpo, o
## chao (offset_on_ground). O comprimento e a distancia da mira (centro das areas).
static func offset_at_cursor(
	ray_origin: Vector3,
	ray_dir: Vector3,
	player_pos: Vector3,
	feet: PackedVector3Array,
	radii: PackedFloat32Array,
	height: float
) -> Vector3:
	var index := TargetPick.pick(ray_origin, ray_dir, feet, radii, height)
	if index == TargetPick.NOT_FOUND:
		return offset_on_ground(ray_origin, ray_dir, player_pos)
	var flat := feet[index] - player_pos
	flat.y = 0.0
	return flat


## Vetor no chao do player ate onde o raio (mouse) toca o chao; ZERO se nao toca. O comprimento
## e a distancia da mira (centro da Chuva de Flechas, F14).
static func offset_on_ground(ray_origin: Vector3, ray_dir: Vector3, player_pos: Vector3) -> Vector3:
	var hit: Variant = GROUND.intersects_ray(ray_origin, ray_dir)
	if hit == null:
		return Vector3.ZERO
	var flat: Vector3 = hit - player_pos
	flat.y = 0.0
	return flat


## Mira pelo analogico direito, relativa a camera ([param yaw]); zero dentro da zona morta.
static func stick_aim(stick: Vector2, yaw: float) -> Vector3:
	if stick.length() < STICK_DEADZONE:
		return Vector3.ZERO
	return CameraRig.to_world(stick, yaw).normalized()
