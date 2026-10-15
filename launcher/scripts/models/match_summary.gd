# GERADO por tools/launcher/gen_models.mjs a partir de backend/openapi.json. Nao editar.
class_name MatchSummary
extends RefCounted
## MatchHistoryDto.matches do backend.
## from_dict devolve null se o JSON nao bater com o contrato.

var match_id: String = ""
var result: String = ""
var played_at: String = ""
var end_reason: String = ""
var duration_s: int = -1
var me: MatchMine = null
var opponent: MatchOpponent = null


static func from_dict(raw: Variant) -> MatchSummary:
	if not raw is Dictionary:
		return null
	var data: Dictionary = raw
	var model := MatchSummary.new()
	if not data.has("matchId"):
		return null
	if not data["matchId"] is String:
		return null
	model.match_id = data["matchId"]
	if not data.has("result"):
		return null
	if not data["result"] is String:
		return null
	if not data["result"] in ["win", "loss", "interrupted"]:
		return null
	model.result = data["result"]
	if not data.has("playedAt"):
		return null
	if not data["playedAt"] is String:
		return null
	model.played_at = data["playedAt"]
	if not data.has("endReason"):
		return null
	if data["endReason"] != null:
		if not data["endReason"] is String:
			return null
		model.end_reason = data["endReason"]
	if not data.has("durationS"):
		return null
	if data["durationS"] != null:
		if (
			not (data["durationS"] is float or data["durationS"] is int)
			or not is_equal_approx(data["durationS"], roundf(data["durationS"]))
		):
			return null
		model.duration_s = int(data["durationS"])
	if not data.has("me"):
		return null
	model.me = MatchMine.from_dict(data["me"])
	if model.me == null:
		return null
	if not data.has("opponent"):
		return null
	model.opponent = MatchOpponent.from_dict(data["opponent"])
	if model.opponent == null:
		return null
	return model
