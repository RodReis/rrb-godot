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

## O padrao do Godot (3 s) nao cobre a ida ao backend (que tem timeout de 5 s). Peer pendurado no
## handshake ocupa uma conexao do ENet por este tempo.
const AUTH_TIMEOUT_SECONDS: float = 7.0
## Servidor: depois de responder a recusa, espera isto antes de largar o peer. Sem a espera, uma
## recusa imediata (token malformado, sem ida ao backend) larga o peer antes da resposta sair, e o
## cliente nao distingue recusa de queda (sairia com 4 em vez de 2).
const DENY_GRACE_SECONDS: float = 0.25
## Cliente sem --token: o auth do SceneMultiplayer nao aceita dado vazio.
const NO_TOKEN: String = "-"

var _scene: SceneMultiplayer
## Servidor: coroutine func(peer: int, token: String) -> String (um AuthReply).
var _admit: Callable
## Servidor: func(peer: int) -> void; esquece um peer admitido que nao chegou a entrar.
var _release: Callable
var _token: String = ""
## Cliente: o codigo de saida ja foi decidido (recusa seguida de queda nao vira 4).
var _decided: bool = false


## Servidor. Chamar antes de abrir o peer.
func serve(admit: Callable, release: Callable) -> void:
	_admit = admit
	_release = release
	_scene = multiplayer as SceneMultiplayer
	_scene.auth_timeout = AUTH_TIMEOUT_SECONDS
	_scene.auth_callback = _on_server_data
	# Desistiu ou estourou o prazo no meio do handshake: nunca chega a peer_disconnected.
	_scene.peer_authentication_failed.connect(_release)


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
		# O peer desistiu enquanto o backend respondia; a conta ja foi marcada como presente.
		_release.call(peer)
		return
	_scene.send_auth(peer, reply.to_utf8_buffer())
	if reply == AuthReply.OK:
		_scene.complete_auth(peer)
	else:
		print("[auth] peer %d recusado (%s)" % [peer, reply])
		await get_tree().create_timer(DENY_GRACE_SECONDS).timeout
		if _scene.get_authenticating_peers().has(peer):  # o cliente pode ja ter saido
			_scene.disconnect_peer(peer)


func _on_client_authenticating(server: int) -> void:
	# send_auth recusa pacote vazio: sem token vai um marcador, recusado como qualquer lixo.
	var token := _token if not _token.is_empty() else NO_TOKEN
	_scene.send_auth(server, token.to_utf8_buffer())


func _on_client_data(server: int, data: PackedByteArray) -> void:
	var reply := data.get_string_from_utf8()
	if reply == AuthReply.OK:
		_scene.complete_auth(server)
	else:
		_deny(AuthReply.exit_code_for(reply))


func _on_client_authentication_failed(_server: int) -> void:
	_deny(ExitCodes.INTERNAL)


func _deny(exit_code: int) -> void:
	if not _decided:
		_decided = true
		denied.emit(exit_code)
