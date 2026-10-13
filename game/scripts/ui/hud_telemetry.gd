class_name HudTelemetry
extends Label
## Telemetria da HUD (F57, prototipo HUD Moderno): FPS · PING · TICK no canto superior esquerdo;
## substitui a linha de rede do rodape (main) enquanto a partida esta na tela.

## Reescreve o texto 4x por segundo: o numero nao "treme" e nao aloca string a cada quadro.
const REFRESH_SECONDS: float = 0.25

var _left: float = 0.0


func _process(delta: float) -> void:
	_left -= delta
	if _left > 0.0 or not is_visible_in_tree():
		return
	_left = REFRESH_SECONDS
	text = format(
		roundi(Engine.get_frames_per_second()), _ping_ms(), NetworkTime.tick, PlayerInput.autopilot
	)


## [param ping] < 0 = sem servidor remoto (host offline).
static func format(fps: int, ping: int, tick: int, autopilot: bool) -> String:
	var ping_text := "%d ms" % ping if ping >= 0 else "—"
	var line := "FPS %d · PING %s · TICK %d" % [fps, ping_text, tick]
	return line + " · AUTOPILOT" if autopilot else line


## RTT do ENet com o servidor; -1 no host ou sem conexao.
func _ping_ms() -> int:
	if multiplayer.is_server():
		return -1
	var peer := multiplayer.multiplayer_peer as ENetMultiplayerPeer
	if peer == null or peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		return -1
	return peer.get_peer(1).get_statistic(ENetPacketPeer.PEER_ROUND_TRIP_TIME)
