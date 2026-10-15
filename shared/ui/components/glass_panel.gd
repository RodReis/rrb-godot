class_name GlassPanel
extends PanelContainer
## Cartao de vidro (backdrop-blur dos prototipos, FRONTEND-LAUNCHER §8.2): o fundo do Theme
## (semitransparente) tinge um desfoque do que esta atras (shader ui_glass). Use com um tipo de
## painel do Theme (LnCardGlass, LnConsole, LnConsoleSoft) em theme_type_variation.

const SHADER: Shader = preload("res://shared/shaders/ui_glass.gdshader")
## backdrop-blur-md / xl / 2xl ~ nivel do mipmap da tela.
const BLUR_MD: float = 2.0
const BLUR_XL: float = 3.0
const BLUR_2XL: float = 4.0

var _blur: ColorRect = ColorRect.new()
var _material: ShaderMaterial = ShaderMaterial.new()


func _init(blur_lod: float = BLUR_XL) -> void:
	_material.shader = SHADER
	_material.set_shader_parameter(&"blur_lod", blur_lod)
	_blur.material = _material
	_blur.show_behind_parent = true
	_blur.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(_blur, false, INTERNAL_MODE_FRONT)
	resized.connect(_on_resized)


func _on_resized() -> void:
	# O PanelContainer encaixa o filho na margem do conteudo; o vidro cobre o retangulo todo.
	_blur.position = Vector2.ZERO
	_blur.size = size
	_material.set_shader_parameter(&"rect_size", size)
	var box := get_theme_stylebox(&"panel") as StyleBoxFlat
	if box != null:
		_material.set_shader_parameter(&"radius", float(box.corner_radius_top_left))
