extends GutTest
## F24: SettingsStore (ARCHITECTURE-LAUNCHER §3.3, §5.3) grava e le o settings.cfg pelo contrato:
## round-trip, chave desconhecida, schema diferente e falha de gravacao.

const TMP_PATH: String = "user://test_f24_store.cfg"


func after_each() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TMP_PATH))


func test_sem_arquivo_comeca_nos_padroes() -> void:
	var store := SettingsStore.new(TMP_PATH)
	assert_eq(store.load_values(), UserSettings.defaults())


func test_round_trip_do_settings_cfg() -> void:
	var store := SettingsStore.new(TMP_PATH)
	var values := UserSettings.defaults()
	values[UserSettings.VIDEO][UserSettings.VSYNC] = false
	values[UserSettings.AUDIO][UserSettings.MASTER] = 0.4
	values[UserSettings.GRAPHICS][UserSettings.GRASS] = false
	values = UserSettings.rebind(values, InputActions.INTERACT, KEY_G)
	assert_eq(store.save(values), OK)
	assert_eq(SettingsStore.new(TMP_PATH).load_values(), values)


func test_chave_desconhecida_no_arquivo_e_ignorada() -> void:
	var config := ConfigFile.new()
	config.set_value(UserSettings.META, UserSettings.SCHEMA_KEY, UserSettings.SCHEMA)
	config.set_value(UserSettings.VIDEO, "ray_tracing", true)
	config.set_value(UserSettings.VIDEO, UserSettings.FPS_CAP, 120)
	config.save(TMP_PATH)
	var values := SettingsStore.new(TMP_PATH).load_values()
	assert_false(values[UserSettings.VIDEO].has("ray_tracing"))
	assert_eq(values[UserSettings.VIDEO][UserSettings.FPS_CAP], 120)


func test_schema_diferente_volta_aos_padroes() -> void:
	var config := ConfigFile.new()
	config.set_value(UserSettings.META, UserSettings.SCHEMA_KEY, 99)
	config.set_value(UserSettings.VIDEO, UserSettings.FPS_CAP, 120)
	config.save(TMP_PATH)
	assert_eq(SettingsStore.new(TMP_PATH).load_values(), UserSettings.defaults())
	assert_push_warning("schema")


func test_salvar_avisa_quem_aplica() -> void:
	var store := SettingsStore.new(TMP_PATH)
	watch_signals(store)
	store.save(UserSettings.defaults())
	assert_signal_emitted(store, "saved")


func test_falha_ao_gravar_mantem_os_valores_e_nao_avisa() -> void:
	var store := SettingsStore.new("user://pasta_que_nao_existe_f24/settings.cfg")
	var before := store.values.duplicate(true)
	var values := UserSettings.defaults()
	values[UserSettings.VIDEO][UserSettings.VSYNC] = false
	watch_signals(store)
	assert_ne(store.save(values), OK)
	assert_eq(store.values, before)
	assert_signal_not_emitted(store, "saved")


func test_restaurar_grava_os_padroes() -> void:
	var store := SettingsStore.new(TMP_PATH)
	var values := UserSettings.defaults()
	values[UserSettings.AUDIO][UserSettings.MUSIC] = 0.1
	store.save(values)
	assert_eq(store.reset(), OK)
	assert_eq(SettingsStore.new(TMP_PATH).load_values(), UserSettings.defaults())
