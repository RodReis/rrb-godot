extends SceneTree
## Renderiza a arte do duelo do Login (FRONTEND-LAUNCHER §8.3 item 3: a imagem do prototipo da
## lugar a um render dos assets reais) a partir do diorama em modo DUEL. Precisa de janela (nao
## roda em --headless):
##   godot --path launcher --script res://scripts/diorama/render_login_art.gd
## Saida: shared/assets/ui/login_duel.png (2x a moldura h-72 de ~1040 px: 2080 x 576).

const OUTPUT: String = "res://shared/assets/ui/login_duel.png"
const SIZE: Vector2i = Vector2i(2080, 576)
const WARMUP_FRAMES: int = 30


func _initialize() -> void:
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.size = SIZE
	var diorama := (load("res://scenes/diorama/lobby_diorama.tscn") as PackedScene).instantiate()
	(diorama as LobbyDiorama).mode = LobbyDiorama.Mode.DUEL
	root.add_child(diorama)
	(diorama as Control).set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	(diorama as Control).size = SIZE
	for i: int in WARMUP_FRAMES:
		(diorama as LobbyDiorama).render_now()
		await process_frame
	await RenderingServer.frame_post_draw
	var image := (diorama as LobbyDiorama).viewport_texture().get_image()
	var err := image.save_png(OUTPUT)
	print("[render] %s %s (%s)" % [OUTPUT, image.get_size(), error_string(err)])
	quit(0 if err == OK else 1)
