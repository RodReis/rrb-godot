extends GutTest
## F94 (SPEC-094 aceite 2, ADR-0030): a arte nova da arena e so visual. Colisao (caminho, tipo,
## tamanho e transform global de cada forma) e marcadores sao iguais aos da arena antes do F94,
## gravados em test/fixtures/arena_colisao_f94.json por tools/arena/collision_fixture.gd. Se o
## layout mudar de proposito (SPEC nova), regere o fixture na mesma PR.

const ARENA: String = "res://scenes/arena/ilha_arcana.tscn"
const FIXTURE: String = "res://test/fixtures/arena_colisao_f94.json"
const ArenaFixture := preload("res://test/fixtures/arena_fixture.gd")

var _arena: Node3D
var _fixture: Dictionary


func before_all() -> void:
	_arena = (load(ARENA) as PackedScene).instantiate() as Node3D
	add_child(_arena)
	_fixture = JSON.parse_string(FileAccess.get_file_as_string(FIXTURE))


func after_all() -> void:
	_arena.free()


func test_colisao_igual_a_de_antes_da_arte_nova() -> void:
	var now := ArenaFixture.shapes(_arena)
	assert_eq(now.size(), (_fixture["shapes"] as Array).size(), "numero de formas")
	assert_eq(now, _fixture["shapes"])


func test_marcadores_iguais_aos_de_antes_da_arte_nova() -> void:
	assert_eq(ArenaFixture.markers(_arena), _fixture["markers"])


## A arte nova nao traz colisao propria: nenhum corpo fisico dentro das pecas do kit.
func test_kit_sem_colisao() -> void:
	for node: Node in _arena.find_children("*", "CollisionObject3D", true, false):
		var owner_path := (node as Node).scene_file_path
		var at: Node = node
		while at != _arena and owner_path.is_empty():
			at = at.get_parent()
			owner_path = at.scene_file_path
		assert_false(owner_path.contains("/rrb/arena/kit/"), "colisao no kit: %s" % node.get_path())
