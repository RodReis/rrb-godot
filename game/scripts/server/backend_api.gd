class_name BackendApi
extends RefCounted
## O que o servidor dedicado pede ao backend (endpoints /internal/matches/:id/*, ARCHITECTURE-
## LAUNCHER §4.2). BackendClient fala HTTP de verdade; os testes usam um duble. As chamadas podem
## ser coroutines: sempre `await`.


## O backend confere assinatura, validade e dono do token. Sucesso traz matchId, userId,
## playerIds e seed.
func validate(_match_id: String, _token: String) -> BackendReply:
	return BackendReply.of(BackendReply.NETWORK_ERROR)


func heartbeat(_match_id: String) -> BackendReply:
	return BackendReply.of(BackendReply.NETWORK_ERROR)


func post_result(_match_id: String, _result: Dictionary) -> BackendReply:
	return BackendReply.of(BackendReply.NETWORK_ERROR)
