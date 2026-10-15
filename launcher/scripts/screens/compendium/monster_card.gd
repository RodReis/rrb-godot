class_name MonsterCard
extends PanelContainer
## Card de criatura do Bestiario (prototipo "Guia & Bestiario", F27). Imagem no topo (render do
## modelo real, §8.3 regra 3) com o tier e o XP em selos, nome, os tres numeros de combate num poco
## e as linhas alcance, golpe e drop. O chefe e o card largo: imagem a esquerda (5/12), numeros com
## barra a direita. Tudo sai de MonsterData; o prototipo tem DEF, funcao tatica e dicas que nao
## existem em shared/data e por isso nao entram (§8.3 regras 1 e 2).

const IMAGE_HEIGHT: float = 192.0
## h-1.5 das barras do chefe.
const BAR_HEIGHT: float = 6.0
const BOSS_IMAGE_HEIGHT: float = 288.0
## Imagem do chefe ocupa 5/12 do card; o texto, 7/12 (md:w-5/12 / md:w-7/12).
const BOSS_IMAGE_RATIO: float = 5.0
const BOSS_TEXT_RATIO: float = 7.0
## Altura do degrade que funde a imagem com o card (from-surface-container).
const FADE_HEIGHT: int = 56
## Zoom da imagem com o mouse (group-hover:scale-105, 500 ms).
const ZOOM: float = 1.05
const ZOOM_SECONDS: float = 0.5
const TIER_BADGES: Array[StringName] = [
	&"LnCpBadgeT1", &"LnCpBadgeT2", &"LnCpBadgeT3", &"LnCpBadgeBoss"
]
const GLOW_ALPHA: float = 0.2
## Brilho do chefe (blur-2xl, canto inferior direito): raio do degrade em fracao do card.
const GLOW_RADIUS: float = 0.45

var species: MonsterSpecies
## Nome em minusculas para a busca do cabecalho.
var search_text: String = ""

var _art: TextureRect
var _zoom_tween: Tween


## [param maxima] maiores HP, dano e cadencia do bestiario (as barras do chefe); [param rules] para
## o instante em que o chefe surge.
func bind(group: MonsterSpecies, rules: MatchRules, maxima: Dictionary[StringName, float]) -> void:
	species = group
	var lead := group.lead()
	search_text = lead.display_name.to_lower()
	for member: MonsterData in group.members:
		search_text += " " + member.display_name.to_lower()
	var boss := lead.tier == MonsterData.Tier.BOSS
	theme_type_variation = &"LnCpCardBoss" if boss else &"LnCpCard"
	clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	if boss:
		add_child(_glow())
	if boss:
		var row := HBoxContainer.new()
		row.theme_type_variation = &"LnHGapNone"
		row.add_child(_image_frame(lead, rules, BOSS_IMAGE_HEIGHT, true))
		row.add_child(_boss_text(group, maxima))
		add_child(row)
	else:
		var column := VBoxContainer.new()
		column.theme_type_variation = &"LnVGapNone"
		column.add_child(_image_frame(lead, rules, IMAGE_HEIGHT, false))
		column.add_child(_content(group))
		add_child(column)
	mouse_entered.connect(_set_zoom.bind(true))
	mouse_exited.connect(_set_zoom.bind(false))


func is_zoomed() -> bool:
	return _art != null and _art.scale.x > 1.0


func _image_frame(lead: MonsterData, rules: MatchRules, height: float, boss: bool) -> Control:
	var frame := Control.new()
	frame.custom_minimum_size = Vector2(0.0, height)
	frame.clip_contents = true
	if boss:
		frame.size_flags_horizontal = SIZE_EXPAND_FILL
		frame.size_flags_stretch_ratio = BOSS_IMAGE_RATIO
	_art = TextureRect.new()
	_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_art.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_art.resized.connect(_on_art_resized)
	var texture := CompendiumArt.monster(lead.id)
	if texture != null:
		_art.texture = texture
	else:
		var placeholder := _label(UiIcons.SKULL, &"LnIconMuted")
		placeholder.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
		placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		placeholder.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		frame.add_child(placeholder)
	frame.add_child(_art)
	frame.add_child(_fade(boss))
	var tag := _label(_tier_text(lead, rules, boss), TIER_BADGES[lead.tier] as StringName)
	tag.position = Vector2(UiTokens.SPACE_SM, UiTokens.SPACE_SM)
	frame.add_child(tag)
	if not boss:
		var xp := _label("%s  +%d XP" % [UiIcons.STARS, lead.xp], &"LnCpBadgeXp")
		xp.set_anchors_and_offsets_preset(PRESET_TOP_RIGHT)
		xp.grow_horizontal = GROW_DIRECTION_BEGIN
		xp.offset_top = UiTokens.SPACE_SM
		xp.offset_right = -UiTokens.SPACE_SM
		frame.add_child(xp)
	return frame


## "TIER 1" ou, no chefe, "CHEFE DA ARENA • SURGE ÀS 03:30" (o instante vem de MatchRules).
func _tier_text(lead: MonsterData, rules: MatchRules, boss: bool) -> String:
	if boss:
		return (
			"%s • %s %s"
			% [tr("CHEFE DA ARENA"), tr("SURGE ÀS"), CompendiumFormat.clock(rules.boss_spawn_time)]
		)
	return tr(CompendiumFormat.tier_name(lead.tier)).to_upper()


## Degrade que funde a imagem com o fundo do card: embaixo (card comum) ou na direita (chefe).
func _fade(horizontal: bool) -> TextureRect:
	var gradient := Gradient.new()
	var solid := Color(UiTokens.BG_PANEL, 1.0)
	gradient.offsets = PackedFloat32Array([0.0, 1.0])
	gradient.colors = PackedColorArray([Color(solid, 0.0), solid])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = FADE_HEIGHT if horizontal else 1
	texture.height = 1 if horizontal else FADE_HEIGHT
	texture.fill_from = Vector2.ZERO
	texture.fill_to = Vector2(1.0, 0.0) if horizontal else Vector2(0.0, 1.0)
	var fade := TextureRect.new()
	fade.texture = texture
	fade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fade.stretch_mode = TextureRect.STRETCH_SCALE
	fade.mouse_filter = MOUSE_FILTER_IGNORE
	if horizontal:
		fade.set_anchors_and_offsets_preset(PRESET_RIGHT_WIDE)
		fade.offset_left = -FADE_HEIGHT
	else:
		fade.set_anchors_and_offsets_preset(PRESET_BOTTOM_WIDE)
		fade.offset_top = -FADE_HEIGHT
	return fade


func _glow() -> TextureRect:
	var gradient := Gradient.new()
	var gold := Color(UiTokens.GOLD, GLOW_ALPHA)
	gradient.offsets = PackedFloat32Array([0.0, 1.0])
	gradient.colors = PackedColorArray([gold, Color(gold, 0.0)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2.ONE
	texture.fill_to = Vector2(1.0 - GLOW_RADIUS, 1.0)
	var glow := TextureRect.new()
	glow.texture = texture
	glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glow.stretch_mode = TextureRect.STRETCH_SCALE
	glow.mouse_filter = MOUSE_FILTER_IGNORE
	return glow


func _content(group: MonsterSpecies) -> MarginContainer:
	var lead := group.lead()
	var margin := MarginContainer.new()
	margin.theme_type_variation = &"LnCpInset"
	var column := VBoxContainer.new()
	column.theme_type_variation = &"LnVGapMd"
	margin.add_child(column)
	var title := HBoxContainer.new()
	title.theme_type_variation = &"LnHGapSm"
	var name_label := _label(lead.display_name, &"LnHeadlineMd")
	name_label.uppercase = true
	name_label.size_flags_horizontal = SIZE_EXPAND_FILL
	name_label.clip_text = true
	title.add_child(name_label)
	title.add_child(_label(_count_text(group), &"LnNum"))
	column.add_child(title)
	column.add_child(_stats(lead, false, {}))
	column.add_child(_rows(group))
	return margin


func _boss_text(group: MonsterSpecies, maxima: Dictionary[StringName, float]) -> MarginContainer:
	var lead := group.lead()
	var margin := MarginContainer.new()
	margin.theme_type_variation = &"LnCpInset"
	margin.size_flags_horizontal = SIZE_EXPAND_FILL
	margin.size_flags_stretch_ratio = BOSS_TEXT_RATIO
	var column := VBoxContainer.new()
	column.theme_type_variation = &"LnVGapMd"
	margin.add_child(column)
	var title := HBoxContainer.new()
	title.theme_type_variation = &"LnHGapMd"
	var name_label := _label(lead.display_name, &"LnHeadlineLgGold")
	name_label.uppercase = true
	name_label.size_flags_horizontal = SIZE_EXPAND_FILL
	title.add_child(name_label)
	var reward := VBoxContainer.new()
	reward.theme_type_variation = &"LnVGapNone"
	var xp := _label("+%d XP" % lead.xp, &"LnNumLgGold")
	xp.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	reward.add_child(xp)
	var loot := _label("%s %s" % [tr("Loot:"), CompendiumFormat.drop_text(lead)], &"LnNum")
	loot.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	reward.add_child(loot)
	title.add_child(reward)
	column.add_child(title)
	column.add_child(_stats(lead, true, maxima))
	var spacer := Control.new()
	spacer.size_flags_vertical = SIZE_EXPAND_FILL
	column.add_child(spacer)
	column.add_child(_rows(group))
	return margin


## Poco com HP, dano e cadencia (prototipo: HP / DEFESA / ATAQUE). No chefe cada numero ganha uma
## barra em fracao do maior do bestiario.
func _stats(lead: MonsterData, bars: bool, maxima: Dictionary[StringName, float]) -> PanelContainer:
	var well := PanelContainer.new()
	well.theme_type_variation = &"LnWell"
	var row := HBoxContainer.new()
	row.theme_type_variation = &"LnHGapMd"
	well.add_child(row)
	var cells: Array[Array] = [
		[
			tr("HP MÁX"),
			CompendiumFormat.thousands(roundi(lead.hp)),
			&"LnNumMdCyan",
			&"LnNumLgCyan",
			&"LnCpBarCyan",
			lead.hp / maxima.get(&"hp", lead.hp),
		],
		[
			tr("DANO"),
			CompendiumFormat.thousands(roundi(lead.damage)),
			&"LnNumMdError",
			&"LnNumLgError",
			&"LnCpBarError",
			lead.damage / maxima.get(&"damage", lead.damage),
		],
		[
			tr("CADÊNCIA"),
			"%s s" % CompendiumFormat.decimal(lead.attack_interval),
			&"LnNumMdGold",
			&"LnNumLgGold",
			&"LnCpBarGold",
			(1.0 / lead.attack_interval) / maxima.get(&"rate", 1.0 / lead.attack_interval),
		],
	]
	for cell: Array in cells:
		var box := VBoxContainer.new()
		box.theme_type_variation = &"LnVGapNone"
		box.size_flags_horizontal = SIZE_EXPAND_FILL
		var caption := _label(cell[0], &"LnNum")
		caption.horizontal_alignment = (
			HORIZONTAL_ALIGNMENT_LEFT if bars else HORIZONTAL_ALIGNMENT_CENTER
		)
		box.add_child(caption)
		var value := _label(cell[1], cell[3] if bars else cell[2])
		value.horizontal_alignment = caption.horizontal_alignment
		box.add_child(value)
		if bars:
			var bar := ProgressBar.new()
			bar.theme_type_variation = cell[4]
			bar.show_percentage = false
			bar.max_value = 1.0
			bar.value = cell[5]
			bar.custom_minimum_size.y = BAR_HEIGHT
			bar.mouse_filter = MOUSE_FILTER_IGNORE
			box.add_child(bar)
		row.add_child(box)
	return well


## Linhas "rotulo ........ valor": alcance, golpe e drop (um por variante quando diferem).
func _rows(group: MonsterSpecies) -> VBoxContainer:
	var lead := group.lead()
	var rows := VBoxContainer.new()
	rows.theme_type_variation = &"LnVGapXs"
	rows.add_child(_row(tr("Alcance"), tr(CompendiumFormat.reach_text(lead))))
	rows.add_child(_row(tr("Golpe"), tr(CompendiumFormat.strike_text(lead))))
	var drops: Dictionary[String, String] = {lead.display_name: CompendiumFormat.drop_text(lead)}
	for member: MonsterData in group.members:
		drops[member.display_name] = CompendiumFormat.drop_text(member)
	var distinct := {}
	for text: String in drops.values():
		distinct[text] = true
	if distinct.size() == 1:
		rows.add_child(_row(tr("Drop"), drops.values()[0], true))
	else:
		for member_name: String in drops:
			rows.add_child(_row(member_name, drops[member_name], true))
	return rows


func _row(caption: String, value: String, highlight: bool = false) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.theme_type_variation = &"LnHGapSm"
	var key := _label(caption, &"LnBodySmMuted")
	key.size_flags_horizontal = SIZE_EXPAND_FILL
	key.clip_text = true
	row.add_child(key)
	var text := _label(value, &"LnBodySmGoldMedium" if highlight else &"LnBodySmMedium")
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(text)
	return row


## "4 por partida" (as variantes somadas).
func _count_text(group: MonsterSpecies) -> String:
	return tr("%d por partida") % group.total_count()


func _label(text: String, type: StringName) -> Label:
	var label := Label.new()
	label.theme_type_variation = type
	label.text = text
	return label


func _set_zoom(zoomed: bool) -> void:
	if _art == null:
		return
	if _zoom_tween != null:
		_zoom_tween.kill()
	_zoom_tween = create_tween()
	(
		_zoom_tween
		. tween_property(_art, ^"scale", Vector2.ONE * (ZOOM if zoomed else 1.0), ZOOM_SECONDS)
		. set_ease(Tween.EASE_OUT)
	)


func _on_art_resized() -> void:
	_art.pivot_offset = _art.size / 2.0
