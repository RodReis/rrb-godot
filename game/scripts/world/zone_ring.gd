class_name ZoneRing
extends Node3D
## Borda da zona da fase 2 (PI 2026-10-10, minimo para a verificacao visual do F16): parede
## vermelha translucida no raio de ZoneRules pelo MatchClock replicado, a partir dos 5:00. So
## visual, igual nos dois lados; o visual final da zona e do F17.

const WALL_HEIGHT: float = 3.0
const WALL_ALPHA: float = 0.3

@export var clock: MatchClock
@export var rules: MatchRules

var _wall: MeshInstance3D


func _ready() -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 1.0
	mesh.bottom_radius = 1.0
	mesh.height = WALL_HEIGHT
	mesh.cap_top = false
	mesh.cap_bottom = false
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(UiTokens.RED, WALL_ALPHA)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_wall = MeshInstance3D.new()
	_wall.mesh = mesh
	_wall.material_override = material
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


func refresh(tick: int) -> void:
	var t_phase2 := clock.phase2_elapsed(tick) if clock.is_started() else -1.0
	var zone_radius := ZoneRules.radius_at(rules, t_phase2)
	_wall.visible = t_phase2 >= 0.0 and zone_radius > 0.0
	if _wall.visible:
		_wall.scale = Vector3(zone_radius, 1.0, zone_radius)
