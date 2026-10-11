extends GutTest
## F38: toggles de [graphics] do settings.cfg (ADR-0006 item 8). Ausente/tipo errado = ligado;
## schema diferente = padroes; o toggle so desliga o que a arena traz ligado.


func _config(values: Dictionary, schema: int = GraphicsSettings.SCHEMA) -> ConfigFile:
	var config := ConfigFile.new()
	config.set_value("meta", "schema", schema)
	for key: String in values:
		config.set_value(GraphicsSettings.SECTION, key, values[key])
	return config


func _env_all_on() -> Environment:
	var env := Environment.new()
	env.volumetric_fog_enabled = true
	env.ssil_enabled = true
	env.ssao_enabled = true
	return env


func test_sem_chaves_tudo_ligado() -> void:
	var flags := GraphicsSettings.read(_config({}))
	for key: String in GraphicsSettings.KEYS:
		assert_true(flags[key], key)


func test_arquivo_inexistente_usa_padroes() -> void:
	var flags := GraphicsSettings.load_file("user://nao_existe_f38.cfg")
	assert_eq(flags, GraphicsSettings.defaults())


func test_chave_falsa_desliga_so_ela() -> void:
	var flags := GraphicsSettings.read(_config({"fog": false}))
	assert_false(flags[GraphicsSettings.FOG])
	assert_true(flags[GraphicsSettings.SSIL])
	assert_true(flags[GraphicsSettings.SSAO])


func test_grama_desligada_no_cfg() -> void:
	var flags := GraphicsSettings.read(_config({"grass": false}))
	assert_false(flags[GraphicsSettings.GRASS])
	assert_true(flags[GraphicsSettings.FOG])


func test_tipo_errado_fica_ligado() -> void:
	var flags := GraphicsSettings.read(_config({"ssao": "nao"}))
	assert_true(flags[GraphicsSettings.SSAO])


func test_schema_diferente_ignora_o_arquivo() -> void:
	var flags := GraphicsSettings.read(_config({"fog": false, "ssil": false}, 99))
	assert_eq(flags, GraphicsSettings.defaults())


func test_apply_desliga_no_environment() -> void:
	var env := _env_all_on()
	GraphicsSettings.apply(env, GraphicsSettings.read(_config({"fog": false, "ssil": false})))
	assert_false(env.volumetric_fog_enabled)
	assert_false(env.ssil_enabled)
	assert_true(env.ssao_enabled)


func test_apply_nao_liga_o_que_vem_desligado() -> void:
	var env := Environment.new()
	env.ssao_enabled = false
	GraphicsSettings.apply(env, GraphicsSettings.defaults())
	assert_false(env.ssao_enabled)
