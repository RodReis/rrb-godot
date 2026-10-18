class_name PotionZoneVfx
extends VfxOneShot
## Pocao Verde do Protetor da Selva (F74, SPEC-074 §VFX), so cliente: a garrafa do pack
## (potion_large_green) sai da mao em arco, gira e quebra no ponto (respingo); a zona fica marcada
## pelo anel verde do raio de cura (area_indicator) com brilhos subindo; a cada pulso (pulse_interval
## de druid.tres) uma onda verde corre do centro a borda. Nasce do evento do ImpactRelay
## (zone_shown): quem chega atrasado (elapsed > 0) ve so o que falta e sem o arco.

## Voo da garrafa (s) e altura do arco (u); giro (rad/s).
const ARC_SECONDS: float = 0.3
const ARC_HEIGHT: float = 1.8
const FLASK_SPIN: float = 12.0
## Os brilhos que sobem param de nascer nos ultimos MOTES_STOP_SECONDS.
const MOTES_STOP_SECONDS: float = 0.6
## Brilhos nascem em ate esta fracao do raio (o quadrado de emissao nao passa do circulo).
const MOTES_FILL: float = 0.7

var _from: Vector3 = Vector3.ZERO
var _arc_left: float = 0.0
var _pulse_interval: float = 0.5
var _next_pulse: float = 0.0

@onready var _flask: Node3D = $Flask
@onready var _ring: MeshInstance3D = $Ring
@onready var _splash: GPUParticles3D = $Splash
@onready var _pulse: GPUParticles3D = $Pulse
@onready var _motes: GPUParticles3D = $Motes


func _process(delta: float) -> void:
	super(delta)
	if not visible:
		return
	if _arc_left > 0.0:
		_arc_left = maxf(_arc_left - delta, 0.0)
		var t := 1.0 - _arc_left / ARC_SECONDS
		var ground := global_position
		_flask.global_position = _from.lerp(ground, t) + Vector3.UP * ARC_HEIGHT * 4.0 * t * (1.0 - t)
		_flask.rotate_x(FLASK_SPIN * delta)
		if _arc_left == 0.0:
			_flask.visible = false
			_splash.restart()
	if _arc_left == 0.0:
		_next_pulse -= delta
		if _next_pulse <= 0.0:
			_next_pulse += _pulse_interval
			_pulse.restart()
	_motes.emitting = _age < lifetime - MOTES_STOP_SECONDS


## Dura [param seconds] a partir de agora (logo depois do play); a garrafa vem de [param from] se a
## zona e recente ([param elapsed] = quanto ja passou desde que o servidor a abriu, s).
func last(seconds: float, pulse_interval: float, from: Vector3, elapsed: float) -> void:
	lifetime = seconds
	_pulse_interval = maxf(pulse_interval, 0.1)
	_next_pulse = 0.0
	_from = from
	_arc_left = maxf(ARC_SECONDS - elapsed, 0.0)
	_flask.visible = _arc_left > 0.0
	_flask.global_position = from
	_flask.rotation = Vector3.ZERO
	if _arc_left == 0.0:
		_splash.restart()


## Respingo e onda tocam so quando o script manda (queda, pulso), nao no play.
func _collect() -> void:
	super()
	_particles.erase(_splash)
	_particles.erase(_pulse)


func _apply_radius(radius: float) -> void:
	_ring.scale = Vector3(radius, 1.0, radius)
	var motes := _motes.process_material as ParticleProcessMaterial
	motes.emission_box_extents = Vector3(radius * MOTES_FILL, 0.05, radius * MOTES_FILL)
	var wave := _pulse.process_material as ParticleProcessMaterial
	wave.scale_min = radius * 2.0
	wave.scale_max = radius * 2.0
