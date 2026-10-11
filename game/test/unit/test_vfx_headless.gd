extends GutTest
## F41 (bloco visual regra 1): o servidor headless nao instancia nada de VFX. Carrega a main como
## servidor sem janela (o runner do GUT e headless), poe os dois herois em Players e conta.

const MAIN: String = "res://scenes/main.tscn"
const HEROES: Array[String] = ["res://scenes/heroes/knight.tscn", "res://scenes/heroes/ranger.tscn"]


func _vfx_nodes(root: Node) -> Array[String]:
	var found: Array[String] = []
	for node: Node in root.find_children("*", "", true, false):
		var script := node.get_script() as Script
		var from_script := script != null and script.resource_path.begins_with("res://scripts/vfx/")
		if from_script or node.scene_file_path.begins_with("res://scenes/vfx/"):
			found.append(str(root.get_path_to(node)))
	return found


func test_headless_nao_quer_vfx() -> void:
	assert_eq(DisplayServer.get_name(), "headless")
	assert_false(VfxSpawner.wanted())


func test_main_headless_com_herois_nao_tem_no_de_vfx() -> void:
	var main := (load(MAIN) as PackedScene).instantiate()
	add_child_autofree(main)
	await wait_process_frames(2)
	var players := main.get_node("Players")
	for i: int in HEROES.size():
		var hero := (load(HEROES[i]) as PackedScene).instantiate() as Hero
		hero.name = str(i + 1)
		players.add_child(hero)
	await wait_process_frames(2)
	assert_not_null(main.get_node_or_null(NodePath(ImpactRelay.NODE_NAME)), "relay existe")
	assert_null(main.get_node_or_null(NodePath(VfxSpawner.NODE_NAME)))
	assert_eq(_vfx_nodes(main), [] as Array[String])
