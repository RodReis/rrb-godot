extends RefCounted
## Leitura da colisao e dos marcadores da arena no formato do fixture do F94 (usada pelo teste
## test_arena_colisao_fixa e pelo gerador tools/arena/collision_fixture.gd).


## Cada forma de colisao: [caminho, tipo, tamanho, transform global] em texto.
static func shapes(arena: Node3D) -> Array:
	var out: Array = []
	for node: Node in arena.find_children("*", "CollisionShape3D", true, false):
		var shape := node as CollisionShape3D
		var path := str(arena.get_path_to(shape))
		var size := _size(shape.shape)
		out.append([path, shape.shape.get_class(), size, var_to_str(shape.global_transform)])
	return out


## Cada marcador: [nome, posicao] em texto.
static func markers(arena: Node3D) -> Array:
	var out: Array = []
	for node: Node in arena.get_node("Markers").get_children():
		out.append([str(node.name), var_to_str((node as Node3D).position)])
	return out


static func _size(shape: Shape3D) -> String:
	if shape is BoxShape3D:
		return var_to_str((shape as BoxShape3D).size)
	if shape is CylinderShape3D:
		var cylinder := shape as CylinderShape3D
		return "r%s h%s" % [cylinder.radius, cylinder.height]
	if shape is ConvexPolygonShape3D:
		return str((shape as ConvexPolygonShape3D).points.size())
	return ""
