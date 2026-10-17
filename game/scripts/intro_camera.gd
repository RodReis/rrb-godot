class_name IntroCamera
extends Node
## Cinematica de abertura no cliente (F69, SPEC-069 §2): na INTRO, voo fixo pela arena (da base
## do adversario ate a do proprio jogador, passando pelo centro) -> close de frente no proprio
## heroi -> blend de 0,5 s para a CameraRig. Acaba (ready ao servidor) quando o blend termina; o
## servidor decide a saida da INTRO (5 s no minimo, corte aos 8 s). So a camera e a HUD mudam:
## o heroi nao recebe input (PlayerInput.cinematic). A matematica e do IntroRules.

## Espera pelo heroi local (spawn pelo MultiplayerSpawner chega depois do RPC de fase).
const HERO_WAIT_SECONDS: float = 1.0
## O servidor mora no peer 1 (host e dedicado).
const SERVER_PEER: int = 1

## Dev (--intro-ready-delay): atraso artificial do ready, para provar o corte aos 8 s.
var ready_delay: float = 0.0

var _camera: FollowCamera
var _match: MatchController
var _players: Node
var _overlay: IntroOverlay
var _running: bool = false
var _playing: bool = false
var _server_moved_on: bool = false
var _ready_sent: bool = false
var _seconds: float = 0.0
var _waited: float = 0.0
var _start: Vector3 = Vector3.ZERO
var _end: Vector3 = Vector3.ZERO
var _hero_position: Vector3 = Vector3.ZERO
var _hero_yaw: float = 0.0


## So quem desenha tem camera para conduzir (nunca o servidor headless).
static func wanted() -> bool:
	return DisplayServer.get_name() != "headless"


func _ready() -> void:
	set_process(false)


func _process(delta: float) -> void:
	advance(delta)


func _exit_tree() -> void:
	PlayerInput.cinematic = false


func bind(camera: FollowCamera, match_controller: MatchController, players: Node) -> void:
	_camera = camera
	_match = match_controller
	_players = players
	_overlay = IntroOverlay.new()
	add_child(_overlay)
	_match.phase_changed.connect(_on_match_phase_changed)
	if _match.state == MatchState.State.INTRO:
		_begin()


func is_running() -> bool:
	return _running


## Segundos de cinematica ja tocados (0 enquanto espera o heroi).
func seconds() -> float:
	return _seconds


## Avanca a cinematica em [param delta] segundos (o _process chama; os testes tambem).
func advance(delta: float) -> void:
	if not _running:
		return
	if not _playing and not _try_start(delta):
		return
	_seconds += delta
	_apply_pose()
	if _seconds >= IntroRules.READY_AT + ready_delay:
		_send_ready()
	if _server_moved_on and _seconds >= IntroRules.READY_AT:
		_stop()


func _begin() -> void:
	_running = true
	_playing = false
	_server_moved_on = false
	_ready_sent = false
	_seconds = 0.0
	_waited = 0.0
	PlayerInput.cinematic = true
	set_process(true)


## Comeca a tocar quando o heroi local existe (ou depois de esperar o suficiente).
func _try_start(delta: float) -> bool:
	var hero := _own_hero()
	if hero == null and _waited < HERO_WAIT_SECONDS:
		_waited += delta
		return false
	var own_team := hero.team if hero != null else GateRules.TEAM_B
	var enemy_team := GateRules.TEAM_A if own_team == GateRules.TEAM_B else GateRules.TEAM_B
	_end = _base_of(own_team)
	_start = _base_of(enemy_team)
	_hero_position = hero.global_position if hero != null else _end
	_hero_yaw = (
		hero.global_rotation.y if hero != null else CameraRig.yaw_towards(_end, _camera.focus)
	)
	if hero != null and hero.hero_data != null:
		_overlay.show_hero(hero.hero_data)
	_camera.intro_active = true
	_playing = true
	return true


func _apply_pose() -> void:
	_camera.intro_pose = IntroRules.pose_at(
		_seconds, _start, _camera.focus, _end, _hero_position, _hero_yaw
	)
	_camera.intro_rig_weight = IntroRules.blend_weight(_seconds)
	_overlay.set_alpha(IntroRules.overlay_alpha(_seconds))


func _send_ready() -> void:
	if _ready_sent:
		return
	_ready_sent = true
	_match.report_intro_ready.rpc_id(SERVER_PEER)


## O servidor saiu da INTRO. Se a cinematica ainda nao chegou ao blend (corte aos 8 s), pula para
## ele: a camera volta ao jogo suave, sem esconder o inicio da partida.
func _on_match_phase_changed(_from: int, to: int, _tick: int) -> void:
	if to == MatchState.State.INTRO:
		_begin()
	elif _running:
		_server_moved_on = true
		_seconds = maxf(_seconds, IntroRules.FLIGHT_SECONDS + IntroRules.CLOSE_SECONDS)


func _stop() -> void:
	_running = false
	_playing = false
	_camera.intro_active = false
	_overlay.dismiss()
	PlayerInput.cinematic = false
	set_process(false)


func _own_hero() -> Hero:
	return _players.get_node_or_null(str(multiplayer.get_unique_id())) as Hero


## Marcador do heroi do [param team]; sem ele, a origem (a arena segue sem a cinematica certa).
func _base_of(team: int) -> Vector3:
	for node: Node in get_tree().get_nodes_in_group(SpawnMarker.GROUP):
		var marker := node as SpawnMarker
		if marker.kind == SpawnMarker.Kind.HERO and marker.team == team:
			return marker.global_position
	push_warning("[intro] sem marcador HERO do time %d" % team)
	return Vector3.ZERO
