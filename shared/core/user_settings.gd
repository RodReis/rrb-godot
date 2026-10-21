class_name UserSettings
extends RefCounted
## Contrato user://settings.cfg (ARCHITECTURE-LAUNCHER §5.3): o Launcher escreve (F24), o Game le
## no boot. Valores num Dictionary secao -> chave -> valor, com os padroes de defaults(). Chave
## desconhecida e ignorada; tipo errado ou valor invalido vira o padrao (volume e sensibilidade
## sao limitados a faixa; a distancia da camera e a escala da interface fora da faixa voltam ao
## padrao); schema diferente
## devolve os padroes e loga. Funcoes puras: rebind() devolve uma copia.

const PATH: String = "user://settings.cfg"
const SCHEMA: int = 1
const META: String = "meta"
const SCHEMA_KEY: String = "schema"

const VIDEO: String = "video"
## Tipo de tela (F79, ADR-0019): modo da janela. O padrao e a janela sem borda.
const WINDOW_MODE: String = "window_mode"
const WINDOWED: String = "windowed"
const BORDERLESS: String = "borderless"
const EXCLUSIVE: String = "exclusive"
const WINDOW_MODES: Array[String] = [WINDOWED, BORDERLESS, EXCLUSIVE]
## Chave antiga ([video] fullscreen=bool), so lida: sem window_mode, true = BORDERLESS e false =
## WINDOWED. Nunca mais e gravada.
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

## [camera] da SPEC-067: distancia do FollowCamera ao heroi, em passos inteiros.
const CAMERA: String = "camera"
const DISTANCE: String = "distance"
const DISTANCE_MIN: float = 9.0
const DISTANCE_MAX: float = 14.0
const DISTANCE_STEP: float = 1.0
const DISTANCE_DEFAULT: float = 11.0

## [ui] da SPEC-097 (ADR-0031): escala da interface 2D do jogo (root.content_scale_factor).
const UI: String = "ui"
const HUD_SCALE: String = "hud_scale"
const HUD_SCALE_MIN: float = 0.7
## Teto 100 % (PI 2026-10-21): acima disso a area logica fica menor que a base 1920x1080 e a
## selecao de herois sobrepoe os cartoes.
const HUD_SCALE_MAX: float = 1.0
const HUD_SCALE_STEP: float = 0.05
const HUD_SCALE_DEFAULT: float = 0.85
## Folga da faixa: o Range arredonda o passo em float (0,7 + 6 x 0,05 = 0,9999999999999999).
const RANGE_EPSILON: float = 0.000001

## [training] do F81 (ADR-0021/0027): ultimo nivel do bot escolhido no Launcher (1..N de
## shared/data/rules/bot_levels.tres). O Launcher manda `--bot-difficulty`; o Game nao le a chave.
## Fora de 1..N o BotLevels.normalize devolve o Medio.
const TRAINING: String = "training"
const BOT_DIFFICULTY: String = "bot_difficulty"

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
	InputActions.CAMERA_ZOOM_IN,
	InputActions.CAMERA_ZOOM_OUT,
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
			WINDOW_MODE: BORDERLESS,
			WIDTH: MIN_WINDOW.x,
			HEIGHT: MIN_WINDOW.y,
			VSYNC: true,
			FPS_CAP: FPS_UNLIMITED,
		},
		AUDIO: {MASTER: VOLUME_MAX, MUSIC: VOLUME_MAX, SFX: VOLUME_MAX, VOICE: VOLUME_MAX},
		CONTROLS: controls,
		GRAPHICS: graphics,
		CAMERA: {DISTANCE: DISTANCE_DEFAULT},
		UI: {HUD_SCALE: HUD_SCALE_DEFAULT},
		TRAINING: {BOT_DIFFICULTY: BotLevels.DEFAULT_NUMBER},
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
	video[WINDOW_MODE] = _migrated_window_mode(config, video[WINDOW_MODE])
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


## Grava so section/key, relendo o arquivo para nao desfazer o que o Launcher salvou: o Game grava
## assim o zoom (F67) e a escala da interface (F97).
static func save_value(section: String, key: String, value: Variant, path: String = PATH) -> Error:
	var values := load_file(path)
	values[section][key] = value
	return save_file(values, path)


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


## Arquivo gravado antes do F79: sem window_mode, o fullscreen booleano manda. Com window_mode
## presente (valido ou nao) o fullscreen e ignorado; fullscreen de tipo errado tambem.
static func _migrated_window_mode(config: ConfigFile, current: String) -> String:
	if config.has_section_key(VIDEO, WINDOW_MODE) or not config.has_section_key(VIDEO, FULLSCREEN):
		return current
	var legacy: Variant = config.get_value(VIDEO, FULLSCREEN)
	if typeof(legacy) != TYPE_BOOL:
		return current
	return BORDERLESS if legacy else WINDOWED


static func _valid(section: String, key: String, raw: Variant, fallback: Variant) -> Variant:
	if fallback is float:
		if not (raw is float or raw is int):
			return fallback
		# fora da faixa nao e limitado: volta ao padrao (SPEC-067 §3, SPEC-097)
		if section == CAMERA:
			return _in_range(float(raw), DISTANCE_MIN, DISTANCE_MAX, fallback)
		if section == UI:
			return _in_range(float(raw), HUD_SCALE_MIN, HUD_SCALE_MAX, fallback)
		return _clamp_float(section, float(raw))
	if typeof(raw) != typeof(fallback):
		return fallback
	if section == CONTROLS and raw is String:
		var code := OS.find_keycode_from_string(raw)
		return raw if code != KEY_NONE and code not in RESERVED_KEYS else fallback
	if section == VIDEO and key == FPS_CAP:
		return raw if raw in FPS_CAPS else fallback
	if section == VIDEO and key == WINDOW_MODE:
		return raw if raw in WINDOW_MODES else fallback
	return raw


static func _in_range(value: float, low: float, high: float, fallback: float) -> float:
	if value < low - RANGE_EPSILON or value > high + RANGE_EPSILON:
		return fallback
	return clampf(value, low, high)


static func _clamp_float(section: String, value: float) -> float:
	if section == AUDIO:
		return clampf(value, VOLUME_MIN, VOLUME_MAX)
	return clampf(value, SENSITIVITY_MIN, SENSITIVITY_MAX)
