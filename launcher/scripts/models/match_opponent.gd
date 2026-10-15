# GERADO por tools/launcher/gen_models.mjs a partir de backend/openapi.json. Nao editar.
class_name MatchOpponent
extends RefCounted
## MatchHistoryDto.matches.opponent do backend.
## from_dict devolve null se o JSON nao bater com o contrato.

var hero_id: String = ""
var kills: int = 0
var final_level: int = 0


static func from_dict(raw: Variant) -> MatchOpponent:
	if not raw is Dictionary:
		return null
	var data: Dictionary = raw
	var model := MatchOpponent.new()
	if not data.has("heroId"):
		return null
	if data["heroId"] != null:
		if not data["heroId"] is String:
			return null
		model.hero_id = data["heroId"]
	if not data.has("kills"):
		return null
	if (
		not (data["kills"] is float or data["kills"] is int)
		or not is_equal_approx(data["kills"], roundf(data["kills"]))
	):
		return null
	model.kills = int(data["kills"])
	if not data.has("finalLevel"):
		return null
	if (
		not (data["finalLevel"] is float or data["finalLevel"] is int)
		or not is_equal_approx(data["finalLevel"], roundf(data["finalLevel"]))
	):
		return null
	model.final_level = int(data["finalLevel"])
	return model
