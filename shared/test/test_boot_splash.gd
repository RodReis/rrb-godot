extends GutTest
## Splash do Launcher (F68, SPEC-068): imagem real do render, cobre a janela e some uma vez so.


func test_loads_the_rendered_splash_covering_the_window() -> void:
	var splash: BootSplash = add_child_autofree(BootSplash.new())
	assert_not_null(splash.texture)
	assert_eq(splash.texture.get_size(), Vector2(1920, 1080))
	assert_eq(splash.stretch_mode, TextureRect.STRETCH_KEEP_ASPECT_COVERED)
	assert_eq(splash.mouse_filter, Control.MOUSE_FILTER_STOP)


func test_dismiss_is_idempotent_and_frees_the_node_after_the_fade() -> void:
	var splash := BootSplash.new()
	add_child(splash)
	splash.dismiss()
	splash.dismiss()
	assert_true(splash.is_dismissed())
	assert_eq(splash.mouse_filter, Control.MOUSE_FILTER_IGNORE)
	await wait_seconds(BootSplash.FADE_SECONDS + 0.3)
	assert_false(is_instance_valid(splash))


func test_dismiss_outside_the_tree_frees_at_once() -> void:
	var splash := BootSplash.new()
	splash.dismiss()
	await wait_frames(2)
	assert_false(is_instance_valid(splash))
