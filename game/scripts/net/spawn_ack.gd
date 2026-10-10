class_name SpawnAck
extends Node
## Spawn confiavel antes do primeiro estado (F20, ADR-0001). O spawn do MultiplayerSpawner vai no
## canal confiavel e o estado do netfox no nao confiavel: sob perda, o estado chegava antes do
## spawn retransmitido e o cliente logava "Node not found". Aqui o servidor comeca sem mandar
## estado a ninguem; cada cliente confirma por RPC confiavel quando o node ja existe nele, e so
## entao entra no filtro de visibilidade dos sincronizadores do node.

const NODE_NAME: StringName = &"SpawnAck"

var _filters: Array[PeerVisibilityFilter] = []
## Servidor: peers que ja tem o node (podem receber RPC dele).
var _confirmed: Dictionary = {}


## Cria o no filho de [param owner], que ja tem os sincronizadores na arvore.
static func guard(owner: Node, filters: Array[PeerVisibilityFilter]) -> SpawnAck:
	var ack := SpawnAck.new()
	ack.name = NODE_NAME
	ack._filters = filters
	owner.add_child(ack)
	return ack


func _ready() -> void:
	if multiplayer.is_server():
		for filter: PeerVisibilityFilter in _filters:
			filter.default_visibility = false
			filter.update_visibility()
	else:
		_confirm.rpc_id(1)


## Servidor: [param peer] ja tem o node; passa a receber o estado dele.
func confirm(peer: int) -> void:
	_confirmed[peer] = true
	for filter: PeerVisibilityFilter in _filters:
		filter.set_visibility_for(peer, true)
		filter.update_visibility()


## Servidor: [param peer] ja confirmou o node.
func has_confirmed(peer: int) -> bool:
	return _confirmed.has(peer)


## Cliente -> servidor, sem payload; o remetente vem do transporte.
@rpc("any_peer", "call_remote", "reliable")
func _confirm() -> void:
	if multiplayer.is_server():
		confirm(multiplayer.get_remote_sender_id())
