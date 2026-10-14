class_name BlunderBlastVfx
extends VfxOneShot
## Tiro do Bacamarte (F59, SPEC-059 §6), de uma vez: clarao de boca em estrela, 10 estilhacos em
## leque que cobrem o cone do GDB (40 graus) ate o alcance (4,5 u) e 2 tufos de fumaca no cano. O
## alcance chega pelo play (engineer.tres); o leque e a abertura saem da cena (Shrapnel). Materiais
## locais a cena: cada instancia do pool tem os seus.

## Os estilhacos chegam ao alcance perto do fim da vida: velocidade = alcance / SHRAPNEL_REACH_TIME.
const SHRAPNEL_REACH_TIME: float = 0.2

const SHRAPNEL: PackedScene = preload("res://shared/assets/rrb/vfx/shrapnel.glb")

@onready var _shrapnel: GPUParticles3D = $Shrapnel


func _ready() -> void:
	_shrapnel.draw_pass_1 = SmokeCloudVfx.mesh_of(SHRAPNEL)
	super()


func _apply_radius(radius: float) -> void:
	var material := _shrapnel.process_material as ParticleProcessMaterial
	var speed := radius / SHRAPNEL_REACH_TIME
	material.initial_velocity_min = speed * 0.8
	material.initial_velocity_max = speed
