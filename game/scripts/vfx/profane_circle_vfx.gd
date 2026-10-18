class_name ProfaneCircleVfx
extends SwampZoneVfx
## Circulo Profano do Ocultista (F77, SPEC-077 §VFX), so cliente: o mesmo disco de zona do Pantano
## (anel tracejado do raio, marcacao visivel como a do Meteoro, onda por pulso, motes e neblina) em
## roxo, com o glifo (aneis + estrela de 5 pontas, profane_glyph.glb) girando devagar no chao.
## Nasce do evento do ImpactRelay (zone_shown); raio, tempo e pulso de occultist.tres.

## Voltas por segundo do glifo.
const GLYPH_SPIN: float = 0.08

@onready var _glyph: Node3D = $Glyph


func _process(delta: float) -> void:
	super(delta)
	if visible:
		_glyph.rotate_y(TAU * GLYPH_SPIN * delta)


func _apply_radius(radius: float) -> void:
	super(radius)
	_glyph.scale = Vector3(radius, 1.0, radius)
