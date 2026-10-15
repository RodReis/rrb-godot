class_name Backdrop
extends ColorRect
## Fundo de tela com gradiente, vinheta e brilhos suaves (shader ui_backdrop): o que os
## prototipos fazem com bg-gradient, radial-gradient e div blur-3xl (FRONTEND-LAUNCHER §8.2).
## Nao recebe mouse. Configure com gradient(), vignette() e glow().

const SHADER: Shader = preload("res://shared/shaders/ui_backdrop.gdshader")
const MAX_GLOWS: int = 3

var _material: ShaderMaterial = ShaderMaterial.new()
var _glow_colors: PackedColorArray = PackedColorArray()
var _glow_centers: PackedVector2Array = PackedVector2Array()
var _glow_radii: PackedFloat32Array = PackedFloat32Array()
var _glow_periods: PackedFloat32Array = PackedFloat32Array()


func _init() -> void:
	color = Color.WHITE
	mouse_filter = MOUSE_FILTER_IGNORE
	_material.shader = SHADER
	material = _material
	_glow_colors.resize(MAX_GLOWS)
	_glow_colors.fill(Color.TRANSPARENT)
	_glow_centers.resize(MAX_GLOWS)
	_glow_radii.resize(MAX_GLOWS)
	_glow_periods.resize(MAX_GLOWS)
	_push_glows()
	resized.connect(_on_resized)


## Gradiente vertical de baixo para cima (bg-gradient-to-t from/via/to).
func gradient(bottom: Color, mid: Color, top: Color) -> void:
	_material.set_shader_parameter(&"bottom_color", bottom)
	_material.set_shader_parameter(&"mid_color", mid)
	_material.set_shader_parameter(&"top_color", top)


## Vinheta radial do centro para a borda.
func vignette(center: Color, edge: Color) -> void:
	_material.set_shader_parameter(&"vignette_center", center)
	_material.set_shader_parameter(&"vignette_edge", edge)


## Brilho [param index] (0..2): centro em UV, raio em px, pulso em s (0 = parado).
func glow(
	index: int, glow_color: Color, center: Vector2, radius: float, period: float = 0.0
) -> void:
	_glow_colors[index] = glow_color
	_glow_centers[index] = center
	_glow_radii[index] = radius
	_glow_periods[index] = period
	_push_glows()


func _push_glows() -> void:
	_material.set_shader_parameter(&"glow_color", _glow_colors)
	_material.set_shader_parameter(&"glow_center", _glow_centers)
	_material.set_shader_parameter(&"glow_radius", _glow_radii)
	_material.set_shader_parameter(&"glow_period", _glow_periods)


func _on_resized() -> void:
	_material.set_shader_parameter(&"rect_size", size)
