extends SceneTree
## Roteiro do fluxo local do F25 (ARCHITECTURE-LAUNCHER §7, "2 launchers + backend + pool"): sobe
## o App de verdade (janela), entra com a conta pela tela de Login, busca partida pelo console do
## Lobby, deixa o App abrir o Game no matched e espera o Launcher voltar ao lobby. Imprime cada
## passo com [drive] e salva uma captura em cada etapa. Precisa de janela (nao headless):
##   godot --path launcher -s <repo>/tools/ui/drive_launcher.gd -- --api=<url> --email=<e>
##     --password=<s> [--register] --game-path=<godot_console.exe> --game-project=<repo>/game
##     --shots=<pasta> [--kill-after=<s>] [--timeout=<s>]
## --kill-after encerra o Game pelo overlay ("Encerrar jogo") depois de N s com ele aberto.

const APP: String = "res://scenes/app.tscn"
const DEFAULT_TIMEOUT: float = 900.0
const STEP: float = 0.5
## Quadros esperando o lobby depois do login (conta buscada no backend).
const LOBBY_WAIT_FRAMES: int = 600
## Espera do card de resultado depois que o Game fecha (3 tentativas a 1 s mais a rede).
const RESULT_TIMEOUT: float = 15.0

var _app: App
var _args: Dictionary = {}
var _shot: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_args = _parse()
	_app = (load(APP) as PackedScene).instantiate() as App
	root.add_child(_app)
	_app.game.exited.connect(func(code: int) -> void: _log("Game saiu com %d" % code))
	await _frames(30)
	var login := _app.stack().current() as LoginScreen
	if _args.has("register"):
		login.select_mode(LoginScreen.Mode.REGISTER)
	login.email_field().text = _args.get("email", "")
	login.password_field().text = _args.get("password", "")
	await login.submit()
	# Depois do login o App ainda busca a conta (F35) antes de abrir o lobby.
	for i: int in LOBBY_WAIT_FRAMES:
		if _app.stack().current() is LobbyScreen:
			break
		await process_frame
	var lobby := _app.stack().current() as LobbyScreen
	if lobby == null:
		_finish(1, "nao entrou no lobby: %s" % login.error_text())
		return
	_log("lobby como %s" % _app.account_email)
	await _frames(30)
	await _save("lobby")
	lobby.toggle_queue()
	var deadline := Time.get_ticks_msec() / 1000.0 + float(_args.get("timeout", DEFAULT_TIMEOUT))
	var seen := LobbyScreen.QueueState.IDLE
	var game_seen := false
	var opened_at := 0.0
	while Time.get_ticks_msec() / 1000.0 < deadline:
		var state := lobby.queue_state()
		if state != seen:
			seen = state
			_log("fila: %s %s" % [LobbyScreen.QueueState.keys()[state], lobby.banner_text()])
			if state == LobbyScreen.QueueState.SEARCHING:
				await _frames(10)
				await _save("procurando")
		if _app.game.is_running() and not game_seen:
			game_seen = true
			opened_at = Time.get_ticks_msec() / 1000.0
			_log("Game aberto pelo Launcher; overlay: %s" % _app.match_overlay().visible)
			await _save("partida")
		var kill_after := float(_args.get("kill-after", "0"))
		var open_for := Time.get_ticks_msec() / 1000.0 - opened_at
		if game_seen and _app.game.is_running() and kill_after > 0.0 and open_for > kill_after:
			_log("encerrando o Game pelo overlay")
			_app.match_overlay().end_requested.emit()
			await _frames(5)
			var modal := _app.find_children("*", "ModalDialog", true, false)[0] as ModalDialog
			modal.buttons()[1].pressed.emit()
		if game_seen and not _app.game.is_running() and not _app.match_overlay().visible:
			if not _args.has("kill-after") and not await _wait_result_card():
				return
			await _frames(30)
			_log(
				(
					"de volta ao lobby: %s, fila %s"
					% [
						_app.stack().current_route(),
						LobbyScreen.QueueState.keys()[lobby.queue_state()]
					]
				)
			)
			await _save("volta")
			_finish(0, "ok")
			return
		if state == LobbyScreen.QueueState.ERROR:
			_finish(1, "erro na fila: %s" % lobby.banner_text())
			return
		await create_timer(STEP).timeout
	_finish(1, "tempo esgotado")


## Partida online que acabou normal (F70): o Launcher volta ao lobby com o card "Resultado da
## partida"; espera ele sair do carregando e confere que mostra um resultado. false = ja encerrou.
func _wait_result_card() -> bool:
	var card := _app.result_card()
	var deadline := Time.get_ticks_msec() / 1000.0 + RESULT_TIMEOUT
	while card.state() in [StateBox.State.IDLE, StateBox.State.LOADING]:
		if Time.get_ticks_msec() / 1000.0 > deadline:
			_finish(1, "o card de resultado nao saiu do carregando")
			return false
		await create_timer(STEP).timeout
	_log("card: %s %s" % [StateBox.State.keys()[card.state()], card.result()])
	await _frames(30)
	await _save("resultado")
	if card.state() != StateBox.State.READY:
		_finish(1, "o card nao achou a partida no historico")
		return false
	if _app.stack().current_route() != Router.LOBBY:
		_finish(1, "o card nao abriu sobre o lobby: %s" % _app.stack().current_route())
		return false
	return true


func _parse() -> Dictionary:
	var parsed := {}
	for arg: String in OS.get_cmdline_user_args():
		var pair := arg.trim_prefix("--").split("=", true, 1)
		parsed[pair[0]] = pair[1] if pair.size() > 1 else ""
	return parsed


func _frames(count: int) -> void:
	for i: int in count:
		await process_frame


func _save(label: String) -> void:
	if not _args.has("shots"):
		return
	await RenderingServer.frame_post_draw
	_shot += 1
	var path := "%s/%02d-%s.png" % [_args["shots"], _shot, label]
	root.get_texture().get_image().save_png(path)


func _log(text: String) -> void:
	print("[drive] %s %s" % [_args.get("email", ""), text])


func _finish(code: int, text: String) -> void:
	_log("fim (%d): %s" % [code, text])
	quit(code)
