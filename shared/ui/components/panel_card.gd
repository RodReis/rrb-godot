@tool
class_name PanelCard
extends PanelContainer
## Card do design system (COMPONENTS.md): fundo por variante e borda de acento de 3 px.
## Variante por theme_type_variation; o acento e um StyleBox do Theme desenhado sobre o fundo.
## GLASS e GLASS_INNER: vidro da HUD (F57), com acento fino e cantoneiras douradas opcionais.

enum Surface { SURFACE, PANEL, INNER, GLASS, GLASS_INNER }
enum Accent { NONE, GOLD, RED, GREEN, PURPLE }

## Indice = Surface; vazio = PanelContainer (BG_PANEL).
const VARIANT_TYPES: Array[StringName] = [
	&"PanelCardSurface", &"", &"PanelCardInner", &"PanelCardGlass", &"PanelCardGlassInner"
]
## Indice = Accent; vazio = sem acento.
const ACCENT_TYPES: Array[StringName] = [
	&"",
	&"PanelCardAccentGold",
	&"PanelCardAccentRed",
	&"PanelCardAccentGreen",
	&"PanelCardAccentPurple"
]
## Tipo do acento no Theme -> token de cor (ThemeBuilder).
const ACCENT_TOKENS: Dictionary[StringName, StringName] = {
	&"PanelCardAccentGold": &"GOLD",
	&"PanelCardAccentRed": &"RED",
	&"PanelCardAccentGreen": &"GREEN",
	&"PanelCardAccentPurple": &"PURPLE",
}
## Cantoneira: comprimento de cada perna e espessura (px), cantos do prototipo da HUD.
const CORNER_LENGTH: float = 8.0
const CORNER_WIDTH: float = 2.0

@export var variant: Surface = Surface.PANEL:
	set(value):
		variant = value
		theme_type_variation = VARIANT_TYPES[value]
		queue_redraw()
@export var accent: Accent = Accent.NONE:
	set(value):
		accent = value
		queue_redraw()
## Quatro cantoneiras douradas por cima da borda.
@export var corners: bool = false:
	set(value):
		corners = value
		queue_redraw()


func _draw() -> void:
	if accent != Accent.NONE:
		var type := ACCENT_TYPES[accent]
		if variant >= Surface.GLASS:
			type = glass_accent_type(type)
		draw_style_box(get_theme_stylebox(&"panel", type), Rect2(Vector2.ZERO, size))
	if corners:
		_draw_corners()


## Acento do vidro: mesmo token, borda fina e raio do vidro.
static func glass_accent_type(accent_type: StringName) -> StringName:
	return StringName(String(accent_type).replace("PanelCard", "PanelCardGlass"))


func _draw_corners() -> void:
	var gold := UiTokens.GOLD
	var w := size.x
	var h := size.y
	var l := CORNER_LENGTH
	for corner: Array in [
		[Vector2(0, 0), Vector2(l, 0), Vector2(0, l)],
		[Vector2(w, 0), Vector2(w - l, 0), Vector2(w, l)],
		[Vector2(0, h), Vector2(l, h), Vector2(0, h - l)],
		[Vector2(w, h), Vector2(w - l, h), Vector2(w, h - l)],
	]:
		draw_polyline(PackedVector2Array([corner[1], corner[0], corner[2]]), gold, CORNER_WIDTH)
