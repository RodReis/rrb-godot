class_name AppBar
extends PanelContainer
## Barra superior do Launcher (cabecalho dos prototipos de docs/prd/telas/): logo, menu so com
## rotas que existem (Router.NAV), chip de status real do backend (V-01b: online/offline e ping
## HTTP, no lugar do "NETFOX 30HZ | 24ms" do prototipo), engrenagem (Configuracoes) e sair. Sem
## ELO nem perfil (FRONTEND-LAUNCHER §8.3; perfil e o F35). Emite; quem navega e o App.

signal navigate_requested(route: StringName)
signal quit_requested

## h-16 do prototipo.
const HEIGHT: float = 64.0
## Caixa do logo (w-9 h-9) e divisor (h-6).
const LOGO_SIZE: Vector2 = Vector2(36, 36)
const DIVIDER_HEIGHT: float = 24.0
const BRAND: String = "ARENA 1V1"
## Ponto do chip (w-2 h-2 rounded-full animate-pulse: opacidade 1 -> 0,5 em 2 s).
const DOT_SIZE: Vector2 = Vector2(8, 8)
const PULSE_SECONDS: float = 1.0
const PULSE_ALPHA: float = 0.5
## Ping ainda nao medido.
const UNKNOWN_PING: int = -1

var _nav: Dictionary[StringName, Button] = {}
var _nav_box: HBoxContainer = HBoxContainer.new()
var _divider: VSeparator = VSeparator.new()
var _dot: Panel = Panel.new()
var _status: Label = Label.new()
var _ping_divider: VSeparator = VSeparator.new()
var _ping: Label = Label.new()


func _init() -> void:
	theme_type_variation = &"LnAppBar"
	custom_minimum_size.y = HEIGHT
	var row := HBoxContainer.new()
	row.theme_type_variation = &"LnHGapLg"
	add_child(row)
	var logo := HBoxContainer.new()
	logo.theme_type_variation = &"LnHGapSm"
	row.add_child(logo)
	var box := PanelContainer.new()
	box.theme_type_variation = &"LnLogoBox"
	box.custom_minimum_size = LOGO_SIZE
	box.size_flags_vertical = SIZE_SHRINK_CENTER
	logo.add_child(box)
	var swords := Label.new()
	swords.theme_type_variation = &"LnIconLogo"
	swords.text = UiIcons.SWORDS
	swords.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	swords.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	box.add_child(swords)
	var brand := Label.new()
	brand.theme_type_variation = &"LnBrand"
	brand.text = BRAND
	brand.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	logo.add_child(brand)
	_divider.theme_type_variation = &"LnDividerV"
	_divider.custom_minimum_size.y = DIVIDER_HEIGHT
	_divider.size_flags_vertical = SIZE_SHRINK_CENTER
	row.add_child(_divider)
	var nav := _nav_box
	nav.theme_type_variation = &"LnHGapXs"
	row.add_child(nav)
	var group := ButtonGroup.new()
	group.allow_unpress = false
	for route: StringName in Router.NAV:
		var item := Button.new()
		item.theme_type_variation = &"LnTab"
		item.text = tr(Router.NAV[route])
		item.toggle_mode = true
		item.button_group = group
		item.size_flags_vertical = SIZE_SHRINK_CENTER
		item.pressed.connect(navigate_requested.emit.bind(route))
		nav.add_child(item)
		_nav[route] = item
	var spacer := Control.new()
	spacer.size_flags_horizontal = SIZE_EXPAND_FILL
	row.add_child(spacer)
	row.add_child(_status_chip())
	var actions := HBoxContainer.new()
	actions.theme_type_variation = &"LnHGapXs"
	row.add_child(actions)
	var gear := _icon_button(UiIcons.SETTINGS, &"LnIconButton", tr("Configurações"))
	gear.pressed.connect(navigate_requested.emit.bind(Router.SETTINGS))
	actions.add_child(gear)
	var power := _icon_button(UiIcons.POWER_SETTINGS_NEW, &"LnIconButtonDanger", tr("Sair"))
	power.pressed.connect(quit_requested.emit)
	actions.add_child(power)


func _ready() -> void:
	var pulse := create_tween().set_loops()
	pulse.tween_property(_dot, ^"modulate:a", PULSE_ALPHA, PULSE_SECONDS)
	pulse.tween_property(_dot, ^"modulate:a", 1.0, PULSE_SECONDS)


## Menu de telas: escondido no Login (sem sessao nao ha para onde ir alem de Configuracoes).
func set_nav_visible(nav_visible: bool) -> void:
	_nav_box.visible = nav_visible
	_divider.visible = nav_visible


## Status real do backend (GET /health): online com o ping em ms, offline ou ainda verificando.
func set_backend_status(online: bool, ping_ms: int = UNKNOWN_PING) -> void:
	var checking := not online and ping_ms == UNKNOWN_PING
	_status.text = tr("VERIFICANDO") if checking else tr("ONLINE" if online else "OFFLINE")
	_status.theme_type_variation = &"LnNumCyan" if online else &"LnNum"
	var dot := &"LnDotOnline" if online else (&"LnDotChecking" if checking else &"LnDotOffline")
	_dot.theme_type_variation = dot
	_ping.text = "%d ms" % ping_ms if online and ping_ms >= 0 else ""
	_ping.visible = not _ping.text.is_empty()
	_ping_divider.visible = _ping.visible


func backend_status_text() -> String:
	return "%s %s" % [_status.text, _ping.text]


## Destaca o item do menu da rota da tela atual (nenhum, se a rota nao esta no menu).
func set_current(route: StringName) -> void:
	for item: StringName in _nav:
		_nav[item].set_pressed_no_signal(item == route)


## Chip "SERVIDOR ONLINE | 24 ms" (bg-low rounded-xl, mono 11).
func _status_chip() -> PanelContainer:
	var chip := PanelContainer.new()
	chip.theme_type_variation = &"LnStatusChip"
	chip.size_flags_vertical = SIZE_SHRINK_CENTER
	var row := HBoxContainer.new()
	row.theme_type_variation = &"LnHGapSm"
	chip.add_child(row)
	_dot.custom_minimum_size = DOT_SIZE
	_dot.size_flags_vertical = SIZE_SHRINK_CENTER
	row.add_child(_dot)
	var server := Label.new()
	server.theme_type_variation = &"LnNum"
	server.text = tr("SERVIDOR")
	row.add_child(server)
	row.add_child(_status)
	_ping_divider.theme_type_variation = &"LnDividerV"
	_ping_divider.custom_minimum_size.y = DOT_SIZE.y + UiTokens.SPACE_XS
	_ping_divider.size_flags_vertical = SIZE_SHRINK_CENTER
	row.add_child(_ping_divider)
	_ping.theme_type_variation = &"LnNum"
	row.add_child(_ping)
	set_backend_status(false)
	return chip


func _icon_button(icon: String, type: StringName, tip: String) -> Button:
	var button := Button.new()
	button.theme_type_variation = type
	button.text = icon
	button.tooltip_text = tip
	button.custom_minimum_size = LOGO_SIZE
	button.size_flags_vertical = SIZE_SHRINK_CENTER
	return button
