class_name GraphicsSettings
extends RefCounted
## Toggles graficos de [graphics] no settings.cfg (ADR-0006 item 8; contrato Launcher <-> Game,
## ARCHITECTURE-LAUNCHER §5.3): o Launcher escreve (F24), o Game le no boot. Chave ausente, de
## tipo errado ou arquivo inexistente = ligado; schema diferente = padroes (e loga).
## So desliga: o que a arena ja traz desligado continua desligado.

const PATH: String = UserSettings.PATH
const SCHEMA: int = UserSettings.SCHEMA
const SECTION: String = UserSettings.GRAPHICS
## Neblina volumetrica.
const FOG: String = UserSettings.FOG
const SSIL: String = UserSettings.SSIL
const SSAO: String = UserSettings.SSAO
## Grama decorativa (F42; Vegetation).
const GRASS: String = UserSettings.GRASS
const KEYS: Array[String] = UserSettings.GRAPHICS_KEYS


static func defaults() -> Dictionary:
	var flags := {}
	for key: String in KEYS:
		flags[key] = true
	return flags


static func read(config: ConfigFile) -> Dictionary:
	var flags := defaults()
	var schema: Variant = config.get_value("meta", "schema", SCHEMA)
	if schema != SCHEMA:
		push_warning("[graphics] settings.cfg com schema %s; usando padroes" % str(schema))
		return flags
	for key: String in KEYS:
		var value: Variant = config.get_value(SECTION, key, true)
		flags[key] = value if value is bool else true
	return flags


## Arquivo ausente = padroes; ilegivel (corrompido) = padroes e loga.
static func load_file(path: String = PATH) -> Dictionary:
	var config := ConfigFile.new()
	var err := config.load(path)
	if err != OK:
		if err != ERR_FILE_NOT_FOUND:
			push_warning("[graphics] %s ilegivel (%s); usando padroes" % [path, error_string(err)])
		return defaults()
	return read(config)


## Liga/desliga no proprio Environment recebido (passe uma copia).
static func apply(env: Environment, flags: Dictionary) -> void:
	env.volumetric_fog_enabled = env.volumetric_fog_enabled and flags[FOG]
	env.ssil_enabled = env.ssil_enabled and flags[SSIL]
	env.ssao_enabled = env.ssao_enabled and flags[SSAO]
