class_name ForgeScreen
extends CompendiumScreen
## Forja (DV tela 6; FRONTEND-LAUNCHER §8: fiel ao prototipo "Equipamentos & Forja"). Cabecalho do
## compendio, tres cards de regra, os conjuntos de armadura, as tres armas universais e o simulador
## de atributos sobre shared/core (V-06, I5). Numeros e nomes de shared/data pelo CatalogService.
## Fora do prototipo (issue #84, §8.3): "recomendado para", papeis, totais de exemplo, "segurar F
## 0,5 s" (a regra de troca mudou: o bau oferece a escolha, ADR-0014), contagem de baus laterais e
## "Arena & Baus" (a aba da Arena volta com o F33); "Heroi" do menu nao tem tela ainda.

enum Section { ALL, WEAPONS, SET }

const ICON_BOX: Vector2 = Vector2(32, 32)
const SEARCH_WIDTH: float = 288.0
const SEARCH_WIDTH_FOCUS: float = 352.0
const SEARCH_ICON_LEFT: float = 8.0
## Heroi de cada lado no card de arma: o primeiro (corpo a corpo) e o segundo do catalogo.
const WEAPON_PREVIEW_HEROES: int = 2

## Montado com o corpo (nulo enquanto o catalogo nao carregou).
var simulator: ForgeSimulator

var _filter_section: Section = Section.ALL
var _filter_set: StringName = &""
var _pills: Array[Button] = []
var _pill_specs: Array[Array] = []
var _search: LineEdit
var _sets_section: Control
var _sets_row: HBoxContainer
var _set_panels: Array[SetPanel] = []
var _weapons_section: Control
var _weapons_row: HBoxContainer
var _weapon_cards: Array[WeaponCard] = []
var _no_match: Label
var _search_tween: Tween


## Filtro por secao: TODOS, ARMAS ou um conjunto (pelo id do conjunto).
func select_filter(section: Section, set_id: StringName = &"") -> void:
	_filter_section = section
	_filter_set = set_id
	for i: int in _pills.size():
		var spec: Array = _pill_specs[i]
		_pills[i].set_pressed_no_signal(spec[0] == section and spec[1] == set_id)
	_apply_filter()


func filter_pills() -> Array[Button]:
	return _pills


func search_field() -> LineEdit:
	return _search


func set_panels() -> Array[SetPanel]:
	return _set_panels


func weapon_cards() -> Array[WeaponCard]:
	return _weapon_cards


func visible_weapon_cards() -> Array[WeaponCard]:
	return _weapon_cards.filter(func(card: WeaponCard) -> bool: return card.is_visible_in_tree())


func visible_set_panels() -> Array[SetPanel]:
	return _set_panels.filter(func(panel: SetPanel) -> bool: return panel.is_visible_in_tree())


func no_match_visible() -> bool:
	return _no_match.visible


func _current_tab() -> Tab:
	return Tab.FORGE


func _header_texts() -> Array[String]:
	return [tr("ARSENAL & SETS SINÉRGICOS"), tr("Compêndio · Equipamentos & Forja"), "", ""]


func _ribbon_cells() -> Array[Array]:
	if catalog == null or not catalog.is_loaded():
		return []
	var pieces := catalog.set_bonuses[0].pieces_required
	return [
		[tr("Equipamentos"), "%02d" % catalog.items.size(), tr("itens"), &"LnNumLgGold"],
		[
			tr("Conjuntos"),
			"%02d" % catalog.set_bonuses.size(),
			"%d/%d" % [pieces, pieces],
			&"LnNumLgCyan"
		],
		[tr("Tiers de raridade"), "%02d" % ItemData.RARITY_NAMES.size(), "", &"LnNumLgError"],
	]


func _build_body(content: VBoxContainer) -> void:
	content.add_child(_rule_cards())
	content.add_child(_filter_row())
	_sets_section = _sets()
	content.add_child(_sets_section)
	_weapons_section = _weapons()
	content.add_child(_weapons_section)
	_no_match = _label(tr("Nenhum equipamento encontrado."), &"LnBodyMuted")
	_no_match.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_no_match.visible = false
	content.add_child(_no_match)
	simulator = ForgeSimulator.new()
	simulator.bind(catalog)
	content.add_child(simulator)
	content.add_child(_call_to_action())


## Tres cards de regra: slots, escolha no bau e distribuicao dos baus (texto de MatchRules e
## dos itens).
func _rule_cards() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.theme_type_variation = &"LnHGapLg"
	var pieces := catalog.set_bonuses[0].pieces_required
	var slots := CompendiumFormat.SLOT_NAMES
	var rules := catalog.match_rules
	var boss := catalog.boss()
	var first := RuleCard.new()
	first.bind(
		UiIcons.INVENTORY_2,
		tr("Estrutura"),
		&"LnNumCyan",
		tr("%d slots de equipamento") % slots.size(),
		(
			tr(
				"Cada duelista equipa %s. Os itens somam ataque, defesa, agilidade, inteligência e vida."
			)
			% ", ".join(PackedStringArray(slots.map(func(name: String) -> String: return tr(name))))
		),
		tr("%d peças do mesmo conjunto ativam o bônus de conjunto") % pieces
	)
	row.add_child(first)
	var second := RuleCard.new()
	second.bind(
		UiIcons.SWAP_HORIZ,
		tr("Mecânica"),
		&"LnNumGold",
		tr("Escolha no baú"),
		tr(
			(
				"Cada baú oferece itens da raridade sorteada. Escolha um com o clique do mouse, "
				+ "comparando com o que você já usa; vale escolher um item pior."
			)
		),
		tr("O item antigo some e o baú aberto não reabre")
	)
	row.add_child(second)
	var third := RuleCard.new()
	third.bind(
		UiIcons.INBOX,
		tr("Distribuição"),
		&"LnNumCyan",
		tr("Baús e drops fixos"),
		(
			tr("%d baús comuns por base e %d baús raros no centro contestado. %s: %s.")
			% [
				rules.common_chests_per_base,
				rules.rare_chests,
				boss.display_name,
				CompendiumFormat.drop_text(boss)
			]
		),
		(
			tr("Chance de épico no baú raro: %s")
			% CompendiumFormat.percent(rules.rare_chest_epic_chance)
		)
	)
	row.add_child(third)
	return row


func _filter_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.theme_type_variation = &"LnHGapMd"
	var strip := PanelContainer.new()
	strip.theme_type_variation = &"LnCpTabStrip"
	var pills := HBoxContainer.new()
	pills.theme_type_variation = &"LnHGapXs"
	strip.add_child(pills)
	var group := ButtonGroup.new()
	var weapons := catalog.items_in_slot(ItemData.Slot.WEAPON).size()
	_pill_specs = [
		[Section.ALL, &"", tr("Todos (%d)") % catalog.items.size()],
		[Section.WEAPONS, &"", tr("Armas (%d)") % weapons],
	]
	for bonus: SetBonusData in catalog.set_bonuses:
		(
			_pill_specs
			. append(
				[
					Section.SET,
					bonus.set_id,
					(
						"%s (%d)"
						% [
							tr("Set da %s") % bonus.display_name,
							catalog.items_of_set(bonus.set_id).size()
						]
					),
				]
			)
		)
	for spec: Array in _pill_specs:
		var pill := Button.new()
		pill.theme_type_variation = &"LnFilter"
		pill.text = String(spec[2]).to_upper()
		pill.toggle_mode = true
		pill.button_group = group
		pill.pressed.connect(select_filter.bind(spec[0], spec[1]))
		pills.add_child(pill)
		_pills.append(pill)
	_pills[0].set_pressed_no_signal(true)
	row.add_child(strip)
	var spacer := Control.new()
	spacer.size_flags_horizontal = SIZE_EXPAND_FILL
	row.add_child(spacer)
	row.add_child(_search_box())
	return row


func _search_box() -> LineEdit:
	_search = LineEdit.new()
	_search.theme_type_variation = &"LnCpSearch"
	_search.placeholder_text = tr("Buscar por nome ou atributo...")
	_search.custom_minimum_size.x = SEARCH_WIDTH
	_search.size_flags_vertical = SIZE_SHRINK_CENTER
	_search.text_changed.connect(_on_search_text_changed)
	_search.focus_entered.connect(_widen_search.bind(true))
	_search.focus_exited.connect(_widen_search.bind(false))
	var icon := Label.new()
	icon.theme_type_variation = &"LnIconSmMuted"
	icon.text = UiIcons.SEARCH
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.set_anchors_and_offsets_preset(PRESET_CENTER_LEFT)
	icon.offset_left = SEARCH_ICON_LEFT
	icon.grow_vertical = GROW_DIRECTION_BOTH
	_search.add_child(icon)
	return _search


func _sets() -> VBoxContainer:
	var section := VBoxContainer.new()
	section.theme_type_variation = &"LnVGapMd"
	var pieces := catalog.set_bonuses[0].pieces_required
	section.add_child(
		_section_title(
			UiIcons.SHIELD_WITH_HEART,
			tr("Conjuntos de armadura especializada"),
			tr("%d peças por conjunto = bônus passivo máximo") % pieces
		)
	)
	_sets_row = HBoxContainer.new()
	_sets_row.theme_type_variation = &"LnHGapLg"
	section.add_child(_sets_row)
	for bonus: SetBonusData in catalog.set_bonuses:
		var panel := SetPanel.new()
		panel.bind(bonus, catalog.items_of_set(bonus.set_id))
		_set_panels.append(panel)
		_sets_row.add_child(panel)
	return section


func _weapons() -> VBoxContainer:
	var section := VBoxContainer.new()
	section.theme_type_variation = &"LnVGapMd"
	section.add_child(
		_section_title(
			UiIcons.SWORDS,
			tr("Armas universais (%d tiers de poder)") % ItemData.RARITY_NAMES.size(),
			tr("Itens iguais para todos os heróis; o modelo 3D da arma muda com a classe.")
		)
	)
	_weapons_row = HBoxContainer.new()
	_weapons_row.theme_type_variation = &"LnHGapLg"
	section.add_child(_weapons_row)
	var heroes: Array[StringName] = []
	for hero: HeroData in catalog.heroes.slice(0, WEAPON_PREVIEW_HEROES):
		heroes.append(hero.id)
	for weapon: ItemData in catalog.items_in_slot(ItemData.Slot.WEAPON):
		var card := WeaponCard.new()
		card.bind(weapon, catalog.match_rules, catalog.boss(), heroes)
		card.size_flags_horizontal = SIZE_EXPAND_FILL
		_weapon_cards.append(card)
		_weapons_row.add_child(card)
	return section


## Titulo de secao: icone + titulo a esquerda e a nota mono a direita (prototipo).
func _section_title(icon: String, title: String, note: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.theme_type_variation = &"LnHGapSm"
	row.add_child(_label(icon, &"LnIconTitle"))
	var heading := _label(title, &"LnHeadlineMd")
	heading.uppercase = true
	heading.size_flags_horizontal = SIZE_EXPAND_FILL
	row.add_child(heading)
	var caption := _label(note, &"LnNum")
	caption.uppercase = true
	row.add_child(caption)
	return row


## Faixa final: volta ao Guia & Bestiario ou segue para o lobby, onde se entra na fila.
func _call_to_action() -> PanelContainer:
	var strip := PanelContainer.new()
	strip.theme_type_variation = &"LnStrip"
	var row := HBoxContainer.new()
	row.theme_type_variation = &"LnHGapMd"
	strip.add_child(row)
	row.add_child(_label(UiIcons.SPORTS_ESPORTS, &"LnIconCyan"))
	var text := _label(
		tr("Pronto para aplicar a forja e as estratégias na arena real?"), &"LnBodyMuted"
	)
	text.size_flags_horizontal = SIZE_EXPAND_FILL
	row.add_child(text)
	var back := Button.new()
	back.theme_type_variation = &"LnButton"
	back.text = "%s  %s" % [UiIcons.ARROW_BACK, tr("GUIA DO BESTIÁRIO")]
	back.pressed.connect(navigate_requested.emit.bind(Router.BESTIARY))
	row.add_child(back)
	var play := Button.new()
	play.theme_type_variation = &"LnButtonPrimary"
	play.text = "%s  %s" % [UiIcons.SWORDS, tr("IR PARA O LOBBY")]
	play.pressed.connect(navigate_requested.emit.bind(Router.LOBBY))
	row.add_child(play)
	return strip


## Secao pelo filtro; dentro dela, so o que a busca acha (nome, conjunto ou atributo).
func _apply_filter() -> void:
	var needle := _search.text.strip_edges().to_lower()
	var weapons_shown := 0
	for card: WeaponCard in _weapon_cards:
		card.visible = needle.is_empty() or needle in card.search_text
		weapons_shown += int(card.visible)
	var sets_shown := 0
	for panel: SetPanel in _set_panels:
		var in_filter := _filter_section != Section.SET or panel.bonus.set_id == _filter_set
		var rows := panel.apply_search(needle)
		panel.visible = in_filter and rows > 0
		sets_shown += int(panel.visible)
	var show_weapons := _filter_section != Section.SET
	var show_sets := _filter_section != Section.WEAPONS
	_weapons_section.visible = show_weapons and weapons_shown > 0
	_sets_section.visible = show_sets and sets_shown > 0
	_no_match.visible = not _weapons_section.visible and not _sets_section.visible


func _label(text: String, type: StringName) -> Label:
	var label := Label.new()
	label.theme_type_variation = type
	label.text = text
	return label


func _widen_search(focused: bool) -> void:
	if _search_tween != null:
		_search_tween.kill()
	_search_tween = create_tween()
	_search_tween.tween_property(
		_search,
		^"custom_minimum_size:x",
		SEARCH_WIDTH_FOCUS if focused else SEARCH_WIDTH,
		UiTokens.DUR_BASE
	)


func _on_search_text_changed(_text: String) -> void:
	_apply_filter()
