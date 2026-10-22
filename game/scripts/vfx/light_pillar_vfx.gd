class_name LightPillarVfx
extends VfxOneShot
## Raio de luz das Correntes do Julgamento (F98, SPEC-098 §4), so cliente: coluna dourada aberta
## (light_pillar.glb, alfa sumindo para cima) com aro no chao no raio da luz, motes descendo e
## luz; a coluna desce do alto ao abrir e pulsa devagar. Nasce do evento do ImpactRelay
## (zone_shown), visivel aos dois jogadores. O radius do play e o raio da luz (2,5 u).

## Pulsos por segundo e quanto o brilho varia.
const PULSE: float = 1.6
const PULSE_DEPTH: float = 0.25
## Abertura (s): a coluna desce do alto ate o chao.
const OPEN_SECONDS: float = 0.18
const MIN_SCALE: float = 0.001

## Material aditivo da coluna (cor do vertice): troca o PBR que vem no glb.
@export var pillar_material: Material

var _light_base: float = 0.0

@onready var _pillar: Node3D = $Pillar
@onready var _light: OmniLight3D = $Light
@onready var _motes: GPUParticles3D = $Motes


func _ready() -> void:
	for mesh: Node in _pillar.find_children("*", "MeshInstance3D", true, false):
		(mesh as MeshInstance3D).material_override = pillar_material
		(mesh as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	super()
	_light_base = _light.light_energy


func _process(delta: float) -> void:
	super(delta)
	if not visible:
		return
	var open := ease(clampf(_age / OPEN_SECONDS, 0.0, 1.0), 0.4)
	_pillar.scale.y = maxf(open, MIN_SCALE)
	var glow := 1.0 + PULSE_DEPTH * sin(TAU * PULSE * _age)
	var fade := clampf((lifetime - _age) / fade_seconds, 0.0, 1.0)
	_light.light_energy = _light_base * glow * fade
	_light.visible = fade > 0.0


## Fica [param seconds] aceso (depois do play).
func last(seconds: float) -> void:
	lifetime = seconds


## A luz e da coluna, nao do clarao: fora da lista que o VfxOneShot apaga em light_seconds.
func _collect() -> void:
	super()
	for i: int in range(_lights.size() - 1, -1, -1):
		if _lights[i].name == &"Light":
			_lights.remove_at(i)
			_light_energy.remove_at(i)


func _apply_radius(radius: float) -> void:
	_pillar.scale = Vector3(radius, _pillar.scale.y, radius)
	_light.omni_range = radius * 2.2
	var emitter := _motes.process_material as ParticleProcessMaterial
	emitter.emission_ring_radius = radius
	emitter.emission_ring_inner_radius = radius * 0.2
