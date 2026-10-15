class_name ScreenHeader
extends PanelContainer
## Cabecalho de tela do Launcher (COMPONENTS.md, FRONTEND-LAUNCHER §3): bloco de titulo dos
## prototipos — voltar (so com pilha), sobretitulo com icone, titulo H1 e descricao a esquerda;
## slot a direita para abas ou filtro e, opcional, uma faixa abaixo (filtros do Historico, que no
## prototipo ficam dentro do mesmo cartao). Emite back_requested; quem decide e o App.

signal back_requested

## Brilho de fundo (circulo desfocado a 5 %: "bg-primary/5 rounded-full blur-3xl" do Historico).
const GLOW_FADE_START: float = 0.55
## A textura do brilho e maior que o circulo (o desfoque sangra para fora).
const GLOW_BLEED: float = 1.25

## Abas, filtro ou acao da tela; alinhado ao fundo do bloco (md:items-end do prototipo).
var right_slot: HBoxContainer = HBoxContainer.new()
## Faixa abaixo do bloco de titulo; escondida ate alguem usar (`show_bottom_slot`).
var bottom_slot: HBoxContainer = HBoxContainer.new()

var _back: Button = Button.new()
var _icon: Label = Label.new()
var _kicker: Label = Label.new()
var _title: Label = Label.new()
var _description: Label = Label.new()
var _glows: Array[Glow] = []


## Um brilho: circulo de `diameter` px com a borda a `right` do canto direito e a `vertical` do
## topo (ou do rodape), como o absolute right-N top-N / bottom-N do CSS (negativo = para fora).
class Glow:
	extends RefCounted
	var texture: GradientTexture2D
	var diameter: float = 0.0
	var right: float = 0.0
	var vertical: float = 0.0
	var from_bottom: bool = false


func _init() -> void:
	theme_type_variation = &"LnCardRaised"
	var content := VBoxContainer.new()
	content.theme_type_variation = &"LnVGapMd"
	add_child(content)
	var columns := HBoxContainer.new()
	columns.theme_type_variation = &"LnHGapMd"
	content.add_child(columns)
	bottom_slot.theme_type_variation = &"LnHGapXs"
	bottom_slot.visible = false
	content.add_child(bottom_slot)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = SIZE_EXPAND_FILL
	left.theme_type_variation = &"LnVGapXs"
	columns.add_child(left)
	var kicker_row := HBoxContainer.new()
	kicker_row.theme_type_variation = &"LnHGapSm"
	left.add_child(kicker_row)
	_back.theme_type_variation = &"LnIconButton"
	_back.text = UiIcons.ARROW_BACK
	_back.tooltip_text = tr("Voltar")
	_back.visible = false
	_back.pressed.connect(back_requested.emit)
	kicker_row.add_child(_back)
	_icon.theme_type_variation = &"LnIconTitle"
	kicker_row.add_child(_icon)
	_kicker.theme_type_variation = &"LnHeadlineSmGold"
	_kicker.uppercase = true
	kicker_row.add_child(_kicker)
	_title.theme_type_variation = &"LnHeadlineLg"
	_title.uppercase = true
	left.add_child(_title)
	_description.theme_type_variation = &"LnBodyMuted"
	_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left.add_child(_description)
	right_slot.size_flags_vertical = SIZE_SHRINK_END
	columns.add_child(right_slot)


## Brilho decorativo atras do conteudo; o cartao recorta o que passa da borda.
func add_glow(
	color: Color, diameter: float, right: float, vertical: float, from_bottom: bool = false
) -> void:
	var glow := Glow.new()
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, GLOW_FADE_START, 1.0])
	gradient.colors = PackedColorArray([color, color, Color(color, 0.0)])
	glow.texture = GradientTexture2D.new()
	glow.texture.gradient = gradient
	glow.texture.fill = GradientTexture2D.FILL_RADIAL
	glow.texture.fill_from = Vector2(0.5, 0.5)
	glow.texture.fill_to = Vector2(1.0, 0.5)
	glow.texture.width = int(diameter * GLOW_BLEED)
	glow.texture.height = int(diameter * GLOW_BLEED)
	glow.diameter = diameter
	glow.right = right
	glow.vertical = vertical
	glow.from_bottom = from_bottom
	_glows.append(glow)
	clip_contents = true
	queue_redraw()


## Sobretitulo pequeno do prototipo do Compendio (mono 11 px e icone de 16 px) no lugar do
## headline-sm do Historico.
func use_compact_kicker() -> void:
	_kicker.theme_type_variation = &"LnNumGold"
	_icon.theme_type_variation = &"LnIconSmGold"


func show_bottom_slot(slot_visible: bool = true) -> void:
	bottom_slot.visible = slot_visible


func bind(
	title: String, show_back: bool, kicker: String = "", icon: String = "", description: String = ""
) -> void:
	_title.text = title
	_back.visible = show_back
	_kicker.text = kicker
	_icon.text = icon
	_icon.visible = not icon.is_empty()
	_description.text = description
	_description.visible = not description.is_empty()


func _draw() -> void:
	for glow: Glow in _glows:
		var x := size.x - glow.right - glow.diameter
		var y := size.y - glow.vertical - glow.diameter if glow.from_bottom else glow.vertical
		var bleed := glow.diameter * (GLOW_BLEED - 1.0) / 2.0
		var rect := Rect2(
			x - bleed, y - bleed, glow.diameter * GLOW_BLEED, glow.diameter * GLOW_BLEED
		)
		draw_texture_rect(glow.texture, rect, false)
