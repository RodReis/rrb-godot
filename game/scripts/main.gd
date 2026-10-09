extends Node3D
## Bootstrap: decide servidor ou cliente pelos argumentos e cuida da conexao.
## NetworkTime e iniciado pelo NetworkEvents do netfox (netfox/events/enabled).

const MAX_PLAYERS: int = 2
const HERO_SCENE: String = "res://scenes/heroes/knight.tscn"

var _hero_scene: PackedScene = preload(HERO_SCENE)
## Nivel dos herois spawnados por este servidor (--level de dev ate o F9).
var _hero_level: int = LaunchArgs.DEFAULT_LEVEL
## Segundos em que o relogio da partida comeca (--time de dev).
var _start_time: float = LaunchArgs.DEFAULT_TIME

@onready var players: Node3D = $Players
@onready var spawns: SpawnDirector = $Spawns
@onready var clock: MatchClock = $MatchClock
@onready var spawner: MultiplayerSpawner = $MultiplayerSpawner
@onready var connect_panel: Control = $UI/ConnectPanel
@onready var address_edit: LineEdit = $UI/ConnectPanel/Address
@onready var connect_button: Button = $UI/ConnectPanel/ConnectButton
@onready var status_label: Label = $UI/Status
## Equipamento do heroi local; provisorio ate a HUD do F13.
@onready var inventory_label: Label = $UI/Inventory


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
	if args["mode"] == "server" or OS.has_feature("dedicated_server"):
		start_server(args["port"])
	elif args["host"] != "":
		start_client(args["host"], args["port"])


func _process(_delta: float) -> void:
	if multiplayer.is_server():
		return
	var peer := multiplayer.multiplayer_peer as ENetMultiplayerPeer
	if peer == null or peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		return
	var rtt := peer.get_peer(1).get_statistic(ENetPacketPeer.PEER_ROUND_TRIP_TIME)
	status_label.text = (
		"peer %d | RTT %d ms | tick %d | %s%s"
		% [
			multiplayer.get_unique_id(),
			rtt,
			NetworkTime.tick,
			_clock_text(),
			" | AUTOPILOT" if PlayerInput.autopilot else ""
		]
	)
	var hero := players.get_node_or_null(str(multiplayer.get_unique_id())) as Hero
	if hero != null:
		inventory_label.text = _inventory_text(hero)


func start_server(port: int) -> void:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(port, MAX_PLAYERS)
	if err != OK:
		push_error("[server] falha ao abrir porta %d: %s" % [port, error_string(err)])
		get_tree().quit(1)
		return
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	connect_panel.hide()
	status_label.text = "servidor na porta %d" % port
	print("[server] escutando na porta %d" % port)


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
	var team := (
		GateRules.TEAM_A if players.get_child_count() % MAX_PLAYERS == 0 else GateRules.TEAM_B
	)
	spawner.spawn({"id": id, "team": team, "level": _hero_level})
	# ponytail: relogio comeca no 1o peer; LOBBY_WAIT/HERO_PICK do MatchController sao do F15.
	if clock.is_started():
		clock.send_state(id)
	else:
		clock.start(NetworkTime.tick, NetworkTime.tickrate, _start_time)
	for node: Node in get_tree().get_nodes_in_group(Chest.GROUP):
		(node as Chest).send_state(id)
	spawns.send_state(id)


## Roda no servidor e nos clientes (MultiplayerSpawner): mesma posicao, time, nivel e mascara.
func _spawn_player(data: Dictionary) -> Node:
	var team: int = data["team"]
	var hero := _hero_scene.instantiate() as Hero
	hero.name = str(data["id"])
	hero.team = team
	hero.level = data["level"]
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


func _clock_text() -> String:
	var seconds := floori(clock.elapsed(NetworkTime.tick))
	return "%d:%02d" % [floori(seconds / 60.0), seconds % 60]


func _inventory_text(hero: Hero) -> String:
	var items := Inventory.items(hero.equipment, hero.item_catalog)
	var lines := PackedStringArray()
	for item: ItemData in items:
		lines.append("%s (%s)" % [item.display_name, Chest.RARITY_NAMES[item.rarity]])
	for bonus: SetBonusData in hero.item_catalog.set_bonuses:
		var pieces := SetBonus.count_pieces(items, bonus.set_id)
		if pieces > 0:
			lines.append("conjunto %s %d/%d" % [bonus.set_id, pieces, bonus.pieces_required])
	return "\n".join(lines)


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


func _on_spawns_boss_killed(peer: int) -> void:
	print("[match] Rei Esqueleto morto por %d" % peer)


func _on_server_disconnected() -> void:
	status_label.text = "desconectado do servidor"
	connect_panel.show()
