class_name HeroDetail
extends PanelContainer
## Painel do heroi escolhido (F71; prototipo "Tela Herois", coluna da direita): retrato grande com
## classe e nome, papel curto, arma e alcance, atributos nos niveis 1 e 10 com barra e as 4
## habilidades com icone, tecla, nome e descricao. Tudo sai de HeroData/SkillData pelo
## HeroesFormat (GDB vence o prototipo, §8.3 regra 2). Fora do prototipo: epiteto, lore, nivel,
## builds, skins e "testar no treino" (sem requisito, §8.3 regra 1).

const BANNER_HEIGHT: float = 300.0
## Faixa de baixo do banner, reservada a classe e ao nome; o retrato inteiro fica acima dela.
const CAPTION_HEIGHT: float = 68.0
const SKILL_ICON: Vector2 = Vector2(56, 56)
const BAR_HEIGHT: float = 6.0
## Seta entre o valor do nivel 1 e o do nivel 10.
const ARROW: String = "→"

var hero: HeroData

var _content: VBoxContainer = VBoxContainer.new()


func _init() -> void:
	theme_type_variation = &"LnHeroSide"
	_content.theme_type_variation = &"LnVGapMd"
	add_child(_content)


## Mostra [param data]; [param maxima] e a escala das barras (HeroesFormat.maxima).
func bind(data: HeroData, maxima: Dictionary[StringName, float]) -> void:
	hero = data
	for child: Node in _content.get_children():
		_content.remove_child(child)
		child.queue_free()
	_content.add_child(_banner(data))
	_content.add_child(_label(data.summary, &"LnBodyMuted", true))
	_content.add_child(_tiles(data))
	var levels := (
		"%s %s %s" % [_level(HeroesFormat.LEVEL_LOW), ARROW, _level(HeroesFormat.LEVEL_HIGH)]
	)
	_content.add_child(_section(tr("ATRIBUTOS"), levels))
	_content.add_child(_stats(data, maxima))
	_content.add_child(_section(tr("HABILIDADES DE COMBATE"), ""))
	_content.add_child(_skills(data))


func _banner(data: HeroData) -> Control:
	var frame := Control.new()
	frame.custom_minimum_size = Vector2(0.0, BANNER_HEIGHT)
	frame.clip_contents = true
	var art := TextureRect.new()
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	# Corpo inteiro sem corte: o fundo do render e o BG_LOW do painel, entao a borda some.
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	art.offset_bottom = -CAPTION_HEIGHT
	art.texture = HeroesFormat.portrait(data.id)
	frame.add_child(art)
	var caption := VBoxContainer.new()
	caption.theme_type_variation = &"LnVGapXs"
	caption.set_anchors_and_offsets_preset(PRESET_BOTTOM_WIDE)
	caption.grow_vertical = GROW_DIRECTION_BEGIN
	caption.offset_left = UiTokens.SPACE_MD
	caption.offset_right = -UiTokens.SPACE_MD
	caption.offset_bottom = -UiTokens.SPACE_SM
	var kicker := _label(
		"%s  %s" % [HeroesFormat.class_icon(data.role), data.role], &"LnNumGold", false
	)
	kicker.uppercase = true
	caption.add_child(kicker)
	var title := _label(data.display_name, &"LnHeadlineLg", false)
	title.uppercase = true
	caption.add_child(title)
	frame.add_child(caption)
	return frame


## ARMA e ALCANCE (do ataque basico), os dois ladrilhos do prototipo que existem em shared/data.
func _tiles(data: HeroData) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.theme_type_variation = &"LnHGapSm"
	row.add_child(_tile(tr("ARMA"), data.weapon_name))
	var reach := "%s u" % CompendiumFormat.decimal(data.basic_attack.attack_range)
	row.add_child(_tile(tr("ALCANCE"), reach))
	return row


func _tile(caption: String, value: String) -> PanelContainer:
	var tile := PanelContainer.new()
	tile.theme_type_variation = &"LnCpTile"
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var column := VBoxContainer.new()
	column.theme_type_variation = &"LnVGapNone"
	tile.add_child(column)
	column.add_child(_label(caption, &"LnNum", false))
	column.add_child(_label(value, &"LnHeadlineSmGold", false))
	return tile


func _section(title: String, aside: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.theme_type_variation = &"LnHGapMd"
	var heading := _label(title, &"LnHeadlineSmGold", false)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(heading)
	if not aside.is_empty():
		row.add_child(_label(aside, &"LnNum", false))
	return row


func _level(level: int) -> String:
	return "%s %d" % [tr("NV"), level]


func _stats(data: HeroData, maxima: Dictionary[StringName, float]) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.theme_type_variation = &"LnVGapSm"
	for row: HeroesFormat.StatRow in HeroesFormat.stat_rows(data):
		column.add_child(_stat(row, maxima.get(row.id, row.high)))
	return column


func _stat(row: HeroesFormat.StatRow, full_scale: float) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.theme_type_variation = &"LnVGapXs"
	var line := HBoxContainer.new()
	line.theme_type_variation = &"LnHGapSm"
	var name_label := _label(tr(row.label), &"LnBodySmMuted", false)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(name_label)
	var values := (
		"%s %s %s" % [HeroesFormat.value_text(row.low), ARROW, HeroesFormat.value_text(row.high)]
	)
	line.add_child(_label(values, &"LnNumMd", false))
	box.add_child(line)
	box.add_child(_bars(row, full_scale))
	return box


## Duas barras sobrepostas: o nivel 10 apagado atras, o nivel 1 aceso na frente.
func _bars(row: HeroesFormat.StatRow, full_scale: float) -> Control:
	var stack := Control.new()
	stack.custom_minimum_size = Vector2(0.0, BAR_HEIGHT)
	for spec: Array in [[&"LnHeroBarHigh", row.high], [&"LnHeroBarLow", row.low]]:
		var bar := ProgressBar.new()
		bar.theme_type_variation = spec[0]
		bar.show_percentage = false
		bar.max_value = 1.0
		bar.value = float(spec[1]) / full_scale
		bar.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stack.add_child(bar)
	return stack


func _skills(data: HeroData) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.theme_type_variation = &"LnVGapMd"
	for slot: HeroesFormat.SkillSlot in HeroesFormat.skill_slots(data):
		column.add_child(_skill(slot))
	return column


func _skill(slot: HeroesFormat.SkillSlot) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.theme_type_variation = &"LnHGapMd"
	var box := PanelContainer.new()
	box.theme_type_variation = &"LnIconBoxGold" if slot.ultimate else &"LnCpIconBox"
	box.custom_minimum_size = SKILL_ICON
	box.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var art := TextureRect.new()
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.texture = slot.skill.icon
	box.add_child(art)
	row.add_child(box)
	var text := VBoxContainer.new()
	text.theme_type_variation = &"LnVGapXs"
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var head := HBoxContainer.new()
	head.theme_type_variation = &"LnHGapSm"
	var skill_name := _label(slot.skill.display_name, &"LnHeadlineSm", false)
	skill_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(skill_name)
	var key := _label(slot.key, &"LnKeyLabel", false)
	key.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(key)
	text.add_child(head)
	text.add_child(_label(slot.skill.description, &"LnBodySmMuted", true))
	row.add_child(text)
	return row


func _label(text: String, type: StringName, wrap: bool) -> Label:
	var label := Label.new()
	label.theme_type_variation = type
	label.text = text
	if wrap:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label
