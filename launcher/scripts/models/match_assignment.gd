# GERADO por tools/launcher/gen_models.mjs a partir de backend/openapi.json. Nao editar.
class_name MatchAssignment
extends RefCounted
## TicketStatusDto.assignment do backend.
## from_dict devolve null se o JSON nao bater com o contrato.

var host: String = ""
var port: int = 0
var token: String = ""


static func from_dict(raw: Variant) -> MatchAssignment:
	if not raw is Dictionary:
		return null
	var data: Dictionary = raw
	var model := MatchAssignment.new()
	if not data.has("host"):
		return null
	if not data["host"] is String:
		return null
	model.host = data["host"]
	if not data.has("port"):
		return null
	if (
		not (data["port"] is float or data["port"] is int)
		or not is_equal_approx(data["port"], roundf(data["port"]))
	):
		return null
	model.port = int(data["port"])
	if not data.has("token"):
		return null
	if not data["token"] is String:
		return null
	model.token = data["token"]
	return model
