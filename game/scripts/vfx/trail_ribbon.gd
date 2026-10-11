class_name TrailRibbon
extends MeshInstance3D
## Rastro em fita (F41): guarda as posicoes de target dos ultimos lifetime segundos e redesenha uma
## fita horizontal que afina e some com a idade (cor do vertice; material aditivo na cena).
## O RibbonTrailMesh do GPUParticles3D desenha o caminho da particula, nao do emissor: a flecha
## corrigida pela rede e a espada que gira com o heroi nao seriam seguidas. So cliente.

## Ponto seguido (null = nenhum).
@export var target: Node3D
@export var lifetime: float = 0.12
@export var width: float = 0.08
## Distancia minima (u) entre pontos gravados.
@export var min_step: float = 0.02

## Desligado: para de gravar pontos; os que existem somem pela idade.
var emitting: bool = false

var _points: PackedVector3Array = PackedVector3Array()
var _ages: PackedFloat32Array = PackedFloat32Array()
var _immediate: ImmediateMesh = ImmediateMesh.new()


func _ready() -> void:
	top_level = true
	global_transform = Transform3D.IDENTITY
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh = _immediate  # a malha da cena e so para o warm-up do material


## Apaga o rastro (disparo novo, golpe novo): nao liga o ponto antigo ao novo.
func clear() -> void:
	_points.clear()
	_ages.clear()
	_immediate.clear_surfaces()


func _process(delta: float) -> void:
	for i: int in _ages.size():
		_ages[i] += delta
	while not _ages.is_empty() and _ages[0] >= lifetime:
		_ages.remove_at(0)
		_points.remove_at(0)
	if emitting and target != null:
		var at := target.global_position
		if _points.is_empty() or _points[-1].distance_to(at) >= min_step:
			_points.append(at)
			_ages.append(0.0)
	_rebuild()


# ponytail: ImmediateMesh refeito por quadro (poucos pontos, 1 fita por flecha/espada); trocar por
# ArrayMesh com buffer reusado se o profiler apontar.
func _rebuild() -> void:
	_immediate.clear_surfaces()
	var count := _points.size()
	if count < 2:
		return
	_immediate.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	for i: int in count:
		var ahead := _points[mini(i + 1, count - 1)] - _points[maxi(i - 1, 0)]
		var side := ahead.cross(Vector3.UP).normalized()
		var life := 1.0 - _ages[i] / lifetime
		_immediate.surface_set_color(Color(1.0, 1.0, 1.0, life))
		_immediate.surface_add_vertex(_points[i] + side * width * 0.5 * life)
		_immediate.surface_set_color(Color(1.0, 1.0, 1.0, life))
		_immediate.surface_add_vertex(_points[i] - side * width * 0.5 * life)
	_immediate.surface_end()
