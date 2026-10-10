class_name WorldHealthBar
extends MeshInstance3D
## Barra de HP no mundo 3D sobre heroi e monstro (PI 2026-10-09, #26): GREEN = heroi local,
## RED = inimigo ou monstro (PATTERNS P9). Diegetica (DESIGN-SYSTEM principio 4); so le o HP
## que o dono passa. Um ShaderMaterial para todas; proporcao e cor por instancia.

const SHADER: Shader = preload("res://scenes/ui/world_health_bar.gdshader")

static var _material: ShaderMaterial

@export var bar_size: Vector2 = Vector2(1.4, 0.2)


func _ready() -> void:
	if _material == null:
		_material = ShaderMaterial.new()
		_material.shader = SHADER
		_material.set_shader_parameter(&"back_color", Color(UiTokens.BG_SURFACE, 1.0))
	var quad := QuadMesh.new()
	quad.size = bar_size
	mesh = quad
	material_override = _material
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	layers = Minimap.WORLD_OVERLAY_LAYER
	set_friendly(false)


func set_ratio(ratio: float) -> void:
	set_instance_shader_parameter(&"ratio", clampf(ratio, 0.0, 1.0))


func set_friendly(friendly: bool) -> void:
	set_instance_shader_parameter(&"fill_color", UiTokens.GREEN if friendly else UiTokens.RED)
