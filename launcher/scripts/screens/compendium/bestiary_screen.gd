class_name BestiaryScreen
extends CompendiumScreen
## Bestiario (DV tela 5; FRONTEND-LAUNCHER §8: fiel ao prototipo "Guia & Bestiario — Monstros e
## Equipamentos"). Cabecalho do compendio com os filtros por tier e a busca, o grid de criaturas
## (um card por especie, o chefe em card largo) e as diretrizes de equilibrio. Numeros, nomes e
## regras vem de shared/data pelo CatalogService (GDB vence o prototipo). Fora do prototipo
## (issue #84, §8.3): DEFESA, funcao tatica, dicas, "KayKit/Quaternius", local de spawn, "Criterio
## M4" e "Fatia vertical M0–M4"; a aba "Arena & Mecanicas" volta com o F33.

enum TierFilter { ALL, T1, T2, T3, BOSS }

const COLUMNS: int = 3
## Largura da busca (w-48) e a ampliada com foco (focus:w-60).
const SEARCH_WIDTH: float = 192.0
const SEARCH_WIDTH_FOCUS: float = 240.0
const SEARCH_ICON_LEFT: float = 8.0
## Ponto da fauna (animate-pulse: opacidade 1 -> 0,5).
const DOT_SIZE: Vector2 = Vector2(8, 8)
const PULSE_SECONDS: float = 1.0
const PULSE_ALPHA: float = 0.5
const ICON_BOX: Vector2 = Vector2(32, 32)
const DESCRIPTION_WIDTH: float = 560.0

var _filter: TierFilter = TierFilter.ALL
var _pills: Dictionary[TierFilter, Button] = {}
var _search: LineEdit
var _frames: Array[LiftFrame] = []
var _no_match: Label
var _search_tween: Tween


func filter_pill(filter: TierFilter) -> Button:
	return _pills[filter]


func search_field() -> LineEdit:
	return _search


func select_filter(filter: TierFilter) -> void:
	_filter = filter
	for key: TierFilter in _pills:
		_pills[key].set_pressed_no_signal(key == filter)
	_scroll.scroll_vertical = 0
	_apply_filter()


func cards() -> Array[MonsterCard]:
	var found: Array[MonsterCard] = []
	for frame: LiftFrame in _frames:
		found.append(frame.card() as MonsterCard)
	return found


func visible_cards() -> Array[MonsterCard]:
	var found: Array[MonsterCard] = []
	for frame: LiftFrame in _frames:
		if frame.visible:
			found.append(frame.card() as MonsterCard)
	return found


func no_match_visible() -> bool:
	return _no_match.visible


func _current_tab() -> Tab:
	return Tab.BESTIARY


func _header_texts() -> Array[String]:
	var description := ""
	if catalog != null and catalog.is_loaded():
		description = (
			tr("Atributos de campo, saques dos %d equipamentos e guia das %d criaturas da arena.")
			% [catalog.items.size(), catalog.monster_species().size()]
		)
	return [
		tr("COMPÊNDIO TÁTICO"), tr("Documentação de balanceamento"), UiIcons.MENU_BOOK, description
	]


func _ribbon_cells() -> Array[Array]:
	if catalog == null or not catalog.is_loaded():
		return []
	return [
		[tr("Criaturas"), "%02d" % catalog.monster_species().size(), tr("unid"), &"LnNumLgGold"],
		[tr("Equipamentos"), "%02d" % catalog.items.size(), tr("itens"), &"LnNumLgCyan"],
		[
			tr("Chefe surge"),
			CompendiumFormat.clock(catalog.match_rules.boss_spawn_time),
			tr("fase 1"),
			&"LnNumLgError"
		],
	]


func _build_filters(slot: HBoxContainer) -> void:
	var pills := PanelContainer.new()
	pills.theme_type_variation = &"LnCpPills"
	pills.size_flags_vertical = SIZE_SHRINK_CENTER
	var row := HBoxContainer.new()
	row.theme_type_variation = &"LnHGapXs"
	pills.add_child(row)
	var group := ButtonGroup.new()
	var boss_clock := CompendiumFormat.clock(catalog.match_rules.boss_spawn_time)
	var specs: Array[Array] = [
		[TierFilter.ALL, tr("Todos"), &"LnCpPill"],
		[TierFilter.T1, tr(CompendiumFormat.tier_name(MonsterData.Tier.T1)), &"LnCpPill"],
		[TierFilter.T2, tr(CompendiumFormat.tier_name(MonsterData.Tier.T2)), &"LnCpPill"],
		[TierFilter.T3, tr(CompendiumFormat.tier_name(MonsterData.Tier.T3)), &"LnCpPill"],
		[TierFilter.BOSS, "%s (%s)" % [tr("Chefe"), boss_clock], &"LnCpPillBoss"],
	]
	for spec: Array in specs:
		var pill := Button.new()
		pill.theme_type_variation = spec[2]
		pill.text = String(spec[1]).to_upper()
		pill.toggle_mode = true
		pill.button_group = group
		pill.pressed.connect(select_filter.bind(spec[0]))
		row.add_child(pill)
		_pills[spec[0]] = pill
	_pills[TierFilter.ALL].set_pressed_no_signal(true)
	slot.add_child(pills)
	slot.add_child(_search_box())


func _search_box() -> LineEdit:
	_search = LineEdit.new()
	_search.theme_type_variation = &"LnCpSearch"
	_search.placeholder_text = tr("Buscar monstro...")
	_search.custom_minimum_size.x = SEARCH_WIDTH
	_search.size_flags_vertical = SIZE_SHRINK_CENTER
	_search.clear_button_enabled = false
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


func _build_body(content: VBoxContainer) -> void:
	content.add_child(_section_header())
	var species := catalog.monster_species()
	var maxima := _maxima(species)
	var grid := GridContainer.new()
	grid.theme_type_variation = &"LnCpGrid"
	grid.columns = COLUMNS
	grid.size_flags_horizontal = SIZE_EXPAND_FILL
	content.add_child(grid)
	var bosses: Array[LiftFrame] = []
	for group: MonsterSpecies in species:
		var card := MonsterCard.new()
		card.bind(group, catalog.match_rules, maxima)
		LiftFrame.ignore_mouse(card)
		var frame := LiftFrame.new(card)
		frame.size_flags_horizontal = SIZE_EXPAND_FILL
		_frames.append(frame)
		if group.lead().tier == MonsterData.Tier.BOSS:
			bosses.append(frame)
		else:
			grid.add_child(frame)
	for frame: LiftFrame in bosses:
		content.add_child(frame)
	_no_match = _label(tr("Nenhuma criatura encontrada."), &"LnBodyMuted")
	_no_match.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_no_match.visible = false
	content.add_child(_no_match)
	content.add_child(_directives())


func _section_header() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.theme_type_variation = &"LnHGapMd"
	var left := VBoxContainer.new()
	left.theme_type_variation = &"LnVGapXs"
	left.size_flags_horizontal = SIZE_EXPAND_FILL
	row.add_child(left)
	var kicker := HBoxContainer.new()
	kicker.theme_type_variation = &"LnHGapXs"
	var dot := Panel.new()
	dot.theme_type_variation = &"LnCpDot"
	dot.custom_minimum_size = DOT_SIZE
	dot.size_flags_vertical = SIZE_SHRINK_CENTER
	kicker.add_child(dot)
	var pulse := dot.create_tween().set_loops()
	pulse.tween_property(dot, ^"modulate:a", PULSE_ALPHA, PULSE_SECONDS)
	pulse.tween_property(dot, ^"modulate:a", 1.0, PULSE_SECONDS)
	var caption := _label(tr("FAUNA DA ARENA"), &"LnNumGold")
	kicker.add_child(caption)
	left.add_child(kicker)
	var title := _label(
		tr("Bestiário tático: %d criaturas") % catalog.monster_species().size(), &"LnHeadlineMd"
	)
	title.uppercase = true
	left.add_child(title)
	var description := _label(
		(
			tr(
				(
					"Quantidade fixa por partida. Na fase 1 cada criatura renasce %s depois de morrer, "
					+ "no mesmo ponto; o chefe não renasce."
				)
			)
			% _respawn_text()
		),
		&"LnBodyMuted"
	)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.custom_minimum_size.x = DESCRIPTION_WIDTH
	left.add_child(description)
	row.add_child(_respawn_pill())
	return row


## Pilula "RESPAWN DE MONSTROS 90 s" (o prototipo diz DESATIVADO; hoje vale MatchRules).
func _respawn_pill() -> PanelContainer:
	var pill := PanelContainer.new()
	pill.theme_type_variation = &"LnCpPanelTight"
	pill.size_flags_vertical = SIZE_SHRINK_END
	var row := HBoxContainer.new()
	row.theme_type_variation = &"LnHGapMd"
	pill.add_child(row)
	var box := PanelContainer.new()
	box.theme_type_variation = &"LnCpIconBox"
	box.custom_minimum_size = ICON_BOX
	var icon := _label(UiIcons.TIMER, &"LnIconGold")
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	box.add_child(icon)
	row.add_child(box)
	var text := VBoxContainer.new()
	text.theme_type_variation = &"LnVGapNone"
	text.add_child(_label(tr("RESPAWN DE MONSTROS"), &"LnNum"))
	text.add_child(_label(_respawn_text(), &"LnHeadlineSmGold"))
	row.add_child(text)
	return pill


func _respawn_text() -> String:
	return "%s s" % CompendiumFormat.decimal(catalog.match_rules.monster_respawn_phase1)


## Maiores HP, dano e cadencia (1 / intervalo) do bestiario: o comprimento cheio das barras.
func _maxima(species: Array[MonsterSpecies]) -> Dictionary[StringName, float]:
	var maxima: Dictionary[StringName, float] = {&"hp": 0.0, &"damage": 0.0, &"rate": 0.0}
	for group: MonsterSpecies in species:
		var lead := group.lead()
		maxima[&"hp"] = maxf(maxima[&"hp"], lead.hp)
		maxima[&"damage"] = maxf(maxima[&"damage"], lead.damage)
		maxima[&"rate"] = maxf(maxima[&"rate"], 1.0 / lead.attack_interval)
	return maxima


## "Diretrizes de equilibrio": o catch-up (GDB §3.3) e o chefe (GDB §5, §7.1), com os valores
## das regras.
func _directives() -> VBoxContainer:
	var section := VBoxContainer.new()
	section.theme_type_variation = &"LnVGapMd"
	var title := HBoxContainer.new()
	title.theme_type_variation = &"LnHGapSm"
	title.add_child(_label(UiIcons.WORKSPACE_PREMIUM, &"LnIconTitle"))
	var heading := _label(tr("Diretrizes de equilíbrio"), &"LnHeadlineMd")
	heading.uppercase = true
	title.add_child(heading)
	section.add_child(title)
	var cards := HBoxContainer.new()
	cards.theme_type_variation = &"LnHGapLg"
	section.add_child(cards)
	var curve := catalog.xp_curve
	var rules := catalog.match_rules
	var boss := catalog.boss()
	var catch_up := CompendiumFormat.percent(curve.catch_up_bonus)
	(
		cards
		. add_child(
			_directive(
				tr("Regra de catch-up"),
				&"LnHeadlineMdGold",
				"+%s XP" % catch_up,
				(
					tr(
						(
							"Se o seu nível estiver %d ou mais abaixo do adversário, "
							+ "todo ganho de XP de monstros e objetivos recebe +%s."
						)
					)
					% [curve.catch_up_level_gap, catch_up]
				),
				[
					[tr("Bônus de XP"), "+%s" % catch_up],
					[tr("Diferença de nível"), "%d+" % curve.catch_up_level_gap],
				]
			)
		)
	)
	(
		cards
		. add_child(
			_directive(
				tr("Chefe aos %s") % CompendiumFormat.clock(rules.boss_spawn_time),
				&"LnHeadlineMdCyan",
				tr("aviso %s") % CompendiumFormat.clock(rules.boss_warning_time),
				(
					tr("%s surge aos %s e dá %d XP. Vivo aos %s, ele sai do mapa sem drop.")
					% [
						boss.display_name,
						CompendiumFormat.clock(rules.boss_spawn_time),
						boss.xp,
						CompendiumFormat.clock(rules.phase1_duration),
					]
				),
				[
					[tr("Recompensa"), "%d XP" % boss.xp],
					[tr("Drop"), CompendiumFormat.drop_text(boss)],
				]
			)
		)
	)
	return section


## Card de regra: titulo e selo, texto e duas linhas "rotulo ... valor".
func _directive(
	title: String, title_type: StringName, tag: String, text: String, facts: Array[Array]
) -> PanelContainer:
	var card := PanelContainer.new()
	card.theme_type_variation = &"LnCpPanel"
	card.size_flags_horizontal = SIZE_EXPAND_FILL
	var column := VBoxContainer.new()
	column.theme_type_variation = &"LnVGapMd"
	card.add_child(column)
	var head := HBoxContainer.new()
	head.theme_type_variation = &"LnHGapSm"
	var name_label := _label(title, title_type)
	name_label.uppercase = true
	name_label.size_flags_horizontal = SIZE_EXPAND_FILL
	head.add_child(name_label)
	head.add_child(_label(tag.to_upper(), &"LnCpBadgeSet"))
	column.add_child(head)
	var body := _label(text, &"LnBodyMuted")
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(body)
	column.add_child(HSeparator.new())
	for fact: Array in facts:
		var row := HBoxContainer.new()
		row.theme_type_variation = &"LnHGapSm"
		var key := _label(fact[0], &"LnNum")
		key.uppercase = true
		key.size_flags_horizontal = SIZE_EXPAND_FILL
		row.add_child(key)
		row.add_child(_label(fact[1], &"LnBodySmMedium"))
		column.add_child(row)
	return card


func _apply_filter() -> void:
	var needle := _search.text.strip_edges().to_lower()
	var shown := 0
	for frame: LiftFrame in _frames:
		var card := frame.card() as MonsterCard
		var matches := _matches_tier(card) and (needle.is_empty() or needle in card.search_text)
		frame.visible = matches
		shown += int(matches)
	_no_match.visible = shown == 0


func _matches_tier(card: MonsterCard) -> bool:
	var tier := card.species.lead().tier
	match _filter:
		TierFilter.T1:
			return tier == MonsterData.Tier.T1
		TierFilter.T2:
			return tier == MonsterData.Tier.T2
		TierFilter.T3:
			return tier == MonsterData.Tier.T3
		TierFilter.BOSS:
			return tier == MonsterData.Tier.BOSS
	return true


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
