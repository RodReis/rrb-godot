# GERADO por tools/launcher/gen_models.mjs a partir de backend/openapi.json. Nao editar.
class_name MatchTotals
extends RefCounted
## MatchHistoryDto.totals do backend.
## from_dict devolve null se o JSON nao bater com o contrato.

var wins: int = 0
var losses: int = 0


static func from_dict(raw: Variant) -> MatchTotals:
	if not raw is Dictionary:
		return null
	var data: Dictionary = raw
	var model := MatchTotals.new()
	if not data.has("wins"):
		return null
	if (
		not (data["wins"] is float or data["wins"] is int)
		or not is_equal_approx(data["wins"], roundf(data["wins"]))
	):
		return null
	model.wins = int(data["wins"])
	if not data.has("losses"):
		return null
	if (
		not (data["losses"] is float or data["losses"] is int)
		or not is_equal_approx(data["losses"], roundf(data["losses"]))
	):
		return null
	model.losses = int(data["losses"])
	return model
