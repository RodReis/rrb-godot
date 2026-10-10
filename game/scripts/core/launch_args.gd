class_name LaunchArgs
extends RefCounted
## Interpreta os argumentos de usuario (depois de `--` na linha de comando do Godot).
## --offline: modo host (servidor + jogador local no mesmo processo); --bot: heroi bot no 2o slot.
## --autopilot: o heroi local anda em circulo; --autopilot=bot: o BotInput joga pelo heroi local
## (so le estado replicado). --probe: sonda de rede (NetProbe, F20), para medir replicacao.

const DEFAULT_PORT: int = 7000
const MAX_PORT: int = 65535
## --level=N e argumento de dev ate a progressao do F9 (PI 2026-10-09).
const DEFAULT_LEVEL: int = 1
## --seed=N: seed dos drops dos baus no servidor; 0 = sorteia (SpawnDirector).
const NO_SEED: int = 0
## --time=S: relogio da partida ja comeca em S segundos (dev, para ver o boss sem esperar 3:30).
const DEFAULT_TIME: float = 0.0


static func parse(args: PackedStringArray) -> Dictionary:
	var result := {
		"mode": "client",
		"host": "",
		"port": DEFAULT_PORT,
		"autopilot": false,
		"level": DEFAULT_LEVEL,
		"seed": NO_SEED,
		"time": DEFAULT_TIME,
		"offline": false,
		"bot": false,
		"bot_pilot": false,
		"probe": false,
	}
	for arg: String in args:
		if arg == "--server":
			result["mode"] = "server"
		elif arg == "--offline":
			result["offline"] = true
		elif arg == "--bot":
			result["bot"] = true
		elif arg == "--autopilot":
			result["autopilot"] = true
		elif arg == "--autopilot=bot":
			result["bot_pilot"] = true
		elif arg == "--probe":
			result["probe"] = true
		elif arg.begins_with("--level="):
			result["level"] = _level_or_default(arg.trim_prefix("--level="))
		elif arg.begins_with("--seed="):
			var text := arg.trim_prefix("--seed=")
			result["seed"] = text.to_int() if text.is_valid_int() else NO_SEED
		elif arg.begins_with("--time="):
			var seconds := arg.trim_prefix("--time=")
			var valid := seconds.is_valid_float() and seconds.to_float() >= DEFAULT_TIME
			result["time"] = seconds.to_float() if valid else DEFAULT_TIME
		elif arg.begins_with("--port="):
			result["port"] = _port_or_default(arg.trim_prefix("--port="))
		elif arg.begins_with("--connect="):
			var parts := arg.trim_prefix("--connect=").split(":")
			result["host"] = parts[0]
			if parts.size() > 1:
				result["port"] = _port_or_default(parts[1])
	return result


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
