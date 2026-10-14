class_name ScaledVfx
extends VfxOneShot
## Efeito de uma vez que escala inteiro pelo radius do play (clarao do disparo da Ladina, F58: o da
## Rajada e maior). Sempre passe o radius: a instancia do pool guarda a escala do uso anterior.


func _apply_radius(radius: float) -> void:
	scale = Vector3.ONE * radius
