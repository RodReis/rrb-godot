class_name App
extends Control
## Raiz do Launcher (ARCHITECTURE-LAUNCHER §3.1): barra superior, pilha de telas, rodape e os
## overlays globais (toast, modal, carregando, partida em andamento). Le o settings.cfg no boot e
## aplica video e audio no proprio Launcher. Dono dos servicos (ApiClient, AuthService,
## QueueService, HistoryService, ProfileService, GameProcess): sem sessao abre no Login; com
## sessao busca a conta e, sem nickname (1o login, F35), abre o Perfil antes do Lobby; o Lobby e a
## raiz; 401 sem renovacao volta ao Login. Fila pareada -> lanca o Game; saida do Game pela
## tabela do §5.2 (codigo 0 de partida online volta ao Lobby com o card "Resultado da partida",
## F70). Telas emitem; quem navega e confirma e o App.
## --gallery (depois do --) abre a galeria do design system, a prova visual dos componentes.
## Splash "Loot Start" (F68, F82): cobre a janela ate a 1a checagem do backend
## (teto SPLASH_MAX_SECONDS).

const GALLERY_ARG: String = "--gallery"
## Toast no canto inferior direito, acima do rodape.
const TOAST_WIDTH: float = 360.0
## Status e ping do backend (GET /health) a cada 10 s.
const HEALTH_SECONDS: float = 10.0
const OFFLINE_ARGS: PackedStringArray = ["--offline", "--bot"]
## Teto do splash se o backend demorar a responder.
const SPLASH_MAX_SECONDS: float = 2.0
## Fim de partida online (F70): o servidor pode ainda estar gravando o resultado, entao o
## GET /matches?mine=1 e repetido ate a partida nova aparecer (3 tentativas, 1 s entre elas).
const RESULT_ATTEMPTS: int = 3
const RESULT_RETRY_SECONDS: float = 1.0

var settings: SettingsStore = SettingsStore.new()
var api: ApiClient = ApiClient.new()
var auth: AuthService = AuthService.new(api)
var history: HistoryService = HistoryService.new(api)
var profile: ProfileService = ProfileService.new(api)
var avatars: AvatarStore = AvatarStore.new()
var catalog: CatalogService = CatalogService.new()
var queue: QueueService = QueueService.new()
var game: GameProcess = GameProcess.new()
## Espera entre as tentativas de achar a partida no historico (teste zera).
var result_retry_seconds: float = RESULT_RETRY_SECONDS
## E-mail da sessao aberta (cartao "Sua conta" do lobby), o do backend; vazio sem sessao.
var account_email: String = ""

var _bar: AppBar = AppBar.new()
var _stack: ScreenStack = ScreenStack.new()
var _footer: ScreenFooter = ScreenFooter.new()
var _toast: Toast = Toast.new()
var _modal: ModalDialog = ModalDialog.new()
var _loading: Control = Control.new()
var _loading_box: StateBox = StateBox.new()
var _match: MatchOverlay = MatchOverlay.new()
var _result: MatchResultCard = MatchResultCard.new()
var _splash: BootSplash = BootSplash.new()
var _health: Timer = Timer.new()
var _online: bool = false
## A primeira checagem do backend ja voltou?
var _checked: bool = false
var _ping_ms: int = AppBar.UNKNOWN_PING
var _ping_filter: PingFilter = PingFilter.new()
## Partida online aberta (para o abandon se o Game nao abrir); vazio = treino ou nada.
var _match_id: String = ""
## O jogador encerrou o Game pelo overlay: sai como 4 (§5.2), mas o aviso nao e de erro.
var _ended_by_player: bool = false
## Partida do card de resultado aberto (para "Tentar de novo" buscar a mesma).
var _result_match_id: String = ""


func _ready() -> void:
	settings.load_values()
	_apply(settings.values)
	settings.saved.connect(_apply)
	catalog.load_all()
	api.base_url = ApiClient.base_url_from(
		OS.get_cmdline_user_args(), ApiClient.embedded_base_url()
	)
	add_child(api)
	queue.api = api
	add_child(queue)
	add_child(game)
	_build()
	_stack.scenes = Router.scenes()
	_stack.screen_pushed.connect(_on_stack_screen_pushed)
	_stack.screen_changed.connect(_on_stack_screen_changed)
	_bar.navigate_requested.connect(_on_bar_navigate_requested)
	_bar.quit_requested.connect(_on_bar_quit_requested)
	_bar.profile_requested.connect(_on_bar_profile_requested)
	api.unauthorized.connect(_on_api_unauthorized)
	# Diferido: a tela mostra "pareado" antes; so entao o App abre o Game (ou mostra o erro).
	queue.matched.connect(_on_queue_matched, CONNECT_DEFERRED)
	game.exited.connect(_on_game_exited)
	_match.end_requested.connect(_on_match_end_requested)
	_result.play_again_requested.connect(_on_result_play_again_requested)
	_result.history_requested.connect(_on_result_history_requested)
	_result.retry_requested.connect(_on_result_retry_requested)
	_health.wait_time = HEALTH_SECONDS
	_health.timeout.connect(check_backend)
	add_child(_health)
	_health.start()
	check_backend()
	var gallery := GALLERY_ARG in OS.get_cmdline_user_args()
	_stack.push(Router.GALLERY if gallery else Router.LOGIN)


func show_toast(text: String, kind: Toast.Kind = Toast.Kind.INFO) -> void:
	_toast.show_message(text, kind)


## Confirmacao modal: devolve o indice do botao (ModalDialog.CANCELLED com Esc).
func confirm(title: String, body: String, actions: Array[DialogAction]) -> int:
	return await _modal.open(title, body, actions)


## Bloqueia a tela com o spinner.
func show_loading(message: String = "") -> void:
	_loading.visible = true
	_stack.locked = true
	_loading_box.set_state(StateBox.State.LOADING, message)


func hide_loading() -> void:
	_loading.visible = false
	_stack.locked = _match.visible
	_loading_box.set_state(StateBox.State.IDLE)


func stack() -> ScreenStack:
	return _stack


func match_overlay() -> MatchOverlay:
	return _match


func result_card() -> MatchResultCard:
	return _result


## GET /health: online e ping em ms na barra, no rodape e no console do lobby (V-01b). O ping vem
## do ApiClient.ping (conexao que fica aberta, sem DNS e TLS de cada chamada: o numero se parece com
## o ping do jogo, #233) e passa pelo PingFilter; backend fora esquece o historico.
func check_backend() -> void:
	var sample: int = await api.ping()
	_online = sample != PingProbe.FAILED
	_checked = true
	if _online:
		_ping_ms = _ping_filter.add(sample)
	else:
		_ping_filter.reset()
		_ping_ms = AppBar.UNKNOWN_PING
	_dismiss_splash()
	_bar.set_backend_status(_online, _ping_ms if _online else 0)
	var lobby := _stack.current() as LobbyScreen
	if lobby != null:
		lobby.set_backend_status(_online, _ping_ms, _checked)
	_refresh_footer()


## Lanca o Game; true se abriu (mostra o overlay e trava a navegacao).
func launch_game(game_args: PackedStringArray, practice: bool) -> bool:
	_ended_by_player = false
	if game.launch(game_args) < 0:
		return false
	_match.open(practice)
	_stack.locked = true
	return true


func _build() -> void:
	var page := VBoxContainer.new()
	page.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	page.add_theme_constant_override(&"separation", 0)
	add_child(page)
	page.add_child(_bar)
	_stack.size_flags_vertical = SIZE_EXPAND_FILL
	page.add_child(_stack)
	page.add_child(_footer)
	_toast.theme_type_variation = &"LnToast"
	_toast.message_variation = &"LnBody"
	_toast.set_anchors_and_offsets_preset(PRESET_BOTTOM_RIGHT)
	_toast.custom_minimum_size.x = TOAST_WIDTH
	_toast.grow_horizontal = GROW_DIRECTION_BEGIN
	_toast.grow_vertical = GROW_DIRECTION_BEGIN
	_toast.position -= Vector2(UiTokens.SPACE_MARGIN, UiTokens.SIZE_FOOTER + UiTokens.SPACE_MARGIN)
	add_child(_toast)
	_loading.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_loading.mouse_filter = MOUSE_FILTER_STOP
	_loading.visible = false
	var dim := ColorRect.new()
	dim.color = ModalDialog.DIM
	dim.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_loading.add_child(dim)
	_loading_box.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_loading.add_child(_loading_box)
	add_child(_loading)
	add_child(_match)
	add_child(_result)
	add_child(_modal)
	add_child(_splash)
	get_tree().create_timer(SPLASH_MAX_SECONDS).timeout.connect(_dismiss_splash)


## O splash se liberta depois do fade; a checagem do backend roda a cada 10 s e o teto tambem chega.
func _dismiss_splash() -> void:
	if is_instance_valid(_splash):
		_splash.dismiss()


func _apply(values: Dictionary) -> void:
	SettingsApplier.apply_video(values, get_window())
	SettingsApplier.apply_audio(values)


func _refresh_footer() -> void:
	var hints: Array[HotkeyHint] = []
	if _stack.depth() > 1:
		hints.append(HotkeyHint.make("ESC", tr("Voltar")))
	var status := tr("SERVIDOR %s") % _bar.backend_status_text().strip_edges()
	_footer.bind(hints, status, AppBar.BRAND)


func _start_practice() -> void:
	if game.is_running():
		return
	if queue.is_searching():
		await queue.leave()  # treino e fila juntos pareariam com o jogo ocupado
	var lobby := _stack.current() as LobbyScreen
	if lobby != null:
		lobby.reset_queue()
	_match_id = ""
	if not launch_game(OFFLINE_ARGS, true):
		show_toast(tr("Instalação incompleta: o jogo não foi encontrado."), Toast.Kind.ERROR)


func _logout() -> void:
	_result.close()
	if queue.is_searching():
		await queue.leave()
	queue.reset()
	history.clear()
	profile.clear()
	_bar.clear_profile()
	auth.logout()
	account_email = ""
	_stack.reset(Router.LOGIN)


func _on_stack_screen_pushed(_route: StringName, screen: Control) -> void:
	var settings_screen := screen as SettingsScreen
	if settings_screen != null:
		settings_screen.bind(settings)
		settings_screen.reset_requested.connect(_on_settings_reset_requested.bind(settings_screen))
		settings_screen.save_failed.connect(show_toast.bind(Toast.Kind.ERROR))
	var login := screen as LoginScreen
	if login != null:
		login.bind(auth)
		login.authenticated.connect(_on_login_authenticated)
		login.practice_requested.connect(_start_practice)
	var profile_screen := screen as ProfileScreen
	if profile_screen != null:
		var mode := (
			ProfileScreen.Mode.SETUP if profile.needs_nickname() else ProfileScreen.Mode.EDIT
		)
		profile_screen.bind(profile, avatars, catalog, mode)
		profile_screen.completed.connect(_on_profile_completed)
		profile_screen.avatar_changed.connect(_on_profile_screen_avatar_changed)
	var history_screen := screen as HistoryScreen
	if history_screen != null:
		history_screen.bind(history)
	var arena_map := screen as ArenaMapScreen
	if arena_map != null:
		arena_map.bind(catalog)
		arena_map.practice_requested.connect(_start_practice)
	var heroes_screen := screen as HeroesScreen
	if heroes_screen != null:
		heroes_screen.bind(catalog)
	var compendium := screen as CompendiumScreen
	if compendium != null:
		compendium.bind(catalog)
		compendium.navigate_requested.connect(_on_compendium_navigate_requested)
	var lobby := screen as LobbyScreen
	if lobby != null:
		lobby.bind(queue, account_email)
		lobby.set_backend_status(_online, _ping_ms, _checked)
		lobby.practice_requested.connect(_start_practice)
		lobby.settings_requested.connect(_stack.push.bind(Router.SETTINGS))
		lobby.logout_requested.connect(_logout)


func _on_stack_screen_changed(route: StringName) -> void:
	_bar.set_current(route)
	# Sem sessao (Login) e antes do 1o nickname nao ha para onde ir alem do que a tela oferece.
	var gated := route == Router.LOGIN or (route == Router.PROFILE and profile.needs_nickname())
	_bar.set_nav_visible(not gated)
	_refresh_footer()


## Login ok: busca a conta (o backend diz se falta o nickname). Conta sem nickname abre o Perfil
## antes do lobby (F35); sem a conta nao ha o que abrir e o Login segue na tela.
func _on_login_authenticated() -> void:
	show_loading(tr("Carregando sua conta…"))
	var loaded := await profile.fetch()
	hide_loading()
	if not auth.is_logged_in():
		return  # 401 sem renovacao: _on_api_unauthorized ja avisou e voltou ao Login
	if not loaded:
		auth.logout()
		show_toast(tr("Não foi possível carregar sua conta. Tente de novo."), Toast.Kind.ERROR)
		return
	account_email = profile.profile.email
	if profile.needs_nickname():
		_stack.reset(Router.PROFILE)
	else:
		_open_lobby()


func _open_lobby() -> void:
	_stack.reset(Router.LOBBY)
	_refresh_profile_chip()


## Nickname definido no 1o login: segue para o lobby.
func _on_profile_completed() -> void:
	_open_lobby()


## Chip do cabecalho: #nickname e avatar local; o V-D vem do historico (sem ele a linha some).
func _refresh_profile_chip() -> void:
	if profile.profile == null or profile.needs_nickname():
		_bar.clear_profile()
		return
	_bar.set_profile(profile.profile.nickname, avatars.texture(profile.profile.id))
	_refresh_record()


func _on_profile_screen_avatar_changed() -> void:
	_refresh_profile_chip()


func _refresh_record() -> void:
	if profile.profile == null or profile.needs_nickname():
		return  # sem sessao nem conta nao ha V-D para mostrar (e nada de buscar sem token)
	var loaded := await history.fetch()
	if profile.profile == null or profile.needs_nickname():
		return  # saiu da conta enquanto a busca voltava
	if loaded:
		_bar.set_profile_record(history.history.totals.wins, history.history.totals.losses)
	else:
		_bar.clear_profile_record()  # nao deixa V-D velho como se fosse atual


func _on_bar_profile_requested() -> void:
	if _stack.current_route() != Router.PROFILE and not _stack.locked:
		_stack.push(Router.PROFILE)


## Menu do topo: LOBBY volta a raiz (desempilha); as demais telas empilham.
func _on_bar_navigate_requested(route: StringName) -> void:
	if route != Router.LOBBY:
		# Mesmo item do menu em outra aba (Forja -> Guia & Bestiario): troca, nao empilha.
		if _stack.current_route() == route:
			return
		if Router.nav_route(_stack.current_route()) == route:
			_stack.replace(route)
		else:
			_stack.push(route)
		return
	while _stack.depth() > 1 and _stack.current_route() != Router.LOBBY:
		_stack.pop()


## Abas do compendio trocam a tela do topo (Esc continua voltando ao que havia antes).
func _on_compendium_navigate_requested(route: StringName) -> void:
	if route == Router.LOBBY:
		_on_bar_navigate_requested(route)
	else:
		_stack.replace(route)


func _on_bar_quit_requested() -> void:
	var actions: Array[DialogAction] = [
		DialogAction.make(tr("CANCELAR")),
		DialogAction.make(tr("SAIR DO JOGO"), DialogAction.Kind.DANGER),
	]
	if await confirm(tr("Sair do jogo?"), tr("O Launcher será fechado."), actions) == 1:
		if queue.is_searching():
			await queue.leave()
		get_tree().quit()


## Sessao expirada sem renovacao (§3.3): volta ao Login com aviso.
func _on_api_unauthorized() -> void:
	_result.close()
	queue.reset()
	history.clear()
	profile.clear()
	_bar.clear_profile()
	show_toast(tr("Sua sessão expirou. Entre de novo."), Toast.Kind.WARN)
	account_email = ""
	_stack.reset(Router.LOGIN)


## Pareado: abre o Game com o servidor e o token; sem executavel, abandona a partida (§6).
func _on_queue_matched(match_id: String, assignment: MatchAssignment) -> void:
	if game.is_running():
		# Nao deveria acontecer (o treino sai da fila); mesmo assim, nao culpar a instalacao.
		await api.request(HTTPClient.METHOD_POST, "/matches/%s/abandon" % match_id)
		_show_lobby_error(tr("Feche o jogo aberto antes de buscar partida."))
		return
	_match_id = match_id
	var args := PackedStringArray(
		[
			"--connect=%s:%d" % [assignment.host, assignment.port],
			"--token=%s" % assignment.token,
		]
	)
	if launch_game(args, false):
		return
	await api.request(HTTPClient.METHOD_POST, "/matches/%s/abandon" % match_id)
	_match_id = ""
	_show_lobby_error(tr("Instalação incompleta: o jogo não foi encontrado."))


func _show_lobby_error(message: String) -> void:
	var lobby := _stack.current() as LobbyScreen
	if lobby != null:
		lobby.show_error(message)


## Fim do Game: tabela do §5.2. Codigo 0 de partida online volta ao Lobby e abre o card "Resultado
## da partida" (F70); o treino contra o bot nao grava partida: lobby sem card. Qualquer outra saida
## de partida online descarta o cache do historico.
func _on_game_exited(code: int) -> void:
	_match.close()
	_stack.locked = false
	var match_id := _match_id
	var online := not match_id.is_empty()
	_match_id = ""
	var outcome := GameProcess.outcome(code)
	var with_card := online and outcome.kind == GameProcess.Kind.NORMAL
	if with_card:
		_go_to_lobby()
	elif online:
		_refresh_history()
	var lobby := _stack.current() as LobbyScreen
	if lobby != null and not queue.is_searching():
		lobby.reset_queue()
	if _ended_by_player:
		_ended_by_player = false
		show_toast(tr("Jogo encerrado."))
		return
	if outcome.kind == GameProcess.Kind.NORMAL:
		if with_card:
			await _show_match_result(match_id)
		return
	if outcome.offer_queue and online and lobby != null:
		var actions: Array[DialogAction] = [
			DialogAction.make(tr("AGORA NÃO")),
			DialogAction.make(tr("ENTRAR NA FILA")),
		]
		var body := tr(outcome.message) + " " + tr("Quer entrar na fila de novo?")
		if await confirm(tr("Partida não iniciada"), body, actions) == 1:
			lobby.toggle_queue()
		return
	var kind := Toast.Kind.WARN if outcome.kind == GameProcess.Kind.WARNING else Toast.Kind.ERROR
	show_toast(tr(outcome.message), kind)


## Partida online acabou (de qualquer jeito): descarta o cache e, se o Historico ja esta aberto,
## recria a tela para ela buscar de novo.
func _refresh_history() -> void:
	history.clear()
	if _stack.current_route() == Router.HISTORY:
		_stack.replace(Router.HISTORY)
	_refresh_record()


func _go_to_lobby() -> void:
	while _stack.depth() > 1 and _stack.current_route() != Router.LOBBY:
		_stack.pop()


## Card do resultado por cima do lobby; o cache do historico e descartado para a partida nova vir
## do backend.
func _show_match_result(match_id: String) -> void:
	_result_match_id = match_id
	history.clear()
	await _load_match_result(match_id)


## Busca a partida no historico (ate RESULT_ATTEMPTS vezes) e mostra o resultado ou o erro. Para se
## o jogador fechou o card ou saiu da conta enquanto esperava.
func _load_match_result(match_id: String) -> void:
	_result.show_loading()
	var summary: MatchSummary = null
	for attempt: int in RESULT_ATTEMPTS:
		if attempt > 0:
			await get_tree().create_timer(result_retry_seconds).timeout
		if not _result.visible or not auth.is_logged_in():
			return
		await history.fetch(true)
		summary = _find_match(match_id)
		if summary != null:
			break
	if not _result.visible or not auth.is_logged_in():
		return
	if summary == null:
		_result.show_error()
		_bar.clear_profile_record()
		return
	_result.show_result(summary, history.history.totals)
	_refresh_record()


func _find_match(match_id: String) -> MatchSummary:
	if not history.is_ready():
		return null
	for summary: MatchSummary in history.history.matches:
		if summary.match_id == match_id:
			return summary
	return null


func _on_result_play_again_requested() -> void:
	_result.close()
	if queue.is_searching():
		return
	var lobby := _stack.current() as LobbyScreen
	if lobby != null:
		lobby.toggle_queue()  # o console do lobby acompanha: ENTRANDO -> PROCURANDO
	else:
		queue.join()


func _on_result_history_requested() -> void:
	_result.close()
	if _stack.current_route() != Router.HISTORY:
		_stack.push(Router.HISTORY)


func _on_result_retry_requested() -> void:
	_load_match_result(_result_match_id)


func _on_match_end_requested() -> void:
	var actions: Array[DialogAction] = [
		DialogAction.make(tr("CONTINUAR JOGANDO")),
		DialogAction.make(tr("ENCERRAR"), DialogAction.Kind.DANGER),
	]
	var body := tr("O jogo será fechado agora.")
	if await confirm(tr("Encerrar o jogo?"), body, actions) == 1:
		_ended_by_player = true
		game.kill()


func _on_settings_reset_requested(screen: SettingsScreen) -> void:
	var actions: Array[DialogAction] = [
		DialogAction.make(tr("CANCELAR")),
		DialogAction.make(tr("RESTAURAR"), DialogAction.Kind.DANGER),
	]
	var body := tr("Vídeo, áudio, controles e gráficos voltam ao padrão e são gravados agora.")
	if await confirm(tr("Restaurar padrões?"), body, actions) == 1:
		screen.restore_defaults()
