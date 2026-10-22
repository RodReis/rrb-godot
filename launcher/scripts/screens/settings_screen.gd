class_name SettingsScreen
extends LauncherScreen
## Configuracoes (DV tela 8; FRONTEND-LAUNCHER §8: fiel a docs/prd/telas/Ajustes & Diagnostico
## de Rede/). Tres cards — controles, graficos, audio — e a aba Creditos. Edita um rascunho do
## settings.cfg; "Salvar & aplicar" grava pelo SettingsStore e o App aplica. Fora do prototipo
## (issue #80, decisoes do PI em 2026-10-15): telemetria netfox, simulador de rede, teste de rota,
## modo de camera, sombras/bloom/backend, suavizacao de mira, deadzone, voz e efeitos.

## Restaurar padroes pedido: o App confirma (ModalDialog) e chama restore_defaults().
signal reset_requested
## Gravacao falhou: o App mostra o erro (Toast).
signal save_failed(message: String)

enum Tab { CONTROLS, GRAPHICS, AUDIO, CREDITS }

const TAB_LABELS: Array[String] = [
	"CONTROLES & CÂMERA", "GRÁFICOS & PERFORMANCE", "ÁUDIO", "CRÉDITOS"
]
## Linhas de atalho: [rotulo, acoes (teclas lado a lado), tipo da tecla, tipo do rotulo].
const KEY_ROWS: Array[Array] = [
	[
		"Movimentação (360°)",
		[
			InputActions.MOVE_FORWARD,
			InputActions.MOVE_LEFT,
			InputActions.MOVE_BACK,
			InputActions.MOVE_RIGHT
		],
		&"LnKey",
		&"LnBody"
	],
	["Habilidade 1", [InputActions.SKILL_Q], &"LnKey", &"LnBody"],
	["Habilidade 2", [InputActions.SKILL_E], &"LnKey", &"LnBody"],
	["Ultimate", [InputActions.SKILL_R], &"LnKeyUltimate", &"LnBodyGold"],
	["Interagir / baús", [InputActions.INTERACT], &"LnKey", &"LnBody"],
	["Esquiva", [InputActions.DODGE], &"LnKeyCyan", &"LnBody"],
	["Placar", [InputActions.SCOREBOARD], &"LnKey", &"LnBody"],
	["Bestiário", [InputActions.OPEN_BESTIARY], &"LnKey", &"LnBody"],
	[
		"Zoom da câmera (aproxima · afasta · ou roda do mouse)",
		[InputActions.CAMERA_ZOOM_IN, InputActions.CAMERA_ZOOM_OUT],
		&"LnKey",
		&"LnBody"
	],
]
## Botoes do mouse (SPEC-045 §2): fixos, nao entram no settings.cfg.
const MOUSE_KEYS: Array[String] = ["M2 (DIR)", "M1 (ESQ)"]
## Nome da tecla no settings.cfg -> texto na tecla.
const KEY_NAMES: Dictionary[String, String] = {"Space": "ESPAÇO", "Equal": "=", "Minus": "-"}
## Tamanhos de janela oferecidos (16:9 e o 1366 x 768 comum); so os que cabem na tela.
const RESOLUTIONS: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1366, 768),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
	Vector2i(3840, 2160),
]
const SENSITIVITY_STEP: float = 0.05
const VOLUME_STEP: float = 0.01
const PERCENT: float = 100.0
## Feedback do botao salvar (prototipo: "Ajustes salvos com sucesso!" por 2 s).
const SAVED_FEEDBACK_SECONDS: float = 2.0
## Nota do card de graficos: o que vale onde.
const WHERE_IT_APPLIES: String = (
	"Vídeo e áudio valem no Launcher e na partida; neblina, iluminação, oclusão e grama só"
	+ " na partida."
)
## Fundo da tecla escutando: "..." ate a proxima tecla.
const LISTENING_TEXT: String = "…"

var _store: SettingsStore
var _draft: Dictionary = UserSettings.defaults()
var _tab: Tab = Tab.CONTROLS
var _tabs: Array[Button] = []
var _keycaps: Dictionary[StringName, Button] = {}
var _listening: StringName = &""
## Tecla cuja escuta o ultimo clique cancelou (o toggle dela nao reabre a escuta).
var _cancelled_by_click: StringName = &""
var _header: ScreenHeader = ScreenHeader.new()
## Corpo: os cards ou os creditos; so a aba visivel define a altura (a barra vem logo abaixo).
var _body: MarginContainer = MarginContainer.new()
var _columns: HBoxContainer
var _credits: CreditsView
var _save: Button = Button.new()
var _resolution: OptionButton
var _feedback: Tween


func _ready() -> void:
	var margin := MarginContainer.new()
	margin.theme_type_variation = &"LnScreenMargin"
	margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(margin)
	var page := VBoxContainer.new()
	page.theme_type_variation = &"LnVGapLg"
	margin.add_child(page)
	page.add_child(_header)
	_bind_header()
	_header.back_requested.connect(back_requested.emit)
	_build_tabs()
	page.add_child(_body)
	_credits = CreditsView.new()
	_body.add_child(_credits)
	page.add_child(_ribbon())
	_rebuild()
	select_tab(Tab.CONTROLS)
	_tabs[0].grab_focus.call_deferred()


## Escuta a tecla nova de um atalho: Esc cancela, clique cancela; troca sem conflito (rebind).
func _input(event: InputEvent) -> void:
	if _listening.is_empty():
		return
	var key := event as InputEventKey
	if key != null and key.pressed and not key.echo:
		get_viewport().set_input_as_handled()
		if key.physical_keycode != KEY_ESCAPE:
			_draft = UserSettings.rebind(_draft, _listening, key.physical_keycode)
		_stop_listening()
	elif event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		_cancelled_by_click = _listening
		_stop_listening()


func bind(store: SettingsStore) -> void:
	_store = store
	_draft = store.values.duplicate(true)
	if is_node_ready():
		_rebuild()


## Depois da confirmacao do App: grava os padroes e redesenha.
func restore_defaults() -> void:
	if _store == null:
		return
	if _store.reset() != OK:
		save_failed.emit(tr("Não foi possível gravar as configurações."))
		return
	_draft = _store.values.duplicate(true)
	_rebuild()


## Valores do formulario (o que "Salvar & aplicar" grava).
func draft() -> Dictionary:
	return _draft.duplicate(true)


## Aba visivel: os tres cards (controles, graficos, audio) ou os creditos.
func select_tab(tab: int) -> void:
	_tab = tab as Tab
	for i: int in _tabs.size():
		_tabs[i].set_pressed_no_signal(i == tab)
	_credits.visible = _tab == Tab.CREDITS
	# Creditos ocupam a altura toda (licenca do Godot rola); os cards so o que precisam.
	_body.size_flags_vertical = SIZE_EXPAND_FILL if _credits.visible else SIZE_SHRINK_BEGIN
	if _columns != null:
		_columns.visible = not _credits.visible


func _can_go_back_changed() -> void:
	if is_node_ready():
		_bind_header()


func _bind_header() -> void:
	_header.bind(
		tr("CONFIGURAÇÕES DO JOGO"),
		can_go_back,
		tr("Painel técnico"),
		UiIcons.TUNE,
		tr("Vídeo, áudio e controles do Launcher e da partida. Salvar grava e aplica na hora.")
	)


func _build_tabs() -> void:
	var well := PanelContainer.new()
	well.theme_type_variation = &"LnWell"
	_header.right_slot.add_child(well)
	var row := HBoxContainer.new()
	row.theme_type_variation = &"LnHGapXs"
	well.add_child(row)
	var group := ButtonGroup.new()
	for i: int in TAB_LABELS.size():
		var tab := Button.new()
		tab.theme_type_variation = &"LnTab"
		tab.text = tr(TAB_LABELS[i])
		tab.toggle_mode = true
		tab.button_group = group
		tab.pressed.connect(select_tab.bind(i))
		row.add_child(tab)
		_tabs.append(tab)


func _ribbon() -> PanelContainer:
	var ribbon := PanelContainer.new()
	ribbon.theme_type_variation = &"LnRibbon"
	var row := HBoxContainer.new()
	row.theme_type_variation = &"LnHGapSm"
	ribbon.add_child(row)
	var reset := Button.new()
	reset.theme_type_variation = &"LnButton"
	reset.text = "%s  %s" % [UiIcons.RESTART_ALT, tr("RESTAURAR PADRÕES")]
	reset.pressed.connect(reset_requested.emit)
	row.add_child(reset)
	var spacer := Control.new()
	spacer.size_flags_horizontal = SIZE_EXPAND_FILL
	row.add_child(spacer)
	_save.theme_type_variation = &"LnButtonPrimary"
	_save.text = _save_text()
	_save.pressed.connect(_on_save_pressed)
	row.add_child(_save)
	return ribbon


func _rebuild() -> void:
	_stop_listening()
	if _columns != null:
		_body.remove_child(_columns)
		_columns.queue_free()
	_keycaps.clear()
	_columns = HBoxContainer.new()
	_columns.theme_type_variation = &"LnHGapLg"
	_body.add_child(_columns)
	_controls_card(
		_card(
			UiIcons.SPORTS_ESPORTS,
			&"LnIconGold",
			"CONTROLES & MAPEAMENTO",
			"PC FIRST",
			&"LnNumGold"
		)
	)
	_graphics_card(
		_card(
			UiIcons.DISPLAY_SETTINGS, &"LnIconCyan", "GRÁFICOS & RENDERER", "FORWARD+", &"LnNumCyan"
		)
	)
	_audio_card(_card(UiIcons.VOLUME_UP, &"LnIconGold", "ÁUDIO", "", &""))
	select_tab(_tab)


## Card do prototipo: icone em caixa, titulo, chip opcional, divisor; devolve a coluna do conteudo.
func _card(
	icon: String, icon_type: StringName, title: String, chip: String, chip_type: StringName
) -> VBoxContainer:
	var card := PanelContainer.new()
	card.theme_type_variation = &"LnCard"
	card.size_flags_horizontal = SIZE_EXPAND_FILL
	card.size_flags_vertical = SIZE_SHRINK_BEGIN
	_columns.add_child(card)
	var column := VBoxContainer.new()
	column.theme_type_variation = &"LnVGapMd"
	card.add_child(column)
	var header := HBoxContainer.new()
	header.theme_type_variation = &"LnHGapSm"
	column.add_child(header)
	var box := PanelContainer.new()
	box.theme_type_variation = &"LnIconBox"
	header.add_child(box)
	box.add_child(_label(icon, icon_type))
	var caption := _label(tr(title), &"LnHeadlineSm")
	caption.size_flags_horizontal = SIZE_EXPAND_FILL
	header.add_child(caption)
	if not chip.is_empty():
		var chip_box := PanelContainer.new()
		chip_box.theme_type_variation = &"LnChip"
		chip_box.size_flags_vertical = SIZE_SHRINK_CENTER
		chip_box.add_child(_label(chip, chip_type))
		header.add_child(chip_box)
	var divider := HSeparator.new()
	divider.theme_type_variation = &"LnDivider"
	column.add_child(divider)
	return column


func _controls_card(column: VBoxContainer) -> void:
	column.add_child(_section(tr("Atalhos primários")))
	var rows := VBoxContainer.new()
	rows.theme_type_variation = &"LnVGapXs"
	column.add_child(rows)
	for i: int in KEY_ROWS.size():
		var spec: Array = KEY_ROWS[i]
		var row := SettingRow.new(tr(spec[0]), "", spec[3])
		for action: StringName in spec[1]:
			row.controls.add_child(_keycap(action, spec[2]))
		rows.add_child(row)
		if i == 0:
			rows.add_child(_mouse_row())
	column.add_child(_section(tr("Câmera e controle")))
	var controls: Dictionary = _draft[UserSettings.CONTROLS]
	column.add_child(
		_slider(
			tr("Sensibilidade do mouse (giro da câmera)"),
			UserSettings.CONTROLS,
			UserSettings.MOUSE_SENSITIVITY,
			UserSettings.SENSITIVITY_MIN,
			UserSettings.SENSITIVITY_MAX,
			SENSITIVITY_STEP,
			func(value: float) -> String: return "%.2fx" % value
		)
	)
	column.add_child(
		_switch(tr("Controle (gamepad)"), "", UserSettings.CONTROLS, UserSettings.GAMEPAD, controls)
	)


func _graphics_card(column: VBoxContainer) -> void:
	var video: Dictionary = _draft[UserSettings.VIDEO]
	var window_mode := SettingRow.new(tr("Tipo de tela"), tr("A resolução só vale em Modo Janela"))
	window_mode.controls.add_child(_window_mode_picker(video))
	column.add_child(window_mode)
	var resolution := SettingRow.new(tr("Resolução de exibição"))
	resolution.controls.add_child(_resolution_picker(video))
	column.add_child(resolution)
	var fps := SettingRow.new(tr("Limite de quadros"))
	var group := ButtonGroup.new()
	for cap: int in UserSettings.FPS_CAPS:
		var segment := Button.new()
		segment.theme_type_variation = &"LnSegment"
		segment.text = "∞" if cap == UserSettings.FPS_UNLIMITED else str(cap)
		segment.toggle_mode = true
		segment.button_group = group
		segment.button_pressed = video[UserSettings.FPS_CAP] == cap
		segment.pressed.connect(_set_value.bind(UserSettings.VIDEO, UserSettings.FPS_CAP, cap))
		fps.controls.add_child(segment)
	column.add_child(fps)
	column.add_child(
		_slider(
			tr("Tamanho da interface na partida"),
			UserSettings.UI,
			UserSettings.HUD_SCALE,
			UserSettings.HUD_SCALE_MIN,
			UserSettings.HUD_SCALE_MAX,
			UserSettings.HUD_SCALE_STEP,
			func(value: float) -> String: return "%d%%" % roundi(value * PERCENT)
		)
	)
	column.add_child(
		_switch(
			tr("Alerta de dano"),
			tr("Bordas vermelhas ao levar dano e com HP baixo"),
			UserSettings.UI,
			UserSettings.DAMAGE_ALERT,
			_draft[UserSettings.UI]
		)
	)
	column.add_child(
		_switch(
			tr("Sincronização vertical (V-Sync)"),
			tr("Menor latência de input quando OFF"),
			UserSettings.VIDEO,
			UserSettings.VSYNC,
			video
		)
	)
	var graphics: Dictionary = _draft[UserSettings.GRAPHICS]
	for spec: Array in [
		[UserSettings.FOG, "Neblina volumétrica", "Atmosfera do vale"],
		[UserSettings.SSIL, "Iluminação indireta (SSIL)", "Luz rebatida no cenário"],
		[UserSettings.SSAO, "Oclusão de ambiente (SSAO)", "Profundidade de cantos da arena"],
		[UserSettings.GRASS, "Grama decorativa", "Tufos de grama do terreno"],
	]:
		column.add_child(
			_switch(tr(spec[1]), tr(spec[2]), UserSettings.GRAPHICS, spec[0], graphics)
		)
	var note := PanelContainer.new()
	note.theme_type_variation = &"LnWell"
	var text := VBoxContainer.new()
	text.theme_type_variation = &"LnVGapXs"
	note.add_child(text)
	text.add_child(_label(tr("ONDE VALE"), &"LnNumGold"))
	var body := _label(tr(WHERE_IT_APPLIES), &"LnBodySmMuted")
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_child(body)
	column.add_child(note)


func _audio_card(column: VBoxContainer) -> void:
	var as_percent := func(value: float) -> String: return "%d%%" % roundi(value * PERCENT)
	for spec: Array in [
		[UserSettings.MASTER, "Volume geral"], [UserSettings.MUSIC, "Alertas e música"]
	]:
		column.add_child(
			_slider(
				tr(spec[1]),
				UserSettings.AUDIO,
				spec[0],
				UserSettings.VOLUME_MIN,
				UserSettings.VOLUME_MAX,
				VOLUME_STEP,
				as_percent
			)
		)


func _mouse_row() -> SettingRow:
	var row := SettingRow.new(tr("Ataque básico · girar câmera"))
	for text: String in MOUSE_KEYS:
		row.controls.add_child(_label(text, &"LnKeyLabel"))
	return row


func _keycap(action: StringName, type: StringName) -> Button:
	var keycap := Button.new()
	keycap.theme_type_variation = type
	keycap.toggle_mode = true
	keycap.custom_minimum_size.x = UiTokens.SIZE_TARGET_MIN  # alvo minimo (FRONTEND §5)
	keycap.text = _key_text(action)
	keycap.tooltip_text = tr("Clique e aperte a tecla nova (Esc cancela)")
	keycap.pressed.connect(_start_listening.bind(action))
	_keycaps[action] = keycap
	return keycap


func _resolution_picker(video: Dictionary) -> OptionButton:
	var picker := OptionButton.new()
	_resolution = picker
	picker.theme_type_variation = &"LnOption"
	picker.get_popup().theme_type_variation = &"LnPopup"
	var current := Vector2i(video[UserSettings.WIDTH], video[UserSettings.HEIGHT])
	var screen := DisplayServer.screen_get_size()
	var sizes: Array[Vector2i] = []
	for res_size: Vector2i in RESOLUTIONS:
		if res_size == current or (res_size.x <= screen.x and res_size.y <= screen.y):
			sizes.append(res_size)
	if current not in sizes:
		sizes.append(current)
	for res_size: Vector2i in sizes:
		picker.add_item("%d x %d" % [res_size.x, res_size.y])
		picker.set_item_metadata(picker.item_count - 1, res_size)
		if res_size == current:
			picker.select(picker.item_count - 1)
	picker.disabled = not SettingsApplier.uses_resolution(video[UserSettings.WINDOW_MODE])
	picker.item_selected.connect(
		func(index: int) -> void:
			var chosen: Vector2i = picker.get_item_metadata(index)
			_set_value(UserSettings.VIDEO, UserSettings.WIDTH, chosen.x)
			_set_value(UserSettings.VIDEO, UserSettings.HEIGHT, chosen.y)
	)
	return picker


## Tipo de tela (F79, ADR-0019): uma opcao por UserSettings.WINDOW_MODES, na mesma ordem.
func _window_mode_picker(video: Dictionary) -> OptionButton:
	var picker := OptionButton.new()
	picker.theme_type_variation = &"LnOption"
	picker.get_popup().theme_type_variation = &"LnPopup"
	for label: String in [tr("Modo Janela"), tr("Janela sem Borda"), tr("Tela Cheia Exclusiva")]:
		picker.add_item(label)
	picker.select(UserSettings.WINDOW_MODES.find(video[UserSettings.WINDOW_MODE]))
	picker.item_selected.connect(
		func(index: int) -> void:
			_set_value(
				UserSettings.VIDEO, UserSettings.WINDOW_MODE, UserSettings.WINDOW_MODES[index]
			)
	)
	return picker


func _switch(
	label: String, sub: String, section: String, key: String, values: Dictionary
) -> SettingRow:
	var row := SettingRow.new(label, sub)
	var toggle := CheckButton.new()
	toggle.theme_type_variation = &"LnSwitch"
	toggle.button_pressed = values[key]
	toggle.toggled.connect(func(on: bool) -> void: _set_value(section, key, on))
	row.controls.add_child(toggle)
	return row


## Rotulo e valor em cima, trilho embaixo (prototipo: "Sensibilidade do Mouse ... 1.35x").
func _slider(
	label: String,
	section: String,
	key: String,
	min_value: float,
	max_value: float,
	step: float,
	format: Callable
) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.theme_type_variation = &"LnVGapXs"
	var top := HBoxContainer.new()
	column.add_child(top)
	var caption := _label(label, &"LnBodySm")
	caption.size_flags_horizontal = SIZE_EXPAND_FILL
	top.add_child(caption)
	var shown := _label("", &"LnNumGold")
	top.add_child(shown)
	var slider := HSlider.new()
	slider.theme_type_variation = &"LnSlider"
	slider.min_value = min_value
	slider.max_value = max_value
	slider.step = step
	slider.value = _draft[section][key]
	shown.text = format.call(slider.value)
	slider.value_changed.connect(
		func(value: float) -> void:
			shown.text = format.call(value)
			_set_value(section, key, value)
	)
	column.add_child(slider)
	return column


func _section(text: String) -> Label:
	var label := _label(text, &"LnNum")
	label.uppercase = true
	return label


func _label(text: String, type: StringName) -> Label:
	var label := Label.new()
	label.theme_type_variation = type
	label.text = text
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label


## Copia do rascunho com o valor trocado (o rascunho nunca e mutado no lugar).
func _set_value(section: String, key: String, value: Variant) -> void:
	var copy := _draft.duplicate(true)
	copy[section][key] = value
	_draft = copy
	if section == UserSettings.VIDEO and key == UserSettings.WINDOW_MODE:
		_resolution.disabled = not SettingsApplier.uses_resolution(value)  # so vale em janela


func _key_text(action: StringName) -> String:
	var key: String = _draft[UserSettings.CONTROLS][String(action)]
	return KEY_NAMES[key] if KEY_NAMES.has(key) else key.to_upper()


## Clicar de novo na tecla que esta escutando cancela (o clique do mouse ja parou a escuta no
## press; o toggle chega no release com _listening vazio, entao a tecla lembra quem cancelou).
func _start_listening(action: StringName) -> void:
	var was_listening := _listening == action or _cancelled_by_click == action
	_cancelled_by_click = &""
	_stop_listening()
	if was_listening:
		return
	_listening = action
	var keycap := _keycaps[action]
	keycap.set_pressed_no_signal(true)
	keycap.text = LISTENING_TEXT


func _stop_listening() -> void:
	_listening = &""
	for action: StringName in _keycaps:
		_keycaps[action].set_pressed_no_signal(false)
		_keycaps[action].text = _key_text(action)


func _save_text() -> String:
	return "%s  %s" % [UiIcons.SAVE, tr("SALVAR & APLICAR ALTERAÇÕES")]


func _on_save_pressed() -> void:
	_stop_listening()
	if _store == null or _store.save(_draft) != OK:
		save_failed.emit(tr("Não foi possível gravar as configurações."))
		return
	_save.text = "%s  %s" % [UiIcons.DONE_ALL, tr("AJUSTES SALVOS COM SUCESSO!")]
	if _feedback != null:
		_feedback.kill()
	_feedback = create_tween()
	_feedback.tween_interval(SAVED_FEEDBACK_SECONDS)
	_feedback.tween_callback(func() -> void: _save.text = _save_text())
