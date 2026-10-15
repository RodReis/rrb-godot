class_name AuthSession
extends RefCounted
## Quem pode entrar neste servidor dedicado: confere o match_token de cada peer no backend e
## guarda a conta de cada um (o MatchResult precisa de userId por jogador). Sem backend
## (`--no-backend`, dev) admite qualquer peer e nao guarda conta.
##
## Cada jogador tem o seu token (sub = conta); a partida e uma so: depois do primeiro peer, token
## de outra partida e recusado sem nem chamar o backend. A mesma conta em dois peers ao mesmo
## tempo e recusada; sair do lobby e voltar e permitido (release), e as estatisticas do peer
## antigo continuam atribuidas a ela.

## Codigo que o backend devolve quando o x-internal-secret nao confere.
const INTERNAL_UNAUTHORIZED: String = "INTERNAL_UNAUTHORIZED"

## "" ate o primeiro token valido.
var match_id: String = ""
## Seed que o backend sorteou para a partida (so informativa: o servidor usa a propria).
var match_seed: int = 0

var _api: BackendApi
## peer -> conta. Nunca apaga: peer que caiu no meio ainda tem estatistica a reportar.
var _users: Dictionary[int, String] = {}
var _online: Dictionary[int, bool] = {}


## Veredito de um peer.
class Decision:
	extends RefCounted
	var admitted: bool = false
	var reply: String = AuthReply.DENIED
	var user_id: String = ""


func _init(api: BackendApi) -> void:
	_api = api


## Conta de cada peer admitido (copia).
func users() -> Dictionary[int, String]:
	return _users.duplicate()


func release(peer: int) -> void:
	_online.erase(peer)


func admit(peer: int, token: String) -> Decision:
	if _api == null:
		return _accept(peer, "")
	var claimed := MatchToken.match_id(token)
	if claimed.is_empty() or _is_other_match(claimed):
		return _refuse(AuthReply.DENIED)
	var reply := await _api.validate(claimed, token)
	if not reply.is_ok():
		# Segredo interno errado tambem e 401, mas a culpa e nossa, nao do token do jogador.
		var ours := reply.is_retryable() or reply.code() == INTERNAL_UNAUTHORIZED
		return _refuse(AuthReply.ERROR if ours else AuthReply.DENIED)
	var user: Variant = reply.body.get("userId")
	if not user is String or (user as String).is_empty() or reply.body.get("matchId") != claimed:
		return _refuse(AuthReply.ERROR)
	var user_id: String = user
	# Dois peers validando juntos: a conferencia que depende do estado e feita depois do await.
	if _is_other_match(claimed) or _is_online(user_id):
		return _refuse(AuthReply.DENIED)
	match_id = claimed
	var seed_value: Variant = reply.body.get("seed")
	match_seed = int(seed_value) if seed_value is float else 0
	return _accept(peer, user_id)


func _is_other_match(claimed: String) -> bool:
	return not match_id.is_empty() and claimed != match_id


func _is_online(user_id: String) -> bool:
	for peer: int in _online:
		if _users[peer] == user_id:
			return true
	return false


func _accept(peer: int, user_id: String) -> Decision:
	if not user_id.is_empty():
		_users[peer] = user_id
	_online[peer] = true
	var decision := Decision.new()
	decision.admitted = true
	decision.reply = AuthReply.OK
	decision.user_id = user_id
	return decision


func _refuse(reply: String) -> Decision:
	var decision := Decision.new()
	decision.reply = reply
	return decision
