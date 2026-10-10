extends Node3D
## Bootstrap: decide servidor, cliente ou host pelos argumentos e cuida da conexao.
## NetworkTime e iniciado pelo NetworkEvents do netfox (netfox/events/enabled).
## --offline = modo host (ARCHITECTURE-GAME §4, PI 2026-10-09): este processo e o servidor e o
## jogador local (peer 1), pelo mesmo caminho do online; o netfox tem um papel so por processo.
## --bot poe o heroi bot no 2o slot (time B), com input do servidor.

const MAX_PLAYERS: int = 2
const HERO_SCENE: String = "res://scenes/heroes/knight.tscn"
## Host so aceita conexao local, em porta escolhida pelo sistema.
const HOST_BIND_IP: String = "127.0.0.1"
const EPHEMERAL_PORT: int = 0
## ponytail: id fixo do bot; peer real do ENet e aleatorio de 32 bits, colisao desprezivel.
const BOT_ID: int = 2

var _hero_scene: PackedScene = preload(HERO_SCENE)
## Nivel dos herois spawnados por este servidor (--level de dev ate o F9).
var _hero_level: int = LaunchArgs.DEFAULT_LEVEL
## Segundos em que o relogio da partida comeca (--time de dev).
var _start_time: float = LaunchArgs.DEFAULT_TIME
## --bot: o bot entra com o 1o jogador (junto com o relogio) e ocupa o time B.
var _wants_bot: bool = false

@onready var players: Node3D = $Players
@onready var spawns: SpawnDirector = $Spawns
@onready var clock: MatchClock = $MatchClock
@onready var spawner: MultiplayerSpawner = $MultiplayerSpawner
@onready var connect_panel: Control = $UI/ConnectPanel
@onready var address_edit: LineEdit = $UI/ConnectPanel/Address
@onready var connect_button: Button = $UI/ConnectPanel/ConnectButton
## Rede e tick no rodape (DV tela 3); o relogio da partida esta na HUD.
@onready var status_label: Label = $UI/Status
@onready var hud: HudPhase1 = $HudPhase1


func _ready() -> void:
	InputActions.ensure()
	spawner.spawn_path = spawner.get_path_to(players)
	spawner.spawn_function = _spawn_player
	connect_button.pressed.connect(_on_connect_pressed)
	clock.boss_warning.connect(_on_clock_boss_warning)
	clock.boss_spawned.connect(spawns.spawn_boss)
	clock.phase1_ended.connect(_on_clock_phase1_ended)
	spawns.boss_killed.connect(_on_spawns_boss_killed)

	var args := LaunchArgs.parse(OS.get_cmdline_user_args())
	PlayerInput.autopilot = args["autopilot"]
	_hero_level = args["level"]
	_start_time = args["time"]
	_wants_bot = args["bot"]
	if args["offline"]:
		if start_server(EPHEMERAL_PORT, HOST_BIND_IP):
			_join(multiplayer.get_unique_id())
	elif args["mode"] == "server" or OS.has_feature("dedicated_server"):
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


## Falso se a porta nao abriu (o processo sai com codigo 1).
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


## Servidor: heroi do jogador [param id] (o proprio host no --offline), relogio e estado do mundo.
func _join(id: int) -> void:
	var team := _free_team()
	if team == GateRules.TEAM_NEUTRAL:
		print("[server] peer %d recusado: partida cheia" % id)
		(multiplayer.multiplayer_peer as ENetMultiplayerPeer).disconnect_peer(id)
		return
	spawner.spawn({"id": id, "team": team, "level": _hero_level, "bot": false})
	# ponytail: relogio comeca no 1o jogador; LOBBY_WAIT/HERO_PICK do MatchController sao do F15.
	if clock.is_started():
		clock.send_state(id)
	else:
		clock.start(NetworkTime.tick, NetworkTime.tickrate, _start_time)
		if _wants_bot:
			_spawn_bot()
	spawns.send_state(id)  # antes dos baus: cria o BossChest no cliente
	for node: Node in get_tree().get_nodes_in_group(Chest.GROUP):
		(node as Chest).send_state(id)


## Servidor: heroi bot no time B e o navmesh que ele usa.
func _spawn_bot() -> void:
	var nav := ArenaNav.new()
	add_child(nav)
	nav.bake($Arena as Node3D, GateRules.gate_layer(GateRules.TEAM_A))
	spawner.spawn({"id": BOT_ID, "team": GateRules.TEAM_B, "level": _hero_level, "bot": true})
	print("[bot] heroi bot %d no time B" % BOT_ID)


## Time livre: A, depois B (o bot ja reserva o B); NEUTRAL = partida cheia.
func _free_team() -> int:
	var taken: Array[int] = []
	for node: Node in players.get_children():
		taken.append((node as Hero).team)
	if _wants_bot:
		taken.append(GateRules.TEAM_B)
	for team: int in [GateRules.TEAM_A, GateRules.TEAM_B]:
		if not taken.has(team):
			return team
	return GateRules.TEAM_NEUTRAL


## Roda no servidor e nos clientes (MultiplayerSpawner): mesma posicao, time, nivel e mascara.
func _spawn_player(data: Dictionary) -> Node:
	var team: int = data["team"]
	var hero := _hero_scene.instantiate() as Hero
	hero.name = str(data["id"])
	hero.team = team
	hero.level = data["level"]
	hero.is_bot = data["bot"]
	if hero.is_bot:
		hero.get_node("Input").set_script(BotInput)
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


func _on_peer_disconnected(id: int) -> void:
	print("[server] peer %d saiu" % id)
	var player := players.get_node_or_null(str(id))
	if player:
		player.queue_free()


func _on_clock_boss_warning(tick: int) -> void:
	print("[match] aviso do boss (3:00), tick %d" % tick)


func _on_clock_phase1_ended(tick: int) -> void:
	print("[match] fim da fase 1 (5:00), portoes caem, tick %d" % tick)
	for node: Node in get_tree().get_nodes_in_group(Gate.GROUP):
		(node as Gate).fall()
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
