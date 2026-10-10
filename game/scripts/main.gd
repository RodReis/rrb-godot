extends Node3D
## Bootstrap: decide servidor, cliente ou host pelos argumentos e cuida da conexao.
## NetworkTime e iniciado pelo NetworkEvents do netfox (netfox/events/enabled).
## --offline = modo host (ARCHITECTURE-GAME §4, PI 2026-10-09): este processo e o servidor e o
## jogador local (peer 1), pelo mesmo caminho do online; o netfox tem um papel so por processo.
## --bot poe o heroi bot no 2o slot (time B), com input do servidor. --autopilot=bot: o BotInput
## joga pelo heroi local deste processo (medicao de rede com 2 clientes reais, F20). --probe: sonda
## de rede (NetProbe).
## Ciclo da partida no MatchController (F15): o servidor abre a espera, cada peer (e o bot) ocupa
## uma vaga, a selecao acontece na HeroSelect e os herois nascem na PHASE1, cada um com o heroi
## escolhido. Quem decide e o MatchController; aqui so se liga sinal e se spawna.

const MAX_PLAYERS: int = 2
## Herois da selecao; sem cena (Hero.SCENE_PATH) aparece indisponivel.
const ROSTER: Array[HeroData] = [
	preload("res://shared/data/heroes/knight.tres"),
	preload("res://shared/data/heroes/ranger.tres"),
]
## Host so aceita conexao local, em porta escolhida pelo sistema.
const HOST_BIND_IP: String = "127.0.0.1"
const EPHEMERAL_PORT: int = 0
## ponytail: id fixo do bot; peer real do ENet e aleatorio de 32 bits, colisao desprezivel.
const BOT_ID: int = 2
## Intervalo do log de heroi desconectado (s): prova que ele segue simulado, sem inundar o log.
const DISCONNECTED_LOG_SECONDS: float = 5.0

## Nivel dos herois spawnados por este servidor (--level de dev ate o F9).
var _hero_level: int = LaunchArgs.DEFAULT_LEVEL
## --bot: o bot ocupa a vaga do time B assim que o servidor abre.
var _wants_bot: bool = false
## --autopilot=bot: o heroi local e jogado pelo BotInput.
var _bot_pilot: bool = false
## Servidor dedicado: encerra o processo no fim da partida.
var _dedicated: bool = false
## Navmesh do bot (so no servidor com --bot).
var _nav: ArenaNav
## Servidor: herois de jogadores que cairam (log periodico).
var _disconnected: Array[Hero] = []
var _disconnected_log: Timer

@onready var players: Node3D = $Players
@onready var spawns: SpawnDirector = $Spawns
@onready var clock: MatchClock = $MatchClock
@onready var match_controller: MatchController = $MatchController
@onready var spawner: MultiplayerSpawner = $MultiplayerSpawner
@onready var connect_panel: Control = $UI/ConnectPanel
@onready var address_edit: LineEdit = $UI/ConnectPanel/Address
@onready var connect_button: Button = $UI/ConnectPanel/ConnectButton
## Rede e tick no rodape (DV tela 3); o relogio da partida esta na HUD.
@onready var status_label: Label = $UI/Status
@onready var hud: HudPhase1 = $HudPhase1
@onready var hero_select: HeroSelect = $HeroSelect


func _ready() -> void:
	InputActions.ensure()
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
	match_controller.phase_changed.connect(_on_match_phase_changed)
	match_controller.match_ended.connect(_on_match_ended)
	hero_select.bind(match_controller, ROSTER, _available_heroes())

	var args := LaunchArgs.parse(OS.get_cmdline_user_args())
	PlayerInput.autopilot = args["autopilot"]
	_hero_level = args["level"]
	match_controller.start_seconds = args["time"]
	_wants_bot = args["bot"]
	_bot_pilot = args["bot_pilot"]
	if args["probe"]:
		var probe := NetProbe.new()
		probe.players = players
		probe.spawns = spawns
		add_child(probe)
	if args["offline"]:
		if start_server(EPHEMERAL_PORT, HOST_BIND_IP):
			_join(multiplayer.get_unique_id())
	elif args["mode"] == "server" or OS.has_feature("dedicated_server"):
		_dedicated = true
		start_server(args["port"])
	elif args["host"] != "":
		start_client(args["host"], args["port"])


func _process(_delta: float) -> void:
	var hero := players.get_node_or_null(str(multiplayer.get_unique_id())) as Hero
	if hero == null:
		return  # servidor dedicado, ou cliente ainda sem heroi
	if not hud.visible:
		hud.bind(hero, clock, spawns, players)
	status_label.text = (
		"%s | tick %d%s"
		% [_net_text(), NetworkTime.tick, " | AUTOPILOT" if PlayerInput.autopilot else ""]
	)


## Falso se a porta nao abriu (o processo sai com codigo 1). Abre a espera pelos jogadores; com
## --bot, o bot ja ocupa a vaga do time B.
func start_server(port: int, bind_ip: String = "*") -> bool:
	var peer := ENetMultiplayerPeer.new()
	peer.set_bind_ip(bind_ip)
	var err := peer.create_server(port, MAX_PLAYERS)
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
	match_controller.open(NetworkTime.tick, NetworkTime.tickrate)
	if _wants_bot:
		match_controller.join(BOT_ID, GateRules.TEAM_B, true, NetworkTime.tick)
	return true


func start_client(host: String, port: int) -> void:
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


func _on_connect_pressed() -> void:
	var args := LaunchArgs.parse(
		PackedStringArray(["--connect=" + address_edit.text.strip_edges()])
	)
	start_client(args["host"], args["port"])


func _on_peer_connected(id: int) -> void:
	print("[server] peer %d conectou" % id)
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


## Navmesh do bot, antes dele nascer: o portao do outro time conta como parede. Um por processo.
func _bake_bot_nav(team: int) -> void:
	if _nav != null:
		return
	var enemy := GateRules.TEAM_B if team == GateRules.TEAM_A else GateRules.TEAM_A
	_nav = ArenaNav.new()
	add_child(_nav)
	_nav.bake($Arena as Node3D, GateRules.gate_layer(enemy))


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


func _net_text() -> String:
	if multiplayer.is_server():
		return "offline (host)"
	var peer := multiplayer.multiplayer_peer as ENetMultiplayerPeer
	if peer == null or peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		return "desconectado"
	var rtt := peer.get_peer(1).get_statistic(ENetPacketPeer.PEER_ROUND_TRIP_TIME)
	return "peer %d | RTT %d ms" % [multiplayer.get_unique_id(), rtt]


## Servidor: o heroi fica na partida, parado, e continua sofrendo dano (ARCHITECTURE-GAME §6).
func _on_peer_disconnected(id: int) -> void:
	print("[server] peer %d saiu" % id)
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


## Quem joga ve a selecao enquanto ela dura. Servidor: o bot confirma o padrao do slot assim
## que a selecao abre (mesmo resultado do timeout, sem esperar 24 s); na PHASE1 nascem os
## herois escolhidos.
func _on_match_phase_changed(_from: int, to: int, tick: int) -> void:
	if not _dedicated and to == MatchState.State.HERO_PICK:
		var ticks_left := match_controller.deadline_tick - tick
		hero_select.open(float(ticks_left) / NetworkTime.tickrate)
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
				match_controller.submit_pick(seat.peer, hero_id, tick)
	elif to == MatchState.State.PHASE1:
		_spawn_heroes()


## Servidor dedicado: partida encerrada encerra o processo (ARCHITECTURE-GAME §3.7).
func _on_match_ended(winner: int, reason: StringName, tick: int) -> void:
	print("[match] fim: %s, vencedor %d, tick %d" % [reason, winner, tick])
	if _dedicated:
		get_tree().quit()


func _on_clock_boss_warning(tick: int) -> void:
	print("[match] aviso do boss (3:00), tick %d" % tick)


func _on_clock_phase1_ended(tick: int) -> void:
	print("[match] fim da fase 1 (5:00), portoes caem, tick %d" % tick)
	for node: Node in get_tree().get_nodes_in_group(Gate.GROUP):
		(node as Gate).fall()
	if _nav != null:
		_nav.bake($Arena as Node3D)  # sem portoes: o bot entra na base do jogador (#52)
	if multiplayer.is_server():
		for node: Node in players.get_children():
			var hero := node as Hero
			var who := "bot" if hero.is_bot else "jogador"
			print("[match] %s %s: Nv %d, %d XP" % [who, hero.name, hero.level, hero.xp])


func _on_spawns_boss_killed(peer: int) -> void:
	print("[match] Rei Esqueleto morto por %d" % peer)


func _on_server_disconnected() -> void:
	status_label.text = "desconectado do servidor"
	connect_panel.show()
