class_name AuthReply
extends RefCounted
## Resposta do servidor ao token do cliente no handshake (PeerAuth), e o codigo de saida que o
## cliente usa quando nao entra (ARCHITECTURE-GAME §6: token invalido -> codigo 2).

const OK: String = "ok"
## O backend recusou o token (invalido, expirado, de partida encerrada, conta repetida).
const DENIED: String = "denied"
## O servidor nao conseguiu decidir (backend fora do ar, resposta sem sentido).
const ERROR: String = "error"


## Recusa e autenticacao (2); servidor sem condicoes de decidir e erro interno (4).
static func exit_code_for(reply: String) -> int:
	return ExitCodes.AUTH if reply == DENIED else ExitCodes.INTERNAL
