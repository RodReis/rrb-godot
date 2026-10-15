# GERADO por tools/launcher/gen_models.mjs a partir de backend/openapi.json. Nao editar.
class_name TicketStatus
extends RefCounted
## TicketStatusDto do backend.
## from_dict devolve null se o JSON nao bater com o contrato.

var status: String = ""
var elapsed_s: int = 0
## Opcional: fica com o valor inicial quando nao vem.
var match_id: String = ""
## Opcional: fica com o valor inicial quando nao vem.
var assignment: MatchAssignment = null


static func from_dict(raw: Variant) -> TicketStatus:
	if not raw is Dictionary:
		return null
	var data: Dictionary = raw
	var model := TicketStatus.new()
	if not data.has("status"):
		return null
	if not data["status"] is String:
		return null
	if not data["status"] in ["searching", "matched", "cancelled"]:
		return null
	model.status = data["status"]
	if not data.has("elapsedS"):
		return null
	if (
		not (data["elapsedS"] is float or data["elapsedS"] is int)
		or not is_equal_approx(data["elapsedS"], roundf(data["elapsedS"]))
	):
		return null
	model.elapsed_s = int(data["elapsedS"])
	if data.get("matchId") != null:
		if not data["matchId"] is String:
			return null
		model.match_id = data["matchId"]
	if data.get("assignment") != null:
		model.assignment = MatchAssignment.from_dict(data["assignment"])
		if model.assignment == null:
			return null
	return model
