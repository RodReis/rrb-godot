extends SceneTree
## Captura do Launcher para a prova por tela (FRONTEND-LAUNCHER §6, itens 1 e 6): sobe o App,
## espera a tela assentar e salva um PNG do tamanho pedido. Precisa de janela (nao headless).
##   godot --path launcher -s <repo>/tools/ui/capture_launcher.gd -- --out=<png> [--size=1920x1080]
##     [--tab=<0..3>] [--gallery] [--modal] [--fps]
## --tab escolhe a aba de Configuracoes; --gallery abre a galeria; --modal abre o "Restaurar
## padroes?" por cima; --fps desliga o vsync e imprime o FPS medio de FPS_SECONDS (§4).

const APP: String = "res://scenes/app.tscn"
const DEFAULT_SIZE: Vector2i = Vector2i(1920, 1080)
## Frames ate fontes, fade de entrada e layout assentarem.
const SETTLE_FRAMES: int = 45
const FPS_SECONDS: float = 3.0


func _initialize() -> void:
	_capture.call_deferred()


func _capture() -> void:
	var args := _args()
	var app := (load(APP) as PackedScene).instantiate()
	root.add_child(app)
	await process_frame
	root.size = _size(args.get("size", ""))
	if args.has("tab"):
		var screen := app.find_children("*", "SettingsScreen", true, false)
		if not screen.is_empty():
			(screen[0] as SettingsScreen).select_tab(int(args["tab"]))
	if args.has("modal"):
		var settings := app.find_children("*", "SettingsScreen", true, false)
		if not settings.is_empty():
			(settings[0] as SettingsScreen).reset_requested.emit()
	for i: int in SETTLE_FRAMES:
		await process_frame
	if args.has("fps"):
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		Engine.max_fps = 0
		var frames := Engine.get_process_frames()
		await create_timer(FPS_SECONDS).timeout
		var fps := (Engine.get_process_frames() - frames) / FPS_SECONDS
		print("[capture] fps medio em %.0f s: %.0f" % [FPS_SECONDS, fps])
	var image := root.get_texture().get_image()
	var out: String = args.get("out", "user://capture.png")
	var err := image.save_png(out)
	print("[capture] %s %s (%s)" % [out, image.get_size(), error_string(err)])
	quit(err)


func _args() -> Dictionary:
	var parsed := {}
	for arg: String in OS.get_cmdline_user_args():
		var pair := arg.trim_prefix("--").split("=", true, 1)
		parsed[pair[0]] = pair[1] if pair.size() > 1 else ""
	return parsed


func _size(text: String) -> Vector2i:
	var parts := text.split("x")
	if parts.size() != 2:
		return DEFAULT_SIZE
	return Vector2i(int(parts[0]), int(parts[1]))
