class_name ChestChoiceCard
extends PanelCard
## Um item do menu do bau (F61, ADR-0014; nasceu do card de oferta da SPEC-047 §3): icone, nome,
## raridade (cor e texto, P6), atributos contra o equipado no mesmo slot (+/-) e conjuntos
## antes -> depois. Clicavel: emite chosen. So exibe; o servidor valida a escolha (Chest.pick).
## Borda cinza que clareia e ganha brilho com o mouse em cima (PI 2026-10-13: dourado parecia item
## lendario).

## Clique no card do item de indice [param index] no menu.
signal chosen(index: int)

const SLOT_ITEM: PackedScene = preload("res://shared/ui/components/slot_item.tscn")
## Indice = ItemData.Rarity.
const RARITY_COLORS: Array[Color] = [
	UiTokens.RARITY_COMMON, UiTokens.RARITY_RARE, UiTokens.RARITY_EPIC
]
## Borda parada e com o mouse em cima; brilho em volta (px) e duracao da transicao (s).
const BORDER: Color = Color(UiTokens.RARITY_COMMON, 0.75)
const BORDER_HOVER: Color = Color(0.86, 0.89, 0.93)
const BORDER_WIDTH: int = 2
const GLOW_SIZE: float = 12.0
const GLOW_ALPHA: float = 0.5
const GLOW_SECONDS: float = 0.15
## Fundo levemente mais claro sob o mouse.
const HOVER_MODULATE: Color = Color(1.08, 1.08, 1.08)

var index: int = 0
## 0 = parado, 1 = mouse em cima (animado por tween).
var glow: float = 0.0:
	set(value):
		glow = value
		queue_redraw()

var _border: StyleBoxFlat = StyleBoxFlat.new()
var _tween: Tween

var _slot: SlotItem = SLOT_ITEM.instantiate() as SlotItem
var _name: Label = Label.new()
var _rarity: Label = Label.new()
var _rows: VBoxContainer = VBoxContainer.new()
var _sets: Label = Label.new()


func _init() -> void:
	variant = Surface.PANEL
	accent = Accent.NONE
	_border.draw_center = false
	_border.set_border_width_all(BORDER_WIDTH)
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var column := VBoxContainer.new()
	var header := HBoxContainer.new()
	var titles := VBoxContainer.new()
	_name.theme_type_variation = &"LabelH2"
	_sets.theme_type_variation = &"LabelMuted"
	_sets.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	titles.add_child(_name)
	titles.add_child(_rarity)
	header.add_child(_slot)
	header.add_child(titles)
	column.add_child(header)
	column.add_child(_rows)
	column.add_child(_sets)
	for node: Node in [column, header, titles, _rows, _slot]:
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(column)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


## Mostra [param incoming] contra o que o [param hero] tem no mesmo slot.
func show_item(hero: Hero, incoming: ItemData, catalog: ItemCatalog, icons: ItemVisuals) -> void:
	var current := Inventory.item_at(hero.equipment, incoming.slot, catalog)
	_slot.slot = incoming.slot
	_slot.bind(incoming, icons.icon(incoming) if icons != null else null)
	_name.text = incoming.display_name
	_rarity.text = ItemData.RARITY_NAMES[incoming.rarity]
	_rarity.add_theme_color_override(&"font_color", RARITY_COLORS[incoming.rarity])
	for child: Node in _rows.get_children():
		_rows.remove_child(child)
		child.queue_free()
	for row: OfferCompare.Row in OfferCompare.rows(current, incoming):
		_rows.add_child(_row_node(row))
	_sets.text = OfferCompare.set_change(hero.equipment, incoming, catalog)
	_sets.visible = not _sets.text.is_empty()


func _draw() -> void:
	super()
	var panel := get_theme_stylebox(&"panel") as StyleBoxFlat
	if panel != null:
		_border.set_corner_radius_all(panel.corner_radius_top_left)
	_border.border_color = BORDER.lerp(BORDER_HOVER, glow)
	_border.shadow_color = Color(BORDER_HOVER, GLOW_ALPHA * glow)
	_border.shadow_size = roundi(GLOW_SIZE * glow)
	draw_style_box(_border, Rect2(Vector2.ZERO, size))


func _gui_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		chosen.emit(index)
		accept_event()


func _row_node(row: OfferCompare.Row) -> HBoxContainer:
	var line := HBoxContainer.new()
	var label := Label.new()
	label.text = "%s %d%s" % [row.label, row.value, "%" if row.percent else ""]
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(label)
	var delta := Label.new()
	delta.text = OfferCompare.delta_text(row)
	delta.add_theme_color_override(&"font_color", UiTokens.GREEN if row.delta > 0 else UiTokens.RED)
	line.add_child(delta)
	return line


func _animate_glow(target: float) -> void:
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, ^"glow", target, GLOW_SECONDS)


func _on_mouse_entered() -> void:
	modulate = HOVER_MODULATE
	_animate_glow(1.0)


func _on_mouse_exited() -> void:
	modulate = Color.WHITE
	_animate_glow(0.0)
