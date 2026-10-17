extends SceneTree
## Captura do Launcher para a prova por tela (FRONTEND-LAUNCHER §6, itens 1 e 6): sobe o App,
## espera a tela assentar e salva um PNG do tamanho pedido. Precisa de janela (nao headless).
##   godot --path launcher -s <repo>/tools/ui/capture_launcher.gd -- --out=<png> [--size=1920x1080]
##     [--tab=<0..3>] [--gallery] [--modal] [--fps] [--route=<rota>] [--state=<estado>] [--overlay]
## --tab escolhe a aba de Configuracoes; --gallery abre a galeria; --modal abre o "Restaurar
## padroes?" por cima; --fps desliga o vsync e imprime o FPS medio de FPS_SECONDS (§4).
## F25: --route abre a rota como raiz (lobby com a conta --email=); --state poe a tela num estado:
## Login register | loading | error (envia sem backend) | field_error; Lobby joining | searching |
## matched | error. --overlay abre o "Partida em andamento".
## F26: --history=ready|many|empty|error|offline|loading troca o servico do Historico por um
## ApiClient falso com dados de exemplo (so da captura; o produto mostra so dado do backend) e
## abre a rota history; --filter=wins|losses escolhe o filtro. Com --login=<email>:<senha> (e
## --api=<url>) entra na conta no backend de verdade antes de abrir a rota: captura com dado real.
## F27: --route=bestiary|forge; --tier=t1|t2|t3|boss e --query=<texto> (Bestiario); --section=
## weapons|<id do conjunto> e --query (Forja); --build=<heroi>:<nivel>:<item>,<item> poe o build no
## simulador; --scroll=<px> rola o corpo (999999 = ate o fim); --catalog=broken mostra o erro.
## F71: --route=heroes; --hero=<id> escolhe o heroi do painel; --role=<classe> filtra por classe;
## --query=<texto> busca; --scroll=<px> rola o corpo (999999 = ate o fim); --catalog=broken erro.
## F33: --route=arena_map; --poi=<id> escolhe o ponto de interesse (base_a, crater, tall_grass...).
## F35: --route=profile --state=setup|invalid|taken|offline|saving|avatar|upload_error|edit poe o
## Perfil num estado (ApiClient falso, avatares em user://capture_avatars/); --route=lobby com
## --nick=<nome> [--avatar=hero:knight] [--record=14:6] mostra o chip do cabecalho.
## F70: --result=win|loss|interrupted|loading|error abre o lobby com o card "Resultado da partida"
## naquele estado (dados de exemplo do Historico; so da captura).

const APP: String = "res://scenes/app.tscn"
const DEFAULT_SIZE: Vector2i = Vector2i(1920, 1080)
## Frames ate fontes, fade de entrada e layout assentarem.
const SETTLE_FRAMES: int = 45
const FPS_SECONDS: float = 3.0

## Dados de exemplo do Historico (so desta captura): destaque, derrota, vitoria e interrompida.
const HISTORY_CALL: String = "GET /matches?mine=1"
const HISTORY_SAMPLE: Dictionary = {
	"totals": {"wins": 4, "losses": 2},
	"matches":
	[
		{
			"matchId": "0b7e9f00-1111-4222-8333-000000000001",
			"result": "win",
			"playedAt": "2026-10-15T15:10:00.000Z",
			"endReason": "kill_goal",
			"durationS": 522,
			"me":
			{
				"heroId": "ranger",
				"kills": 5,
				"finalLevel": 10,
				"deaths": 3,
				"bossKill": true,
				"setActive": "hunter"
			},
			"opponent": {"heroId": "knight", "nickname": "RodReis", "kills": 3, "finalLevel": 9},
		},
		{
			"matchId": "0b7e9f00-1111-4222-8333-000000000002",
			"result": "loss",
			"playedAt": "2026-10-15T13:02:00.000Z",
			"endReason": "collapse_hp",
			"durationS": 555,
			"me":
			{
				"heroId": "knight",
				"kills": 3,
				"finalLevel": 9,
				"deaths": 5,
				"bossKill": false,
				"setActive": null
			},
			"opponent":
			{"heroId": "ranger", "nickname": "Arqueira_01", "kills": 5, "finalLevel": 10},
		},
		{
			"matchId": "0b7e9f00-1111-4222-8333-000000000003",
			"result": "win",
			"playedAt": "2026-10-15T10:40:00.000Z",
			"endReason": "kill_goal",
			"durationS": 410,
			"me":
			{
				"heroId": "fire_wizard",
				"kills": 5,
				"finalLevel": 10,
				"deaths": 1,
				"bossKill": false,
				"setActive": null
			},
			"opponent": {"heroId": "barbarian", "nickname": null, "kills": 1, "finalLevel": 7},
		},
		{
			"matchId": "0b7e9f00-1111-4222-8333-000000000004",
			"result": "interrupted",
			"playedAt": "2026-10-14T21:15:00.000Z",
			"endReason": "heartbeat_lost",
			"durationS": null,
			"me":
			{
				"heroId": null,
				"kills": 0,
				"finalLevel": 0,
				"deaths": 0,
				"bossKill": false,
				"setActive": null
			},
			"opponent": {"heroId": null, "nickname": null, "kills": 0, "finalLevel": 0},
		},
		{
			"matchId": "0b7e9f00-1111-4222-8333-000000000005",
			"result": "win",
			"playedAt": "2026-10-14T20:01:00.000Z",
			"endReason": "collapse_kills",
			"durationS": 598,
			"me":
			{
				"heroId": "rogue",
				"kills": 4,
				"finalLevel": 9,
				"deaths": 4,
				"bossKill": true,
				"setActive": null
			},
			"opponent": {"heroId": "engineer", "nickname": null, "kills": 3, "finalLevel": 9},
		},
	],
}
## Conta de exemplo do Perfil (so desta captura).
const PROFILE_USER: String = "9c2d1a77-aaaa-4bbb-8ccc-ddddeeeeffff"
const CAPTURE_AVATARS: String = "user://capture_avatars/"

var _profile_api: FakeApiClient


func _initialize() -> void:
	_capture.call_deferred()


func _capture() -> void:
	var args := _args()
	var app := (load(APP) as PackedScene).instantiate()
	root.add_child(app)
	await process_frame
	root.size = _size(args.get("size", ""))
	# O splash (F68) cobre a janela ate o 1o health ou 2 s: some antes de a tela ser composta.
	(app as App).call("_dismiss_splash")
	await create_timer(BootSplash.FADE_SECONDS + 0.3).timeout
	if args.has("login"):
		var credentials: PackedStringArray = args["login"].split(":", true, 1)
		var result := await (app as App).auth.login(credentials[0], credentials[1])
		print("[capture] login %s: %s" % [credentials[0], result.ok])
		args["email"] = credentials[0]
	if args.has("history"):
		_fake_history(app as App, args["history"])
		args["route"] = "history"
	if args.has("nick") or args.get("route", "") == "profile":
		_fake_profile(app as App, args)
	if args.get("catalog", "") == "broken":
		(app as App).catalog = BrokenCatalog.new()
	if args.has("route"):
		(app as App).account_email = args.get("email", "duelista@exemplo.com")
		(app as App).stack().reset(StringName(args["route"]))
	if args.get("route", "") == "lobby" and args.has("nick"):
		(app as App).call("_refresh_profile_chip")
	await _set_state(app as App, args.get("state", ""))
	_result_card(app as App, args.get("result", ""))
	await _profile_state(app as App, args.get("state", ""))
	if args.has("overlay"):
		(app as App).match_overlay().open(false)
	if args.has("filter"):
		var history_screen := app.find_children("*", "HistoryScreen", true, false)
		if not history_screen.is_empty():
			var filters: Dictionary = {
				"wins": HistoryScreen.Filter.WINS, "losses": HistoryScreen.Filter.LOSSES
			}
			(history_screen[0] as HistoryScreen).select_filter(filters[args["filter"]])
	await _compendium(app as App, args)
	_arena_map(app as App, args)
	await _heroes(app as App, args)
	if args.has("tab"):
		var screen := app.find_children("*", "SettingsScreen", true, false)
		if not screen.is_empty():
			(screen[0] as SettingsScreen).select_tab(int(args["tab"]))
	if args.has("modal"):
		var settings := app.find_children("*", "SettingsScreen", true, false)
		if not settings.is_empty():
			(settings[0] as SettingsScreen).reset_requested.emit()
	for i: int in SETTLE_FRAMES:
		await process_frame
	if args.has("fps"):
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		Engine.max_fps = 0
		var frames := Engine.get_process_frames()
		await create_timer(FPS_SECONDS).timeout
		var fps := (Engine.get_process_frames() - frames) / FPS_SECONDS
		print("[capture] fps medio em %.0f s: %.0f" % [FPS_SECONDS, fps])
	var image := root.get_texture().get_image()
	var out: String = args.get("out", "user://capture.png")
	var err := image.save_png(out)
	print("[capture] %s %s (%s)" % [out, image.get_size(), error_string(err)])
	quit(err)


## F70: card de resultado por cima do lobby. win/loss/interrupted usam as partidas de exemplo do
## Historico (vitoria, derrota, interrompida); loading e error sao os outros dois estados.
func _result_card(app: App, state: String) -> void:
	if state.is_empty():
		return
	var card := app.result_card()
	if state == "loading":
		card.show_loading()
		return
	if state == "error":
		card.show_error()
		return
	var sample: Array = HISTORY_SAMPLE["matches"]
	var index: int = {"win": 0, "loss": 1, "interrupted": 3}[state]
	var summary := MatchSummary.from_dict(sample[index])
	card.show_result(summary, MatchTotals.from_dict(HISTORY_SAMPLE["totals"]))


## F35: conta de exemplo no ProfileService (ApiClient falso: nada vai ao backend) e avatares em
## user://capture_avatars/ (nao mexe nos do jogador). Rota profile: sem --nick = 1o login (SETUP).
func _fake_profile(app: App, args: Dictionary) -> void:
	var api := FakeApiClient.new()
	app.add_child(api)
	api.reply(HISTORY_CALL, 200, _record_history(args.get("record", "")))
	app.profile = ProfileService.new(api)
	app.history = HistoryService.new(api)
	app.avatars = AvatarStore.new(CAPTURE_AVATARS)
	if DirAccess.dir_exists_absolute(CAPTURE_AVATARS):  # cada captura parte do zero
		for file: String in DirAccess.get_files_at(CAPTURE_AVATARS):
			DirAccess.remove_absolute(CAPTURE_AVATARS + file)
	var nickname: Variant = args.get("nick", null)
	if args.get("state", "") == "edit" and nickname == null:
		nickname = "RodReis"
	app.profile.profile = (
		UserProfile
		. from_dict(
			{
				"id": PROFILE_USER,
				"email": "duelista@exemplo.com",
				"nickname": nickname,
				"createdAt": "2026-10-15T12:00:00.000Z",
			}
		)
	)
	if args.has("avatar"):
		app.avatars.use_preset(PROFILE_USER, args["avatar"])
	_profile_api = api


## "14:6" -> historico so com os totais (V-D do chip); vazio = sem historico (a linha some).
func _record_history(record: String) -> Dictionary:
	var parts := record.split(":")
	if parts.size() != 2:
		return {"totals": {"wins": 0, "losses": 0}, "matches": []}
	return {"totals": {"wins": int(parts[0]), "losses": int(parts[1])}, "matches": []}


## F35: estados do Perfil (so desta captura).
func _profile_state(app: App, state: String) -> void:
	var found := app.find_children("*", "ProfileScreen", true, false)
	if found.is_empty():
		return
	var screen := found[0] as ProfileScreen
	match state:
		"invalid":
			screen.nickname_field().text = "ab"
			await screen.submit()
		"taken":
			screen.nickname_field().text = "RodReis"
			_profile_api.reply("PUT /users/me/nickname", 409, {"code": "NICKNAME_TAKEN"})
			await screen.submit()
		"offline":
			screen.nickname_field().text = "RodReis"
			await screen.submit()
		"saving":
			screen.nickname_field().text = "RodReis"
			screen.call("_set_busy", true)
		"avatar":
			screen.nickname_field().text = "RodReis"
			screen.select_preset("hero:ranger")
		"upload_error":
			screen.load_avatar_file("res://project.godot")


## Troca o servico do Historico por um ApiClient falso (nao fala com o backend).
func _fake_history(app: App, mode: String) -> void:
	var api := FakeApiClient.new() if mode != "loading" else HangingApi.new()
	app.add_child(api)
	match mode:
		"ready":
			api.reply(HISTORY_CALL, 200, HISTORY_SAMPLE)
		"many":
			api.reply(HISTORY_CALL, 200, _many(50))
		"empty":
			api.reply(HISTORY_CALL, 200, {"totals": {"wins": 0, "losses": 0}, "matches": []})
		"error":
			api.reply(HISTORY_CALL, 500, {"statusCode": 500, "code": "INTERNAL_ERROR"})
	app.history = HistoryService.new(api)


## `count` partidas repetindo o exemplo (prova de desempenho do feed cheio, FRONTEND §4).
func _many(count: int) -> Dictionary:
	var matches: Array = []
	var sample: Array = HISTORY_SAMPLE["matches"]
	for i: int in count:
		matches.append(sample[i % sample.size()])
	return {"totals": {"wins": count / 2, "losses": count / 4}, "matches": matches}


## Catalogo que nao carrega: o estado de erro do Compendio (so desta captura).
class BrokenCatalog:
	extends CatalogService

	func load_all() -> void:
		pass

	func is_loaded() -> bool:
		return false


## ApiClient que nunca responde: segura a tela em "carregando".
class HangingApi:
	extends FakeApiClient

	signal never

	func _send(
		_method: HTTPClient.Method, _path: String, _body: Variant, _authed: bool
	) -> ApiClient.Response:
		await never
		return null


## F33: escolhe o ponto de interesse da tela Arena & Mapa (so desta captura).
func _arena_map(app: App, args: Dictionary) -> void:
	var found := app.find_children("*", "ArenaMapScreen", true, false)
	if not found.is_empty() and args.has("poi"):
		(found[0] as ArenaMapScreen).select_poi(args["poi"])


## F71: heroi, classe, busca e rolagem da tela Herois (so desta captura).
func _heroes(app: App, args: Dictionary) -> void:
	var found := app.find_children("*", "HeroesScreen", true, false)
	if found.is_empty():
		return
	var screen := found[0] as HeroesScreen
	if args.has("hero"):
		screen.select_hero(StringName(args["hero"]))
	if args.has("role"):
		screen.select_role(args["role"])
	if args.has("query"):
		screen.search_field().text = args["query"]
		screen.search_field().text_changed.emit(args["query"])
	if args.has("scroll"):
		await process_frame
		await process_frame
		screen.scroll_to(int(args["scroll"]))


## F27: filtros, busca, build do simulador e rolagem do Compendio (so desta captura).
func _compendium(app: App, args: Dictionary) -> void:
	var bestiary := app.find_children("*", "BestiaryScreen", true, false)
	var forge := app.find_children("*", "ForgeScreen", true, false)
	if not bestiary.is_empty():
		var screen := bestiary[0] as BestiaryScreen
		var tiers := {
			"t1": BestiaryScreen.TierFilter.T1,
			"t2": BestiaryScreen.TierFilter.T2,
			"t3": BestiaryScreen.TierFilter.T3,
			"boss": BestiaryScreen.TierFilter.BOSS,
		}
		if args.has("tier"):
			screen.select_filter(tiers[args["tier"]])
		if args.has("query"):
			screen.search_field().text = args["query"]
			screen.search_field().text_changed.emit(args["query"])
	if not forge.is_empty():
		var screen := forge[0] as ForgeScreen
		if args.has("section"):
			if args["section"] == "weapons":
				screen.select_filter(ForgeScreen.Section.WEAPONS)
			else:
				screen.select_filter(ForgeScreen.Section.SET, StringName(args["section"]))
		if args.has("query"):
			screen.search_field().text = args["query"]
			screen.search_field().text_changed.emit(args["query"])
		if args.has("build"):
			var parts: PackedStringArray = args["build"].split(":")
			screen.simulator.select_hero(StringName(parts[0]))
			screen.simulator.set_level(int(parts[1]))
			for item_id: String in parts[2].split(","):
				var item := screen.catalog.item(StringName(item_id))
				screen.simulator.choose(item.slot, item)
	var compendium := (
		(bestiary + forge)[0] as CompendiumScreen if not (bestiary + forge).is_empty() else null
	)
	if compendium != null and args.has("scroll"):
		await process_frame
		await process_frame
		compendium.scroll_to(int(args["scroll"]))


func _set_state(app: App, state: String) -> void:
	var login := app.stack().current() as LoginScreen
	var lobby := app.stack().current() as LobbyScreen
	match state:
		"register":
			login.select_mode(LoginScreen.Mode.REGISTER)
		"loading":
			login.email_field().text = "duelista@exemplo.com"
			login.password_field().text = "senha1234"
			login.call("_set_busy", true)
		"error":
			login.email_field().text = "duelista@exemplo.com"
			login.password_field().text = "senha1234"
			await login.submit()
		"field_error":
			login.select_mode(LoginScreen.Mode.REGISTER)
			login.email_field().text = "duelista@exemplo.com"
			login.password_field().text = "fraca"
			await login.submit()
		"joining":
			lobby.call("_show_state", LobbyScreen.QueueState.JOINING)
		"searching":
			app.queue.searching.emit(83)
		"matched":
			lobby.call("_on_queue_matched")
		"queue_error":
			lobby.call("_on_queue_failed", ApiClient.OFFLINE)


func _args() -> Dictionary:
	var parsed := {}
	for arg: String in OS.get_cmdline_user_args():
		var pair := arg.trim_prefix("--").split("=", true, 1)
		parsed[pair[0]] = pair[1] if pair.size() > 1 else ""
	return parsed


func _size(text: String) -> Vector2i:
	var parts := text.split("x")
	if parts.size() != 2:
		return DEFAULT_SIZE
	return Vector2i(int(parts[0]), int(parts[1]))
