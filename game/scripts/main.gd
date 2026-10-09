extends Node3D
## Bootstrap: decide servidor ou cliente pelos argumentos e cuida da conexao.
## NetworkTime e iniciado pelo NetworkEvents do netfox (netfox/events/enabled).

const MAX_PLAYERS: int = 2

@onready var players: Node3D = $Players
@onready var connect_panel: Control = $UI/ConnectPanel
@onready var address_edit: LineEdit = $UI/ConnectPanel/Address
@onready var connect_button: Button = $UI/ConnectPanel/ConnectButton
@onready var status_label: Label = $UI/Status

func _ready() -> void:
	InputActions.ensure()
	connect_button.pressed.connect(_on_connect_pressed)

	var args := LaunchArgs.parse(OS.get_cmdline_user_args())
	if args["mode"] == "server" or OS.has_feature("dedicated_server"):
		start_server(args["port"])
	elif args["host"] != "":
		start_client(args["host"], args["port"])

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
	var args := LaunchArgs.parse(PackedStringArray(["--connect=" + address_edit.text.strip_edges()]))
	start_client(args["host"], args["port"])

func _on_peer_connected(id: int) -> void:
	print("[server] peer %d conectou" % id)

func _on_peer_disconnected(id: int) -> void:
	print("[server] peer %d saiu" % id)

func _on_server_disconnected() -> void:
	status_label.text = "desconectado do servidor"
	connect_panel.show()
