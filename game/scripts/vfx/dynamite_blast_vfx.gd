class_name DynamiteBlastVfx
extends VfxOneShot
## Explosao da Dinamite (F59, SPEC-059 §6), de uma vez, junto da bola de fogo do F54: anel de choque
## no chao ate a borda e 8–12 destrocos de madeira que sobem e caem sobre o disco. O raio chega pelo
## play (engineer.tres). Materiais locais a cena: cada instancia do pool tem os seus.

const DEBRIS: Array[PackedScene] = [
	preload("res://shared/assets/rrb/vfx/debris_wood_a.glb"),
	preload("res://shared/assets/rrb/vfx/debris_wood_b.glb"),
]

@onready var _debris: GPUParticles3D = $Debris
@onready var _shock: GPUParticles3D = $Shockwave


func _ready() -> void:
	_debris.draw_passes = DEBRIS.size()
	_debris.draw_pass_1 = SmokeCloudVfx.mesh_of(DEBRIS[0])
	_debris.draw_pass_2 = SmokeCloudVfx.mesh_of(DEBRIS[1])
	super()


func _apply_radius(radius: float) -> void:
	var debris := _debris.process_material as ParticleProcessMaterial
	debris.emission_ring_radius = radius
	var shock := _shock.process_material as ParticleProcessMaterial
	shock.scale_min = radius * 2.0
	shock.scale_max = radius * 2.0
