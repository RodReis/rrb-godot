extends GutTest

const BASE_A: Vector2 = Vector2(-24.0, 24.0)
const BASE_B: Vector2 = Vector2(24.0, -24.0)
const ARENA_HALF: float = 40.0


func test_center_is_the_middle_of_the_image() -> void:
	var uv := ArenaMapView.world_to_uv(Vector2.ZERO)
	assert_almost_eq(uv.x, 0.5, 0.0001)
	assert_almost_eq(uv.y, 0.5, 0.0001)


func test_base_a_is_bottom_left_and_base_b_is_top_right() -> void:
	var a := ArenaMapView.world_to_uv(BASE_A)
	var b := ArenaMapView.world_to_uv(BASE_B)
	assert_lt(a.x, 0.5, "base A fica a esquerda")
	assert_gt(a.y, 0.5, "base A fica embaixo")
	assert_gt(b.x, 0.5, "base B fica a direita")
	assert_lt(b.y, 0.5, "base B fica em cima")


func test_rotation_by_180_degrees_mirrors_the_image() -> void:
	for point: Vector2 in [BASE_A, Vector2(-11.3, 11.3), Vector2(-26.0, -18.0)]:
		var uv := ArenaMapView.world_to_uv(point)
		var rotated := ArenaMapView.world_to_uv(-point)
		assert_almost_eq(rotated.x, 1.0 - uv.x, 0.0001)
		assert_almost_eq(rotated.y, 1.0 - uv.y, 0.0001)


func test_whole_playable_square_fits_the_image() -> void:
	for x: float in [-ARENA_HALF, ARENA_HALF]:
		for z: float in [-ARENA_HALF, ARENA_HALF]:
			var uv := ArenaMapView.world_to_uv(Vector2(x, z))
			assert_between(uv.x, 0.0, 1.0)
			assert_between(uv.y, 0.0, 1.0)


func test_uv_to_world_undoes_world_to_uv() -> void:
	for point: Vector2 in [BASE_A, BASE_B, Vector2(7.5, -12.0), Vector2.ZERO]:
		var back := ArenaMapView.uv_to_world(ArenaMapView.world_to_uv(point))
		assert_almost_eq(back.x, point.x, 0.001)
		assert_almost_eq(back.y, point.y, 0.001)


func test_height_moves_the_point_up_in_the_image() -> void:
	var ground := ArenaMapView.world_to_uv(BASE_A)
	var raised := ArenaMapView.world_to_uv(BASE_A, 4.0)
	assert_lt(raised.y, ground.y)
	assert_almost_eq(raised.x, ground.x, 0.0001)


func test_camera_looks_at_the_center_from_the_south() -> void:
	var camera := ArenaMapView.camera_transform()
	assert_almost_eq(camera.origin.x, 0.0, 0.0001)
	assert_gt(camera.origin.y, 0.0)
	assert_gt(camera.origin.z, 0.0, "a camera fica ao sul (+Z)")
	var forward := -camera.basis.z
	assert_lt(forward.y, 0.0, "olha para baixo")
	assert_lt(forward.z, 0.0, "olha para o norte (-Z)")
	assert_almost_eq(forward.x, 0.0, 0.0001)
