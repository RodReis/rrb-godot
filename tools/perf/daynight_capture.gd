extends SceneTree
## Captura do ciclo dia/noite (F49, SPEC-049 §6 item 4): sobe a partida de main.tscn com os
## argumentos de usuario, espera os dois herois nascerem e mostra a luz em progressos escolhidos
## (aplica o DayNight em ticks falsos do relogio: nada espera 10 min). Ferramenta de autoria
## (verificacao visual e captura do roadmap), fora do jogo. Uso, na raiz, janela aberta:
##   godot --path game --resolution 1280x720 -s <repo>/tools/perf/daynight_capture.gd --
##     --offline --bot --autopilot=bot --daynight=day --out=<pasta>/dia --progress=0,0.5,1
##   (fotos <out>_p0.png, <out>_p0.5.png, ...; sai no fim; --sky olha para o sol, para ver o ceu)
##   godot --path game --resolution 1280x720 --write-movie <saida>.avi --fixed-fps 30
##     -s <repo>/tools/perf/daynight_capture.gd -- --offline --bot --autopilot=bot --timelapse=10
##   (video: a partida inteira, 0 a 10:00, em 10 s de video)
## Como o frametime_probe: script de SceneTree compila antes dos autoloads, entao o jogo e lido
## sem tipo de classe.

const MAIN: String = "res://scenes/main.tscn"
const HEROES: int = 2
const SPAWN_TIMEOUT: float = 60.0
## Depois do spawn: compila o que faltar e deixa a camera chegar no heroi.
const WARMUP_SECONDS: float = 5.0
## Quadros esperados depois de aplicar a luz antes de salvar (o ceu e as sombras assentam).
const SETTLE_FRAMES: int = 6
const MATCH_SECONDS: float = 600.0
## --sky: camera no centro da ilha olhando na direcao do sol (a luz do Sun vem de la).
const SKY_CAMERA_AT: Vector3 = Vector3(0.0, 8.0, 0.0)

var _out: String = "daynight"
var _progress: PackedFloat64Array = [0.0, 0.5, 1.0]
var _timelapse: float = 0.0
var _sky_camera: Camera3D
var _main: Node
var _players: Node
var _elapsed: float = 0.0
var _phase: int = 0
var _shot: int = 0
var _settle: int = 0
var _start_tick: int = 0


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
		elif arg.begins_with("--progress="):
			_progress = PackedFloat64Array()
			for text: String in arg.trim_prefix("--progress=").split(","):
				_progress.append(text.to_float())
		elif arg == "--sky":
			_sky_camera = Camera3D.new()
		elif arg.begins_with("--timelapse="):
			_timelapse = arg.trim_prefix("--timelapse=").to_float()
	_main = (load(MAIN) as PackedScene).instantiate()
	root.add_child(_main)
	current_scene = _main
	_players = _main.get_node("Players")


func _process(delta: float) -> bool:
	_elapsed += delta
	match _phase:
		0:
			var clock := _main.get_node("MatchClock")
			if _players.get_child_count() >= HEROES and clock.call("is_started"):
				print("[daynight] herois nasceram em %.1f s" % _elapsed)
				_start()
			elif _elapsed > SPAWN_TIMEOUT:
				push_error("[daynight] herois nao nasceram em %.0f s" % SPAWN_TIMEOUT)
				quit(1)
		1:
			if _elapsed >= WARMUP_SECONDS:
				_phase = 2
				_elapsed = 0.0
		2:
			if _timelapse > 0.0:
				return _step_timelapse()
			return _step_stills()
	return false


func _start() -> void:
	_start_tick = _main.get_node("MatchClock").get("start_tick")
	_main.get_node("DayNight").set_process(false)  # a captura manda no relogio
	if _sky_camera != null:
		root.add_child(_sky_camera)
		_sky_camera.current = true
	_phase = 1
	_elapsed = 0.0


## Aplica a luz no progresso [param p] (0 a 1) do sentido sorteado, como se o relogio estivesse la.
func _show(p: float) -> void:
	var tickrate: int = root.get_node("NetworkTime").get("tickrate")
	_main.get_node("DayNight").call("apply", _start_tick + int(p * MATCH_SECONDS * tickrate))
	if _sky_camera != null:
		var sun_direction: Vector3 = _main.get_node("Arena/Sun").basis.z
		_sky_camera.look_at_from_position(SKY_CAMERA_AT, SKY_CAMERA_AT + sun_direction)


func _step_stills() -> bool:
	if _settle == 0:
		if _shot >= _progress.size():
			quit(0)
			return true
		_show(_progress[_shot])
	_settle += 1
	if _settle < SETTLE_FRAMES:
		return false
	_settle = 0
	var path := "%s_p%s.png" % [_out, str(_progress[_shot])]
	var error := root.get_viewport().get_texture().get_image().save_png(path)
	print("[daynight] %s (%s)" % [path, error_string(error)])
	_shot += 1
	return false


func _step_timelapse() -> bool:
	var p := minf(_elapsed / _timelapse, 1.0)
	_show(p)
	if p >= 1.0:
		quit(0)
		return true
	return false
