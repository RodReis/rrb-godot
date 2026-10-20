class_name LaunchArgs
extends RefCounted
## Interpreta os argumentos de usuario (depois de `--` na linha de comando do Godot).
## --offline: modo host (servidor + jogador local no mesmo processo); --bot: heroi bot no 2o slot.
## --autopilot: o heroi local anda em circulo; --autopilot=bot: o BotInput joga pelo heroi local
## (so le estado replicado). --probe: sonda de rede (NetProbe, F20), para medir replicacao.
## --daynight=day|night: forca o inicio da luz no servidor (F49); fora do contrato com o Launcher.
## --bot-hero=<id>: heroi do bot e, com --autopilot=bot, do heroi local (dev, F53); ausente ou sem
## cena = padrao do slot.
## --bots: as duas vagas sao bots no servidor, sem cliente (soak bot x bot, F19; fora do contrato
## com o Launcher). --bot-heroes=<time A>,<time B>: o heroi de cada bot; so vale com dois ids,
## senao o padrao do slot. --bot-levels=<a>,<b>: o nivel de cada bot com --bots (soak por nivel,
## F81; fora do contrato com o Launcher).
## --token=<match_token>: o cliente online apresenta o token da partida ao servidor (contrato com
## o Launcher, ARCHITECTURE-LAUNCHER §5.2). --no-backend: servidor dedicado de dev, sem backend:
## admite qualquer peer e nao reporta resultado (fora do contrato com o Launcher).
## --arena=<variante>: cena variante da arena (dev, F84; fora do contrato com o Launcher); so as
## de ARENA_VARIANTS, qualquer outro valor = a oficial.

const DEFAULT_PORT: int = 7000
const MAX_PORT: int = 65535
## --level=N e argumento de dev ate a progressao do F9 (PI 2026-10-09).
const DEFAULT_LEVEL: int = 1
## --seed=N: seed dos drops dos baus no servidor; 0 = sorteia (SpawnDirector).
const NO_SEED: int = 0
## --time=S: relogio da partida ja comeca em S segundos (dev, para ver o boss sem esperar 3:30).
const DEFAULT_TIME: float = 0.0
## --daynight: ausente = sentido sorteado pela seed da partida (DayNightRules).
const DAYNIGHT_AUTO: String = ""
const DAYNIGHT_DAY: String = "day"
const DAYNIGHT_NIGHT: String = "night"
## --bot-difficulty=<n>: nivel do bot do treino (F81, ADR-0021/0027); 0 = ausente (BotLevels
## normaliza para o Medio, tambem fora de 1..N).
const NO_DIFFICULTY: int = 0
## --bot-heroes e --bot-levels: um valor por time.
const HERO_PAIR_SIZE: int = 2
## --intro-ready-delay=S: o cliente atrasa o ready da cinematica de abertura em S segundos (dev,
## F69: prova o corte aos 8 s com um dos dois atrasado).
const DEFAULT_INTRO_READY_DELAY: float = 0.0
## --arena: variantes aceitas (nome -> cena); a oficial e a de main.tscn.
const ARENA_VARIANTS: Dictionary[String, String] = {
	"spike_f84": "res://scenes/arena/spike_f84.tscn",
}


static func parse(args: PackedStringArray) -> Dictionary:
	var result := {
		"mode": "client",
		"host": "",
		"port": DEFAULT_PORT,
		"autopilot": false,
		"level": DEFAULT_LEVEL,
		"seed": NO_SEED,
		"time": DEFAULT_TIME,
		"daynight": DAYNIGHT_AUTO,
		"intro_ready_delay": DEFAULT_INTRO_READY_DELAY,
		"offline": false,
		"bot": false,
		"bot_hero": &"",
		"bot_difficulty": NO_DIFFICULTY,
		"bots": false,
		"bot_heroes": [] as Array[StringName],
		"bot_levels": [] as Array[int],
		"bot_pilot": false,
		"probe": false,
		"token": "",
		"no_backend": false,
		"arena": "",
	}
	for arg: String in args:
		if arg == "--server":
			result["mode"] = "server"
		elif arg == "--offline":
			result["offline"] = true
		elif arg == "--bot":
			result["bot"] = true
		elif arg == "--bots":
			result["bots"] = true
		elif arg.begins_with("--bot-difficulty="):
			var text := arg.trim_prefix("--bot-difficulty=")
			result["bot_difficulty"] = text.to_int() if text.is_valid_int() else NO_DIFFICULTY
		elif arg.begins_with("--bot-levels="):
			result["bot_levels"] = _level_pair(arg.trim_prefix("--bot-levels="))
		elif arg.begins_with("--bot-heroes="):
			result["bot_heroes"] = _hero_pair(arg.trim_prefix("--bot-heroes="))
		elif arg.begins_with("--bot-hero="):
			result["bot_hero"] = StringName(arg.trim_prefix("--bot-hero="))
		elif arg == "--autopilot":
			result["autopilot"] = true
		elif arg == "--autopilot=bot":
			result["bot_pilot"] = true
		elif arg == "--probe":
			result["probe"] = true
		elif arg == "--no-backend":
			result["no_backend"] = true
		elif arg.begins_with("--arena="):
			var name := arg.trim_prefix("--arena=")
			result["arena"] = name if ARENA_VARIANTS.has(name) else ""
		elif arg.begins_with("--token="):
			result["token"] = arg.trim_prefix("--token=")
		elif arg.begins_with("--level="):
			result["level"] = _level_or_default(arg.trim_prefix("--level="))
		elif arg.begins_with("--seed="):
			var text := arg.trim_prefix("--seed=")
			result["seed"] = text.to_int() if text.is_valid_int() else NO_SEED
		elif arg.begins_with("--time="):
			var seconds := arg.trim_prefix("--time=")
			var valid := seconds.is_valid_float() and seconds.to_float() >= DEFAULT_TIME
			result["time"] = seconds.to_float() if valid else DEFAULT_TIME
		elif arg.begins_with("--intro-ready-delay="):
			var seconds := arg.trim_prefix("--intro-ready-delay=")
			var valid := seconds.is_valid_float() and seconds.to_float() >= 0.0
			result["intro_ready_delay"] = seconds.to_float() if valid else DEFAULT_INTRO_READY_DELAY
		elif arg.begins_with("--daynight="):
			var mode := arg.trim_prefix("--daynight=")
			var valid := mode == DAYNIGHT_DAY or mode == DAYNIGHT_NIGHT
			result["daynight"] = mode if valid else DAYNIGHT_AUTO
		elif arg.begins_with("--port="):
			result["port"] = _port_or_default(arg.trim_prefix("--port="))
		elif arg.begins_with("--connect="):
			var parts := arg.trim_prefix("--connect=").split(":")
			result["host"] = parts[0]
			if parts.size() > 1:
				result["port"] = _port_or_default(parts[1])
	return result


## Cena da variante [param arena]; vazio = a oficial.
static func arena_scene(arena: String) -> String:
	return ARENA_VARIANTS.get(arena, "")


## Dois ids separados por virgula; qualquer outra forma = vazio (padrao do slot).
static func _hero_pair(text: String) -> Array[StringName]:
	var ids: Array[StringName] = []
	var parts := text.split(",")
	if parts.size() != HERO_PAIR_SIZE:
		return ids
	for part: String in parts:
		if part.strip_edges().is_empty():
			return []
		ids.append(StringName(part.strip_edges()))
	return ids


## Dois inteiros separados por virgula; qualquer outra forma = vazio (nivel padrao).
static func _level_pair(text: String) -> Array[int]:
	var levels: Array[int] = []
	var parts := text.split(",")
	if parts.size() != HERO_PAIR_SIZE:
		return levels
	for part: String in parts:
		if not part.strip_edges().is_valid_int():
			return []
		levels.append(part.strip_edges().to_int())
	return levels


static func _port_or_default(text: String) -> int:
	if text.is_valid_int():
		var port := text.to_int()
		if port > 0 and port <= MAX_PORT:
			return port
	return DEFAULT_PORT


static func _level_or_default(text: String) -> int:
	if text.is_valid_int() and text.to_int() >= DEFAULT_LEVEL:
		return text.to_int()
	return DEFAULT_LEVEL
