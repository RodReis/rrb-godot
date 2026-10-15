class_name MatchToken
extends RefCounted
## Le o match_id do match_token (JWT do backend, ARCHITECTURE-LAUNCHER §4.2) so para montar a URL
## de validacao. O servidor NAO confia no que le aqui: assinatura, validade e dono quem confere e
## o backend (POST /internal/matches/:id/validate). Como o id vira caminho de URL e nome de
## arquivo, so um UUID bem formado passa.

## Mesmo teto do backend (ValidateSchema): maior que isso nem e enviado.
const MAX_LENGTH: int = 2048
## Cabecalho, corpo e assinatura.
const PARTS: int = 3
const PAYLOAD_INDEX: int = 1
const BASE64_BLOCK: int = 4
## base64url (RFC 7515): so estes caracteres, senao o decodificador do motor loga erro.
const BASE64URL_PATTERN: String = "^[A-Za-z0-9_-]+$"
## O $ do PCRE casa antes de um \n final; o comprimento fixo fecha essa brecha.
const UUID_LENGTH: int = 36
const UUID_PATTERN: String = "^[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}$"


## "" se o token nao e um JWT com um match_id em forma de UUID.
static func match_id(token: String) -> String:
	if token.is_empty() or token.length() > MAX_LENGTH:
		return ""
	var parts := token.split(".")
	if parts.size() != PARTS:
		return ""
	var payload_part := parts[PAYLOAD_INDEX]
	# Comprimento 4n+1 nao existe em base64 (o decodificador do motor loga erro).
	var valid_length := payload_part.length() % BASE64_BLOCK != 1
	if not valid_length or RegEx.create_from_string(BASE64URL_PATTERN).search(payload_part) == null:
		return ""
	var parser := JSON.new()  # parse_string loga erro no motor quando o texto nao e JSON
	var text := Marshalls.base64_to_utf8(_standard_base64(payload_part))
	if parser.parse(text) != OK or not parser.data is Dictionary:
		return ""
	var id: Variant = (parser.data as Dictionary).get("match_id")
	var well_formed: bool = (
		id is String
		and (id as String).length() == UUID_LENGTH
		and RegEx.create_from_string(UUID_PATTERN).search(id) != null
	)
	if well_formed:
		return id
	return ""


## JWT usa base64url sem preenchimento; o Marshalls quer o base64 comum, com "=".
static func _standard_base64(text: String) -> String:
	var standard := text.replace("-", "+").replace("_", "/")
	while standard.length() % BASE64_BLOCK != 0:
		standard += "="
	return standard
