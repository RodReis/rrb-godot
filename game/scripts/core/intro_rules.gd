class_name IntroRules
extends RefCounted
## Matematica da cinematica de abertura (F69, SPEC-069 §2), sem nodes: tempo -> fase e pose da
## camera. Voo fixo em spline sobre a arena (3 s) -> close no proprio heroi, em angulo baixo e de
## frente (2 s) -> blend de 0,5 s para a CameraRig. O cliente avisa o servidor (ready) quando o
## blend termina; a INTRO em si e do MatchController.

enum Phase { FLIGHT, CLOSE, BLEND, DONE }

const FLIGHT_SECONDS: float = 3.0
const CLOSE_SECONDS: float = 2.0
const BLEND_SECONDS: float = 0.5
## Instante em que a cinematica acabou e o cliente acusa ready.
const READY_AT: float = FLIGHT_SECONDS + CLOSE_SECONDS + BLEND_SECONDS
## Do fim do voo, a camera leva este tempo ate o close; o resto do CLOSE_SECONDS e plano parado.
const CLOSE_TRAVEL_SECONDS: float = 1.2

## Voo: camera alta, atras do ponto do trajeto e olhando um pouco a frente, no chao.
const FLIGHT_HEIGHT: float = 16.0
const FLIGHT_BACK: float = 12.0
const FLIGHT_AHEAD: float = 6.0
## Passo de s (0..1) para estimar a direcao do trajeto.
const HEADING_STEP: float = 0.01
## O trajeto passa pelo centro na metade; s * (1 - s) vale 1/4 ali, e o inverso normaliza o arco.
const MIDPOINT: float = 0.5
const PARABOLA_PEAK_INVERSE: float = 4.0

## Nome do heroi e da classe: entram pouco antes do close e saem com o blend.
const OVERLAY_IN_AT: float = 2.6
const OVERLAY_FADE_SECONDS: float = 0.6

## Close: a frente do heroi, abaixo da altura dos olhos, olhando um pouco para cima (u).
const CLOSE_DISTANCE: float = 3.6
const CLOSE_HEIGHT: float = 0.7
const CLOSE_LOOK_HEIGHT: float = 1.2


static func phase_at(seconds: float) -> Phase:
	if seconds < FLIGHT_SECONDS:
		return Phase.FLIGHT
	if seconds < FLIGHT_SECONDS + CLOSE_SECONDS:
		return Phase.CLOSE
	if seconds < READY_AT:
		return Phase.BLEND
	return Phase.DONE


## Ponto do trajeto em [param s] (0..1): a reta start -> end mais um arco que a leva a passar por
## [param middle] em s = MIDPOINT (parabola, maxima no meio).
static func path_point(start: Vector3, middle: Vector3, end: Vector3, s: float) -> Vector3:
	var bulge := middle - start.lerp(end, MIDPOINT)
	return start.lerp(end, s) + bulge * (PARABOLA_PEAK_INVERSE * s * (1.0 - s))


## Fracao do trajeto no instante [param seconds] do voo: parte e chega devagar.
static func flight_progress(seconds: float) -> float:
	return smoothstep(0.0, 1.0, clampf(seconds / FLIGHT_SECONDS, 0.0, 1.0))


static func flight_pose(
	start: Vector3, middle: Vector3, end: Vector3, seconds: float
) -> Transform3D:
	var s := flight_progress(seconds)
	var point := path_point(start, middle, end, s)
	var ahead := path_point(start, middle, end, minf(s + HEADING_STEP, 1.0))
	var behind := path_point(start, middle, end, maxf(s - HEADING_STEP, 0.0))
	var heading := Vector3(ahead.x - behind.x, 0.0, ahead.z - behind.z)
	if heading.is_zero_approx():
		heading = Vector3(end.x - start.x, 0.0, end.z - start.z)
	heading = heading.normalized()
	var origin := point - heading * FLIGHT_BACK + Vector3.UP * FLIGHT_HEIGHT
	return _look(origin, point + heading * FLIGHT_AHEAD)


static func close_pose(hero_position: Vector3, hero_yaw: float) -> Transform3D:
	var origin := (
		hero_position + CameraRig.forward(hero_yaw) * CLOSE_DISTANCE + Vector3.UP * CLOSE_HEIGHT
	)
	return _look(origin, hero_position + Vector3.UP * CLOSE_LOOK_HEIGHT)


## Pose da cinematica em [param seconds] (voo, depois a viagem ate o close e o plano parado). O
## blend para a CameraRig e o [method blend_weight].
static func pose_at(
	seconds: float,
	start: Vector3,
	middle: Vector3,
	end: Vector3,
	hero_position: Vector3,
	hero_yaw: float
) -> Transform3D:
	if seconds <= FLIGHT_SECONDS:
		return flight_pose(start, middle, end, seconds)
	var elapsed := clampf((seconds - FLIGHT_SECONDS) / CLOSE_TRAVEL_SECONDS, 0.0, 1.0)
	return flight_pose(start, middle, end, FLIGHT_SECONDS).interpolate_with(
		close_pose(hero_position, hero_yaw), smoothstep(0.0, 1.0, elapsed)
	)


## Peso da CameraRig (0 = so a cinematica, 1 = so a camera de jogo): sobe durante o blend.
static func blend_weight(seconds: float) -> float:
	var blend_start := FLIGHT_SECONDS + CLOSE_SECONDS
	return smoothstep(0.0, 1.0, clampf((seconds - blend_start) / BLEND_SECONDS, 0.0, 1.0))


## Opacidade da sobreposicao com o nome do heroi.
static func overlay_alpha(seconds: float) -> float:
	var fade_in := clampf((seconds - OVERLAY_IN_AT) / OVERLAY_FADE_SECONDS, 0.0, 1.0)
	return fade_in * (1.0 - blend_weight(seconds))


static func _look(origin: Vector3, target: Vector3) -> Transform3D:
	return Transform3D(Basis.looking_at(target - origin, Vector3.UP), origin)
