class_name AppBar
extends PanelContainer
## Barra superior do Launcher (cabecalho dos prototipos de docs/prd/telas/): logo, menu so com
## rotas que existem (Router.NAV), engrenagem (Configuracoes) e sair. Sem chip de rede, ELO nem
## perfil (FRONTEND-LAUNCHER §8.3; perfil e o F35). Emite; quem navega e o App.

signal navigate_requested(route: StringName)
signal quit_requested

## h-16 do prototipo.
const HEIGHT: float = 64.0
## Caixa do logo (w-9 h-9) e divisor (h-6).
const LOGO_SIZE: Vector2 = Vector2(36, 36)
const DIVIDER_HEIGHT: float = 24.0
const BRAND: String = "ARENA 1V1"

var _nav: Dictionary[StringName, Button] = {}


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
	var divider := VSeparator.new()
	divider.theme_type_variation = &"LnDividerV"
	divider.custom_minimum_size.y = DIVIDER_HEIGHT
	divider.size_flags_vertical = SIZE_SHRINK_CENTER
	row.add_child(divider)
	var nav := HBoxContainer.new()
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
	var actions := HBoxContainer.new()
	actions.theme_type_variation = &"LnHGapXs"
	row.add_child(actions)
	var gear := _icon_button(UiIcons.SETTINGS, &"LnIconButton", tr("Configurações"))
	gear.pressed.connect(navigate_requested.emit.bind(Router.SETTINGS))
	actions.add_child(gear)
	var power := _icon_button(UiIcons.POWER_SETTINGS_NEW, &"LnIconButtonDanger", tr("Sair"))
	power.pressed.connect(quit_requested.emit)
	actions.add_child(power)


## Destaca o item do menu da rota da tela atual (nenhum, se a rota nao esta no menu).
func set_current(route: StringName) -> void:
	for item: StringName in _nav:
		_nav[item].set_pressed_no_signal(item == route)


func _icon_button(icon: String, type: StringName, tip: String) -> Button:
	var button := Button.new()
	button.theme_type_variation = type
	button.text = icon
	button.tooltip_text = tip
	button.custom_minimum_size = LOGO_SIZE
	button.size_flags_vertical = SIZE_SHRINK_CENTER
	return button
