class_name ZoneRing
extends Node3D
## Parede da zona da fase 2 (F16; visual final no F17): cilindro vermelho translucido no raio de
## ZoneRules pelo MatchClock replicado, forte no chao e sumindo para cima (zone_wall.gdshader).
## Surge aos poucos nos 5 s da transicao, cobrindo a arena inteira (PRD §3.3), e fecha junto com
## a zona. So visual, igual nos dois lados.

const SHADER: Shader = preload("res://scenes/world/zone_wall.gdshader")
const WALL_HEIGHT: float = 4.0
const RING_SEGMENTS: int = 128

@export var clock: MatchClock
@export var rules: MatchRules

var _wall: MeshInstance3D
var _material: ShaderMaterial


func _ready() -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 1.0
	mesh.bottom_radius = 1.0
	mesh.height = WALL_HEIGHT
	mesh.radial_segments = RING_SEGMENTS
	mesh.cap_top = false
	mesh.cap_bottom = false
	_material = ShaderMaterial.new()
	_material.shader = SHADER
	_material.set_shader_parameter(&"color", UiTokens.RED)
	_material.set_shader_parameter(&"half_height", WALL_HEIGHT / 2.0)
	_wall = MeshInstance3D.new()
	_wall.mesh = mesh
	_wall.material_override = _material
	_wall.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_wall.position = ZoneController.CENTER + Vector3(0.0, WALL_HEIGHT / 2.0, 0.0)
	add_child(_wall)
	_wall.visible = false


func _process(_delta: float) -> void:
	refresh(NetworkTime.tick)


func is_shown() -> bool:
	return _wall.visible


func radius() -> float:
	return _wall.scale.x


## Quanto a parede ja surgiu (0-1).
func appear() -> float:
	return _material.get_shader_parameter(&"appear")


func refresh(tick: int) -> void:
	var t_phase2 := clock.phase2_elapsed(tick) if clock.is_started() else -1.0
	var zone_radius := ZoneRules.radius_at(rules, t_phase2)
	_wall.visible = t_phase2 >= 0.0 and zone_radius > 0.0
	if _wall.visible:
		_wall.scale = Vector3(zone_radius, 1.0, zone_radius)
		var appear_value := clampf(t_phase2 / rules.transition_duration, 0.0, 1.0)
		_material.set_shader_parameter(&"appear", appear_value)
