class_name SwampZoneVfx
extends VfxOneShot
## Pantano do Protetor da Selva (F74, SPEC-074 §VFX), so cliente: o disco de lama com o anel
## tracejado do raio (area_indicator, marcacao visivel como a do Meteoro), bolhas que sobem e
## estouram, neblina rasteira e, a cada pulso de dano (pulse_interval de druid.tres), uma onda
## escura do centro a borda. Nasce do evento do ImpactRelay (zone_shown); quem chega atrasado ve
## so o que falta.

## Bolhas e neblina nascem em ate esta fracao do raio (o quadrado de emissao nao passa do circulo).
const BUBBLES_FILL: float = 0.7
## As bolhas param de nascer nos ultimos BUBBLES_STOP_SECONDS.
const BUBBLES_STOP_SECONDS: float = 0.6

var _pulse_interval: float = 1.0
var _next_pulse: float = 0.0

@onready var _ring: MeshInstance3D = $Ring
@onready var _pulse: GPUParticles3D = $Pulse
@onready var _bubbles: GPUParticles3D = $Bubbles
@onready var _mist: GPUParticles3D = $Mist


func _process(delta: float) -> void:
	super(delta)
	if not visible:
		return
	_next_pulse -= delta
	if _next_pulse <= 0.0:
		_next_pulse += _pulse_interval
		_pulse.restart()
	var live := _age < lifetime - BUBBLES_STOP_SECONDS
	_bubbles.emitting = live
	_mist.emitting = live


## Dura [param seconds] a partir de agora (logo depois do play).
func last(seconds: float, pulse_interval: float) -> void:
	lifetime = seconds
	_pulse_interval = maxf(pulse_interval, 0.1)
	_next_pulse = 0.0


## A onda toca so quando o script manda (pulso), nao no play.
func _collect() -> void:
	super()
	_particles.erase(_pulse)


func _apply_radius(radius: float) -> void:
	_ring.scale = Vector3(radius, 1.0, radius)
	var extents := Vector3(radius * BUBBLES_FILL, 0.05, radius * BUBBLES_FILL)
	(_bubbles.process_material as ParticleProcessMaterial).emission_box_extents = extents
	(_mist.process_material as ParticleProcessMaterial).emission_box_extents = extents
	var wave := _pulse.process_material as ParticleProcessMaterial
	wave.scale_min = radius * 2.0
	wave.scale_max = radius * 2.0
