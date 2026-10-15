extends Node3D
## Bootstrap: decide servidor, cliente ou host pelos argumentos e cuida da conexao.
## NetworkTime e iniciado pelo NetworkEvents do netfox (netfox/events/enabled).
## --offline = modo host (ARCHITECTURE-GAME §4, PI 2026-10-09): este processo e o servidor e o
## jogador local (peer 1), pelo mesmo caminho do online; o netfox tem um papel so por processo.
## --bot poe o heroi bot no 2o slot (time B), com input do servidor. --bots poe bots nas duas vagas
## (soak bot x bot, F19): cada um com o proprio navmesh. --autopilot=bot: o BotInput joga pelo
## heroi local deste processo (medicao de rede com 2 clientes reais, F20). --probe: sonda de rede
## (NetProbe).
## Ciclo da partida no MatchController (F15): o servidor abre a espera, cada peer (e o bot) ocupa
## uma vaga, a selecao acontece na HeroSelect e os herois nascem na PHASE1, cada um com o heroi
## escolhido. Quem decide e o MatchController; aqui so se liga sinal e se spawna. No fim, quem
## joga ve a MatchEnd (F18); os dois botoes dela encerram o processo (ARCHITECTURE-GAME §3.7).
## VFX de combate (F41): o ImpactRelay leva o impacto do servidor aos clientes; o VfxSpawner so
## nasce em quem desenha (nunca no servidor headless). Ciclo dia/noite (F49): o DayNight tambem so
## nasce em quem desenha; o sentido sai da seed no servidor (--daynight forca) e vai por RPC.
## Online (F23): o cliente apresenta o --token no handshake (PeerAuth); o servidor dedicado so deixa
## entrar quem o backend validou, manda heartbeat e reporta o resultado no fim (ServerSession),
## saindo com os codigos de ExitCodes. Sem backend so com --no-backend (dev).

const MAX_PLAYERS: int = 2
## Conexoes do ENet no servidor. Maior que os jogadores: peer ainda no handshake de autenticacao
## ocupa uma, e com so 2 dois peers pendurados trancariam a partida; quem decide quem joga e o
## token (MAX_PLAYERS vagas no MatchController).
const MAX_CONNECTIONS: int = 32
## Herois da selecao; sem cena (Hero.SCENE_PATH) aparece indisponivel.
const ROSTER: Array[HeroData] = [
	preload("res://shared/data/heroes/knight.tres"),
	preload("res://shared/data/heroes/ranger.tres"),
	preload("res://shared/data/heroes/barbarian.tres"),
	preload("res://shared/data/heroes/fire_wizard.tres"),
	preload("res://shared/data/heroes/rogue.tres"),
	preload("res://shared/data/heroes/engineer.tres"),
]
## Host so aceita conexao local, em porta escolhida pelo sistema.
const HOST_BIND_IP: String = "127.0.0.1"
const EPHEMERAL_PORT: int = 0
## ponytail: ids fixos dos bots; peer real do ENet e aleatorio de 32 bits, colisao desprezivel.
const BOT_ID: int = 2
const BOT_ID_TEAM_A: int = 3
## Servidor dedicado: espera antes de sair no fim, para os RPCs confiaveis do fim (estado ENDED,
## ultima morte, match_ended com o placar) chegarem mesmo com perda; sair na hora descarta a fila.
const EXIT_DELAY_SECONDS: float = 2.0
## Codigo de saida do cliente que perdeu o servidor no meio da partida: erro interno, o Launcher
## mostra o erro generico (ARCHITECTURE-LAUNCHER §5.2).
const EXIT_CONNECTION_LOST: int = 4
## Intervalo do log de heroi desconectado (s): prova que ele segue simulado, sem inundar o log.
const DISCONNECTED_LOG_SECONDS: float = 5.0
## Overlay escuro da neblina de guerra (F37) no cliente. Desligado durante o MVP2.5 (decisao do
## PI em 2026-10-10, F39) para a verificacao visual da arena; o servidor continua filtrando o que
## cada um ve. Religar no [GATE] do MVP2.5.
const FOG_OF_WAR_OVERLAY: bool = false
## Argumentos do motor que ja definem a janela (run-clients.ps1 usa --resolution e --position):
## com eles, o settings.cfg nao mexe no modo nem no tamanho.
const WINDOW_ARGS: Array[String] = [
	"--resolution", "--position", "--fullscreen", "-f", "--windowed", "-w", "--maximized", "-m"
]

## Nivel dos herois spawnados por este servidor (--level de dev ate o F9).
var _hero_level: int = LaunchArgs.DEFAULT_LEVEL
## --bot: o bot ocupa a vaga do time B assim que o servidor abre.
var _wants_bot: bool = false
## --bots: os dois slots sao bots (soak); --bot-heroes=a,b escolhe o heroi de cada um.
var _wants_bots: bool = false
var _bot_heroes: Array[StringName] = []
## --bot-hero=<id> (dev): heroi do bot e do heroi local com --autopilot=bot; vazio = padrao.
var _bot_hero: StringName = &""
## --autopilot=bot: o heroi local e jogado pelo BotInput.
var _bot_pilot: bool = false
## Servidor dedicado: encerra o processo no fim da partida.
var _dedicated: bool = false
## Servidor dedicado: elo com o backend (auth, heartbeat, resultado).
var _server: ServerSession
## Cliente online: match_token apresentado ao servidor (--token); nunca vai para o log.
var _token: String = ""
## Navmesh de cada bot, por time (so no servidor com --bot ou --bots).
var _navs: Dictionary[int, ArenaNav] = {}
## Cliente: erro de servidor perdido (#102); null no servidor dedicado.
var _connection_lost: ConnectionLostScreen
## Servidor: herois de jogadores que cairam (log periodico).
var _disconnected: Array[Hero] = []
var _disconnected_log: Timer

@onready var players: Node3D = $Players
@onready var spawns: SpawnDirector = $Spawns
@onready var clock: MatchClock = $MatchClock
@onready var zone: ZoneController = $ZoneController
@onready var match_controller: MatchController = $MatchController
@onready var spawner: MultiplayerSpawner = $MultiplayerSpawner
@onready var connect_panel: Control = $UI/ConnectPanel
@onready var address_edit: LineEdit = $UI/ConnectPanel/Address
@onready var connect_button: Button = $UI/ConnectPanel/ConnectButton
## Conexao no rodape ate a partida; com a HUD ligada, a telemetria dela (F57) assume.
@onready var status_label: Label = $UI/Status
@onready var hud: HudController = $Hud
@onready var hero_select: HeroSelect = $HeroSelect
@onready var match_end: MatchEnd = $MatchEnd
@onready var bestiary: Bestiary = $Bestiary
@onready var camera: FollowCamera = $Camera


func _ready() -> void:
	InputActions.ensure()
	_apply_user_settings()
	spawner.spawn_path = spawner.get_path_to(players)
	spawner.spawn_function = _spawn_player
	connect_button.pressed.connect(_on_connect_pressed)
	clock.boss_warning.connect(_on_clock_boss_warning)
	clock.boss_warning.connect(spawns.warn_boss)
	clock.boss_spawned.connect(spawns.spawn_boss)
	clock.phase1_ended.connect(_on_clock_phase1_ended)
	clock.phase1_ended.connect(spawns.stop_respawns)  # 5:00 = TRANSITION: ninguem mais renasce
	clock.phase1_ended.connect(spawns.dismiss_boss)  # boss vivo sai sem drop (R-PEND-06)
	spawns.boss_killed.connect(_on_spawns_boss_killed)
	spawns.chest_opened.connect(match_controller.report_chest_opened)
	spawns.monster_killed.connect(match_controller.report_monster_killed)
	spawns.boss_killed.connect(match_controller.report_boss_killed)
	match_controller.phase_changed.connect(_on_match_phase_changed)
	match_controller.match_ended.connect(_on_match_ended)
	hero_select.bind(match_controller, ROSTER, _available_heroes())
	var vision := VisionDirector.new()  # neblina (F37): so age no servidor
	vision.name = VisionDirector.NODE_NAME
	add_child(vision)
	var relay := ImpactRelay.new()  # impacto do servidor ate o VFX (F41): existe nos dois lados
	relay.name = ImpactRelay.NODE_NAME
	relay.players = players
	add_child(relay)
	if VfxSpawner.wanted():  # VFX so em quem desenha; servidor headless nao tem no de VFX
		var vfx := VfxSpawner.new()
		vfx.name = VfxSpawner.NODE_NAME
		vfx.players = players
		vfx.relay = relay
		add_child(vfx)

	var args := LaunchArgs.parse(OS.get_cmdline_user_args())
	PlayerInput.autopilot = args["autopilot"]
	_hero_level = args["level"]
	match_controller.start_seconds = args["time"]
	match_controller.match_seed = spawns.loot_seed
	match_controller.forced_daynight = args["daynight"]
	_wants_bot = args["bot"]
	_wants_bots = args["bots"]
	_bot_heroes = args["bot_heroes"]
	_bot_hero = args["bot_hero"]
	_bot_pilot = args["bot_pilot"]
	_token = args["token"]
	if args["probe"]:
		var probe := NetProbe.new()
		probe.players = players
		probe.spawns = spawns
		add_child(probe)
	var dedicated: bool = args["mode"] == "server" or OS.has_feature("dedicated_server")
	if not dedicated:
		_start_day_night()
		await _warm_shaders()
	if args["offline"]:
		if start_server(EPHEMERAL_PORT, HOST_BIND_IP):
			_join(multiplayer.get_unique_id())
	elif dedicated:
		_dedicated = true
		if not _start_session(args["no_backend"]):
			return
		start_server(args["port"])
	elif args["host"] != "":
		start_client(args["host"], args["port"])
	if not _dedicated:
		match_end.bind(match_controller, ROSTER)
		match_end.play_again_requested.connect(_on_match_end_closed)
		match_end.back_requested.connect(_on_match_end_closed)
		_connection_lost = ConnectionLostScreen.new()
		_connection_lost.exit_requested.connect(_on_connection_lost_exit_requested)
		add_child(_connection_lost)


func _process(_delta: float) -> void:
	var hero := players.get_node_or_null(str(multiplayer.get_unique_id())) as Hero
	if hero == null:
		return  # servidor dedicado, ou cliente ainda sem heroi
	if not hud.is_bound():
		hud.bind(hero, clock, spawns, players, match_controller, zone)
		bestiary.bind_hero(hero)
		if FOG_OF_WAR_OVERLAY:
			var fog := FogOfWar.new()  # neblina (F37): so quem joga desenha
			fog.name = "FogOfWar"
			add_child(fog)
			fog.bind(hero)
		status_label.visible = false


## Liga o ciclo dia/noite (F49) aos nodes da arena; antes do warm-up, que ja renderiza o ceu dele.
## No headless volta na hora: nada roda no servidor.
func _start_day_night() -> void:
	if not DayNight.wanted():
		return
	var world := get_node("Arena/WorldEnvironment") as WorldEnvironment
	var sun := get_node("Arena/Sun") as DirectionalLight3D
	var probe := get_node("Arena/ReflectionProbe") as ReflectionProbe
	var day_night := DayNight.new()
	day_night.name = "DayNight"
	add_child(day_night)
	day_night.bind(clock, match_controller, sun, world, probe)


## Aquece shaders antes de qualquer conexao (F38, ADR-0006 item 7): cliente que trava no sync
## inicial pode ficar com o rollback preso (APRENDIZADOS #4). No headless volta na hora.
func _warm_shaders() -> void:
	connect_button.disabled = true
	var warmup := ShaderWarmup.new()
	add_child(warmup)
	var world := get_node_or_null("Arena/WorldEnvironment") as WorldEnvironment
	if world == null:
		push_warning("[warmup] arena sem WorldEnvironment: aquecendo sem o ambiente")
	await warmup.run(world.environment if world else null)
	warmup.queue_free()
	connect_button.disabled = false


## Falso se a porta nao abriu (o processo sai com codigo 1). Abre a espera pelos jogadores; com
## --bot, o bot ja ocupa a vaga do time B; com --bots, os bots ocupam as duas.
func start_server(port: int, bind_ip: String = "*") -> bool:
	var peer := ENetMultiplayerPeer.new()
	peer.set_bind_ip(bind_ip)
	var err := peer.create_server(port, MAX_CONNECTIONS)
	if err != OK:
		push_error("[server] falha ao abrir porta %d: %s" % [port, error_string(err)])
		get_tree().quit(1)
		return false
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	connect_panel.hide()
	status_label.text = "servidor na porta %d" % port
	print("[server] escutando em %s:%d" % [bind_ip, peer.host.get_local_port()])
	match_controller.available_heroes = _available_heroes()
	if _server == null or not _server.is_online():
		# Online, o lobby (e o prazo de espera dele) so abre com o primeiro peer admitido: o
		# container fica ocioso no pool ate a partida ser atribuida.
		match_controller.open(NetworkTime.tick, NetworkTime.tickrate)
	if _wants_bots:
		match_controller.join(BOT_ID_TEAM_A, GateRules.TEAM_A, true, NetworkTime.tick)
	if _wants_bot or _wants_bots:
		match_controller.join(BOT_ID, GateRules.TEAM_B, true, NetworkTime.tick)
	return true


## Servidor dedicado: monta o elo com o backend e o handshake de autenticacao, antes de abrir a
## porta. Falso (processo sai com ExitCodes.ARGUMENTS) se faltar BACKEND_URL/INTERNAL_SECRET e nao
## for --no-backend: servidor sem backend aceitaria qualquer peer.
func _start_session(no_backend: bool) -> bool:
	_server = ServerSession.new()
	_server.name = "ServerSession"
	add_child(_server)
	var api: BackendApi = null
	if no_backend and ServerSession.has_backend_environment():
		# Container de producao sempre tem as duas variaveis; um --no-backend ali seria engano.
		push_error("[server] --no-backend com BACKEND_URL/INTERNAL_SECRET definidos: recusado")
		get_tree().quit(ExitCodes.ARGUMENTS)
		return false
	if not no_backend:
		api = ServerSession.backend_from_environment(_server)
		if api == null:
			push_error(
				(
					"[server] defina %s e %s (ou --no-backend, so para dev)"
					% [ServerSession.ENV_URL, ServerSession.ENV_SECRET]
				)
			)
			get_tree().quit(ExitCodes.ARGUMENTS)
			return false
	else:
		push_warning("[server] --no-backend: qualquer peer entra e o resultado nao e reportado")
	_server.setup(api)
	var auth := PeerAuth.new()
	auth.name = "PeerAuth"
	add_child(auth)
	auth.serve(_server.admit, _server.auth.release)
	return true


func start_client(host: String, port: int) -> void:
	var auth := PeerAuth.new()
	auth.name = "PeerAuth"
	add_child(auth)
	auth.denied.connect(_on_auth_denied)
	auth.join(_token)
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(host, port)
	if err != OK:
		status_label.text = "erro ao conectar: %s" % error_string(err)
		return
	multiplayer.multiplayer_peer = peer
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	connect_panel.hide()
	status_label.text = "conectando a %s:%d..." % [host, port]
	await multiplayer.connected_to_server
	print("[client] conectado como peer %d" % multiplayer.get_unique_id())
	status_label.text = tr("Aguardando o adversário...")
	await NetworkTime.after_sync
	print("[client] NetworkTime sincronizado, tick %d" % NetworkTime.tick)


## settings.cfg do Launcher (ARCHITECTURE-LAUNCHER §5.3, F24): controles, audio, video e a
## sensibilidade do giro da camera. O [graphics] fica com a arena (GraphicsSettings). Headless
## (servidor dedicado, testes) nao tem janela, audio nem jogador local: nao le o arquivo.
func _apply_user_settings() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var values := UserSettings.load_file()
	SettingsApplier.apply_controls(values)
	SettingsApplier.apply_audio(values)
	var cli_window := false
	for arg: String in OS.get_cmdline_args():
		cli_window = cli_window or arg.get_slice("=", 0) in WINDOW_ARGS
	SettingsApplier.apply_video(values, get_window(), not cli_window)
	camera.orbit_sensitivity *= values[UserSettings.CONTROLS][UserSettings.MOUSE_SENSITIVITY]


func _on_connect_pressed() -> void:
	var args := LaunchArgs.parse(
		PackedStringArray(["--connect=" + address_edit.text.strip_edges()])
	)
	start_client(args["host"], args["port"])


func _on_peer_connected(id: int) -> void:
	print("[server] peer %d conectou" % id)
	if not match_controller.is_open():
		match_controller.open(NetworkTime.tick, NetworkTime.tickrate)
	_join(id)


## Servidor: vaga do jogador [param id] (o proprio host no --offline). So ha vaga no LOBBY_WAIT;
## cheio ou depois dele, o peer e desconectado.
func _join(id: int) -> void:
	var team := _free_team()
	if team != GateRules.TEAM_NEUTRAL and match_controller.join(id, team, false, NetworkTime.tick):
		return
	print("[server] peer %d recusado: partida cheia ou ja comecou" % id)
	(multiplayer.multiplayer_peer as ENetMultiplayerPeer).disconnect_peer(id)


## Time livre: A, depois B (o bot ja ocupa o B); NEUTRAL = partida cheia.
func _free_team() -> int:
	var taken: Array[int] = []
	for seat: MatchController.Seat in match_controller.seats():
		taken.append(seat.team)
	for team: int in MatchController.SLOT_TEAMS:
		if not taken.has(team):
			return team
	return GateRules.TEAM_NEUTRAL


## Ids dos herois com cena, na ordem do ROSTER.
func _available_heroes() -> Array[StringName]:
	var result: Array[StringName] = []
	for data: HeroData in ROSTER:
		if ResourceLoader.exists(Hero.SCENE_PATH % data.id):
			result.append(data.id)
	return result


## Servidor: um heroi por vaga, com o heroi escolhido; quem caiu na selecao ja nasce
## desconectado (input do servidor).
func _spawn_heroes() -> void:
	for seat: MatchController.Seat in match_controller.seats():
		if seat.is_bot:
			_bake_bot_nav(seat.team)
		var data := {
			"id": seat.peer,
			"team": seat.team,
			"level": _hero_level,
			"bot": seat.is_bot,
			"hero": seat.hero,
		}
		var hero := spawner.spawn(data) as Hero
		if not seat.connected:
			hero.mark_disconnected()
		print("[match] %s para o peer %d (time %d)" % [seat.hero, seat.peer, seat.team])


## Navmesh do bot, antes dele nascer: o portao do outro time conta como parede. Um por time; com
## dois bots no processo (--bots) cada um tem o proprio mapa, senao a parede de um valeria no outro.
func _bake_bot_nav(team: int) -> void:
	if _navs.has(team):
		return
	var enemy := GateRules.TEAM_B if team == GateRules.TEAM_A else GateRules.TEAM_A
	var nav := ArenaNav.new()
	nav.team = team
	nav.own_map = _wants_bots
	add_child(nav)
	nav.bake($Arena as Node3D, GateRules.gate_layer(enemy))
	_navs[team] = nav


## Roda no servidor e nos clientes (MultiplayerSpawner): mesmo heroi, posicao, time, nivel e
## mascara.
func _spawn_player(data: Dictionary) -> Node:
	var team: int = data["team"]
	var scene := load(Hero.SCENE_PATH % data["hero"]) as PackedScene
	var hero := scene.instantiate() as Hero
	hero.name = str(data["id"])
	hero.team = team
	hero.level = data["level"]
	hero.is_bot = data["bot"]
	var piloted: bool = _bot_pilot and data["id"] == multiplayer.get_unique_id()
	if hero.is_bot or piloted:
		hero.get_node("Input").set_script(BotInput)
	if piloted:
		_bake_bot_nav(team)
	hero.collision_mask = GateRules.hero_mask(team)
	hero.transform = _hero_spawn(team)
	return hero


func _hero_spawn(team: int) -> Transform3D:
	for node: Node in get_tree().get_nodes_in_group(SpawnMarker.GROUP):
		var marker := node as SpawnMarker
		if marker.kind == SpawnMarker.Kind.HERO and marker.team == team:
			return marker.global_transform
	push_error("[arena] sem marcador HERO do time %d" % team)
	return Transform3D.IDENTITY


## Servidor: o heroi fica na partida, parado, e continua sofrendo dano (ARCHITECTURE-GAME §6).
func _on_peer_disconnected(id: int) -> void:
	print("[server] peer %d saiu" % id)
	if _server != null:
		_server.auth.release(id)
	match_controller.leave(id, NetworkTime.tick)
	var hero := players.get_node_or_null(str(id)) as Hero
	if hero != null:
		hero.mark_disconnected()
		print("[match] heroi %d segue simulado com input vazio do servidor" % id)
		_watch_disconnected(hero)


## Servidor: loga tick, HP e posicao de cada heroi desconectado a cada poucos segundos.
func _watch_disconnected(hero: Hero) -> void:
	_disconnected.append(hero)
	if _disconnected_log != null:
		return
	_disconnected_log = Timer.new()
	_disconnected_log.wait_time = DISCONNECTED_LOG_SECONDS
	_disconnected_log.timeout.connect(_on_disconnected_log_timeout)
	add_child(_disconnected_log)
	_disconnected_log.start()


func _on_disconnected_log_timeout() -> void:
	for hero: Hero in _disconnected:
		if is_instance_valid(hero):
			var where := hero.global_position
			print(
				(
					"[net] heroi %d desconectado: tick %d, HP %d/%d, pos (%.1f, %.1f)"
					% [
						hero.peer_id,
						NetworkTime.tick,
						hero.hp,
						hero.attributes.max_hp,
						where.x,
						where.z
					]
				)
			)


## Quem joga ve a selecao enquanto ela dura. Servidor: o bot confirma o padrao do slot (ou o
## --bot-hero de dev) assim que a selecao abre (mesmo resultado do timeout, sem esperar 24 s);
## na PHASE1 nascem os herois escolhidos.
func _on_match_phase_changed(_from: int, to: int, tick: int) -> void:
	if not _dedicated and to == MatchState.State.HERO_PICK:
		var ticks_left := match_controller.deadline_tick - tick
		hero_select.open(float(ticks_left) / NetworkTime.tickrate)
		if _bot_pilot:
			_pilot_pick()
	elif hero_select.visible:
		hero_select.close()
	if not multiplayer.is_server():
		return
	if to == MatchState.State.HERO_PICK:
		var defaults := match_controller.rules.default_heroes
		for seat: MatchController.Seat in match_controller.seats():
			if seat.is_bot:
				var slot := MatchController.SLOT_TEAMS.find(seat.team)
				var hero_id := PickRules.default_hero(defaults, slot, _available_heroes())
				var wanted := _bot_heroes[slot] if _bot_heroes.size() > slot else _bot_hero
				if PickRules.can_pick(wanted, _available_heroes()):
					hero_id = wanted
				match_controller.submit_pick(seat.peer, hero_id, tick)
	elif to == MatchState.State.PHASE1:
		_spawn_heroes()


## --autopilot=bot com --bot-hero (dev): confirma o heroi pedido pela propria selecao (RPC normal).
func _pilot_pick() -> void:
	var index := ROSTER.find_custom(func(d: HeroData) -> bool: return d.id == _bot_hero)
	if index >= 0:
		hero_select.select(index)
		hero_select.lock_in()


## Servidor dedicado: partida encerrada reporta o resultado ao backend e encerra o processo com o
## codigo de ExitCodes (0 se reportou ou sem backend; 3 se o resultado nao chegou; ARCHITECTURE-GAME
## §3.7, §6).
func _on_match_ended(winner: int, reason: StringName, stats: MatchStats, tick: int) -> void:
	print(
		(
			"[match] fim: %s, vencedor %d, estatisticas %s, tick %d"
			% [reason, winner, stats.to_dict(), tick]
		)
	)
	if _dedicated:
		# Uma linha em JSON para o tools/soak.ps1 (F19) ler sem depender da prosa acima.
		var summary := {"winner": winner, "reason": reason, "tick": tick, "stats": stats.to_dict()}
		print("[soak] ", JSON.stringify(summary))
		var code := await _server.report(winner, reason, stats, match_controller.match_seed)
		await get_tree().create_timer(EXIT_DELAY_SECONDS).timeout
		get_tree().quit(code)


## "Jogar novamente" e "Voltar": o Game nao tem fila; o processo acaba e o Launcher decide.
func _on_match_end_closed() -> void:
	get_tree().quit(0)


func _on_clock_boss_warning(tick: int) -> void:
	print("[match] aviso do boss (3:00), tick %d" % tick)


func _on_clock_phase1_ended(tick: int) -> void:
	print("[match] fim da fase 1 (5:00), portoes caem, tick %d" % tick)
	for node: Node in get_tree().get_nodes_in_group(Gate.GROUP):
		(node as Gate).fall()
	for nav: ArenaNav in _navs.values():
		nav.bake($Arena as Node3D)  # sem portoes: o bot entra na base do jogador (#52)
	if multiplayer.is_server():
		for node: Node in players.get_children():
			var hero := node as Hero
			var who := "bot" if hero.is_bot else "jogador"
			print("[match] %s %s: Nv %d, %d XP" % [who, hero.name, hero.level, hero.xp])


func _on_spawns_boss_killed(peer: int) -> void:
	print("[match] Rei Esqueleto morto por %d" % peer)


## Cliente: o servidor encerrou ou caiu. Pausa a arvore (sem peer, `get_unique_id()` erra a cada
## quadro) e mostra o erro; se a tela do fim ja esta aberta, ela fica e so ela anima.
func _on_server_disconnected() -> void:
	status_label.text = "desconectado do servidor"
	status_label.visible = true
	get_tree().paused = true
	if match_controller.state == MatchState.State.ENDED and match_end.visible:
		match_end.process_mode = Node.PROCESS_MODE_ALWAYS
		return
	_connection_lost.present()


## Cliente: o servidor nao aceitou o token (ou nao pode decidir); sai com o codigo que o
## Launcher entende (ARCHITECTURE-LAUNCHER §5.2).
func _on_auth_denied(exit_code: int) -> void:
	push_error("[client] servidor recusou a entrada (codigo de saida %d)" % exit_code)
	get_tree().quit(exit_code)


func _on_connection_lost_exit_requested() -> void:
	get_tree().quit(EXIT_CONNECTION_LOST)
