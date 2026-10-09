extends GutTest
## Cena de alinhamento (PRD §11): o Cavaleiro tem ~1,8 u, como a capsula de referencia;
## monstros do F9 conferidos contra ele.

const SCENE: String = "res://shared/assets/_alignment.tscn"
const HERO_HEIGHT: float = 1.8
const TOLERANCE: float = 0.15
## Capacete/chapeu acima da cabeca (u).
const ACCESSORY: float = 0.3

var _scene: Node3D


func before_all() -> void:
	_scene = (load(SCENE) as PackedScene).instantiate() as Node3D
	add_child(_scene)


func after_all() -> void:
	_scene.free()


func _top(root: Node, prefix: String) -> float:
	var top := -INF
	for node: Node in root.find_children(prefix + "*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		top = maxf(top, (mi.global_transform * mi.get_aabb()).end.y)
	return top


func test_cavaleiro_tem_a_altura_do_heroi() -> void:
	await wait_process_frames(2)
	var top := _top(_scene.get_node("Knight"), "Knight_")
	gut.p("Cavaleiro: %.2f u" % top)
	assert_almost_eq(top, HERO_HEIGHT, TOLERANCE)


func test_esqueleto_e_um_pouco_menor_que_o_cavaleiro() -> void:
	await wait_process_frames(2)
	var skeleton := _top(_scene.get_node("SkeletonMinion"), "Skeleton_Minion_")
	gut.p("Esqueleto: %.2f u" % skeleton)
	assert_true(skeleton <= _top(_scene.get_node("Knight"), "Knight_"))
	assert_almost_eq(skeleton, HERO_HEIGHT, TOLERANCE)


func test_esqueletos_guerreiro_e_mago_tem_a_altura_do_heroi() -> void:
	await wait_process_frames(2)
	var warrior := _top(_scene.get_node("SkeletonWarrior"), "Skeleton_Warrior_")
	var mage := _top(_scene.get_node("SkeletonMage"), "Skeleton_Mage_")
	gut.p("Guerreiro: %.2f u, Mago: %.2f u" % [warrior, mage])
	# Mesmo rig do Esqueleto; capacete e chapeu passam um pouco da cabeca.
	assert_between(warrior, HERO_HEIGHT, HERO_HEIGHT + ACCESSORY)
	assert_between(mage, HERO_HEIGHT, HERO_HEIGHT + ACCESSORY)


func test_golem_e_maior_que_o_heroi() -> void:
	# Golem a 2,5 u (art/monsters/golem.blend): cobre a capsula de colisao h 2,4 (F9).
	await wait_process_frames(2)
	var golem := _top(_scene.get_node("Golem"), "golem")
	gut.p("Golem: %.2f u" % golem)
	assert_almost_eq(golem, 2.5, 0.05)


func test_tem_tile_e_modelos_da_arena() -> void:
	for node_name: String in [
		"HexUnderKnight",
		"HexWater",
		"Wall",
		"Gate",
		"Bridge",
		"Rock",
		"BorderMountain",
		"CraterPillar",
		"TallGrass4x4",
		"TallGrass4x3",
	]:
		assert_not_null(_scene.get_node_or_null(node_name), node_name)
