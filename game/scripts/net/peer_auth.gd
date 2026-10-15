class_name PeerAuth
extends Node
## Handshake de autenticacao do peer, no proprio connect do ENet (SceneMultiplayer.auth_callback):
## ate os dois lados completarem, o peer nao entra no jogo (sem peer_connected, sem RPC, sem
## spawn). O cliente manda o match_token; o servidor decide (callback `admit`, que pode esperar
## o backend) e responde AuthReply. Recusado: o servidor larga o peer e o cliente sai com o codigo
## de AuthReply.exit_code_for. Os dois lados rodam o handshake sempre; o que muda no servidor de
## dev (--no-backend) e que `admit` aceita tudo.

## Cliente: o servidor recusou ou nao conseguiu decidir.
signal denied(exit_code: int)

## O padrao do Godot (3 s) nao cobre a ida ao backend.
const AUTH_TIMEOUT_SECONDS: float = 10.0
## Servidor: depois de responder a recusa, espera isto antes de largar o peer. Sem a espera, uma
## recusa imediata (token malformado, sem ida ao backend) larga o peer antes da resposta sair, e o
## cliente nao distingue recusa de queda (sairia com 4 em vez de 2).
const DENY_GRACE_SECONDS: float = 0.25

var _scene: SceneMultiplayer
## Servidor: coroutine func(peer: int, token: String) -> String (um AuthReply).
var _admit: Callable
var _token: String = ""


## Servidor. Chamar antes de abrir o peer.
func serve(admit: Callable) -> void:
	_admit = admit
	_scene = multiplayer as SceneMultiplayer
	_scene.auth_timeout = AUTH_TIMEOUT_SECONDS
	_scene.auth_callback = _on_server_data


## Cliente. Chamar antes de abrir o peer.
func join(token: String) -> void:
	_token = token
	_scene = multiplayer as SceneMultiplayer
	_scene.auth_timeout = AUTH_TIMEOUT_SECONDS
	_scene.auth_callback = _on_client_data
	_scene.peer_authenticating.connect(_on_client_authenticating)
	_scene.peer_authentication_failed.connect(_on_client_authentication_failed)


func _on_server_data(peer: int, data: PackedByteArray) -> void:
	var reply: String = await _admit.call(peer, data.get_string_from_utf8())
	if not _scene.get_authenticating_peers().has(peer):
		return  # o peer desistiu enquanto o backend respondia
	_scene.send_auth(peer, reply.to_utf8_buffer())
	if reply == AuthReply.OK:
		_scene.complete_auth(peer)
	else:
		print("[auth] peer %d recusado (%s)" % [peer, reply])
		await get_tree().create_timer(DENY_GRACE_SECONDS).timeout
		_scene.disconnect_peer(peer)


func _on_client_authenticating(server: int) -> void:
	_scene.send_auth(server, _token.to_utf8_buffer())


func _on_client_data(server: int, data: PackedByteArray) -> void:
	var reply := data.get_string_from_utf8()
	if reply == AuthReply.OK:
		_scene.complete_auth(server)
	else:
		denied.emit(AuthReply.exit_code_for(reply))


func _on_client_authentication_failed(_server: int) -> void:
	denied.emit(ExitCodes.INTERNAL)
