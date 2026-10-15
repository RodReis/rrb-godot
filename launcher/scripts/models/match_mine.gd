# GERADO por tools/launcher/gen_models.mjs a partir de backend/openapi.json. Nao editar.
class_name MatchMine
extends RefCounted
## MatchHistoryDto.matches.me do backend.
## from_dict devolve null se o JSON nao bater com o contrato.

var hero_id: String = ""
var kills: int = 0
var final_level: int = 0
var deaths: int = 0
var boss_kill: bool = false
var set_active: String = ""


static func from_dict(raw: Variant) -> MatchMine:
	if not raw is Dictionary:
		return null
	var data: Dictionary = raw
	var model := MatchMine.new()
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
	if not data.has("deaths"):
		return null
	if (
		not (data["deaths"] is float or data["deaths"] is int)
		or not is_equal_approx(data["deaths"], roundf(data["deaths"]))
	):
		return null
	model.deaths = int(data["deaths"])
	if not data.has("bossKill"):
		return null
	if not data["bossKill"] is bool:
		return null
	model.boss_kill = data["bossKill"]
	if not data.has("setActive"):
		return null
	if data["setActive"] != null:
		if not data["setActive"] is String:
			return null
		model.set_active = data["setActive"]
	return model
