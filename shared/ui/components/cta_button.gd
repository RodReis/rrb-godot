class_name CtaButton
extends Button
## Botao grande de chamada (prototipo Menu Principal, BUSCAR PARTIDA 1V1): gradiente dourado,
## borda 3D de 6 px, reflexo que atravessa no hover (1 s), clareia no hover e afunda ao apertar.
## Variante DANGER (fila ativa: CANCELAR FILA) troca o gradiente pelo vermelho do prototipo.

enum Variant { GOLD, DANGER }

const SHADER: Shader = preload("res://shared/shaders/ui_cta.gdshader")
## group-hover:translate-x-[300%] duration-1000: o reflexo sai de -50 % e cruza ate 150 %.
const SHINE_FROM: float = -0.5
const SHINE_TO: float = 1.5
const SHINE_OFF: float = -1.0
const SHINE_SECONDS: float = 1.0
## hover:brightness-110.
const HOVER_BRIGHTEN: float = 0.1

var variant: Variant = Variant.GOLD:
	set(value):
		variant = value
		_apply_variant()

var _face: ColorRect = ColorRect.new()
var _material: ShaderMaterial = ShaderMaterial.new()
var _shine: Tween


func _init() -> void:
	theme_type_variation = &"LnButtonCta"
	_material.shader = SHADER
	_material.set_shader_parameter(&"radius", float(UiTokens.RADIUS_MD))
	_material.set_shader_parameter(&"edge", float(LauncherTheme.CTA_EDGE))
	_material.set_shader_parameter(&"edge_color", UiTokens.GOLD_SHADE)
	_material.set_shader_parameter(&"shine", SHINE_OFF)
	_face.material = _material
	_face.show_behind_parent = true
	_face.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(_face, false, INTERNAL_MODE_FRONT)
	_apply_variant()
	resized.connect(_on_resized)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	button_down.connect(_material.set_shader_parameter.bind(&"press", 1.0))
	button_up.connect(_material.set_shader_parameter.bind(&"press", 0.0))


## Posicao do reflexo (fracao da largura; fora de 0..1 = fora do botao).
func shine_position() -> float:
	return _material.get_shader_parameter(&"shine")


func _set_shine(position_x: float) -> void:
	_material.set_shader_parameter(&"shine", position_x)


func _apply_variant() -> void:
	var edge := UiTokens.GOLD_SHADE if variant == Variant.GOLD else UiTokens.ON_ERROR
	# from-primary-container via-primary to-primary-container | from-error-container to-error.
	var stops: Array[Color] = [UiTokens.GOLD, UiTokens.GOLD_BRIGHT, UiTokens.GOLD]
	if variant == Variant.DANGER:
		stops = [UiTokens.ERROR_BG, UiTokens.ERROR_BG.lerp(UiTokens.ERROR, 0.5), UiTokens.ERROR]
	_material.set_shader_parameter(&"color_from", stops[0])
	_material.set_shader_parameter(&"color_via", stops[1])
	_material.set_shader_parameter(&"color_to", stops[2])
	_material.set_shader_parameter(&"edge_color", edge)


func _on_resized() -> void:
	_face.position = Vector2.ZERO
	_face.size = size
	_material.set_shader_parameter(&"rect_size", size)


func _on_mouse_entered() -> void:
	_material.set_shader_parameter(&"brighten", HOVER_BRIGHTEN)
	if _shine != null:
		_shine.kill()
	_shine = create_tween()
	_shine.tween_method(_set_shine, SHINE_FROM, SHINE_TO, SHINE_SECONDS)


func _on_mouse_exited() -> void:
	_material.set_shader_parameter(&"brighten", 0.0)
