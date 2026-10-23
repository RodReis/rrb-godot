class_name PingSampler
extends Node
## Servidor: amostra o RTT de cada peer a cada SAMPLE_SECONDS enquanto a partida corre e entrega a
## media ao PingAverage (F29, SPEC-029 §3.1). O ENet mede o RTT; aqui so se le. Nada no cliente.

const SAMPLE_SECONDS: float = 1.0

var average: PingAverage = PingAverage.new()

var _match: MatchController
var _elapsed: float = 0.0


## Liga o medidor ao MatchController, que passa a ler [member average] no fim.
func bind(match_controller: MatchController) -> void:
	_match = match_controller
	_match.ping = average


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed < SAMPLE_SECONDS:
		return
	_elapsed = 0.0
	if _match != null and MatchState.is_running(_match.state):
		_sample()


func _sample() -> void:
	var enet := multiplayer.multiplayer_peer as ENetMultiplayerPeer
	if enet == null:
		return
	for id: int in multiplayer.get_peers():
		var peer := enet.get_peer(id)
		if peer != null:
			average.add(id, roundi(peer.get_statistic(ENetPacketPeer.PEER_ROUND_TRIP_TIME)))
