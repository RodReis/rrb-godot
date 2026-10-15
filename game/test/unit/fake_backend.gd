class_name FakeBackend
extends BackendApi
## Duble do backend para os testes: devolve as respostas roteirizadas, na ordem, e repete a
## ultima quando acabam; sem roteiro, falha de rede. Guarda o que recebeu.

var validate_replies: Array[BackendReply] = []
var heartbeat_replies: Array[BackendReply] = []
var result_replies: Array[BackendReply] = []
## Cada entrada: {"match_id": String, "token": String}.
var validated: Array[Dictionary] = []
var heartbeats: Array[String] = []
## Cada entrada: {"match_id": String, "result": Dictionary}.
var results: Array[Dictionary] = []


func validate(match_id: String, token: String) -> BackendReply:
	validated.append({"match_id": match_id, "token": token})
	return _next(validate_replies)


func heartbeat(match_id: String) -> BackendReply:
	heartbeats.append(match_id)
	return _next(heartbeat_replies)


func post_result(match_id: String, result: Dictionary) -> BackendReply:
	results.append({"match_id": match_id, "result": result})
	return _next(result_replies)


func _next(replies: Array[BackendReply]) -> BackendReply:
	if replies.is_empty():
		return BackendReply.of(BackendReply.NETWORK_ERROR)
	if replies.size() == 1:
		return replies[0]
	return replies.pop_front()
