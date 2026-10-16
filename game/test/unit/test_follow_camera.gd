extends GutTest
## FollowCamera: zoom (SPEC-067) e yaw do time que prende o minimapa e o radar (PI 2026-10-16).

var _root: Node3D
var _camera: FollowCamera
var _hero: Node3D


func before_each() -> void:
	_root = add_child_autofree(Node3D.new())
	var players := Node3D.new()
	players.name = "Players"
	_root.add_child(players)
	_hero = Node3D.new()
	_hero.name = "1"  # id do peer offline
	_hero.position = Vector3(-24, 0, 24)
	players.add_child(_hero)
	_camera = FollowCamera.new()
	_root.add_child(_camera)


func _mouse_move(dx: float) -> InputEventMouseMotion:
	var event := InputEventMouseMotion.new()
	event.screen_relative = Vector2(dx, 0)
	return event


func test_padrao_e_11_unidades() -> void:
	assert_eq(_camera.distance, 11.0)


func test_zoom_aproxima_afasta_e_avisa() -> void:
	watch_signals(_camera)
	_camera.zoom_by(1)
	assert_signal_emitted_with_parameters(_camera, "distance_changed", [10.0])
	_camera.zoom_by(-2)
	assert_signal_emitted_with_parameters(_camera, "distance_changed", [12.0])


func test_zoom_no_limite_nao_avisa() -> void:
	_camera.set_distance(UserSettings.DISTANCE_MIN)
	watch_signals(_camera)
	_camera.zoom_by(1)
	assert_signal_not_emitted(_camera, "distance_changed")
	assert_eq(_camera.distance, UserSettings.DISTANCE_MIN)


func test_zoom_chega_ao_valor_pedido_pelo_tween() -> void:
	_camera.zoom_by(2)
	await wait_seconds(FollowCamera.ZOOM_SECONDS + 0.2)
	assert_almost_eq(_camera.distance, 9.0, 0.001)


func test_set_distance_prende_na_faixa_sem_sinal() -> void:
	watch_signals(_camera)
	_camera.set_distance(99.0)
	assert_eq(_camera.distance, UserSettings.DISTANCE_MAX)
	_camera.set_distance(1.0)
	assert_eq(_camera.distance, UserSettings.DISTANCE_MIN)
	assert_signal_not_emitted(_camera, "distance_changed")


func test_yaw_do_time_olha_o_centro_a_partir_da_base() -> void:
	assert_eq(_camera.team_yaw(), 0.0, "antes do heroi nascer")
	_camera._process(0.0)
	assert_almost_eq(
		_camera.team_yaw(), CameraRig.yaw_towards(_hero.position, Vector3.ZERO), 0.0001
	)


func test_giro_da_camera_nao_mexe_no_yaw_do_time() -> void:
	_camera._process(0.0)
	var before := _camera.team_yaw()
	_camera._orbiting = true
	_camera._input(_mouse_move(200.0))
	_camera._process(0.0)
	assert_ne(_camera.global_rotation.y, before, "a camera girou")
	assert_eq(_camera.team_yaw(), before)
	_camera._orbiting = false
