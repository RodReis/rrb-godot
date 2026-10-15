class_name SetPanel
extends PanelContainer
## Painel de conjunto da Forja (prototipo "Equipamentos & Forja"): nome e "3/3 pecas", o efeito
## sinergico do conjunto completo e uma linha por slot com o que cada raridade soma. Tudo de
## shared/data: o conjunto vem de SetBonusData, as pecas de ItemData (§8.3). O prototipo traz
## "recomendado para", papel e totais de exemplo, que nao existem nos dados e nao entram.

const ICON_BOX: Vector2 = Vector2(48, 48)
const ITEM_ICON: Vector2 = Vector2(40, 40)
## Tipo do Label da linha de cada raridade (indice = ItemData.Rarity): comum apagada, rara ciano,
## epica dourada — a raridade tambem vai por extenso no texto (nunca so cor, FRONTEND §5).
const RARITY_LINE_TYPES: Array[StringName] = [
	&"LnBodySmMuted", &"LnBodySmCyan", &"LnBodySmGoldMedium"
]

var bonus: SetBonusData
## Pecas do conjunto, por slot (Elmo, Peitoral, Botas), cada uma com o texto que a busca olha.
var rows: Array[SetRow] = []


## Uma linha de slot: as pecas do slot (uma por raridade) e o texto da busca.
class SetRow:
	extends RefCounted
	var panel: Control
	var items: Array[ItemData] = []
	var search_text: String = ""


func bind(set_bonus: SetBonusData, set_items: Array[ItemData]) -> void:
	bonus = set_bonus
	theme_type_variation = &"LnCpPanel"
	size_flags_horizontal = SIZE_EXPAND_FILL
	var column := VBoxContainer.new()
	column.theme_type_variation = &"LnVGapMd"
	add_child(column)
	column.add_child(_head(set_bonus))
	column.add_child(_effect(set_bonus))
	for slot: int in ItemData.Slot.values():
		var in_slot := set_items.filter(func(item: ItemData) -> bool: return item.slot == slot)
		if in_slot.is_empty():
			continue
		var row := SetRow.new()
		row.items.assign(in_slot)
		row.panel = _slot_row(row.items)
		row.search_text = _search_text(set_bonus, row.items)
		rows.append(row)
		column.add_child(row.panel)


## O conjunto tem alguma peca que passa na busca ([param needle] em minusculas, vazio = todas)?
func apply_search(needle: String) -> int:
	var shown := 0
	for row: SetRow in rows:
		row.panel.visible = needle.is_empty() or needle in row.search_text
		shown += int(row.panel.visible)
	return shown


func _head(set_bonus: SetBonusData) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.theme_type_variation = &"LnHGapMd"
	var box := PanelContainer.new()
	box.theme_type_variation = &"LnCpIconBox"
	box.custom_minimum_size = ICON_BOX
	var glyph := _label(_set_icon(set_bonus), &"LnIconMdGold")
	glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	box.add_child(glyph)
	row.add_child(box)
	var names := VBoxContainer.new()
	names.theme_type_variation = &"LnVGapNone"
	names.size_flags_horizontal = SIZE_EXPAND_FILL
	names.add_child(_label(tr("CONJUNTO DE ARMADURA"), &"LnNum"))
	var title := _label(tr("Set da %s") % set_bonus.display_name, &"LnHeadlineLg")
	title.uppercase = true
	names.add_child(title)
	row.add_child(names)
	var pieces := _label(
		"%d/%d %s" % [set_bonus.pieces_required, set_bonus.pieces_required, tr("PEÇAS")],
		&"LnCpBadgeSet"
	)
	pieces.size_flags_vertical = SIZE_SHRINK_BEGIN
	row.add_child(pieces)
	return row


## Efeito do conjunto completo: o que SetBonusData soma.
func _effect(set_bonus: SetBonusData) -> PanelContainer:
	var well := PanelContainer.new()
	well.theme_type_variation = &"LnCpEffect"
	var column := VBoxContainer.new()
	column.theme_type_variation = &"LnVGapXs"
	var kicker := _label(
		tr("EFEITO SINÉRGICO DE %d PEÇAS") % set_bonus.pieces_required, &"LnNumGold"
	)
	column.add_child(kicker)
	var text := _label(CompendiumFormat.bonus_text(set_bonus), &"LnHeadlineSm")
	text.uppercase = true
	column.add_child(text)
	well.add_child(column)
	return well


## Slot: icone da peca epica, nome, slot e, a direita, uma linha por raridade.
func _slot_row(slot_items: Array[ItemData]) -> PanelContainer:
	var best: ItemData = slot_items.back()
	var tile := PanelContainer.new()
	tile.theme_type_variation = &"LnCpTile"
	var row := HBoxContainer.new()
	row.theme_type_variation = &"LnHGapMd"
	tile.add_child(row)
	var box := PanelContainer.new()
	box.theme_type_variation = &"LnCpIconBox"
	box.custom_minimum_size = ITEM_ICON + Vector2.ONE * UiTokens.SPACE_SM * 2.0
	box.size_flags_vertical = SIZE_SHRINK_CENTER
	var image := TextureRect.new()
	image.texture = CompendiumArt.item(best)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.custom_minimum_size = ITEM_ICON
	box.add_child(image)
	row.add_child(box)
	var names := VBoxContainer.new()
	names.theme_type_variation = &"LnVGapNone"
	names.size_flags_horizontal = SIZE_EXPAND_FILL
	names.size_flags_vertical = SIZE_SHRINK_CENTER
	var title := _label(best.display_name, &"LnHeadlineSm")
	title.uppercase = true
	names.add_child(title)
	names.add_child(_label(tr(CompendiumFormat.slot_name(best.slot)), &"LnBodySmMuted"))
	row.add_child(names)
	var lines := VBoxContainer.new()
	lines.theme_type_variation = &"LnVGapNone"
	lines.size_flags_vertical = SIZE_SHRINK_CENTER
	for item: ItemData in slot_items:
		var line := _label(
			(
				"%s: %s"
				% [
					tr(CompendiumFormat.rarity_name(item.rarity)),
					", ".join(CompendiumFormat.item_stats(item))
				]
			),
			RARITY_LINE_TYPES[item.rarity]
		)
		line.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		lines.add_child(line)
	row.add_child(lines)
	return tile


## Escudo para o conjunto de vida e defesa, velocidade para os de velocidade.
func _set_icon(set_bonus: SetBonusData) -> String:
	if set_bonus.max_hp_pct > 0.0 or set_bonus.defense > 0.0:
		return UiIcons.SHIELD
	return UiIcons.SPEED


func _search_text(set_bonus: SetBonusData, slot_items: Array[ItemData]) -> String:
	var text := set_bonus.display_name.to_lower()
	for item: ItemData in slot_items:
		text += (
			" %s %s"
			% [item.display_name.to_lower(), " ".join(CompendiumFormat.item_stats(item)).to_lower()]
		)
	return text


func _label(text: String, type: StringName) -> Label:
	var label := Label.new()
	label.theme_type_variation = type
	label.text = text
	return label
