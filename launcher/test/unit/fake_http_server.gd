class_name FakeHttpServer
extends Node
## Servidor HTTP/1.1 minimo em processo (teste do PingProbe, #233): atende GET com 200 e o corpo
## {"status":"ok"} e mantem a conexao aberta (keep-alive). Conta as conexoes aceitas e as
## requisicoes atendidas. Precisa estar na arvore: atende no _process.

const RESPONSE: String = (
	"HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: 15\r\n"
	+ 'Connection: keep-alive\r\n\r\n{"status":"ok"}'
)
const HEADER_END: String = "\r\n\r\n"

var connections: int = 0
var requests: int = 0
## Resposta atrasada em ms (simula o RTT); 0 = na hora.
var delay_msec: int = 0
## Fecha a conexao depois de cada resposta (servidor sem keep-alive).
var close_after_reply: bool = false

var _server: TCPServer = TCPServer.new()
var _peers: Array[StreamPeerTCP] = []
var _buffers: Dictionary[StreamPeerTCP, String] = {}


func start() -> int:
	_server.listen(0, "127.0.0.1")
	return _server.get_local_port()


func _process(_delta: float) -> void:
	while _server.is_connection_available():
		var peer := _server.take_connection()
		_peers.append(peer)
		_buffers[peer] = ""
		connections += 1
	for peer: StreamPeerTCP in _peers.duplicate():
		peer.poll()
		if peer.get_status() != StreamPeerTCP.STATUS_CONNECTED:
			_forget(peer)
			continue
		var available := peer.get_available_bytes()
		if available > 0:
			_buffers[peer] += peer.get_string(available)
		if (_buffers[peer] as String).contains(HEADER_END):
			_buffers[peer] = ""
			requests += 1
			if delay_msec > 0:
				OS.delay_msec(delay_msec)
			peer.put_data(RESPONSE.to_utf8_buffer())
			if close_after_reply:
				peer.disconnect_from_host()
				_forget(peer)


func _forget(peer: StreamPeerTCP) -> void:
	_peers.erase(peer)
	_buffers.erase(peer)


func _exit_tree() -> void:
	_server.stop()
