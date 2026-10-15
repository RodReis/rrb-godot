class_name WeaponCard
extends PanelContainer
## Card de arma universal da Forja (prototipo "Equipamentos & Forja"): icone da arma de dois herois
## de classes diferentes sobre o poco escuro, selo de tier e raridade, nome, bonus de ataque, a
## passiva (se houver) e onde a arma aparece, com as chances de MatchRules. As tres armas sao a
## mesma para todos os herois (GDB §6.2); so o modelo 3D muda com a classe.

const IMAGE_HEIGHT: float = 128.0
const ICON_SIZE: Vector2 = Vector2(96, 96)
## Indice = ItemData.Rarity.
const TIER_BADGES: Array[StringName] = [&"LnCpBadgeT1", &"LnCpBadgeT2", &"LnCpBadgeT3"]

var item: ItemData
var search_text: String = ""


## [param hero_ids] herois cujos icones de arma aparecem lado a lado.
func bind(
	weapon: ItemData, rules: MatchRules, boss: MonsterData, hero_ids: Array[StringName]
) -> void:
	item = weapon
	var stats := CompendiumFormat.item_stats(weapon)
	search_text = (
		("%s %s %s" % [weapon.display_name, " ".join(stats), CompendiumFormat.passive_text(weapon)])
		. to_lower()
	)
	theme_type_variation = &"LnCpCard"
	clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	var column := VBoxContainer.new()
	column.theme_type_variation = &"LnVGapNone"
	add_child(column)
	column.add_child(_image_frame(weapon, hero_ids))
	column.add_child(_content(weapon, stats, rules, boss))


func _image_frame(weapon: ItemData, hero_ids: Array[StringName]) -> Control:
	var frame := PanelContainer.new()
	frame.theme_type_variation = &"LnCpWell"
	frame.custom_minimum_size = Vector2(0.0, IMAGE_HEIGHT)
	var row := HBoxContainer.new()
	row.theme_type_variation = &"LnHGapLg"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	frame.add_child(row)
	for hero_id: StringName in hero_ids:
		var image := TextureRect.new()
		image.texture = CompendiumArt.item(weapon, hero_id)
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		image.custom_minimum_size = ICON_SIZE
		row.add_child(image)
	var overlay := MarginContainer.new()
	overlay.theme_type_variation = &"LnCpTagMargin"
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tag := Label.new()
	tag.theme_type_variation = TIER_BADGES[weapon.rarity]
	tag.text = (
		"%s %d • %s"
		% [
			tr("TIER"),
			weapon.rarity + 1,
			tr(CompendiumFormat.rarity_name(weapon.rarity)).to_upper(),
		]
	)
	tag.size_flags_horizontal = SIZE_SHRINK_BEGIN
	tag.size_flags_vertical = SIZE_SHRINK_BEGIN
	overlay.add_child(tag)
	frame.add_child(overlay)
	return frame


func _content(
	weapon: ItemData, stats: PackedStringArray, rules: MatchRules, boss: MonsterData
) -> MarginContainer:
	var margin := MarginContainer.new()
	margin.theme_type_variation = &"LnCpInset"
	var column := VBoxContainer.new()
	column.theme_type_variation = &"LnVGapMd"
	margin.add_child(column)
	var title := _label(weapon.display_name, &"LnHeadlineMd")
	title.uppercase = true
	column.add_child(title)
	var well := PanelContainer.new()
	well.theme_type_variation = &"LnWell"
	var row := HBoxContainer.new()
	row.theme_type_variation = &"LnHGapMd"
	well.add_child(row)
	var caption := _label(tr("BÔNUS DE ATAQUE"), &"LnNum")
	caption.size_flags_horizontal = SIZE_EXPAND_FILL
	row.add_child(caption)
	row.add_child(_label(stats[0], &"LnNumLgGold"))
	column.add_child(well)
	var passive := CompendiumFormat.passive_text(weapon)
	if not passive.is_empty():
		column.add_child(_note(UiIcons.BOLT, passive, &"LnBodySmCyan"))
	column.add_child(
		_note(
			UiIcons.INVENTORY_2,
			tr(CompendiumFormat.chest_sources(weapon.rarity, rules, boss)),
			&"LnBodySmMuted"
		)
	)
	return margin


func _note(icon: String, text: String, type: StringName) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.theme_type_variation = &"LnHGapXs"
	var glyph := _label(icon, &"LnIconSmCyan")
	glyph.size_flags_vertical = SIZE_SHRINK_BEGIN
	row.add_child(glyph)
	var label := _label(text, type)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = SIZE_EXPAND_FILL
	row.add_child(label)
	return row


func _label(text: String, type: StringName) -> Label:
	var label := Label.new()
	label.theme_type_variation = type
	label.text = text
	return label
