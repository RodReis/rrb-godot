# GERADO por tools/launcher/gen_models.mjs a partir de backend/openapi.json. Nao editar.
class_name QueueTicket
extends RefCounted
## QueueTicketDto do backend.
## from_dict devolve null se o JSON nao bater com o contrato.

var id: String = ""
var status: String = ""
var created_at: String = ""


static func from_dict(raw: Variant) -> QueueTicket:
	if not raw is Dictionary:
		return null
	var data: Dictionary = raw
	var model := QueueTicket.new()
	if not data.has("id"):
		return null
	if not data["id"] is String:
		return null
	model.id = data["id"]
	if not data.has("status"):
		return null
	if not data["status"] is String:
		return null
	if not data["status"] in ["searching"]:
		return null
	model.status = data["status"]
	if not data.has("createdAt"):
		return null
	if not data["createdAt"] is String:
		return null
	model.created_at = data["createdAt"]
	return model
