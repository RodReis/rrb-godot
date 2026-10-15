class_name ForgeSimulator
extends PanelContainer
## Simulador de atributos e mitigacao da Forja (V-06; prototipo "Equipamentos & Forja"). Escolhe o
## heroi, o nivel e ate um item por slot; os atributos finais, o bonus de conjunto e a mitigacao
## saem de shared/core pelo ForgeBuild — a mesma conta do servidor (I5). Nenhum numero e escrito
## aqui: ate a formula do cabecalho e montada com Stats.DEFENSE_SCALE.

const ICON_SIZE: Vector2 = Vector2(48, 48)
const NONE_TEXT: String = "—"
## Dano bruto de exemplo da linha "X de dano bruto -> Y de dano recebido": a escala da formula.
const SAMPLE_RAW_DAMAGE: float = Stats.DEFENSE_SCALE
const LEVEL_BUTTON_WIDTH: float = 40.0
## Item do botao (sem a chave = "sem item").
const ITEM_META: StringName = &"item"

var build: ForgeBuild

var _catalog: CatalogService
var _hero_chips: Dictionary[StringName, FilterChip] = {}
var _level_value: Label = Label.new()
var _level_down: Button = Button.new()
var _level_up: Button = Button.new()
var _pickers: Dictionary[ItemData.Slot, Array] = {}
var _groups: Dictionary[ItemData.Slot, ButtonGroup] = {}
var _weapon_summary: Label = Label.new()
var _set_lines: VBoxContainer = VBoxContainer.new()
var _defense: Label = Label.new()
var _absorb_value: Label = Label.new()
var _absorb_bar: ProgressBar = ProgressBar.new()
var _sample: Label = Label.new()
var _hp: Label = Label.new()
var _sustain: Label = Label.new()
var _stat_cells: Dictionary[StringName, Label] = {}


func bind(catalog: CatalogService) -> void:
	_catalog = catalog
	build = ForgeBuild.new(catalog.heroes[0], XpTable.max_level(catalog.xp_curve))
	theme_type_variation = &"LnCpPanel"
	size_flags_horizontal = SIZE_EXPAND_FILL
	var column := VBoxContainer.new()
	column.theme_type_variation = &"LnVGapLg"
	add_child(column)
	column.add_child(_head())
	var body := HBoxContainer.new()
	body.theme_type_variation = &"LnHGapMd"
	column.add_child(body)
	body.add_child(_weapon_column())
	body.add_child(_armor_column())
	body.add_child(_mitigation_column())
	body.add_child(_effective_column())
	column.add_child(_attribute_strip())
	_refresh()


## Troca o heroi do build (a arma muda de forma; os itens ficam).
func select_hero(hero_id: StringName) -> void:
	var hero := _catalog.hero(hero_id)
	if hero == null:
		return
	build.hero = hero
	for key: StringName in _hero_chips:
		_hero_chips[key].set_pressed_no_signal(key == hero_id)
		_hero_chips[key].refresh()
	_refresh_weapon_icons()
	_refresh()


func set_level(level: int) -> void:
	build.level = level
	build.clamp_level(XpTable.max_level(_catalog.xp_curve))
	_refresh()


## Poe o item no slot (nulo esvazia) e atualiza os numeros.
func choose(slot: ItemData.Slot, item: ItemData) -> void:
	if item == null:
		build.unequip(slot)
	else:
		build.equip(item)
	var buttons: Array = _pickers[slot]
	for button: Button in buttons:
		var picked: ItemData = _item_of(button)
		button.set_pressed_no_signal(picked == item)
	_refresh()


func picker_buttons(slot: ItemData.Slot) -> Array:
	return _pickers[slot]


func hero_chip(hero_id: StringName) -> FilterChip:
	return _hero_chips[hero_id]


func level_buttons() -> Array[Button]:
	return [_level_down, _level_up]


func level_text() -> String:
	return _level_value.text


func defense_text() -> String:
	return _defense.text


func absorption_text() -> String:
	return _absorb_value.text


func hp_text() -> String:
	return _hp.text


func stat_text(key: StringName) -> String:
	return _stat_cells[key].text


func set_lines_text() -> PackedStringArray:
	var lines := PackedStringArray()
	for line: Node in _set_lines.get_children():
		lines.append((line as Label).text)
	return lines


func _head() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.theme_type_variation = &"LnHGapLg"
	var names := VBoxContainer.new()
	names.theme_type_variation = &"LnVGapXs"
	names.size_flags_horizontal = SIZE_EXPAND_FILL
	names.add_child(_label(tr("CALCULADORA TÁTICA INTEGRADA"), &"LnNumGold"))
	var title := _label(tr("Simulador de atributos & mitigação de dano"), &"LnHeadlineMd")
	title.uppercase = true
	names.add_child(title)
	names.add_child(_label(_formula_text(), &"LnNum"))
	row.add_child(names)
	var controls := VBoxContainer.new()
	controls.theme_type_variation = &"LnVGapSm"
	controls.add_child(_hero_row())
	controls.add_child(_level_row())
	row.add_child(controls)
	return row


## "Dano recebido = dano x 100 / (100 + DEF)": a escala vem de Stats (GDB §2.2 A).
func _formula_text() -> String:
	var scale_text := CompendiumFormat.decimal(Stats.DEFENSE_SCALE)
	return tr("Dano recebido = dano × %s / (%s + DEF)") % [scale_text, scale_text]


func _hero_row() -> PanelContainer:
	var strip := PanelContainer.new()
	strip.theme_type_variation = &"LnCpTabStrip"
	strip.size_flags_horizontal = SIZE_SHRINK_END
	var row := HBoxContainer.new()
	row.theme_type_variation = &"LnHGapXs"
	strip.add_child(row)
	var group := ButtonGroup.new()
	for hero: HeroData in _catalog.heroes:
		var chip := FilterChip.new(hero.display_name, "", FilterChip.ICON_INACTIVE_DEFAULT)
		chip.button_group = group
		chip.set_count(FilterChip.NO_COUNT)
		chip.pressed.connect(select_hero.bind(hero.id))
		row.add_child(chip)
		_hero_chips[hero.id] = chip
	_hero_chips[build.hero.id].set_pressed_no_signal(true)
	_hero_chips[build.hero.id].refresh()
	return strip


func _level_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.theme_type_variation = &"LnHGapSm"
	row.alignment = BoxContainer.ALIGNMENT_END
	row.add_child(_label(tr("NÍVEL"), &"LnNum"))
	for spec: Array in [[_level_down, "−", -1], [_level_up, "+", 1]]:
		var button: Button = spec[0]
		button.theme_type_variation = &"LnButtonSmall"
		button.text = spec[1]
		button.custom_minimum_size.x = LEVEL_BUTTON_WIDTH
		button.pressed.connect(_step_level.bind(spec[2]))
	_level_value.theme_type_variation = &"LnNumLgGold"
	_level_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_level_value.custom_minimum_size.x = LEVEL_BUTTON_WIDTH
	row.add_child(_level_down)
	row.add_child(_level_value)
	row.add_child(_level_up)
	return row


func _weapon_column() -> PanelContainer:
	var well := _column(tr("SLOT 1 · ARMA"))
	var box: VBoxContainer = well.get_child(0)
	box.add_child(_picker(ItemData.Slot.WEAPON, tr("Arma")))
	var summary := HBoxContainer.new()
	summary.theme_type_variation = &"LnHGapSm"
	var key := _label(tr("Dano físico base:"), &"LnBodySmMuted")
	key.size_flags_horizontal = SIZE_EXPAND_FILL
	summary.add_child(key)
	_weapon_summary.theme_type_variation = &"LnNumMdGold"
	summary.add_child(_weapon_summary)
	box.add_child(summary)
	return well


func _armor_column() -> PanelContainer:
	var well := _column(tr("SLOTS 2, 3 E 4 · ARMADURA"))
	var box: VBoxContainer = well.get_child(0)
	for slot: ItemData.Slot in [ItemData.Slot.HELM, ItemData.Slot.CHEST, ItemData.Slot.BOOTS]:
		box.add_child(_picker(slot, tr(CompendiumFormat.slot_name(slot))))
	var synergy := _label(tr("Bônus de sinergia:"), &"LnBodySmMuted")
	box.add_child(synergy)
	_set_lines.theme_type_variation = &"LnVGapXs"
	for _bonus: SetBonusData in _catalog.set_bonuses:
		_set_lines.add_child(_label("", &"LnNum"))
	box.add_child(_set_lines)
	return well


func _mitigation_column() -> PanelContainer:
	var well := _column(tr("MITIGAÇÃO DE IMPACTO"))
	var box: VBoxContainer = well.get_child(0)
	var total := HBoxContainer.new()
	total.theme_type_variation = &"LnHGapXs"
	_defense.theme_type_variation = &"LnNumLgCyan"
	total.add_child(_defense)
	var unit := _label(tr("DEFESA TOTAL"), &"LnNum")
	unit.size_flags_vertical = SIZE_SHRINK_END
	total.add_child(unit)
	box.add_child(total)
	var absorb := HBoxContainer.new()
	absorb.theme_type_variation = &"LnHGapSm"
	var key := _label(tr("Absorção de dano:"), &"LnBodySmMuted")
	key.size_flags_horizontal = SIZE_EXPAND_FILL
	absorb.add_child(key)
	_absorb_value.theme_type_variation = &"LnNumMdCyan"
	absorb.add_child(_absorb_value)
	box.add_child(absorb)
	_absorb_bar.theme_type_variation = &"LnCpBarCyan"
	_absorb_bar.show_percentage = false
	_absorb_bar.max_value = 1.0
	_absorb_bar.custom_minimum_size.y = MonsterCard.BAR_HEIGHT
	box.add_child(_absorb_bar)
	_sample.theme_type_variation = &"LnBodySmMuted"
	_sample.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_sample)
	return well


func _effective_column() -> PanelContainer:
	var well := _column(tr("ESTATÍSTICA EFETIVA DE COMBATE"))
	var box: VBoxContainer = well.get_child(0)
	var total := HBoxContainer.new()
	total.theme_type_variation = &"LnHGapXs"
	_hp.theme_type_variation = &"LnNumLgGold"
	total.add_child(_hp)
	var unit := _label(tr("HP MÁXIMO"), &"LnNum")
	unit.size_flags_vertical = SIZE_SHRINK_END
	total.add_child(unit)
	box.add_child(total)
	_sustain.theme_type_variation = &"LnBodySmMuted"
	_sustain.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_sustain)
	return well


## Fileira com os demais atributos finais do heroi com o build atual.
func _attribute_strip() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.theme_type_variation = &"LnHGapMd"
	var cells: Array[Array] = [
		[&"attack", tr("ATAQUE")],
		[&"intelligence", tr("INTELIGÊNCIA")],
		[&"agility", tr("AGILIDADE")],
		[&"move_speed", tr("VEL. MOVIMENTO")],
		[&"attack_interval", tr("INTERVALO DE ATAQUE")],
		[&"cdr", tr("REDUÇÃO DE RECARGA")],
	]
	for cell: Array in cells:
		var chip := PanelContainer.new()
		chip.theme_type_variation = &"LnChipLowest"
		chip.size_flags_horizontal = SIZE_EXPAND_FILL
		var box := VBoxContainer.new()
		box.theme_type_variation = &"LnVGapNone"
		chip.add_child(box)
		box.add_child(_label(cell[1], &"LnNum"))
		var value := _label("", &"LnNumMd")
		box.add_child(value)
		_stat_cells[cell[0]] = value
		row.add_child(chip)
	return row


## Poco com titulo mono em cima; o conteudo vai no VBox (primeiro filho).
func _column(title: String) -> PanelContainer:
	var well := PanelContainer.new()
	well.theme_type_variation = &"LnCpEffect"
	well.size_flags_horizontal = SIZE_EXPAND_FILL
	var box := VBoxContainer.new()
	box.theme_type_variation = &"LnVGapSm"
	well.add_child(box)
	box.add_child(_label(title, &"LnNum"))
	return well


## Fileira de escolha de um slot: "sem item" e uma caixa por item (moldura pela raridade).
func _picker(slot: ItemData.Slot, caption: String) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.theme_type_variation = &"LnVGapXs"
	column.add_child(_label(caption, &"LnBodySmMuted"))
	var row := HBoxContainer.new()
	row.theme_type_variation = &"LnHGapXs"
	column.add_child(row)
	var group := ButtonGroup.new()
	_groups[slot] = group
	var buttons: Array[Button] = []
	buttons.append(_item_button(null, group, row))
	for item: ItemData in _catalog.items_in_slot(slot):
		buttons.append(_item_button(item, group, row))
	buttons[0].set_pressed_no_signal(true)
	_pickers[slot] = buttons
	return column


func _item_button(item: ItemData, group: ButtonGroup, row: HBoxContainer) -> Button:
	var button := Button.new()
	button.toggle_mode = true
	button.button_group = group
	button.custom_minimum_size = ICON_SIZE
	button.set_meta(ITEM_META, item)  # nulo apaga a chave: "sem item" fica sem meta
	if item == null:
		button.theme_type_variation = &"LnCpSlotCommon"
		button.text = NONE_TEXT
		button.tooltip_text = tr("Sem item")
	else:
		button.theme_type_variation = [&"LnCpSlotCommon", &"LnCpSlotRare", &"LnCpSlotEpic"][
			item.rarity
		]
		button.expand_icon = true
		button.icon = CompendiumArt.item(item, build.hero.id)
		button.tooltip_text = _tooltip(item)
	button.pressed.connect(choose.bind(item.slot if item != null else _slot_of(group), item))
	row.add_child(button)
	return button


## Item do botao; nulo no "sem item" (get_meta com padrao nulo erra, entao confere antes).
func _item_of(button: Button) -> ItemData:
	return button.get_meta(ITEM_META) if button.has_meta(ITEM_META) else null


func _slot_of(group: ButtonGroup) -> ItemData.Slot:
	for slot: ItemData.Slot in _groups:
		if _groups[slot] == group:
			return slot
	return ItemData.Slot.WEAPON


func _tooltip(item: ItemData) -> String:
	return (
		"%s · %s\n%s"
		% [
			item.display_name,
			tr(CompendiumFormat.rarity_name(item.rarity)),
			", ".join(CompendiumFormat.item_stats(item)),
		]
	)


func _refresh_weapon_icons() -> void:
	for button: Button in _pickers[ItemData.Slot.WEAPON]:
		var item: ItemData = _item_of(button)
		if item != null:
			button.icon = CompendiumArt.item(item, build.hero.id)


func _step_level(delta: int) -> void:
	set_level(build.level + delta)


func _refresh() -> void:
	var attrs := build.attributes(_catalog.set_bonuses)
	var max_level := XpTable.max_level(_catalog.xp_curve)
	_level_value.text = str(build.level)
	_level_down.disabled = build.level <= 1
	_level_up.disabled = build.level >= max_level
	var weapon := build.item_in(ItemData.Slot.WEAPON)
	_weapon_summary.text = (
		"+%s" % CompendiumFormat.decimal(weapon.attack) if weapon != null else NONE_TEXT
	)
	_defense.text = CompendiumFormat.decimal(attrs.defense)
	_absorb_value.text = CompendiumFormat.percent(attrs.mitigation)
	_absorb_bar.value = attrs.mitigation
	_sample.text = (
		tr("%s de dano bruto → %s de dano recebido")
		% [
			CompendiumFormat.decimal(SAMPLE_RAW_DAMAGE),
			CompendiumFormat.decimal(snappedf(build.damage_taken(SAMPLE_RAW_DAMAGE, attrs), 0.1)),
		]
	)
	_hp.text = CompendiumFormat.thousands(attrs.max_hp)
	_sustain.text = (
		tr("Sustenta %s de dano bruto antes de ser eliminado.")
		% CompendiumFormat.thousands(roundi(build.effective_hp(attrs)))
	)
	_stat_cells[&"attack"].text = CompendiumFormat.decimal(snappedf(attrs.attack, 0.1))
	_stat_cells[&"intelligence"].text = CompendiumFormat.decimal(snappedf(attrs.intelligence, 0.1))
	_stat_cells[&"agility"].text = CompendiumFormat.decimal(snappedf(attrs.agility, 0.1))
	_stat_cells[&"move_speed"].text = (
		"%s u/s" % CompendiumFormat.decimal(snappedf(attrs.move_speed, 0.01))
	)
	_stat_cells[&"attack_interval"].text = (
		"%s s" % CompendiumFormat.decimal(snappedf(attrs.attack_interval, 0.01))
	)
	_stat_cells[&"cdr"].text = "%s%%" % CompendiumFormat.decimal(snappedf(attrs.cdr_percent, 0.1))
	_refresh_sets()


## Uma linha por conjunto: "Guarda 3/3 · ATIVO (+15% HP máximo · +10 DEF)" ou
## "Caçador 1/3 · inativo".
func _refresh_sets() -> void:
	for i: int in _catalog.set_bonuses.size():
		var bonus := _catalog.set_bonuses[i]
		var pieces := build.set_pieces(bonus.set_id)
		var active := pieces >= bonus.pieces_required
		var text := "%s %d/%d" % [bonus.display_name, pieces, bonus.pieces_required]
		if active:
			text += " · %s (%s)" % [tr("ATIVO"), CompendiumFormat.bonus_text(bonus)]
		else:
			text += " · %s" % tr("inativo")
		var line := _set_lines.get_child(i) as Label
		line.text = text
		line.theme_type_variation = &"LnNumCyan" if active else &"LnNum"


func _label(text: String, type: StringName) -> Label:
	var label := Label.new()
	label.theme_type_variation = type
	label.text = text
	return label
