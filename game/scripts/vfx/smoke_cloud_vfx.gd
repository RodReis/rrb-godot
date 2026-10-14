class_name SmokeCloudVfx
extends VfxOneShot
## Bomba de Fumaca da Ladina (F58, SPEC-058 §6), so cliente: a bomba do pack cai aos pes, quica e
## estoura; tufos de fumaca (malhas smoke_puff_a/b/c em GPUParticles3D, sem FogVolume pelo
## orcamento) crescem em grow_seconds, derivam devagar e se desfazem nos ultimos
## dissolve_seconds; um anel discreto no chao marca o raio. O raio chega pelo play e a duracao
## pelo last (rogue.tres; quem chega atrasado ve so o que falta). Materiais locais a cena.

## Os tufos nascem ate esta fracao do raio (o tamanho deles cobre o resto).
const SPREAD_FILL: float = 0.6
## Escala dos tufos por u de raio da nuvem (malha de 1 u de diametro).
const PUFF_PER_RADIUS: float = 0.55
## Variacao do tamanho dos tufos (fracao).
const PUFF_JITTER: float = 0.25
## Escala do tufo no fim da dissolucao (some encolhendo um pouco, alem do alfa).
const DISSOLVE_SCALE: float = 0.85
const PUFF_MESHES: Array[PackedScene] = [
	preload("res://shared/assets/rrb/vfx/smoke_puff_a.glb"),
	preload("res://shared/assets/rrb/vfx/smoke_puff_b.glb"),
	preload("res://shared/assets/rrb/vfx/smoke_puff_c.glb"),
]

@export var grow_seconds: float = 0.3
@export var dissolve_seconds: float = 0.5
## Queda e quique da bomba antes de estourar (s) e altura do quique (u).
@export var bomb_seconds: float = 0.3
@export var bomb_hop: float = 0.45

var _puffs: Array[GPUParticles3D] = []

@onready var _bomb: Node3D = $Bomb
@onready var _ring: MeshInstance3D = $Ring


func _ready() -> void:
	for i: int in PUFF_MESHES.size():
		var particles := get_node("Puffs%d" % i) as GPUParticles3D
		particles.draw_pass_1 = mesh_of(PUFF_MESHES[i])
		_puffs.append(particles)
	super()


## Dura [param seconds] a partir de agora (chamado logo depois do play). Curvas novas a cada nuvem
## (uma a cada 10 s no maximo): as da cena sao compartilhadas entre as instancias do pool.
func last(seconds: float) -> void:
	lifetime = seconds
	var grow := clampf(grow_seconds / seconds, 0.0, 1.0)
	var fade := clampf(1.0 - dissolve_seconds / seconds, grow, 1.0)
	for particles: GPUParticles3D in _puffs:
		particles.lifetime = seconds
		var process := particles.process_material as ParticleProcessMaterial
		var curve := Curve.new()
		curve.add_point(Vector2(0.0, 0.0))
		curve.add_point(Vector2(grow, 1.0))
		curve.add_point(Vector2(fade, 1.0))
		curve.add_point(Vector2(1.0, DISSOLVE_SCALE))
		var scale_texture := CurveTexture.new()
		scale_texture.curve = curve
		process.scale_curve = scale_texture
		var ramp := (process.color_ramp as GradientTexture1D).gradient.duplicate() as Gradient
		ramp.set_offset(1, fade)
		var ramp_texture := GradientTexture1D.new()
		ramp_texture.gradient = ramp
		process.color_ramp = ramp_texture
		particles.restart()


func _apply_radius(radius: float) -> void:
	_ring.scale = Vector3(radius, 1.0, radius)
	for particles: GPUParticles3D in _puffs:
		var process := particles.process_material as ParticleProcessMaterial
		process.emission_sphere_radius = radius * SPREAD_FILL
		process.scale_min = radius * PUFF_PER_RADIUS * (1.0 - PUFF_JITTER)
		process.scale_max = radius * PUFF_PER_RADIUS * (1.0 + PUFF_JITTER)


## A bomba quica uma vez e some quando a fumaca estoura.
func _fade(age: float) -> void:
	super(age)
	if _bomb == null:
		return
	var t := age / bomb_seconds
	_bomb.visible = t < 1.0
	if _bomb.visible:
		_bomb.position.y = bomb_hop * 4.0 * t * (1.0 - t)


static func mesh_of(scene: PackedScene) -> Mesh:
	var instance := scene.instantiate()
	var found := instance.find_children("*", "MeshInstance3D", true, false)
	var mesh: Mesh = (found[0] as MeshInstance3D).mesh if not found.is_empty() else null
	instance.free()
	return mesh
