class_name ZoneRadar
extends Control
## Radar da zona (COMPONENTS.md, DV tela 4): fora do circulo seguro vermelho translucido, borda
## do circulo em TEXT, proximo fechamento tracejado em GOLD e os herois. Desenha por _draw, por
## cima do Minimap (mesma escala e giro: world_extent e set_yaw) ou sozinho. Nao le dado: recebe
## a fracao do raio e as posicoes.

const RING_WIDTH: float = 2.0
const RING_POINTS: int = 96
## Pedacos do circulo tracejado (metade desenhada).
const DASHES: int = 48
const OUTSIDE_ALPHA: float = 0.35
const MARKER_OUTLINE: float = 2.0

## Meia largura do mundo mostrada (u): a mesma do Minimap por baixo.
@export var world_extent: float = 1.0
## Raio do mundo (u) que vale 100 % da zona.
@export var full_radius: float = 1.0
@export var marker_radius: float = 6.0

var radius_pct: float = 1.0
var next_radius_pct: float = 1.0
## Segundos ate o proximo fechamento (0 = nenhum: sem circulo tracejado).
var t_next: float = 0.0

var _yaw: float = 0.0
var _positions: PackedVector3Array = PackedVector3Array()
var _colors: PackedColorArray = PackedColorArray()


func _init() -> void:
	clip_contents = true
	mouse_filter = MOUSE_FILTER_IGNORE


## Ponto do mundo no radar (px a partir do canto de [param area]): "para cima" segue o giro
## [param yaw], como a camera do Minimap (direita = X girado, cima = -Z girado).
static func to_radar(point: Vector3, yaw: float, extent: float, area: Vector2) -> Vector2:
	var right := Vector3.RIGHT.rotated(Vector3.UP, yaw)
	var up := Vector3.FORWARD.rotated(Vector3.UP, yaw)
	var half := area / 2.0
	var scale := minf(half.x, half.y) / extent
	return half + Vector2(point.dot(right), -point.dot(up)) * scale


func set_zone(p_radius_pct: float, p_next_radius_pct: float, p_t_next: float) -> void:
	radius_pct = maxf(p_radius_pct, 0.0)
	next_radius_pct = maxf(p_next_radius_pct, 0.0)
	t_next = p_t_next
	queue_redraw()


## Pontos do mundo e cor de cada heroi, copiados para buffers proprios: quem chama pode reusar
## os arrays dele a cada frame sem alocar (Packed e copy-on-write).
func set_players(positions: PackedVector3Array, colors: PackedColorArray) -> void:
	var count := mini(positions.size(), colors.size())
	_positions.resize(count)
	_colors.resize(count)
	for i: int in count:
		_positions[i] = positions[i]
		_colors[i] = colors[i]
	queue_redraw()


## Giro da camera (radianos), o mesmo passado ao Minimap.
func set_yaw(yaw: float) -> void:
	_yaw = yaw
	queue_redraw()


## Raio em px de uma fracao da zona.
func radius_px(pct: float) -> float:
	return pct * full_radius * minf(size.x, size.y) / 2.0 / world_extent


func _draw() -> void:
	var center := size / 2.0
	var radius := radius_px(radius_pct)
	var outer := size.length() / 2.0
	if radius < outer:
		var band := Color(UiTokens.RED, OUTSIDE_ALPHA)
		draw_arc(center, (radius + outer) / 2.0, 0.0, TAU, RING_POINTS, band, outer - radius)
	if radius > 0.0:
		draw_arc(center, radius, 0.0, TAU, RING_POINTS, UiTokens.TEXT, RING_WIDTH, true)
	var next := radius_px(next_radius_pct)
	if t_next > 0.0 and next > 0.0 and next < radius:
		var step := TAU / DASHES
		for i: int in range(0, DASHES, 2):
			draw_arc(center, next, i * step, (i + 1) * step, 4, UiTokens.GOLD, RING_WIDTH, true)
	for i: int in mini(_positions.size(), _colors.size()):
		var point := to_radar(_positions[i], _yaw, world_extent, size)
		draw_circle(point, marker_radius + MARKER_OUTLINE, UiTokens.BG_SURFACE)
		draw_circle(point, marker_radius, _colors[i])
