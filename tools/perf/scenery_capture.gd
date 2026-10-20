extends SceneTree
## Captura do cenario em 8 poses fixas (F73, SPEC-073 aceite: "antes/depois, 8 angulos fixos, dia e
## noite"): sobe a partida de main.tscn com os argumentos de usuario, espera os herois nascerem,
## esconde o HUD e fotografa o cenario de cameras proprias, cada uma posta ao lado de um node
## nomeado da arena (a pose acompanha o node, nao uma coordenada solta). Ferramenta de autoria,
## fora do jogo. Uso (na raiz do repo, janela aberta, nao headless):
##   godot --path game --resolution 1920x1080 -s <repo>/tools/perf/scenery_capture.gd --
##     --offline --bot --autopilot=bot --seed=38 --daynight=day --out=<pasta>/dia
##   (fotos <out>_<pose>.png; --daynight=night para a noite)
## Como o frametime_probe: script de SceneTree compila antes dos autoloads, entao o jogo e lido
## sem tipo de classe.

const MAIN: String = "res://scenes/main.tscn"
const HEROES: int = 2
const SPAWN_TIMEOUT: float = 60.0
const WARMUP_SECONDS: float = 5.0
## Quadros esperados depois de mover a camera (sombras, SSAO e neblina assentam).
const SETTLE_FRAMES: int = 12
const FOV: float = 55.0
## Camera a esta distancia (u) do alvo, de cima, olhando para um ponto um pouco acima dele.
const STANDOFF: Vector3 = Vector3(6.0, 4.5, 8.0)
const LOOK_AT_HEIGHT: float = 1.0
## Ponto (x, z) fixo: a camera da grama mira o tufo mais proximo dele, igual antes e depois do F73
## (o indice de um tufo muda quando a densidade muda).
const GRASS_AT: Vector2 = Vector2(8.0, -12.0)
const GRASS_STANDOFF: Vector3 = Vector3(3.0, 1.6, 4.0)
const VALLEY_AT: Vector3 = Vector3(0.0, 9.0, 44.0)
const VALLEY_LOOK: Vector3 = Vector3(0.0, 4.0, 75.0)
## Pose: [nome do arquivo, prefixo do node da arena, deslocamento da camera]; prefixo vazio =
## pose especial (grama e vale).
const POSES: Array[Array] = [
	["castelo", "GateA", Vector3(6.0, 4.5, 8.0)],
	["ponte", "Bridge1", Vector3(7.0, 5.0, 9.0)],
	["cavalo_de_frisa", "Barricade", Vector3(0.5, 5.5, 2.5)],
	["balista", "Ballista", Vector3(0.5, 6.0, 3.0)],
	["bau", "Chest", Vector3(2.5, 2.0, 3.0)],
	["rocha", "Center0", Vector3(5.0, 3.5, 6.5)],
	["grama", "", GRASS_STANDOFF],
	["vale", "", VALLEY_AT],
]
## --poses=f84: closes da base A (SO) para o spike visual (SPEC-084 aceite 4), com a camera vinda
## de dentro da base; servem a oficial e a variante (--arena=spike_f84), mesmo enquadramento.
const POSES_F84: Array[Array] = [
	["portao", "GateA", Vector3(-6.0, 4.0, 6.0)],
	["fonte", "FountainA", Vector3(3.5, 3.0, 5.0)],
	["casa", "HouseA0", Vector3(5.5, 4.0, 2.0)],
	["patio", "VillageA0", Vector3(7.0, 5.0, -4.0)],
	["torreao", "KeepA", Vector3(14.0, 9.0, -14.0)],
]

var _out: String = "scenery"
var _poses: Array[Array] = POSES
var _main: Node
var _players: Node
var _camera: Camera3D
var _elapsed: float = 0.0
var _phase: int = 0
var _shot: int = 0
var _settle: int = 0


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
		elif arg == "--poses=f84":
			_poses = POSES_F84
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
				_start()
			elif _elapsed > SPAWN_TIMEOUT:
				push_error("[scenery] herois nao nasceram em %.0f s" % SPAWN_TIMEOUT)
				quit(1)
		1:
			if _elapsed >= WARMUP_SECONDS:
				_phase = 2
		2:
			return _step()
	return false


func _start() -> void:
	var start_tick: int = _main.get_node("MatchClock").get("start_tick")
	_main.get_node("DayNight").set_process(false)  # a captura manda no relogio
	_main.get_node("DayNight").call("apply", start_tick)
	for node: Node in _main.find_children("*", "CanvasLayer", true, false):
		(node as CanvasLayer).visible = false
	_camera = Camera3D.new()
	_camera.fov = FOV
	_camera.far = 400.0
	root.add_child(_camera)
	_camera.current = true
	_phase = 1
	_elapsed = 0.0


func _step() -> bool:
	if _shot >= _poses.size():
		quit(0)
		return true
	if _settle == 0:
		_place(_poses[_shot])
	_settle += 1
	if _settle < SETTLE_FRAMES:
		return false
	_settle = 0
	var path := "%s_%s.png" % [_out, _poses[_shot][0]]
	var error := root.get_viewport().get_texture().get_image().save_png(path)
	print("[scenery] %s (%s)" % [path, error_string(error)])
	_shot += 1
	return false


func _place(pose: Array) -> void:
	var target := Vector3.ZERO
	var offset: Vector3 = pose[2]
	var prefix: String = pose[1]
	if prefix != "":
		var found := _find(prefix)
		if found == null:
			push_error("[scenery] sem node '%s*' na arena" % prefix)
			return
		target = found.global_position
	elif pose[0] == "grama":
		var tufts: PackedVector4Array = _main.get_node("Arena/Vegetation").get("tufts")
		var best := tufts[0]
		for tuft: Vector4 in tufts:
			if _grass_distance(tuft) < _grass_distance(best):
				best = tuft
		target = Vector3(best.x, 0.0, best.y)
	else:
		_camera.look_at_from_position(offset, VALLEY_LOOK)
		return
	_camera.look_at_from_position(target + offset, target + Vector3.UP * LOOK_AT_HEIGHT)


## Distancia ao quadrado do tufo ate GRASS_AT (plano xz).
func _grass_distance(tuft: Vector4) -> float:
	return Vector2(tuft.x, tuft.y).distance_squared_to(GRASS_AT)


## Primeiro node 3D da arena cujo nome comeca com [param prefix] (ordem da arvore).
func _find(prefix: String) -> Node3D:
	var arena := _main.get_node("Arena")
	for node: Node in arena.find_children(prefix + "*", "Node3D", true, false):
		return node as Node3D
	return null
