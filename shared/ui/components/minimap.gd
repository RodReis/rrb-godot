class_name Minimap
extends SubViewportContainer
## Minimapa da fase 1 (COMPONENTS.md): camera ortografica de cima sobre o World3D da partida
## num SubViewport (DEBITO DS-07: medir FPS) e marcadores desenhados por cima. So enxerga a
## camada visual 1; rotulos e barras sobre a cabeca ficam na WORLD_OVERLAY_LAYER. Nao le dado
## sozinho: quem usa passa o mundo, o giro e as posicoes.

## Camada visual (bit) de rotulos e barras no mundo, fora do minimapa.
const WORLD_OVERLAY_LAYER: int = 2
const CAMERA_HEIGHT: float = 80.0
const MARKER_OUTLINE: float = 2.0

## Meia largura do mundo mostrada (u), a partir da origem.
@export var world_extent: float = 37.0
@export var marker_radius: float = 6.0

var _positions: PackedVector3Array = PackedVector3Array()
var _colors: PackedColorArray = PackedColorArray()

@onready var _viewport: SubViewport = %Viewport
@onready var _camera: Camera3D = %Camera
@onready var _markers: Control = %Markers


func _ready() -> void:
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.size = world_extent * 2.0
	_camera.far = CAMERA_HEIGHT * 2.0
	_camera.cull_mask = 1
	set_yaw(0.0)
	_markers.draw.connect(_on_markers_draw)


func bind(world: Node3D) -> void:
	_viewport.world_3d = world.get_world_3d()


## Gira o mapa para o "para cima" seguir a camera do jogador ([param yaw] em radianos).
func set_yaw(yaw: float) -> void:
	var basis := Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, -PI / 2.0)
	_camera.transform = Transform3D(basis, Vector3(0.0, CAMERA_HEIGHT, 0.0))


## Pontos do mundo e cor de cada um; os arrays sao copiados pelo Godot (Packed).
func set_markers(positions: PackedVector3Array, colors: PackedColorArray) -> void:
	_positions = positions
	_colors = colors
	_markers.queue_redraw()


func _on_markers_draw() -> void:
	var ratio := _markers.size / Vector2(_viewport.size)
	for i: int in mini(_positions.size(), _colors.size()):
		var point := _camera.unproject_position(_positions[i]) * ratio
		_markers.draw_circle(point, marker_radius + MARKER_OUTLINE, UiTokens.BG_SURFACE)
		_markers.draw_circle(point, marker_radius, _colors[i])
