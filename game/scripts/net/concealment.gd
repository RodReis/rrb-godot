class_name Concealment
extends Node
## Mato alto (F32, CONVENTION §4.7): o servidor para de mandar o estado do heroi a quem nao o ve
## (filtro do RollbackSynchronizer, ao lado do SpawnAck) — neblina so no cliente e proibida. Sem
## estado, o node remoto ficaria parado onde sumiu; por isso o servidor tambem avisa o peer por
## RPC confiavel (evento discreto, fora da simulacao) e o cliente esconde o heroi e tira a colisao
## dele ate chegar estado de depois da revelacao. No host (--offline) o jogador local e o
## servidor: ali o esconder e so visual, pela mesma regra (VisibilityRules).

const NODE_NAME: StringName = &"Concealment"

var _hero: Hero
var _rollback: RollbackSynchronizer
var _ack: SpawnAck
## Servidor: peer -> o heroi esta escondido dele (o que o peer ja sabe pelo RPC).
var _hidden: Dictionary = {}
## Servidor: peers que mudaram no ultimo refresh (reusado a cada tick).
var _changed: PackedInt32Array = PackedInt32Array()
## Cliente: o servidor escondeu o heroi deste peer.
var _hidden_here: bool = false
## Cliente: tick a partir do qual o estado recebido e de depois da revelacao (-1 = nunca sumiu).
var _shown_tick: int = -1
## Cliente: ultimo valor de is_shown (log so na troca).
var _was_shown: bool = true


## Cria o no filho de [param hero], que ja tem o RollbackSynchronizer e o SpawnAck.
static func guard(hero: Hero, rollback: RollbackSynchronizer, ack: SpawnAck) -> Concealment:
	var concealment := Concealment.new()
	concealment.name = NODE_NAME
	concealment._hero = hero
	concealment._rollback = rollback
	concealment._ack = ack
	hero.add_child(concealment)
	return concealment


func _ready() -> void:
	if multiplayer.is_server():
		_rollback.visibility_filter.add_visibility_filter(_visible_to)
		NetworkTime.before_tick.connect(_on_network_time_before_tick)
	set_process(not multiplayer.is_server())


func _process(_delta: float) -> void:
	var shown := is_shown()
	if shown == _was_shown:
		return
	_was_shown = shown
	print(
		(
			"[mato] heroi %d %s (ultimo estado recebido: tick %d)"
			% [_hero.peer_id, "reapareceu" if shown else "sumiu", _rollback.get_last_known_state()]
		)
	)


## O jogador deste processo ve o heroi? No servidor (host), pela regra; no cliente, pelo aviso do
## servidor e pela chegada de estado novo.
func is_shown() -> bool:
	if multiplayer.is_server():
		return not _hero.hidden_from(_observer(multiplayer.get_unique_id()))
	return VisibilityRules.shown_on_client(
		_hidden_here, _shown_tick, _rollback.get_last_known_state()
	)


## Servidor: recalcula, para cada peer de [param peers] que ja tem o node, se o heroi esta
## escondido dele; atualiza o filtro e devolve os peers que mudaram.
func refresh(peers: PackedInt32Array) -> PackedInt32Array:
	_changed.clear()
	for peer: int in peers:
		if not _ack.has_confirmed(peer):
			continue
		var hidden := _hero.hidden_from(_observer(peer))
		var was: bool = _hidden.get(peer, false)
		if hidden != was:
			_hidden[peer] = hidden
			_changed.append(peer)
	if not _changed.is_empty():
		_rollback.visibility_filter.update_visibility(peers)
	return _changed


## Heroi do [param peer] (irmao com o nome do peer_id), ou null.
func _observer(peer: int) -> Hero:
	return _hero.get_parent().get_node_or_null(str(peer)) as Hero


## Filtro do RollbackSynchronizer: false = nao manda estado ao [param peer].
func _visible_to(peer: int) -> bool:
	return not _hidden.get(peer, false)


## Servidor -> cliente: o heroi sumiu ([param hidden]) ou voltou a partir de [param tick].
@rpc("authority", "call_remote", "reliable")
func _set_hidden(hidden: bool, tick: int) -> void:
	_hidden_here = hidden
	_shown_tick = tick


func _on_network_time_before_tick(_delta: float, tick: int) -> void:
	for peer: int in refresh(multiplayer.get_peers()):
		var hidden: bool = _hidden[peer]
		print(
			(
				"[mato] heroi %d %s para o peer %d (tick %d)"
				% [_hero.peer_id, "escondido" if hidden else "visivel", peer, tick]
			)
		)
		_set_hidden.rpc_id(peer, hidden, tick)
