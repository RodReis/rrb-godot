class_name EarthquakeVfx
extends VfxOneShot
## Terremoto do Cavaleiro (F41): rachadura (Decal) no raio do GDB que some no fim, erupcao de
## fragmentos sobre o disco e onda de choque com refracao que chega ate a borda. O raio chega pelo
## play (skill_r.radius de knight.tres); materiais locais a cena, cada instancia do pool tem o seu.

## Altura da caixa do decal (u): pega o chao sem subir nas pernas de quem esta na area.
const DECAL_HEIGHT: float = 0.8

@onready var _crack: Decal = $Crack
@onready var _fragments: GPUParticles3D = $Fragments
@onready var _shock: GPUParticles3D = $Shockwave


func _apply_radius(radius: float) -> void:
	_crack.size = Vector3(radius * 2.0, DECAL_HEIGHT, radius * 2.0)
	(_fragments.process_material as ParticleProcessMaterial).emission_ring_radius = radius
	var shock := _shock.process_material as ParticleProcessMaterial
	shock.scale_min = radius * 2.0
	shock.scale_max = radius * 2.0
