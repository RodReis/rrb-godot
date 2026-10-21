extends "arena_river.gd"
## Vale em volta da arena (F56, ADR-0012): faixa externa so visual no lugar do abismo. Relevo,
## riacho e pinheiros saem de art/arena/build_valley.py (valley_terrain.glb, valley_stream.glb,
## pine_valley.glb e tools/arena/valley_trees.json); aqui so se monta: o terreno e o riacho
## entram na arena e as arvores vao como dado numa cena propria, que o ValleyForest transforma
## em MultiMesh no cliente (o servidor de renderizacao headless nao guarda buffer de MultiMesh,
## mesmo caso do Vegetation). Sem colisao, sem navmesh, fora do bake: o vale nao entra na regra.

const VALLEY_TERRAIN: String = RRB_ARENA + "valley_terrain.glb"
const VALLEY_STREAM: String = RRB_ARENA + "valley_stream.glb"
const TREES_FILE: String = "valley_trees.json"
const FOREST_OUT: String = "res://scenes/arena/valley_forest.tscn"
const FOREST_SCRIPT: String = "res://scripts/world/valley_forest.gd"


func _build_valley() -> void:
	var valley := _group("Valley")
	_asset(valley, VALLEY_TERRAIN, "Terrain")
	_asset(valley, VALLEY_STREAM, "Stream")
	var trees := _load_valley_trees()
	var node := Node3D.new()
	node.name = "Forest"
	node.set_script(load(FOREST_SCRIPT))
	node.set(&"trees", trees)
	var packed := PackedScene.new()
	var err := packed.pack(node)
	if err == OK:
		err = ResourceSaver.save(packed, FOREST_OUT)
	print("[arena] %s (%d arvores) -> %s" % [FOREST_OUT, trees.size(), error_string(err)])
	node.free()
	var scene := ResourceLoader.load(FOREST_OUT, "", ResourceLoader.CACHE_MODE_REPLACE)
	_add(valley, (scene as PackedScene).instantiate())


## Arvores (x, y, z, escala) de tools/arena/valley_trees.json; vazio e erro (o vale sem floresta
## nao e o que o PI aprovou).
func _load_valley_trees() -> PackedVector4Array:
	var path := (get_script() as Script).resource_path.get_base_dir().path_join(TREES_FILE)
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	var out := PackedVector4Array()
	if not parsed is Dictionary or not (parsed as Dictionary).has("trees"):
		push_error("[arena] %s invalido: rode art/arena/build_valley.py" % path)
		return out
	for tree: Array in (parsed as Dictionary)["trees"]:
		out.append(Vector4(tree[0], tree[1], tree[2], tree[3]))
	return out
