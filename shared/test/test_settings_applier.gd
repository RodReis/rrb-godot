extends GutTest
## F24: o Game aplica o settings.cfg no boot (controles e audio; video e no-op em headless).

var _music_bus: int = -1
var _added_bus: bool = false


func before_each() -> void:
	InputActions.ensure()
	_music_bus = AudioServer.get_bus_index(SettingsApplier.MUSIC_BUS)
	_added_bus = _music_bus < 0
	if _added_bus:
		AudioServer.add_bus()
		_music_bus = AudioServer.bus_count - 1
		AudioServer.set_bus_name(_music_bus, SettingsApplier.MUSIC_BUS)


func after_each() -> void:
	var defaults := UserSettings.defaults()
	SettingsApplier.apply_controls(defaults)
	SettingsApplier.apply_audio(defaults)
	for action: StringName in InputActions.ALL:  # devolve os eventos de gamepad
		InputMap.erase_action(action)
	for action: StringName in InputActions.LEARN + InputActions.MOUSE_ONLY:
		InputMap.erase_action(action)
	InputActions.ensure()
	if _added_bus:
		AudioServer.remove_bus(_music_bus)


func _keys(action: StringName, ctrl: bool) -> Array[Key]:
	var keys: Array[Key] = []
	for event: InputEvent in InputMap.action_get_events(action):
		var key := event as InputEventKey
		if key != null and key.ctrl_pressed == ctrl:
			keys.append(key.physical_keycode)
	return keys


func _has_joypad(action: StringName) -> bool:
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventJoypadButton or event is InputEventJoypadMotion:
			return true
	return false


## F79 / ADR-0019: tipo de tela -> Window.Mode (doc 4.7). O video e no-op em headless.
func test_tipo_de_tela_vira_o_modo_da_janela() -> void:
	assert_eq(SettingsApplier.window_mode_of(UserSettings.WINDOWED), Window.MODE_WINDOWED)
	assert_eq(SettingsApplier.window_mode_of(UserSettings.BORDERLESS), Window.MODE_FULLSCREEN)
	assert_eq(
		SettingsApplier.window_mode_of(UserSettings.EXCLUSIVE), Window.MODE_EXCLUSIVE_FULLSCREEN
	)


func test_tipo_de_tela_desconhecido_vira_janela_sem_borda() -> void:
	assert_eq(SettingsApplier.window_mode_of("lixo"), Window.MODE_FULLSCREEN)


func test_so_o_modo_janela_usa_a_resolucao_escolhida() -> void:
	assert_true(SettingsApplier.uses_resolution(UserSettings.WINDOWED))
	assert_false(SettingsApplier.uses_resolution(UserSettings.BORDERLESS))
	assert_false(SettingsApplier.uses_resolution(UserSettings.EXCLUSIVE))


func test_tecla_remapeada_substitui_a_padrao() -> void:
	var values := UserSettings.rebind(UserSettings.defaults(), InputActions.SKILL_Q, KEY_1)
	SettingsApplier.apply_controls(values)
	assert_eq(_keys(InputActions.SKILL_Q, false), [KEY_1] as Array[Key])


func test_aprender_skill_segue_a_tecla_nova() -> void:
	var values := UserSettings.rebind(UserSettings.defaults(), InputActions.SKILL_E, KEY_2)
	SettingsApplier.apply_controls(values)
	assert_eq(_keys(InputActions.LEARN_E, true), [KEY_2] as Array[Key])


func test_gamepad_desligado_tira_os_eventos_de_controle() -> void:
	var values := UserSettings.defaults()
	values[UserSettings.CONTROLS][UserSettings.GAMEPAD] = false
	assert_true(_has_joypad(InputActions.DODGE))
	SettingsApplier.apply_controls(values)
	assert_false(_has_joypad(InputActions.DODGE))
	assert_eq(_keys(InputActions.DODGE, false), [KEY_SPACE] as Array[Key])


func test_volume_vai_para_os_barramentos() -> void:
	var values := UserSettings.defaults()
	values[UserSettings.AUDIO][UserSettings.MASTER] = 0.5
	values[UserSettings.AUDIO][UserSettings.MUSIC] = 0.0
	SettingsApplier.apply_audio(values)
	assert_almost_eq(AudioServer.get_bus_volume_db(0), linear_to_db(0.5), 0.01)
	assert_false(AudioServer.is_bus_mute(0))
	assert_true(AudioServer.is_bus_mute(_music_bus))


func test_video_em_headless_nao_falha() -> void:
	var fps := Engine.max_fps
	var values := UserSettings.defaults()
	values[UserSettings.VIDEO][UserSettings.FPS_CAP] = 60
	SettingsApplier.apply_video(values, get_tree().root)
	assert_eq(Engine.max_fps, fps, "headless: video ignorado")
