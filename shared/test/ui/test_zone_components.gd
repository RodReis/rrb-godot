extends GutTest
## ScoreBanner e ZoneRadar, componentes da HUD da fase 2 (COMPONENTS.md, regra 2; F17).

const MINIMAP: PackedScene = preload("res://shared/ui/components/minimap.tscn")


func test_score_banner_names_kills_and_target() -> void:
	var banner: ScoreBanner = add_child_autofree(ScoreBanner.new())
	var me := ScoreBanner.PlayerScore.new("CAVALEIRO", 3, true)
	var them := ScoreBanner.PlayerScore.new("ARQUEIRA", 2, false)
	banner.bind(me, them, 5)
	var texts: Array[String] = []
	for label: Node in banner.find_children("*", "Label", true, false):
		texts.append((label as Label).text)
	assert_has(texts, "CAVALEIRO (VOCÊ)")
	assert_has(texts, "ARQUEIRA (OPONENTE)")
	assert_has(texts, "3")
	assert_has(texts, "2")
	assert_has(texts, "META: 5 KILLS")


func test_score_banner_leader_gets_gold_and_tie_none() -> void:
	assert_eq(ScoreBanner.leader_index(3, 2), 0)
	assert_eq(ScoreBanner.leader_index(1, 4), 1)
	assert_eq(ScoreBanner.leader_index(2, 2), -1)
	var banner: ScoreBanner = add_child_autofree(ScoreBanner.new())
	banner.bind(ScoreBanner.PlayerScore.new("A", 0, true), ScoreBanner.PlayerScore.new("B", 1), 5)
	var sides := banner.find_children("*", "PanelCard", true, false)
	assert_eq((sides[0] as PanelCard).accent, PanelCard.Accent.NONE)
	assert_eq((sides[1] as PanelCard).accent, PanelCard.Accent.GOLD)


func test_score_banner_local_kills_green_enemy_red() -> void:
	var banner: ScoreBanner = add_child_autofree(ScoreBanner.new())
	banner.bind(
		ScoreBanner.PlayerScore.new("A", 7, false), ScoreBanner.PlayerScore.new("B", 9, true), 5
	)
	for label: Node in banner.find_children("*", "Label", true, false):
		var text := (label as Label).text
		if text == "7":
			assert_eq((label as Label).theme_type_variation, &"LabelCounterDanger")
		elif text == "9":
			assert_eq((label as Label).theme_type_variation, &"LabelCounterAlly")


## Mesmo mapeamento da camera do Minimap: direita = +X, cima = -Z (giro 0).
func test_zone_radar_maps_world_like_the_minimap() -> void:
	var area := Vector2(200, 200)
	assert_eq(ZoneRadar.to_radar(Vector3.ZERO, 0.0, 10.0, area), Vector2(100, 100))
	assert_eq(ZoneRadar.to_radar(Vector3(10, 0, 0), 0.0, 10.0, area), Vector2(200, 100))
	assert_eq(ZoneRadar.to_radar(Vector3(0, 5, -10), 0.0, 10.0, area), Vector2(100, 0))


func test_zone_radar_radius_in_pixels() -> void:
	var radar: ZoneRadar = add_child_autofree(ZoneRadar.new())
	radar.size = Vector2(280, 280)
	radar.world_extent = 37.0
	radar.full_radius = 37.0
	radar.set_zone(0.5, 0.25, 30.0)
	assert_almost_eq(radar.radius_px(radar.radius_pct), 70.0, 0.001)
	assert_almost_eq(radar.radius_px(radar.next_radius_pct), 35.0, 0.001)
	radar.set_zone(-1.0, 0.0, 0.0)
	assert_eq(radar.radius_pct, 0.0, "colapso nao fica negativo")


## O radar fica por cima do Minimap: com o mesmo giro e extensao, cada ponto cai onde a camera
## dele projeta.
func test_zone_radar_matches_the_minimap_camera_when_turned() -> void:
	var minimap: Minimap = add_child_autofree(MINIMAP.instantiate())
	var yaw := 0.7
	minimap.set_yaw(yaw)
	var camera := minimap.get_node("%Camera") as Camera3D
	var area := Vector2(minimap.get_node("%Viewport").size)
	for point: Vector3 in [Vector3(10, 0, 0), Vector3(-5, 0, 20), Vector3(30, 0, -12)]:
		var expected := camera.unproject_position(point)
		var got := ZoneRadar.to_radar(point, yaw, minimap.world_extent, area)
		assert_almost_eq(got.x, expected.x, 0.01, str(point))
		assert_almost_eq(got.y, expected.y, 0.01, str(point))
