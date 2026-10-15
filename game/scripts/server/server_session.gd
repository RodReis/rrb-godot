class_name ServerSession
extends Node
## Elo do servidor dedicado com o backend numa partida online: quem entra (AuthSession), sinal de
## vida (Heartbeat) e resultado no fim (ResultReporter). Sem backend (`--no-backend`, dev) nada
## disso acontece: admite qualquer peer e nao reporta (ARCHITECTURE-GAME §4, "modo nulo").

const ENV_URL: String = "BACKEND_URL"
const ENV_SECRET: String = "INTERNAL_SECRET"

var auth: AuthSession

var _api: BackendApi
var _heartbeat: Heartbeat
var _reporter: ResultReporter


## BackendClient montado com as variaveis de ambiente do container (o orquestrador as define);
## null se faltar alguma. O segredo nunca passa por argumento de linha de comando.
static func backend_from_environment(host: Node) -> BackendApi:
	var url := OS.get_environment(ENV_URL)
	var secret := OS.get_environment(ENV_SECRET)
	if url.is_empty() or secret.is_empty():
		return null
	return BackendClient.new(host, url, secret)


## [param api] null = sem backend.
func setup(api: BackendApi) -> void:
	_api = api
	auth = AuthSession.new(api)
	_reporter = ResultReporter.new(api, _wait)
	_heartbeat = Heartbeat.new()
	_heartbeat.name = "Heartbeat"
	add_child(_heartbeat)


func is_online() -> bool:
	return _api != null


## Handshake de um peer (PeerAuth): devolve AuthReply. A primeira conta valida poe a partida em
## `running` no backend, e dai o servidor passa a mandar heartbeat.
func admit(peer: int, token: String) -> String:
	var decision := await auth.admit(peer, token)
	if decision.admitted and is_online() and not _heartbeat.is_running():
		_heartbeat.start(_api, auth.match_id)
	return decision.reply


## Fim da partida: manda o resultado e devolve o codigo de saida do processo.
func report(winner: int, reason: StringName, stats: MatchStats, match_seed: int) -> int:
	_heartbeat.stop()
	if not is_online():
		return ExitCodes.OK
	if auth.match_id.is_empty():
		push_error("[server] partida terminou sem nenhum token validado: nada a reportar")
		return ExitCodes.INTERNAL
	var result := MatchResultBuilder.build(stats, winner, reason, match_seed, auth.users())
	return await _reporter.report(auth.match_id, result)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
