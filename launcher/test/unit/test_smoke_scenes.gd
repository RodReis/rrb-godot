extends GutTest
## F24: smoke de telas (ARCHITECTURE-LAUNCHER §7) — cada .tscn do Launcher e a galeria instanciam
## sem erro de no; o App sobe na tela inicial.

const SCENE_DIRS: Array[String] = ["res://scenes", "res://scenes/screens"]
const GALLERY: String = "res://shared/ui/components/_gallery.tscn"


func _scene_paths() -> Array[String]:
	var paths: Array[String] = [GALLERY]
	for dir: String in SCENE_DIRS:
		for file: String in DirAccess.get_files_at(dir):
			if file.ends_with(".tscn"):
				paths.append(dir.path_join(file))
	return paths


func test_toda_cena_instancia() -> void:
	var paths := _scene_paths()
	assert_gt(paths.size(), 2, "app, settings e galeria")
	for path: String in paths:
		var scene := load(path) as PackedScene
		assert_not_null(scene, path)
		var node := scene.instantiate()
		add_child_autofree(node)
		await wait_process_frames(2)
		assert_true(is_instance_valid(node), path)


func test_app_abre_no_login() -> void:
	var app: App = add_child_autofree(load("res://scenes/app.tscn").instantiate())
	await wait_process_frames(2)
	var stack := app.find_children("*", "ScreenStack", true, false)
	assert_eq(stack.size(), 1)
	assert_eq((stack[0] as ScreenStack).current_route(), Router.LOGIN, "sem sessao abre no Login")
