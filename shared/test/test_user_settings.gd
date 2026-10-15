extends GutTest
## F24: contrato user://settings.cfg (ARCHITECTURE-LAUNCHER §5.3). O Launcher escreve, o Game le.
## Chave desconhecida e ignorada; tipo ou valor fora da faixa vira o padrao; schema diferente
## devolve os padroes.

const TMP_PATH: String = "user://test_f24_settings.cfg"


func after_each() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TMP_PATH))


func _config(section: String, values: Dictionary, schema: int = UserSettings.SCHEMA) -> ConfigFile:
	var config := ConfigFile.new()
	config.set_value(UserSettings.META, UserSettings.SCHEMA_KEY, schema)
	for key: String in values:
		config.set_value(section, key, values[key])
	return config


func test_padroes_cobrem_as_secoes_do_contrato() -> void:
	var values := UserSettings.defaults()
	for section: String in [
		UserSettings.VIDEO, UserSettings.AUDIO, UserSettings.CONTROLS, UserSettings.GRAPHICS
	]:
		assert_true(values.has(section), section)
	assert_eq(values[UserSettings.CONTROLS][String(InputActions.SKILL_Q)], "Q")
	assert_eq(values[UserSettings.CONTROLS][String(InputActions.DODGE)], "Space")
	assert_true(values[UserSettings.GRAPHICS][UserSettings.FOG])


func test_round_trip_pelo_arquivo() -> void:
	var values := UserSettings.defaults()
	values[UserSettings.VIDEO][UserSettings.FULLSCREEN] = true
	values[UserSettings.VIDEO][UserSettings.FPS_CAP] = 144
	values[UserSettings.AUDIO][UserSettings.MUSIC] = 0.25
	values[UserSettings.CONTROLS][UserSettings.MOUSE_SENSITIVITY] = 1.5
	values[UserSettings.GRAPHICS][UserSettings.SSAO] = false
	values = UserSettings.rebind(values, InputActions.SKILL_Q, KEY_1)
	assert_eq(UserSettings.save_file(values, TMP_PATH), OK)
	assert_eq(UserSettings.load_file(TMP_PATH), values)


func test_arquivo_grava_schema() -> void:
	var config := UserSettings.write(UserSettings.defaults())
	assert_eq(config.get_value(UserSettings.META, UserSettings.SCHEMA_KEY), UserSettings.SCHEMA)


func test_arquivo_inexistente_usa_padroes() -> void:
	assert_eq(UserSettings.load_file("user://nao_existe_f24.cfg"), UserSettings.defaults())


func test_chave_desconhecida_e_ignorada() -> void:
	var config := _config(UserSettings.VIDEO, {"hdr": true, UserSettings.VSYNC: false})
	config.set_value("rede", "porta", 7012)
	var values := UserSettings.read(config)
	assert_false(values[UserSettings.VIDEO].has("hdr"))
	assert_false(values.has("rede"))
	assert_false(values[UserSettings.VIDEO][UserSettings.VSYNC])


func test_schema_diferente_usa_padroes() -> void:
	var values := UserSettings.read(_config(UserSettings.VIDEO, {UserSettings.VSYNC: false}, 2))
	assert_eq(values, UserSettings.defaults())
	assert_push_warning("schema")


func test_tipo_errado_vira_padrao() -> void:
	var values := UserSettings.read(_config(UserSettings.AUDIO, {UserSettings.MASTER: "alto"}))
	assert_eq(values[UserSettings.AUDIO][UserSettings.MASTER], 1.0)


func test_volume_inteiro_e_aceito_e_fora_da_faixa_e_limitado() -> void:
	var values := UserSettings.read(
		_config(UserSettings.AUDIO, {UserSettings.MASTER: 0, UserSettings.MUSIC: 3.0})
	)
	assert_eq(values[UserSettings.AUDIO][UserSettings.MASTER], 0.0)
	assert_eq(values[UserSettings.AUDIO][UserSettings.MUSIC], 1.0)


func test_limite_de_quadros_fora_da_lista_vira_padrao() -> void:
	var values := UserSettings.read(_config(UserSettings.VIDEO, {UserSettings.FPS_CAP: 75}))
	assert_eq(values[UserSettings.VIDEO][UserSettings.FPS_CAP], 0)


func test_janela_menor_que_o_minimo_vira_padrao() -> void:
	var values := UserSettings.read(
		_config(UserSettings.VIDEO, {UserSettings.WIDTH: 320, UserSettings.HEIGHT: 200})
	)
	assert_eq(
		values[UserSettings.VIDEO][UserSettings.WIDTH],
		UserSettings.defaults()[UserSettings.VIDEO][UserSettings.WIDTH]
	)
	assert_eq(
		values[UserSettings.VIDEO][UserSettings.HEIGHT],
		UserSettings.defaults()[UserSettings.VIDEO][UserSettings.HEIGHT]
	)


func test_sensibilidade_fora_da_faixa_e_limitada() -> void:
	var values := UserSettings.read(
		_config(UserSettings.CONTROLS, {UserSettings.MOUSE_SENSITIVITY: 99.0})
	)
	assert_eq(
		values[UserSettings.CONTROLS][UserSettings.MOUSE_SENSITIVITY], UserSettings.SENSITIVITY_MAX
	)


func test_tecla_invalida_vira_padrao() -> void:
	var values := UserSettings.read(
		_config(UserSettings.CONTROLS, {String(InputActions.SKILL_E): "NaoExiste"})
	)
	assert_eq(values[UserSettings.CONTROLS][String(InputActions.SKILL_E)], "E")


func test_keycode_le_a_tecla_da_acao() -> void:
	assert_eq(UserSettings.keycode(UserSettings.defaults(), InputActions.INTERACT), KEY_F)


func test_rebind_troca_a_tecla_sem_mexer_no_original() -> void:
	var before := UserSettings.defaults()
	var after := UserSettings.rebind(before, InputActions.SKILL_Q, KEY_1)
	assert_eq(UserSettings.keycode(after, InputActions.SKILL_Q), KEY_1)
	assert_eq(UserSettings.keycode(before, InputActions.SKILL_Q), KEY_Q)


func test_rebind_com_tecla_em_uso_troca_as_duas() -> void:
	var values := UserSettings.rebind(UserSettings.defaults(), InputActions.SKILL_Q, KEY_E)
	assert_eq(UserSettings.keycode(values, InputActions.SKILL_Q), KEY_E)
	assert_eq(UserSettings.keycode(values, InputActions.SKILL_E), KEY_Q)


func test_rebind_de_acao_nao_remapeavel_nao_muda_nada() -> void:
	var before := UserSettings.defaults()
	assert_eq(UserSettings.rebind(before, InputActions.CANCEL, KEY_1), before)


func test_esc_nao_pode_ser_atribuido() -> void:
	var before := UserSettings.defaults()
	assert_eq(UserSettings.rebind(before, InputActions.SKILL_Q, KEY_ESCAPE), before)
