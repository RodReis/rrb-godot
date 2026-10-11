class_name VfxOneShot
extends Node3D
## Efeito de uma vez do VfxPool (F41): faiscas, poeira, pulso, Terremoto, fantasma do Rolamento.
## play() reinicia as particulas filhas, acende a luz efemera (OmniLight3D) e, nos ultimos
## fade_seconds, apaga decals e malhas; no fim fica oculto e avisa o pool (finished). So cliente.

## O efeito terminou e pode voltar ao pool.
signal finished(effect: VfxOneShot)

@export var lifetime: float = 1.0
## As OmniLight3D filhas apagam em light_seconds (0,15–0,3 s, spec F41).
@export var light_seconds: float = 0.2
## Decals e malhas somem nos ultimos fade_seconds.
@export var fade_seconds: float = 0.3

var _age: float = 0.0
var _particles: Array[GPUParticles3D] = []
var _lights: Array[OmniLight3D] = []
var _light_energy: PackedFloat32Array = PackedFloat32Array()
var _decals: Array[Decal] = []
var _meshes: Array[MeshInstance3D] = []


func _ready() -> void:
	_collect()
	hide()
	set_process(false)


func _process(delta: float) -> void:
	_age += delta
	if _age >= lifetime:
		hide()
		set_process(false)
		finished.emit(self)
		return
	_fade(_age)


## Comeca em [param at]; [param radius] > 0 dimensiona o efeito de area (subclasse).
func play(at: Transform3D, radius: float = 0.0) -> void:
	global_transform = at
	if radius > 0.0:
		_apply_radius(radius)
	_age = 0.0
	show()
	for particles: GPUParticles3D in _particles:
		particles.restart()
	_fade(0.0)
	set_process(true)


## Refaz as listas de filhos (subclasse que cria filhos depois do _ready).
func _collect() -> void:
	_particles.clear()
	_lights.clear()
	_light_energy.clear()
	_decals.clear()
	_meshes.clear()
	for node: Node in find_children("*", "", true, false):
		if node is GPUParticles3D:
			_particles.append(node)
		elif node is OmniLight3D:
			_lights.append(node)
			_light_energy.append((node as OmniLight3D).light_energy)
		elif node is Decal:
			_decals.append(node)
		elif node is MeshInstance3D:
			_meshes.append(node)


func _fade(age: float) -> void:
	var light := maxf(1.0 - age / light_seconds, 0.0)
	for i: int in _lights.size():
		_lights[i].light_energy = _light_energy[i] * light
		_lights[i].visible = light > 0.0
	var alpha := clampf((lifetime - age) / fade_seconds, 0.0, 1.0)
	for decal: Decal in _decals:
		decal.modulate.a = alpha
	for mesh: MeshInstance3D in _meshes:
		mesh.transparency = 1.0 - alpha


func _apply_radius(_radius: float) -> void:
	pass
