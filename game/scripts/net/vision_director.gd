class_name VisionDirector
extends Node
## Neblina de guerra no servidor (F37, CONVENTION §4.9): uma vez por tick, antes da simulacao,
## decide quem ve cada alvo (todo Concealment na arvore: herois, monstros, baus) entre os herois
## da partida — inclusive o bot e o jogador do host, que nao recebem RPC — e avisa quem mudou.
## Mede o proprio custo por tick (ARCHITECTURE-GAME §9) e loga a cada LOG_SECONDS. Decide em
## before_tick com a posicao do tick: na borda do raio, entrar e sair atrasam 1 tick.

const NODE_NAME: StringName = &"VisionDirector"
const LOG_SECONDS: float = 10.0

## Peers conectados (recebem RPC e estado); refeito so quando alguem entra ou sai.
var _remote: PackedInt32Array = PackedInt32Array()
## Herois observadores do tick (reusado).
var _observers: Array[Hero] = []
var _window_ticks: int = 0
var _window_usec: int = 0
var _window_peak: int = 0
var _window_changes: int = 0


func _ready() -> void:
	# No _ready o peer ainda e offline e is_server() mente: decide no tick.
	NetworkTime.before_tick.connect(_on_network_time_before_tick)
	multiplayer.peer_connected.connect(_on_multiplayer_peer_connected)
	multiplayer.peer_disconnected.connect(_on_multiplayer_peer_disconnected)


## Servidor: um passe da visao no [param tick]; devolve quantos (alvo, peer) mudaram.
func update(tick: int) -> int:
	_observers.clear()
	for concealment: Concealment in Concealment.all():
		var hero := concealment.target() as Hero
		if hero != null:
			_observers.append(hero)
	var changes := 0
	for concealment: Concealment in Concealment.all():
		var changed := concealment.refresh(_observers, _remote)
		if not changed.is_empty():
			changes += changed.size()
			concealment.announce(changed, _remote, tick)
	return changes


func _report(tick: int) -> void:
	var targets := Concealment.all().size()
	print(
		(
			(
				"[neblina] filtro: media %.1f us/tick, pico %d us, %d trocas em %d ticks (%d alvos, %d "
				+ "observadores, %d peers), tick %d"
			)
			% [
				float(_window_usec) / maxi(_window_ticks, 1),
				_window_peak,
				_window_changes,
				_window_ticks,
				targets,
				_observers.size(),
				_remote.size(),
				tick
			]
		)
	)
	_window_ticks = 0
	_window_usec = 0
	_window_peak = 0
	_window_changes = 0


func _on_network_time_before_tick(_delta: float, tick: int) -> void:
	if not multiplayer.is_server():
		return
	var start := Time.get_ticks_usec()
	_window_changes += update(tick)
	var spent := Time.get_ticks_usec() - start
	_window_usec += spent
	_window_peak = maxi(_window_peak, spent)
	_window_ticks += 1
	if _window_ticks >= roundi(LOG_SECONDS * NetworkTime.tickrate) and not _observers.is_empty():
		_report(tick)


func _on_multiplayer_peer_connected(_id: int) -> void:
	_remote = multiplayer.get_peers()


## O heroi de quem caiu segue observador (mark_disconnected), mas sem RPC: tira o id na mao, sem
## depender de get_peers() ja sem ele dentro do sinal.
func _on_multiplayer_peer_disconnected(id: int) -> void:
	_remote = multiplayer.get_peers()
	var at := _remote.find(id)
	if at >= 0:
		_remote.remove_at(at)
