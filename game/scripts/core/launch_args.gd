class_name LaunchArgs
extends RefCounted
## Interpreta os argumentos de usuario (depois de `--` na linha de comando do Godot).

const DEFAULT_PORT: int = 7000
const MAX_PORT: int = 65535


static func parse(args: PackedStringArray) -> Dictionary:
	var result := {"mode": "client", "host": "", "port": DEFAULT_PORT, "autopilot": false}
	for arg: String in args:
		if arg == "--server":
			result["mode"] = "server"
		elif arg == "--autopilot":
			result["autopilot"] = true
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
