extends SceneTree
## Grava o fixture de colisao e marcadores da arena (F94) em
## game/test/fixtures/arena_colisao_f94.json, lido pelo test_arena_colisao_fixa. Rode so quando o
## layout mudar de proposito (SPEC nova).
## Uso (na raiz do repo):
##   godot --headless --path game -s <repo>/tools/arena/collision_fixture.gd

const ARENA: String = "res://scenes/arena/ilha_arcana.tscn"
const OUT: String = "res://test/fixtures/arena_colisao_f94.json"
const ArenaFixture := preload("res://test/fixtures/arena_fixture.gd")


func _initialize() -> void:
	var arena := (load(ARENA) as PackedScene).instantiate() as Node3D
	root.add_child(arena)
	await process_frame
	var data := {"shapes": ArenaFixture.shapes(arena), "markers": ArenaFixture.markers(arena)}
	var file := FileAccess.open(OUT, FileAccess.WRITE)
	file.store_string(JSON.stringify(data, " "))
	file.close()
	var counts: Array = [data["shapes"].size(), data["markers"].size(), OUT]
	print("[fixture] %d formas, %d marcadores -> %s" % counts)
	arena.free()
	quit()
