class_name PhaseCard
extends PanelContainer
## Card de uma das duas fases (prototipo "Arena & Mapa", "Regras dos 2 Tempos"): ponto e sobretitulo
## da fase, janela de tempo, titulo, as regras (icone + destaque em negrito + texto) e, no fim, uma
## faixa: a nota da fase 1 ou a tabela de raio da zona da fase 2. Todo texto vem de
## ArenaMapTexts (numeros de shared/data); o card so monta e desenha.

enum Kind { PREPARATION, CONFRONTATION }

const DOT_SIZE: Vector2 = Vector2(12, 12)
## Ponto da fase 2 (animate-ping): opacidade 1 -> 0,3 em 1 s.
const PULSE_SECONDS: float = 1.0
const PULSE_ALPHA: float = 0.3
const ICON_TYPES: Dictionary[StringName, StringName] = {
	ArenaMapTexts.ACCENT_GOLD: &"LnIconSmGold",
	ArenaMapTexts.ACCENT_CYAN: &"LnIconSmCyan",
	ArenaMapTexts.ACCENT_ERROR: &"LnIconSmError",
}

var kind: Kind = Kind.PREPARATION

var _column: VBoxContainer = VBoxContainer.new()
var _rules: VBoxContainer = VBoxContainer.new()
var _rule_texts: Array[RichTextLabel] = []
var _window: Label = Label.new()
var _title: Label = Label.new()
var _kicker: Label = Label.new()
var _pulse_dot: Panel
var _pulse: Tween


func _init() -> void:
	theme_type_variation = &"LnAmPhase"
	size_flags_horizontal = SIZE_EXPAND_FILL
	_column.theme_type_variation = &"LnVGapSm"
	add_child(_column)
	visibility_changed.connect(_on_visibility_changed)


## [param rules]: linhas de regra; o rodape (nota ou zona) entra depois, por set_note/set_zone.
func bind(
	phase: Kind, kicker: String, window: String, title: String, rules: Array[ArenaMapTexts.Rule]
) -> void:
	if _column.get_child_count() > 0:
		return
	kind = phase
	var error := phase == Kind.CONFRONTATION
	var head := HBoxContainer.new()
	head.theme_type_variation = &"LnHGapXs"
	var dot := Panel.new()
	dot.theme_type_variation = &"LnAmDotError" if error else &"LnAmDotCyan"
	dot.custom_minimum_size = DOT_SIZE
	dot.size_flags_vertical = SIZE_SHRINK_CENTER
	head.add_child(dot)
	_kicker.theme_type_variation = &"LnNumError" if error else &"LnNumCyan"
	_kicker.text = kicker
	_kicker.uppercase = true
	head.add_child(_kicker)
	var spacer := Control.new()
	spacer.size_flags_horizontal = SIZE_EXPAND_FILL
	head.add_child(spacer)
	var chip := PanelContainer.new()
	chip.theme_type_variation = &"LnChip"
	_window.theme_type_variation = &"LnNumError" if error else &"LnNumCyan"
	_window.text = window
	chip.add_child(_window)
	head.add_child(chip)
	_column.add_child(head)
	_title.theme_type_variation = &"LnHeadlineSm"
	_title.text = title
	_column.add_child(_title)
	_rules.theme_type_variation = &"LnVGapSm"
	_column.add_child(_rules)
	for rule: ArenaMapTexts.Rule in rules:
		_rules.add_child(_rule_row(rule))
	if error:
		_pulse_dot = dot
		# O card ainda nao esta na arvore: o pulso nasce quando ele entra.
		if is_inside_tree():
			_start_pulse()
		else:
			tree_entered.connect(_start_pulse, CONNECT_ONE_SHOT)


## Faixa de rodape da fase 1: rotulo a esquerda e valor a direita.
func set_note(note: PackedStringArray) -> void:
	var well := PanelContainer.new()
	well.theme_type_variation = &"LnWell"
	var row := HBoxContainer.new()
	var caption := Label.new()
	caption.theme_type_variation = &"LnNum"
	caption.text = note[0]
	caption.size_flags_horizontal = SIZE_EXPAND_FILL
	row.add_child(caption)
	var value := Label.new()
	value.theme_type_variation = &"LnNumCyan"
	value.text = note[1]
	row.add_child(value)
	well.add_child(row)
	_column.add_child(well)


## Tabela do raio da zona da fase 2: por passo, o instante, o raio em u e a barra (fracao da arena).
func set_zone(caption: String, steps: Array[PackedStringArray]) -> void:
	var box := VBoxContainer.new()
	box.theme_type_variation = &"LnVGapXs"
	var title := Label.new()
	title.theme_type_variation = &"LnNum"
	title.text = caption
	title.uppercase = true
	box.add_child(title)
	var row := HBoxContainer.new()
	row.theme_type_variation = &"LnHGapSm"
	for step: PackedStringArray in steps:
		var cell := VBoxContainer.new()
		cell.theme_type_variation = &"LnVGapXs"
		cell.size_flags_horizontal = SIZE_EXPAND_FILL
		var clock := Label.new()
		clock.theme_type_variation = &"LnNum"
		clock.text = step[0]
		cell.add_child(clock)
		var radius := Label.new()
		radius.theme_type_variation = &"LnNumError"
		radius.text = step[1]
		cell.add_child(radius)
		var bar := ProgressBar.new()
		bar.theme_type_variation = &"LnCpBarError"
		bar.show_percentage = false
		bar.min_value = 0.0
		bar.max_value = 100.0
		bar.value = step[2].to_float()
		bar.custom_minimum_size.y = 6.0
		cell.add_child(bar)
		row.add_child(cell)
	box.add_child(row)
	_column.add_child(box)


func title_text() -> String:
	return _title.text


func window_text() -> String:
	return _window.text


## Texto simples de cada regra: "Destaque texto".
func rule_texts() -> PackedStringArray:
	var found := PackedStringArray()
	for label: RichTextLabel in _rule_texts:
		found.append(label.get_parsed_text())
	return found


func rule_count() -> int:
	return _rules.get_child_count()


## Todos os textos da fase (regras, fita e tabela), para o teste varrer.
func all_texts() -> PackedStringArray:
	var found := PackedStringArray()
	for child: Node in find_children("*", "Label", true, false):
		found.append((child as Label).text)
	found.append_array(rule_texts())
	return found


func _start_pulse() -> void:
	if _pulse != null:
		_pulse.kill()
	_pulse = _pulse_dot.create_tween().set_loops()
	_pulse.tween_property(_pulse_dot, ^"modulate:a", PULSE_ALPHA, PULSE_SECONDS)
	_pulse.tween_property(_pulse_dot, ^"modulate:a", 1.0, PULSE_SECONDS)


## Tela escondida pela pilha: o pulso para.
func _on_visibility_changed() -> void:
	if _pulse == null or not _pulse.is_valid():
		return
	if is_visible_in_tree():
		_pulse.play()
	else:
		_pulse.pause()


func _rule_row(rule: ArenaMapTexts.Rule) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.theme_type_variation = &"LnHGapXs"
	var icon := Label.new()
	icon.theme_type_variation = ICON_TYPES[rule.accent]
	icon.text = rule.icon
	icon.size_flags_vertical = SIZE_SHRINK_BEGIN
	row.add_child(icon)
	var text := RichTextLabel.new()
	text.theme_type_variation = &"LnAmRule"
	text.bbcode_enabled = false
	text.fit_content = true
	text.scroll_active = false
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.size_flags_horizontal = SIZE_EXPAND_FILL
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text.push_bold()
	text.add_text(rule.title)
	text.pop()
	text.add_text(" " + rule.text)
	_rule_texts.append(text)
	row.add_child(text)
	return row
