class_name LoginScreen
extends LauncherScreen
## Login e cadastro (DV tela 1; FRONTEND-LAUNCHER §8: fiel a docs/prd/telas/Tela de Login &
## Autenticacao/). Fundo: a arena de noite (render real) sob um veu. Esquerda: marca, descricao, a
## arte com os herois na arena (render dos assets reais) e a faixa de numeros reais (F82);
## direita: cartao de vidro com as abas Entrar / Criar conta, e-mail, senha (com olho), regra de
## senha no cadastro e envio. O treino vs bot fica no Lobby, depois do login (PI, F81). Fora do
## prototipo (issue #81, §8.3): lembrar credenciais, esqueceu, regiao, badges tecnicos, patch e
## numeros de exemplo.
## Chama o AuthService; com sessao aberta emite authenticated e o App leva ao lobby.

signal authenticated

enum Mode { LOGIN, REGISTER }

## Arte: os herois na arena (tools/ui/render_loading.gd --only=login_duel). Fundo: a arena de noite
## da tela de loading, sob o veu BG_VEIL (o formulario precisa de contraste).
const ART_PATH: String = "res://shared/assets/ui/login_duel.png"
const BG_PATH: String = "res://shared/assets/ui/loading/arena_night.png"
const BG_VEIL: Color = Color(0.043, 0.075, 0.149, 0.78)
const RULES: MatchRules = preload("res://shared/data/rules/match_pacing.tres")
const SECONDS_PER_MINUTE: float = 60.0
## lg:grid-cols-12: 7 colunas de texto e arte, 5 do cartao; gap space-xl.
const LEFT_COLUMNS: float = 7.0
const RIGHT_COLUMNS: float = 5.0
## Arte (maior que o h-72 do prototipo desde o F82: ocupa o vazio da tela) e paragrafo max-w-xl.
const ART_HEIGHT: float = 360.0
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
var _hero_count: Label = Label.new()
var _hero_stat: PanelContainer


func _ready() -> void:
	var arena := TextureRect.new()
	arena.texture = load(BG_PATH) as Texture2D
	arena.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	arena.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	arena.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(arena)
	var veil := ColorRect.new()
	veil.color = BG_VEIL
	veil.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(veil)
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


## [param catalog]: numero de herois da faixa (sem catalogo, o bloco some).
func bind(auth: AuthService, catalog: CatalogService = null) -> void:
	_auth = auth
	var heroes := catalog.heroes.size() if catalog != null else 0
	_hero_count.text = str(heroes)
	_hero_stat.visible = heroes > 0


## Numero de herois da faixa; vazio se o bloco esta escondido.
func hero_count_text() -> String:
	return _hero_count.text if _hero_stat.visible else ""


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
	column.add_child(_stats())
	return column


## Arte (h-72 rounded-xl shadow-xl) com o gradiente to-t de baixo para cima.
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
	return frame


## Faixa de 3 numeros do prototipo, so com dado real: herois do catalogo, o modo e a duracao maxima.
func _stats() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.theme_type_variation = &"LnHGapMd"
	_hero_stat = _stat(_hero_count, tr("HERÓIS JOGÁVEIS"))
	_hero_stat.visible = false  # aparece no bind, com o catalogo
	row.add_child(_hero_stat)
	var duel := Label.new()
	duel.text = "1V1"
	row.add_child(_stat(duel, tr("DUELO ONLINE")))
	var minutes := Label.new()
	minutes.text = tr("%d MIN") % roundi(RULES.max_match_duration / SECONDS_PER_MINUTE)
	row.add_child(_stat(minutes, tr("PARTIDA MÁXIMA")))
	return row


func _stat(value: Label, caption: String) -> PanelContainer:
	var box := PanelContainer.new()
	box.theme_type_variation = &"LnCard"
	box.size_flags_horizontal = SIZE_EXPAND_FILL
	var column := VBoxContainer.new()
	box.add_child(column)
	value.theme_type_variation = &"LnHeadlineMdGold"
	column.add_child(value)
	var label := Label.new()
	label.theme_type_variation = &"LnBodySmMuted"
	label.text = caption
	column.add_child(label)
	return box


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
