class_name BossPortal
extends Node3D
## Pista visual do aviso do boss (PATTERNS P7, PI 2026-10-09): anel e feixe roxos pulsando no
## marcador BOSS, do aviso (3:00) ate o Rei Esqueleto surgir. So visual; o SpawnDirector cria
## e remove nos dois lados pelos eventos do MatchClock.

const RING_INNER: float = 2.2
const RING_OUTER: float = 2.8
const BEAM_RADIUS: float = 0.35
const BEAM_HEIGHT: float = 10.0
const BEAM_ALPHA: float = 0.35
const PULSE_SCALE: float = 1.15


func _ready() -> void:
	var ring := TorusMesh.new()
	ring.inner_radius = RING_INNER
	ring.outer_radius = RING_OUTER
	_add_mesh(ring, Vector3.ZERO, 1.0)
	var beam := CylinderMesh.new()
	beam.top_radius = BEAM_RADIUS
	beam.bottom_radius = BEAM_RADIUS
	beam.height = BEAM_HEIGHT
	_add_mesh(beam, Vector3(0.0, BEAM_HEIGHT / 2.0, 0.0), BEAM_ALPHA)
	var pulse := create_tween().set_loops().set_trans(Tween.TRANS_SINE)
	pulse.tween_property(self, ^"scale", Vector3.ONE * PULSE_SCALE, UiTokens.DUR_SLOW)
	pulse.tween_property(self, ^"scale", Vector3.ONE, UiTokens.DUR_SLOW)


func _add_mesh(mesh: Mesh, offset: Vector3, alpha: float) -> void:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(UiTokens.PURPLE, alpha)
	if alpha < 1.0:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	instance.position = offset
	add_child(instance)
