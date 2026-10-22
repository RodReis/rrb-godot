class_name FakeGameProcess
extends GameProcess
## GameProcess falso (ARCHITECTURE-LAUNCHER §7): nao abre processo nenhum. Grava os argumentos de
## cada lancamento e devolve `launch_result` (-1 = "instalacao incompleta"). `running` simula o
## Game aberto.

var launched: Array[PackedStringArray] = []
var launch_result: int = 4242
var running: bool = false


func launch(game_args: PackedStringArray, _launcher_args: PackedStringArray = []) -> int:
	launched.append(game_args)
	return launch_result


func is_running() -> bool:
	return running
