class_name ValleyForest
extends Node3D
## Floresta do vale (F56, ADR-0012): os pinheiros vem como dado do builder
## (tools/arena/arena_valley.gd, em scenes/arena/valley_forest.tscn) e os MultiMesh sao montados
## aqui, um por lado de TILE_SIZE u: o corte por frustum e por tile (um MultiMesh unico entra
## inteiro em qualquer vista). O builder roda headless e o servidor de renderizacao headless nao
## guarda buffer de MultiMesh: a cena nao tem como salvar o MultiMesh pronto. So visual: no
## servidor headless o node sai da arvore no _ready, sem alocar nada.

const TILE_SIZE: float = 40.0
## Pinheiro leve de cartoes (F96, art/arena/build_rim_kit.py): so a copa, uma superficie.
const PINE_SCENE: String = "res://shared/assets/rrb/arena/kit/kit_pine_far.glb"

## Uma arvore por item: (x, y, z, escala uniforme). O giro sai de um hash da posicao.
@export var trees: PackedVector4Array = PackedVector4Array()


func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		queue_free()
		return
	var pine := _pine()
	if pine == null:
		return
	var groups := group_by_tile(trees, TILE_SIZE)
	for key: Vector2i in groups.keys():
		add_child(_tile(key, groups[key] as PackedVector4Array, pine))
	pine.free()


## Arvores por tile (indice inteiro do quadrado de [param size] u): chave `Vector2i`, valor
## `PackedVector4Array`. Cada arvore cai em exatamente um tile.
static func group_by_tile(data: PackedVector4Array, size: float) -> Dictionary:
	var groups: Dictionary = {}
	for tree: Vector4 in data:
		var key := Vector2i(floori(tree.x / size), floori(tree.z / size))
		# PackedArray e valor: o balde sai do dicionario, cresce e volta.
		var bucket: PackedVector4Array = groups.get(key, PackedVector4Array())
		bucket.append(tree)
		groups[key] = bucket
	return groups


## Giro de uma arvore em (x, z): hash deterministico (a floresta e igual a cada partida).
static func yaw_at(x: float, z: float) -> float:
	return TAU * fposmod(sin(x * 12.9898 + z * 78.233) * 43758.5453, 1.0)


func _tile(key: Vector2i, data: PackedVector4Array, pine: MeshInstance3D) -> MultiMeshInstance3D:
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.mesh = pine.mesh
	multi.instance_count = data.size()
	for i: int in range(data.size()):
		var t := data[i]
		var basis := Basis(Vector3.UP, yaw_at(t.x, t.z)).scaled(Vector3.ONE * t.w)
		multi.set_instance_transform(i, Transform3D(basis, Vector3(t.x, t.y, t.z)))
	var node := MultiMeshInstance3D.new()
	node.name = "Tile_%d_%d" % [key.x, key.y]
	node.multimesh = multi
	# O material externo do .import (kit_pine_far.tres) fica no node, nao na malha.
	node.material_override = pine.get_active_material(0)
	# Sem sombra (o sol so projeta ate 65 u e a copa ja e escura) e fora do bake e das sondas.
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	return node


## MeshInstance3D do pinheiro leve do .glb (a malha e o material externo do .import), solto da
## cena instanciada: quem chama usa e libera.
func _pine() -> MeshInstance3D:
	var instance := (load(PINE_SCENE) as PackedScene).instantiate()
	var found := instance.find_children("*", "MeshInstance3D", true, false)
	if found.is_empty():
		push_error("[valley] %s sem malha" % PINE_SCENE)
		instance.free()
		return null
	var pine := found[0] as MeshInstance3D
	if pine.get_active_material(0) == null:
		push_error("[valley] %s sem material (use_external do .import)" % PINE_SCENE)
	pine.get_parent().remove_child(pine)
	instance.free()
	return pine
