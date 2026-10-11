class_name HoldRing
extends Control
## Anel de progresso de segurar F (SPEC-047 §3): arco de GOLD sobre trilho de BORDER, de 0 a 1.

const SIZE: float = 28.0
const WIDTH: float = 3.0
const SEGMENTS: int = 32

var progress: float = 0.0:
	set(value):
		var clamped := clampf(value, 0.0, 1.0)
		if clamped != progress:
			progress = clamped
			queue_redraw()


func _init() -> void:
	custom_minimum_size = Vector2(SIZE, SIZE)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var center := size / 2.0
	var radius := (minf(size.x, size.y) - WIDTH) / 2.0
	draw_arc(center, radius, 0.0, TAU, SEGMENTS, UiTokens.BORDER, WIDTH, true)
	if progress > 0.0:
		var start := -PI / 2.0
		draw_arc(
			center, radius, start, start + TAU * progress, SEGMENTS, UiTokens.GOLD, WIDTH, true
		)
