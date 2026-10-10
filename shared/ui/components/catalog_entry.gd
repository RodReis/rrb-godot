class_name CatalogEntry
extends RefCounted
## Item de uma CatalogList: id devolvido no sinal, titulo e etiqueta curta (tier, raridade).

var id: StringName
var title: String
var tag: String


func _init(p_id: StringName = &"", p_title: String = "", p_tag: String = "") -> void:
	id = p_id
	title = p_title
	tag = p_tag
