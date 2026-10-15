# GERADO por tools/launcher/gen_models.mjs a partir de backend/openapi.json. Nao editar.
class_name AuthTokens
extends RefCounted
## AuthTokensDto do backend. from_dict devolve null se o JSON nao bater com o contrato.

var access_token: String = ""
var refresh_token: String = ""


static func from_dict(raw: Variant) -> AuthTokens:
	if not raw is Dictionary:
		return null
	var data: Dictionary = raw
	var model := AuthTokens.new()
	if not data.has("accessToken"):
		return null
	if not data["accessToken"] is String:
		return null
	model.access_token = data["accessToken"]
	if not data.has("refreshToken"):
		return null
	if not data["refreshToken"] is String:
		return null
	model.refresh_token = data["refreshToken"]
	return model
