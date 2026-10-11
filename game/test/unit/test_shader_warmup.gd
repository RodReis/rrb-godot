extends GutTest
## F38: o warm-up cobre o que nasce depois do connect (herois, monstros, bau) e so copia a parte
## visual, sem script, para o _ready de Hero/Monster/netfox nunca rodar fora da partida.


func test_cobre_herois_monstros_e_bau() -> void:
	var paths := ShaderWarmup.scene_paths()
	for hero: String in ["knight", "ranger"]:
		assert_has(paths, Hero.SCENE_PATH % hero)
	for file: String in ResourceLoader.list_directory("res://scenes/monsters/"):
		if file.get_extension() == "tscn":
			assert_has(paths, "res://scenes/monsters/" + file)
	assert_has(paths, "res://scenes/world/chest.tscn")


func test_cobre_as_pecas_de_equipamento() -> void:
	var paths := ShaderWarmup.scene_paths()
	var visuals := ItemVisuals.for_hero(&"knight")
	for item: StringName in [&"guard_helm_t3", &"hunter_chest_t1", &"sword_t2"]:
		assert_has(paths, (visuals.pieces[item] as PackedScene).resource_path)


func test_toda_cena_carrega() -> void:
	for path: String in ShaderWarmup.scene_paths():
		assert_true(load(path) is PackedScene, path)


func test_shaders_de_codigo_carregam() -> void:
	for path: String in ShaderWarmup.SHADERS:
		var shader := load(path) as Shader
		assert_not_null(shader, path)
		assert_eq(shader.get_mode(), Shader.MODE_SPATIAL, path)


func test_copias_sao_visuais_sem_script_nem_filhos() -> void:
	for path: String in ShaderWarmup.scene_paths():
		var instance := (load(path) as PackedScene).instantiate()
		var copies: Array[GeometryInstance3D] = []
		ShaderWarmup._collect_visuals(instance, instance, Transform3D.IDENTITY, copies)
		instance.free()
		assert_gt(copies.size(), 0, path)
		for copy: GeometryInstance3D in copies:
			assert_null(copy.get_script(), "%s/%s" % [path, copy.name])
			assert_eq(copy.get_child_count(), 0, "%s/%s" % [path, copy.name])
			copy.free()


func test_todo_shader_spatial_de_scenes_esta_na_lista() -> void:
	for path: String in _shaders_under("res://scenes/"):
		var shader := load(path) as Shader
		if shader.get_mode() == Shader.MODE_SPATIAL:
			assert_has(ShaderWarmup.SHADERS, path, "spatial fora do warm-up")


func test_viewport_recebe_todas_as_copias() -> void:
	var warmup := ShaderWarmup.new()
	add_child_autofree(warmup)
	var viewport := warmup._make_viewport(null)
	warmup.add_child(viewport)
	var copies := warmup._fill(viewport)
	assert_gt(copies, ShaderWarmup.SHADERS.size())
	# camera + sol + copias (sem WorldEnvironment com ambiente nulo)
	assert_eq(viewport.get_child_count(), copies + 2)
	assert_true(viewport.own_world_3d, "copias nao aparecem no mundo da partida")
	viewport.free()


func test_headless_termina_na_hora() -> void:
	if DisplayServer.get_name() != "headless":
		pending("so headless")
		return
	var warmup := ShaderWarmup.new()
	add_child_autofree(warmup)
	watch_signals(warmup)
	var copies: int = await warmup.run(null)
	assert_eq(copies, 0)
	assert_signal_emitted_with_parameters(warmup, "finished", [0])


func _shaders_under(dir: String) -> PackedStringArray:
	var found := PackedStringArray()
	for entry: String in ResourceLoader.list_directory(dir):
		if entry.ends_with("/"):
			found.append_array(_shaders_under(dir + entry))
		elif entry.get_extension() == "gdshader":
			found.append(dir + entry)
	return found
