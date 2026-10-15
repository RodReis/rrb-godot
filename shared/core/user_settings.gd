class_name UserSettings
extends RefCounted
## Contrato user://settings.cfg (ARCHITECTURE-LAUNCHER §5.3): o Launcher escreve (F24), o Game le
## no boot. Valores num Dictionary secao -> chave -> valor, com os padroes de defaults(). Chave
## desconhecida e ignorada; tipo errado ou valor invalido vira o padrao (volume e sensibilidade
## sao limitados a faixa); schema diferente devolve os padroes e loga. Funcoes puras: rebind()
## devolve uma copia.

const PATH: String = "user://settings.cfg"
const SCHEMA: int = 1
const META: String = "meta"
const SCHEMA_KEY: String = "schema"

const VIDEO: String = "video"
const FULLSCREEN: String = "fullscreen"
const WIDTH: String = "width"
const HEIGHT: String = "height"
const VSYNC: String = "vsync"
const FPS_CAP: String = "fps_cap"

const AUDIO: String = "audio"
const MASTER: String = "master"
const MUSIC: String = "music"
const SFX: String = "sfx"
const VOICE: String = "voice"

const CONTROLS: String = "controls"
const MOUSE_SENSITIVITY: String = "mouse_sensitivity"
const GAMEPAD: String = "gamepad"

## [graphics] do F38 (ADR-0006 item 8): o Game so desliga o que a arena traz ligado.
const GRAPHICS: String = "graphics"
const FOG: String = "fog"
const SSIL: String = "ssil"
const SSAO: String = "ssao"
const GRASS: String = "grass"
const GRAPHICS_KEYS: Array[String] = [FOG, SSIL, SSAO, GRASS]

## Limites de quadros oferecidos; 0 = sem limite (Engine.max_fps).
const FPS_UNLIMITED: int = 0
const FPS_CAPS: Array[int] = [60, 120, 144, FPS_UNLIMITED]
## Janela minima suportada (TOKENS §5) e a padrao: a mesma do project.godot dos dois projetos.
const MIN_WINDOW: Vector2i = Vector2i(1280, 720)
const VOLUME_MIN: float = 0.0
const VOLUME_MAX: float = 1.0
## Multiplicador da sensibilidade do giro da camera (FollowCamera.orbit_sensitivity).
const SENSITIVITY_MIN: float = 0.25
const SENSITIVITY_MAX: float = 3.0
const SENSITIVITY_DEFAULT: float = 1.0
## Teclas remapeaveis: as de InputActions.KEYS menos Esc (cancelar e da interface).
const BINDABLE: Array[StringName] = [
	InputActions.MOVE_FORWARD,
	InputActions.MOVE_BACK,
	InputActions.MOVE_LEFT,
	InputActions.MOVE_RIGHT,
	InputActions.SKILL_Q,
	InputActions.SKILL_E,
	InputActions.SKILL_R,
	InputActions.INTERACT,
	InputActions.DODGE,
	InputActions.SCOREBOARD,
	InputActions.OPEN_BESTIARY,
]
## Teclas que nao podem ir para uma acao: Esc volta/fecha em toda tela.
const RESERVED_KEYS: Array[Key] = [KEY_ESCAPE]


static func defaults() -> Dictionary:
	var controls := {MOUSE_SENSITIVITY: SENSITIVITY_DEFAULT, GAMEPAD: true}
	for action: StringName in BINDABLE:
		controls[String(action)] = OS.get_keycode_string(InputActions.KEYS[action])
	var graphics := {}
	for key: String in GRAPHICS_KEYS:
		graphics[key] = true
	return {
		VIDEO:
		{
			FULLSCREEN: false,
			WIDTH: MIN_WINDOW.x,
			HEIGHT: MIN_WINDOW.y,
			VSYNC: true,
			FPS_CAP: FPS_UNLIMITED,
		},
		AUDIO: {MASTER: VOLUME_MAX, MUSIC: VOLUME_MAX, SFX: VOLUME_MAX, VOICE: VOLUME_MAX},
		CONTROLS: controls,
		GRAPHICS: graphics,
	}


static func read(config: ConfigFile) -> Dictionary:
	var values := defaults()
	var schema: Variant = config.get_value(META, SCHEMA_KEY, SCHEMA)
	if schema != SCHEMA:
		push_warning("[settings] settings.cfg com schema %s; usando padroes" % str(schema))
		return values
	for section: String in values:
		var fields: Dictionary = values[section]
		for key: String in fields:
			var raw: Variant = config.get_value(section, key, fields[key])
			fields[key] = _valid(section, key, raw, fields[key])
	var video: Dictionary = values[VIDEO]
	if video[WIDTH] < MIN_WINDOW.x or video[HEIGHT] < MIN_WINDOW.y:
		video[WIDTH] = MIN_WINDOW.x
		video[HEIGHT] = MIN_WINDOW.y
	return values


static func write(values: Dictionary) -> ConfigFile:
	var config := ConfigFile.new()
	for section: String in values:
		var fields: Dictionary = values[section]
		for key: String in fields:
			config.set_value(section, key, fields[key])
	config.set_value(META, SCHEMA_KEY, SCHEMA)
	return config


## Arquivo ausente = padroes; ilegivel (corrompido) = padroes e loga.
static func load_file(path: String = PATH) -> Dictionary:
	var config := ConfigFile.new()
	var err := config.load(path)
	if err != OK:
		if err != ERR_FILE_NOT_FOUND:
			push_warning("[settings] %s ilegivel (%s); usando padroes" % [path, error_string(err)])
		return defaults()
	return read(config)


static func save_file(values: Dictionary, path: String = PATH) -> Error:
	return write(values).save(path)


static func keycode(values: Dictionary, action: StringName) -> Key:
	return OS.find_keycode_from_string(values[CONTROLS][String(action)])


## Copia de values com a tecla na acao; se outra acao usava a tecla, ela fica com a antiga
## (troca, sem conflito). Acao nao remapeavel, tecla reservada ou sem codigo: copia sem mudanca.
static func rebind(values: Dictionary, action: StringName, key: Key) -> Dictionary:
	var copy := values.duplicate(true)
	if action not in BINDABLE or key in RESERVED_KEYS or key == KEY_NONE:
		return copy
	var controls: Dictionary = copy[CONTROLS]
	var old: String = controls[String(action)]
	var wanted := OS.get_keycode_string(key)
	for other: StringName in BINDABLE:
		if controls[String(other)] == wanted:
			controls[String(other)] = old
	controls[String(action)] = wanted
	return copy


static func _valid(section: String, key: String, raw: Variant, fallback: Variant) -> Variant:
	if fallback is float:
		if not (raw is float or raw is int):
			return fallback
		return _clamp_float(section, float(raw))
	if typeof(raw) != typeof(fallback):
		return fallback
	if section == CONTROLS and raw is String:
		var code := OS.find_keycode_from_string(raw)
		return raw if code != KEY_NONE and code not in RESERVED_KEYS else fallback
	if section == VIDEO and key == FPS_CAP:
		return raw if raw in FPS_CAPS else fallback
	return raw


static func _clamp_float(section: String, value: float) -> float:
	if section == AUDIO:
		return clampf(value, VOLUME_MIN, VOLUME_MAX)
	return clampf(value, SENSITIVITY_MIN, SENSITIVITY_MAX)
