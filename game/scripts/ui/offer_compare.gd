class_name OfferCompare
extends RefCounted
## Texto da comparacao do card do bau (SPEC-047 §3): atributos do item do bau contra o equipado
## no mesmo slot e contagem dos conjuntos antes -> depois. Funcoes puras; so exibicao, o servidor
## decide a troca (ItemRules.offer).


## Um atributo: [member value] do item do bau e [member delta] contra o equipado (0 = igual).
class Row:
	extends RefCounted
	var label: String = ""
	var value: int = 0
	var delta: int = 0
	var percent: bool = false

	func _init(p_label: String, p_value: int, p_delta: int, p_percent: bool = false) -> void:
		label = p_label
		value = p_value
		delta = p_delta
		percent = p_percent


## Atributos planos e a AGI percentual que o item do bau ou o equipado tem (equipado pode ser nulo).
static func rows(current: ItemData, incoming: ItemData) -> Array[Row]:
	var result: Array[Row] = []
	for stat: StringName in ItemTooltip.STAT_LABELS:
		var value := roundi(incoming.get(stat) as float)
		var old := 0 if current == null else roundi(current.get(stat) as float)
		if value != 0 or old != 0:
			result.append(Row.new(ItemTooltip.STAT_LABELS[stat], value, value - old))
	var pct := roundi(incoming.agility_pct * ItemTooltip.PERCENT)
	var old_pct := 0 if current == null else roundi(current.agility_pct * ItemTooltip.PERCENT)
	if pct != 0 or old_pct != 0:
		result.append(Row.new("AGI", pct, pct - old_pct, true))
	return result


## "Guarda 2/3 -> 1/3 · Cacador 1/3 -> 2/3": so os conjuntos cuja contagem muda; vazio se nenhum.
static func set_change(equipment: Vector4i, incoming: ItemData, catalog: ItemCatalog) -> String:
	var before := Inventory.items(equipment, catalog)
	var after := Inventory.items(Inventory.equip(equipment, incoming), catalog)
	var parts := PackedStringArray()
	for bonus: SetBonusData in catalog.set_bonuses:
		var was := SetBonus.count_pieces(before, bonus.set_id)
		var now := SetBonus.count_pieces(after, bonus.set_id)
		if was != now:
			var text := "%s %d/%d → %d/%d"
			parts.append(
				text % [bonus.display_name, was, bonus.pieces_required, now, bonus.pieces_required]
			)
	return " · ".join(parts)


## "+7" / "−3" (sinal de menos tipografico); vazio se igual.
static func delta_text(row: Row) -> String:
	if row.delta == 0:
		return ""
	var sign_text := "+" if row.delta > 0 else "−"
	return "%s%d%s" % [sign_text, absi(row.delta), "%" if row.percent else ""]
