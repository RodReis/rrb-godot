@tool
class_name PanelCard
extends PanelContainer
## Card do design system (COMPONENTS.md): fundo por variante e borda de acento de 3 px.
## Variante por theme_type_variation; o acento e um StyleBox do Theme desenhado sobre o fundo.

enum Surface { SURFACE, PANEL, INNER }
enum Accent { NONE, GOLD, RED, GREEN, PURPLE }

## Indice = Surface; vazio = PanelContainer (BG_PANEL).
const VARIANT_TYPES: Array[StringName] = [&"PanelCardSurface", &"", &"PanelCardInner"]
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

@export var variant: Surface = Surface.PANEL:
	set(value):
		variant = value
		theme_type_variation = VARIANT_TYPES[value]
@export var accent: Accent = Accent.NONE:
	set(value):
		accent = value
		queue_redraw()


func _draw() -> void:
	if accent == Accent.NONE:
		return
	draw_style_box(get_theme_stylebox(&"panel", ACCENT_TYPES[accent]), Rect2(Vector2.ZERO, size))
