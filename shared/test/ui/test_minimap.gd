extends GutTest
## Minimap (F65, ADR-0014): imagem pronta do mapa no lugar da camera ao vivo (fecha DEBITO DS-07).
## A imagem e os marcadores caem onde o ZoneRadar desenha a zona, com e sem giro.

const MINIMAP: PackedScene = preload("res://shared/ui/components/minimap.tscn")
const MAP_IMAGE: String = "res://shared/assets/rrb/arena/minimap_arena.webp"
const AREA: Vector2 = Vector2(280, 280)
const POINTS: Array[Vector3] = [Vector3(10, 0, 0), Vector3(-5, 0, 20), Vector3(30, 0, -12)]


func test_sem_camera_ao_vivo() -> void:
	var minimap: Minimap = add_child_autofree(MINIMAP.instantiate())
	assert_eq(minimap.find_children("*", "SubViewport", true, false).size(), 0)
	assert_eq(minimap.find_children("*", "Camera3D", true, false).size(), 0)


## O mundo (x, z) desenhado pela imagem cai no mesmo ponto que o ZoneRadar projeta.
func test_imagem_do_mapa_segue_o_radar_com_giro() -> void:
	for yaw: float in [0.0, 0.7, -2.1]:
		var to_screen := Minimap.map_transform(yaw, 42.0, AREA)
		for point: Vector3 in POINTS:
			var got := to_screen * Vector2(point.x, point.z)
			var expected := ZoneRadar.to_radar(point, yaw, 42.0, AREA)
			assert_almost_eq(got.x, expected.x, 0.01, "%s giro %s" % [point, yaw])
			assert_almost_eq(got.y, expected.y, 0.01, "%s giro %s" % [point, yaw])


func test_marcadores_seguem_o_radar() -> void:
	var minimap: Minimap = add_child_autofree(MINIMAP.instantiate())
	minimap.size = AREA
	minimap.set_yaw(0.7)
	for point: Vector3 in POINTS:
		var expected := ZoneRadar.to_radar(point, 0.7, minimap.world_extent, AREA)
		assert_almost_eq(minimap.point_of(point), expected, Vector2(0.01, 0.01), str(point))


## Imagem gerada por tools/arena/minimap_image.gd: quadrada e nitida.
func test_imagem_do_mapa_e_quadrada() -> void:
	var texture := load(MAP_IMAGE) as Texture2D
	assert_not_null(texture)
	assert_eq(texture.get_width(), texture.get_height())
	assert_true(texture.get_width() >= 256)
