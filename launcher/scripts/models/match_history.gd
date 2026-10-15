# GERADO por tools/launcher/gen_models.mjs a partir de backend/openapi.json. Nao editar.
class_name MatchHistory
extends RefCounted
## MatchHistoryDto do backend.
## from_dict devolve null se o JSON nao bater com o contrato.

var totals: MatchTotals = null
var matches: Array[MatchSummary] = []


static func from_dict(raw: Variant) -> MatchHistory:
	if not raw is Dictionary:
		return null
	var data: Dictionary = raw
	var model := MatchHistory.new()
	if not data.has("totals"):
		return null
	model.totals = MatchTotals.from_dict(data["totals"])
	if model.totals == null:
		return null
	if not data.has("matches"):
		return null
	if not data["matches"] is Array:
		return null
	for entry: Variant in data["matches"]:
		var parsed := MatchSummary.from_dict(entry)
		if parsed == null:
			return null
		model.matches.append(parsed)
	return model
