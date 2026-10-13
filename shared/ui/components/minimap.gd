class_name Minimap
extends Control
## Minimapa das fases 1 e 2 (COMPONENTS.md): imagem pronta do mapa (tools/arena/minimap_image.gd,
## luz de dia, sempre clara — F65, ADR-0014) girada com a camera do jogador e marcadores
## desenhados por cima. Mesma projecao do ZoneRadar (ZoneRadar.to_radar), que fica por cima na
## fase 2. Nao le dado sozinho: quem usa passa o giro e as posicoes.

const MARKER_OUTLINE: float = 2.0

## Imagem do mapa vista de cima, cobrindo o quadrado de lado 2 x world_extent centrado na origem
## (cima = -Z, direita = +X).
@export var map_texture: Texture2D
## Meia largura do mundo mostrada (u), a partir da origem: o quadrado jogavel de 40 u mais a
## beira da ilha (SPEC-046 §1).
@export var world_extent: float = 42.0
@export var marker_radius: float = 6.0

var _yaw: float = 0.0
var _positions: PackedVector3Array = PackedVector3Array()
var _colors: PackedColorArray = PackedColorArray()
var _radii: PackedFloat32Array = PackedFloat32Array()


## Mundo (x, z) -> ponto do controle de tamanho [param area]: igual a ZoneRadar.to_radar.
static func map_transform(yaw: float, extent: float, area: Vector2) -> Transform2D:
	var px := minf(area.x, area.y) / 2.0 / extent
	return Transform2D(yaw, Vector2(px, px), 0.0, area / 2.0)


## Gira o mapa para o "para cima" seguir a camera do jogador ([param yaw] em radianos).
func set_yaw(yaw: float) -> void:
	if is_equal_approx(yaw, _yaw):
		return
	_yaw = yaw
	queue_redraw()


## Ponto do controle onde o [param point] do mundo cai.
func point_of(point: Vector3) -> Vector2:
	return ZoneRadar.to_radar(point, _yaw, world_extent, size)


## Pontos do mundo, cor e raio (px) de cada um; sem raio = [member marker_radius]. Os arrays sao
## copiados pelo Godot (Packed).
func set_markers(
	positions: PackedVector3Array,
	colors: PackedColorArray,
	radii: PackedFloat32Array = PackedFloat32Array()
) -> void:
	_positions = positions
	_colors = colors
	_radii = radii
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), UiTokens.BG_SURFACE)
	if map_texture != null:
		draw_set_transform_matrix(map_transform(_yaw, world_extent, size))
		var side := world_extent * 2.0
		draw_texture_rect(map_texture, Rect2(-world_extent, -world_extent, side, side), false)
		draw_set_transform_matrix(Transform2D.IDENTITY)
	for i: int in mini(_positions.size(), _colors.size()):
		var point := point_of(_positions[i])
		var radius := _radii[i] if i < _radii.size() else marker_radius
		draw_circle(point, radius + MARKER_OUTLINE, UiTokens.BG_SURFACE)
		draw_circle(point, radius, _colors[i])
