class_name DayNightKey
extends Resource
## Um ponto da curva do ciclo dia/noite (F49, SPEC-049 §2): a luz e o ambiente nesse instante.
## `time` e `t` da curva (0 = dia, 1 = noite). A noite e o visual aceito no F40.

## Posicao na curva, em [0, 1].
@export_range(0.0, 1.0) var time: float = 0.0
## Direcao do Sun: elevacao negativa (rotacao X; -90 = a pino) e azimute (rotacao Y).
@export_range(-90.0, 0.0) var sun_pitch_deg: float = -38.0
@export var sun_yaw_deg: float = 38.0
@export var sun_color: Color = Color.WHITE
@export var sun_energy: float = 1.0
## Desfoque da sombra do sol (quanto menor, mais forte e nitida).
@export var sun_shadow_blur: float = 3.0
@export var ambient_color: Color = Color.WHITE
@export var ambient_energy: float = 1.0
@export var fog_density: float = 0.01
@export var fog_albedo: Color = Color.WHITE
@export var exposure: float = 1.0
## Mistura do ceu: 1 = dia (gradiente azul + disco do sol), 0 = noite (abismo cosmico do F40).
@export_range(0.0, 1.0) var sky_day: float = 0.0
## Multiplicador da emissao de magma, cristais e rio de mana (mais forte a noite).
@export var emission_scale: float = 1.0


## Mistura [param a] e [param b] por [param weight] em [param out], sem alocar.
static func blend(a: DayNightKey, b: DayNightKey, weight: float, out: DayNightKey) -> void:
	out.time = lerpf(a.time, b.time, weight)
	out.sun_pitch_deg = lerpf(a.sun_pitch_deg, b.sun_pitch_deg, weight)
	out.sun_yaw_deg = lerpf(a.sun_yaw_deg, b.sun_yaw_deg, weight)
	out.sun_color = a.sun_color.lerp(b.sun_color, weight)
	out.sun_energy = lerpf(a.sun_energy, b.sun_energy, weight)
	out.sun_shadow_blur = lerpf(a.sun_shadow_blur, b.sun_shadow_blur, weight)
	out.ambient_color = a.ambient_color.lerp(b.ambient_color, weight)
	out.ambient_energy = lerpf(a.ambient_energy, b.ambient_energy, weight)
	out.fog_density = lerpf(a.fog_density, b.fog_density, weight)
	out.fog_albedo = a.fog_albedo.lerp(b.fog_albedo, weight)
	out.exposure = lerpf(a.exposure, b.exposure, weight)
	out.sky_day = lerpf(a.sky_day, b.sky_day, weight)
	out.emission_scale = lerpf(a.emission_scale, b.emission_scale, weight)
