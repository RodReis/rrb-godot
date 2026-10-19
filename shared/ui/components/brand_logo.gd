class_name BrandLogo
extends BoxContainer
## Marca "Loot Start" (F82, ADR-0022): o bau aberto com o "play" e o wordmark em Cinzel dourada,
## igual ao site (site/src/brand/Logo.tsx). Horizontal na barra do Launcher; empilhada no Login e
## no splash. Use [method make].

const NAME: String = "Loot Start"
const WORDMARK: String = "LOOT START"
const ICON: String = "res://shared/assets/ui/brand/logo.svg"
const SHADER: String = "res://shared/ui/components/brand_gold.gdshader"
## Cinzel no peso maximo, como o site (font-weight 900).
const WEIGHT_BLACK: int = 900
## Espacamento entre letras em fracao do tamanho da fonte (site: 0.12em; empilhada: 0.16em).
const TRACKING: float = 0.12
const TRACKING_STACKED: float = 0.16
## Distancia icone-palavra em fracao do tamanho da fonte (site: gap 0.6em / 0.4em).
const GAP: float = 0.6
const GAP_STACKED: float = 0.4

var _word: Label


## [param icon_px]: lado do icone; [param word_px]: tamanho da fonte do wordmark.
static func make(icon_px: float, word_px: int, stacked: bool = false) -> BrandLogo:
	var logo := BrandLogo.new()
	logo.vertical = stacked
	logo.alignment = BoxContainer.ALIGNMENT_CENTER
	logo.add_theme_constant_override(
		&"separation", roundi(word_px * (GAP_STACKED if stacked else GAP))
	)
	var icon := TextureRect.new()
	icon.texture = load(ICON) as Texture2D
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	# SVG importado a 256 px (svg/scale=4) com mipmaps: nitido no splash e sem serrilhado na barra.
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	icon.custom_minimum_size = Vector2(icon_px, icon_px)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	logo.add_child(icon)
	logo._word = Label.new()
	logo._word.text = WORDMARK
	logo._word.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	logo._word.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	logo._word.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	logo._word.add_theme_font_override(
		&"font", _font(word_px, TRACKING_STACKED if stacked else TRACKING)
	)
	logo._word.add_theme_font_size_override(&"font_size", word_px)
	var material := ShaderMaterial.new()
	material.shader = load(SHADER) as Shader
	material.set_shader_parameter(&"top_color", UiTokens.GOLD_BRIGHT)
	material.set_shader_parameter(&"bottom_color", UiTokens.GOLD)
	logo._word.material = material
	logo._word.resized.connect(logo._on_word_resized)
	logo.add_child(logo._word)
	return logo


func word() -> Label:
	return _word


static func _font(word_px: int, tracking: float) -> FontVariation:
	var font := FontVariation.new()
	font.base_font = load(UiTokens.FONT_DISPLAY_PATH) as FontFile
	var wght := TextServerManager.get_primary_interface().name_to_tag("wght")
	font.variation_opentype = {wght: WEIGHT_BLACK}
	font.spacing_glyph = roundi(word_px * tracking)
	return font


func _on_word_resized() -> void:
	(_word.material as ShaderMaterial).set_shader_parameter(&"height", _word.size.y)
