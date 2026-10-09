class_name LaunchArgs
extends RefCounted
## Interpreta os argumentos de usuario (depois de `--` na linha de comando do Godot).

const DEFAULT_PORT: int = 7000
const MAX_PORT: int = 65535
## --level=N e argumento de dev ate a progressao do F9 (PI 2026-10-09).
const DEFAULT_LEVEL: int = 1
## --seed=N: seed dos drops dos baus no servidor; 0 = sorteia (SpawnDirector).
const NO_SEED: int = 0


static func parse(args: PackedStringArray) -> Dictionary:
	var result := {
		"mode": "client",
		"host": "",
		"port": DEFAULT_PORT,
		"autopilot": false,
		"level": DEFAULT_LEVEL,
		"seed": NO_SEED,
	}
	for arg: String in args:
		if arg == "--server":
			result["mode"] = "server"
		elif arg == "--autopilot":
			result["autopilot"] = true
		elif arg.begins_with("--level="):
			result["level"] = _level_or_default(arg.trim_prefix("--level="))
		elif arg.begins_with("--seed="):
			var text := arg.trim_prefix("--seed=")
			result["seed"] = text.to_int() if text.is_valid_int() else NO_SEED
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
