class_name SettingsApplier
extends RefCounted
## Aplica no processo os valores de UserSettings (settings.cfg, ARCHITECTURE-LAUNCHER §5.3): video
## e audio no Launcher e no Game; controles so no Game (InputMap). O [graphics] e da arena
## (GraphicsSettings). Headless nao tem janela: o video e ignorado.

## Barramento dos alertas e jingles: a chave music do contrato (decisao do PI em 2026-10-15).
const MUSIC_BUS: StringName = &"Music"
const MASTER_BUS: StringName = &"Master"


## Janela (modo e tamanho) so com window = true: o Game rodado com --resolution/--position
## (run-clients.ps1) mantem o que a linha de comando pediu.
static func apply_video(values: Dictionary, root: Window, window: bool = true) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var video: Dictionary = values[UserSettings.VIDEO]
	var vsync := (
		DisplayServer.VSYNC_ENABLED if video[UserSettings.VSYNC] else DisplayServer.VSYNC_DISABLED
	)
	DisplayServer.window_set_vsync_mode(vsync)
	Engine.max_fps = video[UserSettings.FPS_CAP]
	if not window:
		return
	if video[UserSettings.FULLSCREEN]:
		root.mode = Window.MODE_FULLSCREEN
		return
	root.mode = Window.MODE_WINDOWED
	var wanted := Vector2i(video[UserSettings.WIDTH], video[UserSettings.HEIGHT])
	var usable := DisplayServer.screen_get_usable_rect(root.current_screen).size
	root.size = wanted.min(usable)
	root.move_to_center()


## Barramento ausente (o Launcher nao tem Music) e ignorado.
static func apply_audio(values: Dictionary) -> void:
	var audio: Dictionary = values[UserSettings.AUDIO]
	_set_volume(MASTER_BUS, audio[UserSettings.MASTER])
	_set_volume(MUSIC_BUS, audio[UserSettings.MUSIC])


## Troca a tecla de cada acao remapeavel (e o Ctrl + tecla de aprender a skill, InputActions.LEARN)
## e, com gamepad desligado, tira os eventos de controle. Chame depois de InputActions.ensure().
static func apply_controls(values: Dictionary) -> void:
	for action: StringName in UserSettings.BINDABLE:
		_set_key(action, UserSettings.keycode(values, action), false)
	var skills: Array[StringName] = [
		InputActions.SKILL_Q, InputActions.SKILL_E, InputActions.SKILL_R
	]
	for i: int in InputActions.LEARN.size():
		_set_key(InputActions.LEARN[i], UserSettings.keycode(values, skills[i]), true)
	if not values[UserSettings.CONTROLS][UserSettings.GAMEPAD]:
		for action: StringName in InputActions.ALL:
			for event: InputEvent in InputMap.action_get_events(action):
				if event is InputEventJoypadButton or event is InputEventJoypadMotion:
					InputMap.action_erase_event(action, event)


static func _set_volume(bus_name: StringName, linear: float) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index < 0:
		return
	AudioServer.set_bus_mute(index, linear <= UserSettings.VOLUME_MIN)
	if linear > UserSettings.VOLUME_MIN:
		AudioServer.set_bus_volume_db(index, linear_to_db(linear))


static func _set_key(action: StringName, keycode: Key, ctrl: bool) -> void:
	if not InputMap.has_action(action):
		return
	var current: Array[InputEventKey] = []
	for event: InputEvent in InputMap.action_get_events(action):
		var key := event as InputEventKey
		if key != null and key.ctrl_pressed == ctrl:
			current.append(key)
	if current.size() == 1 and current[0].physical_keycode == keycode:
		return  # mesma tecla: nao mexe (a ordem dos eventos da acao fica a do ensure)
	for key: InputEventKey in current:
		InputMap.action_erase_event(action, key)
	var replacement := InputEventKey.new()
	replacement.physical_keycode = keycode
	replacement.ctrl_pressed = ctrl
	InputMap.action_add_event(action, replacement)
