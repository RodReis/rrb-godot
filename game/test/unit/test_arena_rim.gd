extends GutTest
## F96 (SPEC-096, ADR-0030): a borda da ilha no estilo novo. Floresta, tochas, cristais,
## cavalo-de-frisa, torre de vigia, balista e a cantaria e a cortina da poca dos bastioes NO/SE
## vem do kit (shared/assets/rrb/arena/kit/), sem colisao, e nada da borda usa mais os assets
## antigos do F40.

const ARENA: String = "res://scenes/arena/ilha_arcana.tscn"
const KIT: String = "res://shared/assets/rrb/arena/kit/"
## Prefixo do node na borda -> asset do kit.
const RIM_KIT: Dictionary[String, String] = {
	"Pine": "kit_pine.glb",
	"Torch": "kit_torch.glb",
	"Barricade": "kit_barricade.glb",
	"Watchtower": "kit_watchtower.glb",
	"Ballista": "kit_ballista.glb",
	"FallsCurb": "kit_falls_curb.glb",
	"FallsSheet": "kit_falls_sheet.glb",
}
const OLD_ASSETS: Array[String] = [
	"pine_dark.glb", "torch_post.glb", "barricade.glb", "watchtower.glb", "ballista.glb"
]

var _arena: Node3D
var _rim: Node3D


func before_all() -> void:
	_arena = (load(ARENA) as PackedScene).instantiate() as Node3D
	_rim = _arena.get_node("RimDecor") as Node3D


func after_all() -> void:
	_arena.free()


func test_pecas_da_borda_vem_do_kit() -> void:
	for prefix: String in RIM_KIT.keys():
		var found := _pieces(prefix)
		assert_gt(found.size(), 1, "%s nas duas metades" % prefix)
		for node: Node in found:
			assert_eq(node.scene_file_path, KIT + RIM_KIT[prefix], node.name)


func test_cristais_da_borda_vem_do_kit() -> void:
	var crystals := _pieces("Crystal")
	assert_eq(crystals.size(), 6)
	for node: Node in crystals:
		assert_string_starts_with(node.scene_file_path, KIT + "kit_crystal_")


func test_borda_nao_usa_os_assets_antigos() -> void:
	for node: Node in _rim.get_children():
		for old: String in OLD_ASSETS:
			assert_false(node.scene_file_path.ends_with("/arena/" + old), node.name)


func test_borda_nao_tem_colisao() -> void:
	assert_eq(_rim.find_children("*", "CollisionObject3D", true, false).size(), 0)
	assert_eq(_rim.find_children("*", "CollisionShape3D", true, false).size(), 0)


## A cantaria sai em coordenadas do mundo do canto NO: a B e o giro de 180 graus.
func test_poca_do_se_e_a_do_no_girada() -> void:
	for prefix: String in ["FallsCurb", "FallsSheet"]:
		var a := _rim.get_node("%sA" % prefix) as Node3D
		var b := _rim.get_node("%sB" % prefix) as Node3D
		assert_eq(a.transform, Transform3D.IDENTITY, prefix)
		var turned := Basis(Vector3.UP, PI)
		assert_true(b.transform.basis.is_equal_approx(turned), prefix)
		assert_eq(b.transform.origin, Vector3.ZERO, prefix)


## A escada da torre (+x do kit) fica virada para dentro da arena nas duas metades.
func test_escada_da_torre_vira_para_a_arena() -> void:
	for tag: String in ["A", "B"]:
		var tower := _rim.get_node("Watchtower%s" % tag) as Node3D
		var ladder := tower.transform.basis.x
		assert_gt(ladder.dot(-tower.position.normalized()), 0.5, tag)


func test_cascata_de_particulas_saiu() -> void:
	var ambience := _arena.get_node("Ambience")
	assert_null(ambience.get_node_or_null("WaterfallNO"))
	assert_null(ambience.get_node_or_null("WaterfallSE"))


func _pieces(prefix: String) -> Array[Node]:
	var out: Array[Node] = []
	for node: Node in _rim.get_children():
		var tail := node.name.trim_prefix(prefix)
		if tail != node.name and (tail.begins_with("A") or tail.begins_with("B")):
			out.append(node)
	return out
