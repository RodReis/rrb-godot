class_name AimMath
extends RefCounted
## Direcao horizontal de mira: raio do mouse (camera) projetado no chao, ou analogico direito.

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
	var hit: Variant = GROUND.intersects_ray(ray_origin, ray_dir)
	if hit == null:
		return Vector3.ZERO
	var flat: Vector3 = hit - player_pos
	flat.y = 0.0
	if flat.length() < deadzone:
		return Vector3.ZERO
	return flat.normalized()


## Mira pelo analogico direito, relativa a camera ([param yaw]); zero dentro da zona morta.
static func stick_aim(stick: Vector2, yaw: float) -> Vector3:
	if stick.length() < STICK_DEADZONE:
		return Vector3.ZERO
	return CameraRig.to_world(stick, yaw).normalized()
