class_name LoginScreen
extends LauncherScreen
## Login e cadastro (DV tela 1; FRONTEND-LAUNCHER §8: fiel a docs/prd/telas/Tela de Login &
## Autenticacao/). Esquerda: marca, descricao e a arte do duelo (render dos assets reais);
## direita: cartao de vidro com as abas Entrar / Criar conta, e-mail, senha (com olho), regra de
## senha no cadastro, envio e o treino offline vs bot (sem conta). Fora do prototipo (issue #81,
## §8.3): lembrar credenciais, esqueceu, regiao, badges tecnicos, patch e numeros de exemplo.
## Chama o AuthService; com sessao aberta emite authenticated e o App leva ao lobby.

signal authenticated
## Treino offline vs bot (nao depende do backend, ARCHITECTURE-LAUNCHER §6).
signal practice_requested

enum Mode { LOGIN, REGISTER }

## Arte do duelo (render do diorama com os herois reais, tools/launcher/render_login_art.gd).
const ART_PATH: String = "res://shared/assets/ui/login_duel.png"
const KNIGHT: HeroData = preload("res://shared/data/heroes/knight.tres")
const RANGER: HeroData = preload("res://shared/data/heroes/ranger.tres")
const RULES: MatchRules = preload("res://shared/data/rules/match_pacing.tres")
const SECONDS_PER_MINUTE: float = 60.0
## lg:grid-cols-12: 7 colunas de texto e arte, 5 do cartao; gap space-xl.
const LEFT_COLUMNS: float = 7.0
const RIGHT_COLUMNS: float = 5.0
## Arte h-72 e paragrafo max-w-xl.
const ART_HEIGHT: float = 288.0
const TEXT_MAX_WIDTH: float = 576.0
## Icone da marca no Login (F82): proporcional ao wordmark de 56 px.
const BRAND_ICON_SIZE: float = 72.0
## Fundo: blur-3xl de tres circulos (cor, centro UV, raio px).
const GLOW_GOLD: Color = Color(UiTokens.GOLD, 0.10)
const GLOW_BLUE: Color = Color(UiTokens.BLUE, 0.15)
const GLOW_TINT: Color = Color(UiTokens.GOLD_BRIGHT, 0.05)
## Arte: gradiente to-t de surface a transparente.
const ART_FADE: Color = Color(0.043, 0.075, 0.149)

var _auth: AuthService
var _mode: Mode = Mode.LOGIN
var _tabs: Array[Button] = []
var _banner: PanelContainer = PanelContainer.new()
var _banner_text: Label = Label.new()
var _email_row: FormRow = FormRow.new()
var _password_row: FormRow = FormRow.new()
var _email: IconField = IconField.new()
var _password: IconField = IconField.new()
var _rule: Label = Label.new()
var _submit: Button = Button.new()
var _practice: Button = Button.new()


func _ready() -> void:
	var backdrop := Backdrop.new()
	backdrop.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	backdrop.glow(0, GLOW_GOLD, Vector2(0.03, 0.06), 256.0)
	backdrop.glow(1, GLOW_BLUE, Vector2(0.85, 0.95), 304.0)
	backdrop.glow(2, GLOW_TINT, Vector2(0.42, 0.5), 200.0)
	add_child(backdrop)
	var margin := MarginContainer.new()
	margin.theme_type_variation = &"LnScreenMarginXl"
	margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(margin)
	var columns := HBoxContainer.new()
	columns.theme_type_variation = &"LnHGapXl"
	columns.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(columns)
	columns.add_child(_left_column())
	columns.add_child(_card())
	select_mode(Mode.LOGIN)
	_email.line_edit.grab_focus.call_deferred()


func bind(auth: AuthService) -> void:
	_auth = auth


func select_mode(mode: Mode) -> void:
	_mode = mode
	for tab: Mode in [Mode.LOGIN, Mode.REGISTER]:
		_tabs[tab].set_pressed_no_signal(tab == mode)
	var register := mode == Mode.REGISTER
	_rule.visible = register
	_restore_submit_text()
	_password.line_edit.placeholder_text = tr("mín. 8, letra e número") if register else ""
	_clear_errors()


## Envia (botao ou Enter): valida e chama o backend pelo AuthService; erro no campo ou na faixa.
func submit() -> void:
	if _auth == null or _submit.disabled:
		return
	_clear_errors()
	_set_busy(true)
	var email := _email.line_edit.text
	var password := _password.line_edit.text
	var result: AuthService.Result
	if _mode == Mode.REGISTER:
		result = await _auth.register(email, password)
	else:
		result = await _auth.login(email, password)
	_set_busy(false)
	if result.ok:
		authenticated.emit()
		return
	match result.field:
		AuthService.Field.EMAIL:
			_email_row.set_error(result.message)
			_email.line_edit.grab_focus()
		AuthService.Field.PASSWORD:
			_password_row.set_error(result.message)
			_rule.visible = false  # o erro ja diz a regra
			_password.line_edit.grab_focus()
		_:
			_banner_text.text = "%s  %s" % [UiIcons.ERROR, result.message]
			_banner.visible = true


func email_field() -> LineEdit:
	return _email.line_edit


func password_field() -> LineEdit:
	return _password.line_edit


func submit_button() -> Button:
	return _submit


func error_text() -> String:
	return _banner_text.text if _banner.visible else ""


func _left_column() -> VBoxContainer:
	var column := VBoxContainer.new()
	column.theme_type_variation = &"LnVGapLg"
	column.size_flags_horizontal = SIZE_EXPAND_FILL
	column.size_flags_stretch_ratio = LEFT_COLUMNS
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	var brand := BrandLogo.make(BRAND_ICON_SIZE, UiTokens.TYPE_LN_DISPLAY)
	brand.size_flags_horizontal = SIZE_SHRINK_BEGIN
	column.add_child(brand)
	var text := Label.new()
	text.theme_type_variation = &"LnBodyLg"
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.custom_minimum_size.x = TEXT_MAX_WIDTH
	text.size_flags_horizontal = SIZE_SHRINK_BEGIN
	text.text = (
		(
			tr("Duelos 1v1 de até %d minutos em dois tempos: %d minutos de preparação — monstros,")
			% [
				roundi(RULES.max_match_duration / SECONDS_PER_MINUTE),
				roundi(RULES.phase1_duration / SECONDS_PER_MINUTE)
			]
		)
		+ " "
		+ tr("baús e itens — e o confronto final, com a zona fechando.")
	)
	column.add_child(text)
	column.add_child(_art())
	return column


## Arte do duelo (h-72 rounded-xl shadow-xl) com o gradiente to-t e os chips dos dois herois.
func _art() -> PanelContainer:
	var frame := PanelContainer.new()
	frame.theme_type_variation = &"LnArtFrame"
	frame.custom_minimum_size.y = ART_HEIGHT
	frame.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	var art := TextureRect.new()
	art.texture = load(ART_PATH) as Texture2D
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	frame.add_child(art)
	var fade := Backdrop.new()
	fade.gradient(ART_FADE, Color(ART_FADE, 0.4), Color(ART_FADE, 0.0))
	frame.add_child(fade)
	var chips := MarginContainer.new()
	chips.theme_type_variation = &"LnInsetMd"
	frame.add_child(chips)
	var row := HBoxContainer.new()
	row.theme_type_variation = &"LnHGapXs"
	row.size_flags_vertical = SIZE_SHRINK_BEGIN
	row.size_flags_horizontal = SIZE_SHRINK_BEGIN
	chips.add_child(row)
	row.add_child(_hero_chip(UiIcons.SHIELD_WITH_HEART, &"LnIconGold", KNIGHT.display_name))
	row.add_child(_hero_chip(UiIcons.CRISIS_ALERT, &"LnIconCyan", RANGER.display_name))
	return frame


func _hero_chip(icon: String, icon_type: StringName, hero_name: String) -> GlassPanel:
	var chip := GlassPanel.new(GlassPanel.BLUR_MD)
	chip.theme_type_variation = &"LnChipGlass"
	var row := HBoxContainer.new()
	row.theme_type_variation = &"LnHGapXs"
	chip.add_child(row)
	var glyph := Label.new()
	glyph.theme_type_variation = icon_type
	glyph.text = icon
	row.add_child(glyph)
	var label := Label.new()
	label.theme_type_variation = &"LnNumText"
	label.text = hero_name
	row.add_child(label)
	return chip


func _card() -> GlassPanel:
	var card := GlassPanel.new(GlassPanel.BLUR_XL)
	card.theme_type_variation = &"LnCardGlass"
	card.size_flags_horizontal = SIZE_EXPAND_FILL
	card.size_flags_stretch_ratio = RIGHT_COLUMNS
	card.size_flags_vertical = SIZE_SHRINK_CENTER
	var form := VBoxContainer.new()
	form.theme_type_variation = &"LnVGapMd"
	card.add_child(form)
	form.add_child(_tab_track())
	_banner.theme_type_variation = &"LnBannerError"
	_banner.visible = false
	_banner_text.theme_type_variation = &"LnBodySmError"
	_banner_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_banner.add_child(_banner_text)
	form.add_child(_banner)
	_email_row.bind(tr("E-mail"))
	_email.bind(UiIcons.ACCOUNT_CIRCLE, "seu@email.com")
	_email.line_edit.text_submitted.connect(_on_field_submitted.unbind(1))
	_email_row.add_child(_email)
	form.add_child(_email_row)
	_password_row.bind(tr("Senha"))
	_password.bind(UiIcons.KEY, "")
	_password.make_secret()
	_password.line_edit.text_submitted.connect(_on_field_submitted.unbind(1))
	_password_row.add_child(_password)
	_rule.theme_type_variation = &"LnBodySmMuted"
	_rule.text = "%s  %s" % [UiIcons.INFO, tr("Mínimo de 8 caracteres, com letra e número.")]
	_password_row.add_child(_rule)
	form.add_child(_password_row)
	_submit.theme_type_variation = &"LnButtonSubmit"
	_submit.pressed.connect(submit)
	form.add_child(_submit)
	_practice.theme_type_variation = &"LnButtonCyan"
	_practice.text = "%s  %s" % [UiIcons.SMART_TOY, tr("Treinar contra o bot (offline, sem conta)")]
	_practice.pressed.connect(practice_requested.emit)
	form.add_child(_practice)
	return card


func _tab_track() -> PanelContainer:
	var track := PanelContainer.new()
	track.theme_type_variation = &"LnTabTrack"
	var row := HBoxContainer.new()
	row.theme_type_variation = &"LnHGapNone"
	track.add_child(row)
	var group := ButtonGroup.new()
	group.allow_unpress = false
	for mode: Mode in [Mode.LOGIN, Mode.REGISTER]:
		var tab := Button.new()
		tab.theme_type_variation = &"LnAuthTab"
		tab.text = tr("ENTRAR") if mode == Mode.LOGIN else tr("CRIAR CONTA")
		tab.toggle_mode = true
		tab.button_group = group
		tab.size_flags_horizontal = SIZE_EXPAND_FILL
		tab.pressed.connect(select_mode.bind(mode))
		row.add_child(tab)
		_tabs.append(tab)
	return track


func _set_busy(busy: bool) -> void:
	_submit.disabled = busy
	_practice.disabled = busy
	for tab: Button in _tabs:
		tab.disabled = busy
	if busy:
		var doing := tr("CRIANDO CONTA…") if _mode == Mode.REGISTER else tr("ENTRANDO…")
		_submit.text = "%s  %s" % [UiIcons.PROGRESS_ACTIVITY, doing]
	else:
		_restore_submit_text()


func _restore_submit_text() -> void:
	var register := _mode == Mode.REGISTER
	_submit.text = (
		"%s  %s" % [UiIcons.HOW_TO_REG, tr("FORJAR NOVA CONTA")]
		if register
		else "%s  %s" % [UiIcons.SWORDS, tr("ENTRAR NA ARENA")]
	)


func _clear_errors() -> void:
	_rule.visible = _mode == Mode.REGISTER
	_banner.visible = false
	_email_row.clear_error()
	_password_row.clear_error()


## Enter no e-mail vai para a senha; na senha, envia.
func _on_field_submitted() -> void:
	if _email.line_edit.has_focus() and _password.line_edit.text.is_empty():
		_password.line_edit.grab_focus()
	else:
		submit()
