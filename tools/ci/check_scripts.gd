extends SceneTree
## Compila cada script passado depois de `--` com o projeto carregado (autoloads e
## warnings-como-erro do project.godot). Sai 1 se algum nao compila.


func _initialize() -> void:
	var failed: int = 0
	for path: String in OS.get_cmdline_user_args():
		var script: Script = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
		if script == null or not script.can_instantiate():
			printerr("FALHA: ", path)
			failed = 1
	quit(failed)
