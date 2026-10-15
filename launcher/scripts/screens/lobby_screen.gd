class_name LobbyScreen
extends LauncherScreen
## Lobby (DV tela 1; FRONTEND-LAUNCHER §8: fiel a docs/prd/telas/Menu Principal/screen1.png). O
## fundo e o diorama 3D (heroi em destaque no pedestal, ARCHITECTURE-LAUNCHER §3.5) com o
## gradiente e os brilhos do prototipo. Sub-menu (JOGAR, TREINO, CONFIGURACOES); a esquerda o
## heroi em destaque (dados de shared/data); a direita o console da fila (status, tempo na fila e
## servidor reais; BUSCAR PARTIDA / CANCELAR FILA) e o modo de batalha; embaixo, treino vs bot e
## a conta (sair). Fora do prototipo (issue #81, §8.3): ELO, 2v2/3v3, Herois e MUDAR, fila media,
## jogadores na fila, historico (F26), versao, netfox e jitter.
## A fila e um estado do lobby: chama o QueueService; o App lanca o Game no matched.

signal practice_requested
signal settings_requested
signal logout_requested

enum QueueState { IDLE, JOINING, SEARCHING, MATCHED, ERROR }

const HERO: HeroData = preload("res://shared/data/heroes/knight.tres")
const RULES: MatchRules = preload("res://shared/data/rules/match_pacing.tres")
const DIORAMA: PackedScene = preload("res://scenes/diorama/lobby_diorama.tscn")
const SECONDS_PER_MINUTE: float = 60.0
## lg:col-span-6 xl:col-span-7 / 5; area do heroi h-[580px].
const LEFT_COLUMNS: float = 7.0
const RIGHT_COLUMNS: float = 5.0
const HERO_AREA_HEIGHT: float = 580.0
## Banner do heroi max-w-xl; caixas de icone w-12 (heroi), w-10 (relogio e cartoes), w-8 (modo).
const BANNER_MAX_WIDTH: float = 576.0
const ICON_BOX_LG: Vector2 = Vector2(48, 48)
const ICON_BOX_MD: Vector2 = Vector2(40, 40)
const ICON_BOX_SM: Vector2 = Vector2(32, 32)
const QUEUE_DOT: Vector2 = Vector2(12, 12)
## Fundo: gradient-to-t (background -> background/40 -> lowest/70, aliviado para o diorama
## aparecer como a imagem do prototipo a brightness-75) e as runas que pulsam (4 s e 6 s).
const BG: Color = Color(0.043, 0.075, 0.149)
const FADE_BOTTOM: Color = Color(BG, 0.92)
const FADE_MID: Color = Color(BG, 0.2)
const FADE_TOP: Color = Color(0.024, 0.055, 0.125, 0.55)
const VIGNETTE_CENTER: Color = Color(UiTokens.GOLD_BRIGHT, 0.04)
const VIGNETTE_EDGE: Color = Color(BG, 0.6)
const RUNE_GLOW: Color = Color(UiTokens.GOLD_BRIGHT, 0.28)
## Pulso do ponto da fila (animate-ping).
const PING_SECONDS: float = 0.8
const TICK_SECONDS: float = 1.0

var _queue: QueueService
var _state: QueueState = QueueState.IDLE
var _elapsed: int = 0
var _tick: Timer = Timer.new()
var _diorama: LobbyDiorama
var _cta: CtaButton = CtaButton.new()
var _play: Button = Button.new()
var _status_cell: Label = Label.new()
var _time_cell: Label = Label.new()
var _server_cell: Label = Label.new()
var _banner: PanelContainer = PanelContainer.new()
var _banner_dot: Panel = Panel.new()
var _banner_text: Label = Label.new()
var _banner_clock: Label = Label.new()
var _retry: Button = Button.new()
var _account: Label = Label.new()


func _ready() -> void:
	_diorama = DIORAMA.instantiate() as LobbyDiorama
	_diorama.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(_diorama)
	add_child(_backdrop())
	var margin := MarginContainer.new()
	margin.theme_type_variation = &"LnScreenMarginXl"
	margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(margin)
	var page := VBoxContainer.new()
	page.theme_type_variation = &"LnVGapMd"
	margin.add_child(page)
	page.add_child(_sub_nav())
	var middle := HBoxContainer.new()
	middle.theme_type_variation = &"LnHGapLg"
	middle.size_flags_vertical = SIZE_EXPAND_FILL
	middle.alignment = BoxContainer.ALIGNMENT_CENTER
	page.add_child(middle)
	middle.add_child(_hero_area())
	middle.add_child(_console_column())
	page.add_child(_bento())
	_tick.wait_time = TICK_SECONDS
	_tick.timeout.connect(_on_tick_timeout)
	add_child(_tick)
	var ping := create_tween().set_loops()
	ping.tween_property(_banner_dot, ^"modulate:a", 0.2, PING_SECONDS)
	ping.tween_property(_banner_dot, ^"modulate:a", 1.0, PING_SECONDS)
	_show_state(QueueState.IDLE)
	_cta.grab_focus.call_deferred()


func bind(queue: QueueService, account_email: String) -> void:
	_queue = queue
	_account.text = account_email
	_queue.searching.connect(_on_queue_searching)
	_queue.matched.connect(_on_queue_matched.unbind(2))
	_queue.cancelled.connect(_show_state.bind(QueueState.IDLE))
	_queue.failed.connect(_on_queue_failed)


## Status real do backend no console (celula SERVIDOR); antes da 1a checagem, um traco.
func set_backend_status(online: bool, ping_ms: int, checked: bool = true) -> void:
	_server_cell.text = "%d ms" % ping_ms if online and ping_ms >= 0 else tr("OFFLINE")
	if not checked:
		_server_cell.text = "—"
	_server_cell.theme_type_variation = &"LnNumMdCyan" if online else &"LnNumMd"


## Partida aberta: o console volta ao inicio quando o Game encerra (App chama reset_queue).
func reset_queue() -> void:
	_show_state(QueueState.IDLE)


## Mensagem de erro no console (ex.: o Game nao abriu), com "Tentar de novo" = nova fila.
func show_error(message: String) -> void:
	_show_state(QueueState.ERROR, message)


func queue_state() -> QueueState:
	return _state


func cta() -> CtaButton:
	return _cta


func diorama() -> LobbyDiorama:
	return _diorama


func banner_text() -> String:
	return _banner_text.text if _banner.visible else ""


## BUSCAR PARTIDA (ou JOGAR / Tentar de novo) e CANCELAR FILA no mesmo botao.
func toggle_queue() -> void:
	if _queue == null:
		return
	if _state == QueueState.SEARCHING:
		_cta.disabled = true
		await _queue.leave()
		_cta.disabled = _state in [QueueState.JOINING, QueueState.MATCHED]
	elif _state in [QueueState.IDLE, QueueState.ERROR]:
		_show_state(QueueState.JOINING)
		await _queue.join()
		if _state == QueueState.JOINING:  # join falhou sem sinal de busca (failed ja tratou)
			_show_state(QueueState.IDLE)


func _show_state(state: QueueState, message: String = "") -> void:
	_state = state
	var searching := state == QueueState.SEARCHING
	_cta.variant = CtaButton.Variant.DANGER if searching else CtaButton.Variant.GOLD
	_cta.text = (
		"%s  %s" % [UiIcons.CLOSE, tr("CANCELAR FILA")]
		if searching
		else "%s  %s  %s" % [UiIcons.SWORDS, tr("BUSCAR PARTIDA 1V1"), UiIcons.CHEVRON_RIGHT]
	)
	_cta.disabled = state in [QueueState.JOINING, QueueState.MATCHED]
	_play.disabled = _cta.disabled
	if state != QueueState.SEARCHING:
		_tick.stop()
	if state in [QueueState.IDLE, QueueState.JOINING]:
		_elapsed = 0
	_time_cell.text = _clock(_elapsed)
	var labels: Dictionary[QueueState, Array] = {
		QueueState.IDLE: ["PRONTO", &"LnNumMdCyan"],
		QueueState.JOINING: ["ENTRANDO", &"LnNumMdGold"],
		QueueState.SEARCHING: ["PROCURANDO", &"LnNumMdGold"],
		QueueState.MATCHED: ["PAREADO", &"LnNumMd"],
		QueueState.ERROR: ["ERRO", &"LnNumMd"],
	}
	_status_cell.text = tr(labels[state][0])
	_status_cell.theme_type_variation = labels[state][1]
	_banner.visible = state in [QueueState.SEARCHING, QueueState.MATCHED, QueueState.ERROR]
	_banner.theme_type_variation = &"LnBannerError" if state == QueueState.ERROR else &"LnBanner"
	_banner_dot.visible = searching
	_banner_clock.visible = searching
	_retry.visible = state == QueueState.ERROR
	match state:
		QueueState.SEARCHING:
			_banner_text.text = tr("Procurando oponente…")
		QueueState.MATCHED:
			_banner_text.text = (
				"%s  %s" % [UiIcons.CHECK_CIRCLE, tr("Oponente encontrado! Abrindo a partida…")]
			)
		QueueState.ERROR:
			_banner_text.text = "%s  %s" % [UiIcons.ERROR, message]
	_banner_text.theme_type_variation = (
		&"LnBodySmError" if state == QueueState.ERROR else &"LnTitle"
	)


static func _clock(seconds: int) -> String:
	return "%02d:%02d" % [seconds / int(SECONDS_PER_MINUTE), seconds % int(SECONDS_PER_MINUTE)]


func _backdrop() -> Backdrop:
	var backdrop := Backdrop.new()
	backdrop.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	backdrop.gradient(FADE_BOTTOM, FADE_MID, FADE_TOP)
	backdrop.vignette(VIGNETTE_CENTER, VIGNETTE_EDGE)
	backdrop.glow(0, RUNE_GLOW, Vector2(0.2, 0.65), 180.0, 4.0)
	backdrop.glow(1, RUNE_GLOW, Vector2(0.8, 0.3), 220.0, 6.0)
	return backdrop


## Sub-menu central: JOGAR (busca partida), TREINO BOT IA e CONFIGURACOES.
func _sub_nav() -> CenterContainer:
	var center := CenterContainer.new()
	var track := GlassPanel.new(GlassPanel.BLUR_XL)
	track.theme_type_variation = &"LnSubNavTrack"
	center.add_child(track)
	var row := HBoxContainer.new()
	row.theme_type_variation = &"LnHGapXs"
	track.add_child(row)
	_play.theme_type_variation = &"LnSubNavPlay"
	_play.text = "%s %s" % [UiIcons.SWORDS, tr("JOGAR")]
	_play.pressed.connect(toggle_queue)
	row.add_child(_play)
	for item: Array in [
		[UiIcons.SMART_TOY, "TREINO VS BOT", practice_requested],
		[UiIcons.TUNE, "CONFIGURAÇÕES", settings_requested],
	]:
		var button := Button.new()
		button.theme_type_variation = &"LnSubNav"
		button.text = "%s %s" % [item[0], tr(item[1])]
		button.pressed.connect((item[2] as Signal).emit)
		row.add_child(button)
	return center


## Area do heroi: o diorama aparece atras; aqui so o banner flutuante embaixo.
func _hero_area() -> Control:
	var area := VBoxContainer.new()
	area.size_flags_horizontal = SIZE_EXPAND_FILL
	area.size_flags_stretch_ratio = LEFT_COLUMNS
	area.custom_minimum_size.y = HERO_AREA_HEIGHT
	area.alignment = BoxContainer.ALIGNMENT_END
	var banner := GlassPanel.new(GlassPanel.BLUR_XL)
	banner.theme_type_variation = &"LnCardGlassMd"
	banner.custom_minimum_size.x = BANNER_MAX_WIDTH
	banner.size_flags_horizontal = SIZE_SHRINK_CENTER
	area.add_child(banner)
	var row := HBoxContainer.new()
	row.theme_type_variation = &"LnHGapMd"
	banner.add_child(row)
	row.add_child(_icon_box(UiIcons.SHIELD, &"LnIconOnGold", &"LnIconBoxGold", ICON_BOX_LG))
	var text := VBoxContainer.new()
	text.theme_type_variation = &"LnVGapNone"
	text.size_flags_horizontal = SIZE_EXPAND_FILL
	row.add_child(text)
	var title := HBoxContainer.new()
	title.theme_type_variation = &"LnHGapXs"
	text.add_child(title)
	var hero_name := Label.new()
	hero_name.theme_type_variation = &"LnHeadlineMdGold"
	hero_name.text = HERO.display_name.to_upper()
	title.add_child(hero_name)
	var role := Label.new()
	role.theme_type_variation = &"LnBadgeChip"
	role.text = HERO.role.to_upper()
	role.size_flags_vertical = SIZE_SHRINK_CENTER
	title.add_child(role)
	var summary := Label.new()
	summary.theme_type_variation = &"LnBodySmMuted"
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary.text = HERO.summary
	text.add_child(summary)
	return area


func _console_column() -> VBoxContainer:
	var column := VBoxContainer.new()
	column.theme_type_variation = &"LnVGapMd"
	column.size_flags_horizontal = SIZE_EXPAND_FILL
	column.size_flags_stretch_ratio = RIGHT_COLUMNS
	column.size_flags_vertical = SIZE_SHRINK_CENTER
	column.add_child(_console())
	column.add_child(_modes())
	return column


## Console da fila: modo, celulas reais (status, tempo na fila, servidor), CTA e faixa de estado.
func _console() -> GlassPanel:
	var card := GlassPanel.new(GlassPanel.BLUR_2XL)
	card.theme_type_variation = &"LnConsole"
	var body := VBoxContainer.new()
	body.theme_type_variation = &"LnVGapMd"
	card.add_child(body)
	var head := HBoxContainer.new()
	head.theme_type_variation = &"LnHGapMd"
	body.add_child(head)
	var titles := VBoxContainer.new()
	titles.theme_type_variation = &"LnVGapNone"
	titles.size_flags_horizontal = SIZE_EXPAND_FILL
	head.add_child(titles)
	var kicker := Label.new()
	kicker.theme_type_variation = &"LnNumGold"
	kicker.text = "%s %s" % [UiIcons.BOLT, tr("MODO PRINCIPAL ATIVO")]
	titles.add_child(kicker)
	var title := Label.new()
	title.theme_type_variation = &"LnHeadlineLg"
	title.text = tr("Duelo 1v1")
	titles.add_child(title)
	var subtitle := Label.new()
	subtitle.theme_type_variation = &"LnBodyMuted"
	subtitle.text = (
		tr("Arena de 2 tempos (limite de %d minutos)")
		% roundi(RULES.max_match_duration / SECONDS_PER_MINUTE)
	)
	titles.add_child(subtitle)
	var timer_box := _icon_box(UiIcons.TIMER, &"LnIconMdGold", &"LnIconBoxHigh", ICON_BOX_MD)
	timer_box.size_flags_vertical = SIZE_SHRINK_BEGIN
	head.add_child(timer_box)
	var cells := PanelContainer.new()
	cells.theme_type_variation = &"LnCellTrack"
	body.add_child(cells)
	var row := HBoxContainer.new()
	row.theme_type_variation = &"LnHGapXs"
	cells.add_child(row)
	row.add_child(_cell(tr("STATUS"), _status_cell))
	row.add_child(_cell(tr("NA FILA"), _time_cell))
	row.add_child(_cell(tr("SERVIDOR"), _server_cell))
	set_backend_status(false, -1, false)
	_cta.pressed.connect(toggle_queue)
	body.add_child(_cta)
	body.add_child(_queue_banner())
	return card


func _cell(caption: String, value: Label) -> PanelContainer:
	var cell := PanelContainer.new()
	cell.theme_type_variation = &"LnCell"
	cell.size_flags_horizontal = SIZE_EXPAND_FILL
	var column := VBoxContainer.new()
	column.theme_type_variation = &"LnVGapNone"
	cell.add_child(column)
	var label := Label.new()
	label.theme_type_variation = &"LnNum"
	label.text = caption
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(label)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(value)
	return cell


func _queue_banner() -> PanelContainer:
	var row := HBoxContainer.new()
	row.theme_type_variation = &"LnHGapSm"
	_banner.add_child(row)
	_banner_dot.theme_type_variation = &"LnDotGold"
	_banner_dot.custom_minimum_size = QUEUE_DOT
	_banner_dot.size_flags_vertical = SIZE_SHRINK_CENTER
	row.add_child(_banner_dot)
	_banner_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_banner_text.size_flags_horizontal = SIZE_EXPAND_FILL
	row.add_child(_banner_text)
	_banner_clock.theme_type_variation = &"LnNumMdGold"
	row.add_child(_banner_clock)
	_retry.theme_type_variation = &"LnButtonSmall"
	_retry.text = "%s %s" % [UiIcons.RESTART_ALT, tr("Tentar de novo")]
	_retry.pressed.connect(toggle_queue)
	row.add_child(_retry)
	return _banner


## Modo de batalha (um so na fatia: o 1v1 ativo; 2v2/3v3 sao roadmap e sairam, §8.3).
func _modes() -> GlassPanel:
	var card := GlassPanel.new(GlassPanel.BLUR_XL)
	card.theme_type_variation = &"LnConsoleSoft"
	var body := VBoxContainer.new()
	body.theme_type_variation = &"LnVGapSm"
	card.add_child(body)
	var kicker := Label.new()
	kicker.theme_type_variation = &"LnNumOutline"
	kicker.text = tr("MODO DE BATALHA")
	body.add_child(kicker)
	var mode := PanelContainer.new()
	mode.theme_type_variation = &"LnModeRow"
	body.add_child(mode)
	var row := HBoxContainer.new()
	row.theme_type_variation = &"LnHGapSm"
	mode.add_child(row)
	row.add_child(_icon_box(UiIcons.PERSON, &"LnIconMdGold", &"LnIconBoxCard", ICON_BOX_SM))
	var text := VBoxContainer.new()
	text.theme_type_variation = &"LnVGapNone"
	text.size_flags_horizontal = SIZE_EXPAND_FILL
	row.add_child(text)
	var name_label := Label.new()
	name_label.theme_type_variation = &"LnTitleGold"
	name_label.text = tr("Duelo 1v1")
	text.add_child(name_label)
	var detail := Label.new()
	detail.theme_type_variation = &"LnBodySmMuted"
	detail.text = (
		tr("%d min de preparação e o confronto com a zona")
		% roundi(RULES.phase1_duration / SECONDS_PER_MINUTE)
	)
	text.add_child(detail)
	var badge := Label.new()
	badge.theme_type_variation = &"LnBadgeGold"
	badge.text = tr("ATIVO")
	badge.size_flags_vertical = SIZE_SHRINK_CENTER
	row.add_child(badge)
	return card


## Cartoes de baixo: treino vs bot (Iniciar) e a conta (Sair).
func _bento() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.theme_type_variation = &"LnHGapMd"
	var practice := Button.new()
	practice.theme_type_variation = &"LnButtonSmallBlue"
	practice.text = tr("Iniciar")
	practice.pressed.connect(practice_requested.emit)
	var practice_detail := Label.new()
	practice_detail.text = tr("Offline, sem fila: o bot farma, saqueia, contesta e luta.")
	row.add_child(
		_bento_card(
			UiIcons.PSYCHOLOGY, &"LnIconMdCyan", tr("Treino vs Bot"), practice_detail, practice
		)
	)
	var logout := Button.new()
	logout.theme_type_variation = &"LnButtonSmall"
	logout.text = "%s %s" % [UiIcons.LOGOUT, tr("Sair")]
	logout.pressed.connect(logout_requested.emit)
	row.add_child(_bento_card(UiIcons.PERSON, &"LnIconMdGold", tr("Sua conta"), _account, logout))
	return row


func _bento_card(
	icon: String, icon_type: StringName, title: String, detail: Label, action: Button
) -> GlassPanel:
	var card := GlassPanel.new(GlassPanel.BLUR_XL)
	card.theme_type_variation = &"LnConsoleSoft"
	card.size_flags_horizontal = SIZE_EXPAND_FILL
	var row := HBoxContainer.new()
	row.theme_type_variation = &"LnHGapSm"
	card.add_child(row)
	row.add_child(_icon_box(icon, icon_type, &"LnIconBoxCard", ICON_BOX_MD))
	var text := VBoxContainer.new()
	text.theme_type_variation = &"LnVGapNone"
	text.size_flags_horizontal = SIZE_EXPAND_FILL
	text.size_flags_vertical = SIZE_SHRINK_CENTER
	row.add_child(text)
	var title_label := Label.new()
	title_label.theme_type_variation = &"LnTitle"
	title_label.text = title
	text.add_child(title_label)
	detail.theme_type_variation = &"LnBodySmMuted"
	text.add_child(detail)
	action.size_flags_vertical = SIZE_SHRINK_CENTER
	row.add_child(action)
	return card


func _icon_box(icon: String, icon_type: StringName, box_type: StringName, box: Vector2) -> Control:
	var panel := PanelContainer.new()
	panel.theme_type_variation = box_type
	panel.custom_minimum_size = box
	var glyph := Label.new()
	glyph.theme_type_variation = icon_type
	glyph.text = icon
	glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.add_child(glyph)
	return panel


func _on_queue_searching(elapsed_s: int) -> void:
	if _state != QueueState.SEARCHING:
		_show_state(QueueState.SEARCHING)
		_tick.start()
	_elapsed = elapsed_s
	_time_cell.text = _clock(_elapsed)
	_banner_clock.text = _time_cell.text


func _on_queue_matched() -> void:
	_show_state(QueueState.MATCHED)


func _on_queue_failed(reason: String) -> void:
	var messages: Dictionary[String, String] = {
		ApiClient.OFFLINE: "Servidor fora do ar. A fila não foi mantida.",
		"ALREADY_QUEUED": "Esta conta já está na fila ou em uma partida.",
		QueueService.MATCH_GONE: "A partida encontrada não está mais disponível.",
	}
	_show_state(QueueState.ERROR, tr(messages.get(reason, "Não foi possível entrar na fila.")))


## Tempo na fila entre os polls (o backend manda o valor certo a cada 2 s).
func _on_tick_timeout() -> void:
	_elapsed += 1
	_time_cell.text = _clock(_elapsed)
	_banner_clock.text = _time_cell.text
