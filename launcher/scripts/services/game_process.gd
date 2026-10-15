class_name GameProcess
extends Node
## Lanca e acompanha o processo do Game (ARCHITECTURE-LAUNCHER §3.3, contrato §5). O Launcher so
## conhece o executavel, os argumentos e o codigo de saida. Instalacao: <launcher>/game/game.exe.
## Dev: --game-path=<executavel> (ex.: o Godot console) e --game-project=<pasta do projeto game>.
## Os argumentos do Game vao depois de "--" (o Game le OS.get_cmdline_user_args()).

## Codigo de saida (ou KILLED, quando o jogador encerrou o jogo pelo Launcher).
signal exited(code: int)

enum Kind { NORMAL, WARNING, ERROR }

const POLL_SECONDS: float = 0.5
const GAME_PATH_ARG: String = "--game-path="
const GAME_PROJECT_ARG: String = "--game-project="
const INSTALL_PATH: String = "/game/game.exe"
const NOT_RUNNING: int = -1
## Codigos do Game (ARCHITECTURE-GAME §6); processo morto pelo jogador conta como interno (§5.2).
const EXIT_NORMAL: int = 0
const EXIT_ARGUMENTS: int = 1
const EXIT_AUTH: int = 2
const EXIT_RESULT_NOT_REPORTED: int = 3
const EXIT_INTERNAL: int = 4
const KILLED: int = EXIT_INTERNAL

var _pid: int = NOT_RUNNING
var _timer: Timer = Timer.new()


## O que o Launcher faz com o codigo de saida (§5.2).
class Outcome:
	extends RefCounted
	var kind: Kind = Kind.NORMAL
	var message: String = ""
	## Codigo 2 (token recusado/expirado): oferecer nova fila (§6).
	var offer_queue: bool = false


## [executavel, argumentos...] para os argumentos do Game e os do proprio Launcher.
static func command(
	game_args: PackedStringArray, launcher_args: PackedStringArray, exe_dir: String
) -> PackedStringArray:
	var path := exe_dir + INSTALL_PATH
	var project := ""
	for arg: String in launcher_args:
		if arg.begins_with(GAME_PATH_ARG):
			path = arg.trim_prefix(GAME_PATH_ARG)
		elif arg.begins_with(GAME_PROJECT_ARG):
			project = arg.trim_prefix(GAME_PROJECT_ARG)
	var result := PackedStringArray([path])
	if not project.is_empty():
		result.append_array(PackedStringArray(["--path", project]))
	result.append("--")
	result.append_array(game_args)
	return result


static func outcome(code: int) -> Outcome:
	var result := Outcome.new()
	match code:
		EXIT_NORMAL:
			pass
		EXIT_ARGUMENTS:
			result.kind = Kind.ERROR
			result.message = "O jogo não aceitou os dados da partida. Reinstale o jogo."
		EXIT_AUTH:
			result.kind = Kind.ERROR
			result.message = "O servidor da partida recusou a entrada (convite expirado)."
			result.offer_queue = true
		EXIT_RESULT_NOT_REPORTED:
			result.kind = Kind.WARNING
			result.message = "Partida encerrada. O resultado pode demorar a aparecer."
		_:
			result.kind = Kind.ERROR
			result.message = "O jogo foi encerrado por um erro."
	return result


func _ready() -> void:
	_timer.wait_time = POLL_SECONDS
	_timer.timeout.connect(_on_timer_timeout)
	add_child(_timer)


## Lanca o Game; devolve o pid ou -1 (executavel ausente ou falha do sistema: "instalacao
## incompleta", §6). launcher_args e para teste; por padrao, os argumentos do proprio Launcher.
func launch(game_args: PackedStringArray, launcher_args: PackedStringArray = []) -> int:
	if is_running():
		return NOT_RUNNING
	var args := launcher_args if not launcher_args.is_empty() else OS.get_cmdline_user_args()
	var cmd := command(game_args, args, OS.get_executable_path().get_base_dir())
	if not FileAccess.file_exists(cmd[0]):
		push_warning("[game] executavel ausente: %s" % cmd[0])
		return NOT_RUNNING
	var pid := OS.create_process(cmd[0], cmd.slice(1))
	if pid <= 0:
		return NOT_RUNNING
	_pid = pid
	_timer.start()
	return _pid


func is_running() -> bool:
	return _pid != NOT_RUNNING


## "Encerrar jogo" do overlay: mata o processo e sai como KILLED.
func kill() -> void:
	if not is_running():
		return
	OS.kill(_pid)
	_finish(KILLED)


func _finish(code: int) -> void:
	_timer.stop()
	_pid = NOT_RUNNING
	exited.emit(code)


func _on_timer_timeout() -> void:
	if OS.is_process_running(_pid):
		return
	_finish(OS.get_process_exit_code(_pid))
