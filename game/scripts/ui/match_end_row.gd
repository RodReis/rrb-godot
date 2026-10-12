class_name MatchEndRow
extends PanelContainer
## Linha da tabela da tela de fim (F52, protótipo "Destaques da Tela de Fim de Partida"): ícone,
## nome da estatística e valor num cartão arredondado, que clareia sob o mouse. Só mostra; quem
## decide o estilo, a cor e o texto é a MatchEnd.

const HEIGHT: int = 48
const ICON_SIZE: Vector2 = Vector2(22, 22)
## Só a linha comum clareia sob o mouse (hover:bg-slate-800/70 do protótipo).
const PLAIN_STYLE: StringName = &"EndRow"
const HOVER_STYLE: StringName = &"EndRowHover"

## Tipo do Theme do cartão (EndRow, EndRowBoss, EndRowSet, EndRowMuted).
var style: StringName = PLAIN_STYLE
var icon_rect: TextureRect
var name_label: Label
var value_label: Label


func _init() -> void:
	custom_minimum_size.y = HEIGHT
	theme_type_variation = PLAIN_STYLE
	var line := HBoxContainer.new()
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(line)
	icon_rect = TextureRect.new()
	icon_rect.custom_minimum_size = ICON_SIZE
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_child(icon_rect)
	name_label = Label.new()
	name_label.theme_type_variation = &"LabelBody"
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	line.add_child(name_label)
	value_label = Label.new()
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	line.add_child(value_label)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


## Nome e ícone da estatística; chame uma vez, ao montar a tabela.
func setup(label_text: String, icon: Texture2D) -> void:
	name_label.text = label_text
	icon_rect.texture = icon


## Mostra o valor: [param row_style] é o tipo do cartão, [param value_type] o tipo do Label do
## valor e [param icon_color] a cor do ícone (branco no SVG, então a cor sai do modulate).
func show_value(
	row_style: StringName, value: String, value_type: StringName, icon_color: Color
) -> void:
	style = row_style
	theme_type_variation = row_style
	value_label.text = value
	value_label.theme_type_variation = value_type
	icon_rect.modulate = icon_color


func _on_mouse_entered() -> void:
	if style == PLAIN_STYLE:
		theme_type_variation = HOVER_STYLE


func _on_mouse_exited() -> void:
	theme_type_variation = style
