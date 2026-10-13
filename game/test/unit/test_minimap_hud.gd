extends GutTest
## F65 (ADR-0014): as duas HUDs mostram a imagem pronta do mapa no Minimap.

const MAP_IMAGE: String = "res://shared/assets/rrb/arena/minimap_arena.webp"
const HUDS: Array[String] = ["res://scenes/ui/hud_phase1.tscn", "res://scenes/ui/hud_phase2.tscn"]


func test_huds_usam_a_imagem_do_mapa() -> void:
	for path: String in HUDS:
		var hud := (load(path) as PackedScene).instantiate()
		var minimap := hud.find_children("Minimap", "", true, false)[0] as Minimap
		assert_not_null(minimap.map_texture, path)
		if minimap.map_texture != null:
			assert_eq(minimap.map_texture.resource_path, MAP_IMAGE, path)
		hud.free()
