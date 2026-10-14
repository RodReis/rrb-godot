class_name TurretTracerVfx
extends VfxOneShot
## Tracante reto da Torreta (F59, SPEC-059 §6): 0,08 s do cano ao alvo, com clarao de boca na ponta
## de partida. Nasce em [param at] olhando para o alvo; o comprimento chega pelo play (radius).

@onready var _beam: MeshInstance3D = $Beam


func _apply_radius(length: float) -> void:
	_beam.scale = Vector3(1.0, 1.0, maxf(length, 0.01))
