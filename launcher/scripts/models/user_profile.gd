# GERADO por tools/launcher/gen_models.mjs a partir de backend/openapi.json. Nao editar.
class_name UserProfile
extends RefCounted
## UserProfileDto do backend.
## from_dict devolve null se o JSON nao bater com o contrato.

var id: String = ""
var email: String = ""
var created_at: String = ""


static func from_dict(raw: Variant) -> UserProfile:
	if not raw is Dictionary:
		return null
	var data: Dictionary = raw
	var model := UserProfile.new()
	if not data.has("id"):
		return null
	if not data["id"] is String:
		return null
	model.id = data["id"]
	if not data.has("email"):
		return null
	if not data["email"] is String:
		return null
	model.email = data["email"]
	if not data.has("createdAt"):
		return null
	if not data["createdAt"] is String:
		return null
	model.created_at = data["createdAt"]
	return model
