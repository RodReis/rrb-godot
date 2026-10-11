class_name GhostVfx
extends VfxOneShot
## Fantasma do Rolamento da Arqueira (F41, 0,2 s): copia a pose atual das malhas do modelo
## (bake_mesh_from_current_skeleton_pose) com material de fresnel translucido e some no lifetime.
## Os filhos de malha sao reusados entre rolamentos (o pool reusa o efeito).

@export var ghost_material: Material

## Malhas do fantasma (a 1a vem da cena e aquece o shader no warm-up).
var _copies: Array[MeshInstance3D] = []


## Congela a pose de [param model] no lugar onde ela esta agora.
func capture(model: Node3D) -> void:
	if _copies.is_empty():
		_copies.append($Mesh as MeshInstance3D)
	var used := 0
	for node: Node in model.find_children("*", "MeshInstance3D", true, false):
		var source := node as MeshInstance3D
		if not source.is_visible_in_tree() or source.mesh == null:
			continue
		var copy := _copy_at(used)
		var posed: Mesh = source.mesh
		if source.skin != null:
			posed = null  # renderer dummy (headless, testes) nao registra o skin: sem pose
			if RenderingServer.get_rendering_device() != null:
				posed = source.bake_mesh_from_current_skeleton_pose(copy.mesh as ArrayMesh)
		copy.mesh = posed
		copy.global_transform = source.global_transform
		copy.visible = posed != null
		used += 1
	for i: int in range(used, _copies.size()):
		_copies[i].visible = false
	_collect()
	_fade(0.0)


func _copy_at(index: int) -> MeshInstance3D:
	if index < _copies.size():
		return _copies[index]
	var copy := MeshInstance3D.new()
	copy.material_override = ghost_material
	copy.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(copy)
	_copies.append(copy)
	return copy
