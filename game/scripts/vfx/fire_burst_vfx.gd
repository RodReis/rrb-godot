class_name FireBurstVfx
extends VfxOneShot
## Fogo do Bruxo (F54), de uma vez: explosao (Explosao de Chamas, queda do Meteoro) e Anel de Fogo.
## As chamas nascem numa esfera (explosao, saindo para todo lado) ou num anel (Anel de Fogo,
## subindo) do raio da skill, que chega pelo play (fire_wizard.tres); o nucleo (malha, so na
## explosao) cresce ate o raio e some em core_seconds; o clarao (OmniLight3D, VfxOneShot) cobre o
## raio. Materiais locais a cena: cada instancia do pool tem os seus.

## Na explosao as chamas nascem ate esta fracao do raio e voam o resto.
const SPHERE_FILL: float = 0.35
## Velocidade das chamas da explosao por u de raio (u/s): com o amortecimento, chegam a borda.
const SPEED_PER_RADIUS: float = 2.2
## No anel, as chamas nascem entre esta fracao do raio e o raio.
const RING_INNER: float = 0.85
## Alcance do clarao por u de raio.
const LIGHT_PER_RADIUS: float = 2.5

## Duracao do crescimento e do sumico do nucleo (s).
@export var core_seconds: float = 0.25

## Raio aplicado no ultimo play (u).
var radius: float = 0.0

@onready var _flames: GPUParticles3D = $Flames
@onready var _core: MeshInstance3D = get_node_or_null("Core") as MeshInstance3D
@onready var _flash: OmniLight3D = get_node_or_null("Flash") as OmniLight3D


func _apply_radius(p_radius: float) -> void:
	radius = p_radius
	for particles: GPUParticles3D in _particles:  # chamas e faiscas do anel
		var ring := particles.process_material as ParticleProcessMaterial
		if ring.emission_shape == ParticleProcessMaterial.EMISSION_SHAPE_RING:
			ring.emission_ring_radius = p_radius
	var flames := _flames.process_material as ParticleProcessMaterial
	if flames.emission_shape == ParticleProcessMaterial.EMISSION_SHAPE_RING:
		flames.emission_ring_inner_radius = p_radius * RING_INNER
	else:
		flames.emission_sphere_radius = p_radius * SPHERE_FILL
		flames.initial_velocity_min = p_radius * SPEED_PER_RADIUS * 0.6
		flames.initial_velocity_max = p_radius * SPEED_PER_RADIUS
	if _flash != null:
		_flash.omni_range = p_radius * LIGHT_PER_RADIUS


func _fade(age: float) -> void:
	super(age)
	if _core == null:
		return
	var t := clampf(age / core_seconds, 0.0, 1.0)
	_core.scale = Vector3.ONE * maxf(radius * (0.4 + 0.6 * t), 0.01)
	_core.transparency = t
