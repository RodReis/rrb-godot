class_name WorldHealthBar
extends MeshInstance3D
## Placa de HP no mundo 3D sobre heroi, monstro e servo (PI 2026-10-09, #26; refeita em
## 2026-10-22): selo do nivel a esquerda (heroi = nivel, monstro = tier, chefe = coroa) e barra
## dividida a cada 100 HP, com rastro do dano que escorre e escudo em branco. GREEN = heroi local,
## RED = inimigo ou monstro (PATTERNS P9). Diegetica (DESIGN-SYSTEM principio 4); so le o que o
## dono passa. Um ShaderMaterial para todas; o resto por instancia (shader world_health_bar).

const SHADER: Shader = preload("res://scenes/ui/world_health_bar.gdshader")
const FONT_PATH: String = UiTokens.FONT_DATA_PATH
## Selo quadrado: lado = altura da barra x BADGE_SCALE; espaco ate a barra em fracao do selo.
const BADGE_SCALE: float = 1.6
const BADGE_GAP: float = 0.12
## Numero do selo: tamanho do pixel do Label3D (u) e altura do texto em fracao do selo.
const LABEL_PIXEL: float = 0.004
const LABEL_HEIGHT: float = 0.62
const LABEL_OUTLINE: int = 8
## Rastro do dano: espera antes de escorrer (s) e velocidade (fracao da barra por segundo).
const TRAIL_HOLD: float = 0.35
const TRAIL_SPEED: float = 0.9

static var _material: ShaderMaterial

@export var bar_size: Vector2 = Vector2(1.4, 0.2)

## Fracao mostrada e o rastro (>= ratio enquanto escorre).
var ratio: float = 1.0
var trail: float = 1.0

var _badge_text: String = ""
var _crown: bool = false
var _trail_hold: float = 0.0
var _label: Label3D = Label3D.new()


func _ready() -> void:
	if _material == null:
		_material = ShaderMaterial.new()
		_material.shader = SHADER
		_material.set_shader_parameter(&"back_color", Color(UiTokens.BG_SURFACE, 1.0))
	material_override = _material
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.pixel_size = LABEL_PIXEL
	_label.outline_size = LABEL_OUTLINE
	_label.font = load(FONT_PATH) as Font
	_label.layers = layers
	_label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_label.no_depth_test = true  # como a barra: por cima do cenario
	_label.render_priority = 1  # e por cima do selo
	add_child(_label)
	_layout()
	set_friendly(false)
	set_process(false)


## HP atual, maximo e escudo (mesma unidade do HP). Queda deixa o rastro, que escorre depois.
func set_hp(hp: float, max_hp: float, shield: float = 0.0) -> void:
	var top := maxf(max_hp, 1.0)
	var next := clampf(hp / top, 0.0, 1.0)
	if next < ratio:
		_trail_hold = TRAIL_HOLD
		set_process(true)
	ratio = next
	trail = maxf(trail, ratio)
	set_instance_shader_parameter(&"ratio", ratio)
	set_instance_shader_parameter(&"trail", trail)
	set_instance_shader_parameter(&"max_hp", top)
	set_instance_shader_parameter(&"shield", maxf(shield, 0.0) / top)


func set_friendly(friendly: bool) -> void:
	var color := UiTokens.GREEN if friendly else UiTokens.RED
	set_instance_shader_parameter(&"fill_color", color)
	if not _crown:
		set_instance_shader_parameter(&"badge_color", color)


## Texto do selo ("7"); vazio esconde o selo. [param crown]: selo dourado com coroa (chefe).
func set_badge(text: String, crown: bool = false) -> void:
	if text == _badge_text and crown == _crown and is_node_ready():
		return
	_badge_text = text
	_crown = crown
	if crown:
		set_instance_shader_parameter(&"badge_color", UiTokens.GOLD)
	if is_node_ready():
		_layout()


func badge_text() -> String:
	return _badge_text if _label.visible else ""


func _process(delta: float) -> void:
	if _trail_hold > 0.0:
		_trail_hold -= delta
		return
	trail = move_toward(trail, ratio, TRAIL_SPEED * delta)
	set_instance_shader_parameter(&"trail", trail)
	if trail <= ratio:
		set_process(false)


## Quad = selo + espaco + barra; sem selo, so a barra. O numero fica no centro do selo.
func _layout() -> void:
	var badged := not _badge_text.is_empty() or _crown
	var side := bar_size.y * BADGE_SCALE if badged else 0.0
	var width := bar_size.x + side * (1.0 + BADGE_GAP)
	var height := side if badged else bar_size.y
	var quad := QuadMesh.new()
	quad.size = Vector2(width, height)
	mesh = quad
	set_instance_shader_parameter(&"badge_frac", side / width)
	set_instance_shader_parameter(&"gap_frac", side * BADGE_GAP / width)
	set_instance_shader_parameter(&"bar_height", bar_size.y / height)
	set_instance_shader_parameter(&"crown", 1.0 if _crown else 0.0)
	_label.visible = badged and not _crown
	if not _label.visible:
		return
	_label.text = _badge_text
	_label.font_size = roundi(side * LABEL_HEIGHT / LABEL_PIXEL)
	_label.offset = Vector2(-(width - side) / 2.0 / LABEL_PIXEL, 0.0)
