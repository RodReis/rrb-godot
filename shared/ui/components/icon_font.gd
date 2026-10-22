class_name IconFont
extends RefCounted
## Glifos do UiIcons dentro do texto de um Label do jogo (paineis enxutos da HUD, PI 2026-10-22):
## as fontes do tema do Game nao tem a de icones como fallback (so as do Launcher). Troca a fonte
## do label por uma copia da fonte do tema (mesmo peso) com a de icones como fallback; uma por
## fonte base. Chame com o label ja na arvore (o tema resolve a fonte).

static var _by_base: Dictionary[Font, Font] = {}


static func apply(label: Label) -> void:
	var base := label.get_theme_font(&"font")
	var font: Font = _by_base.get(base)
	if font == null:
		# Copia, nao envolve: FontVariation dentro de outra perde o peso (wght) da de dentro.
		font = base.duplicate() as Font
		var fallbacks: Array[Font] = font.fallbacks.duplicate()
		fallbacks.append(load(UiTokens.FONT_ICONS_PATH) as Font)
		font.fallbacks = fallbacks
		_by_base[base] = font
	label.add_theme_font_override(&"font", font)
