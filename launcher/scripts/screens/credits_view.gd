class_name CreditsView
extends HBoxContainer
## Aba Creditos de Configuracoes (decisao do PI em 2026-10-10; ARCHITECTURE-LAUNCHER §3.4): os
## autores e licencas de shared/assets/LICENSES.md, das fontes e icones (shared/ui/theme/fonts/) e
## do motor. A licenca do Godot e dos componentes dele vem do proprio Engine (texto oficial).
## Mesma linguagem visual das outras abas (sem prototipo proprio).

## Grupo -> [icone, entradas]; entrada = [obra, autor, licenca, site].
const GROUPS: Array[Array] = [
	[
		"ARTE E SOM",
		UiIcons.LICENSE,
		[
			[
				"KayKit — Medieval Hexagon, Adventurers 1.0, 2.0 e 2.0 Extra, Skeletons",
				"Kay Lousberg",
				"CC0 1.0",
				"kaylousberg.com"
			],
			["Medieval Village MegaKit", "Quaternius", "CC0 1.0", "quaternius.com"],
			["Texturas PBR", "Lennart Demes (ambientCG)", "CC0 1.0", "ambientcg.com"],
			["Music Jingles", "Kenney Vleugels", "CC0 1.0", "kenney.nl"],
		]
	],
	[
		"FONTES E ÍCONES",
		UiIcons.KEYBOARD,
		[
			["Space Grotesk", "The Space Grotesk Project Authors", "SIL OFL 1.1", ""],
			["Outfit", "The Outfit Project Authors", "SIL OFL 1.1", ""],
			["JetBrains Mono", "The JetBrains Mono Project Authors", "SIL OFL 1.1", ""],
			["Cinzel", "The Cinzel Project Authors", "SIL OFL 1.1", ""],
			["Montserrat", "The Montserrat Project Authors", "SIL OFL 1.1", ""],
			["Barlow Condensed", "The Barlow Project Authors", "SIL OFL 1.1", ""],
			["Material Symbols", "Google", "Apache 2.0", "fonts.google.com/icons"],
		]
	],
	[
		"MOTOR E BIBLIOTECAS",
		UiIcons.SETTINGS,
		[
			["netfox", "Gálffy Tamás", "MIT", "github.com/foxssake/netfox"],
		]
	],
]


func _init() -> void:
	theme_type_variation = &"LnHGapLg"
	for group: Array in GROUPS:
		var card := _card(group[0], group[1])
		for entry: Array in group[2]:
			card.add_child(_entry(entry))
		if group == GROUPS.back():
			card.add_child(_engine())


## Uma linha por obra: nome, autor e licenca, site.
static func _entry(entry: Array) -> SettingRow:
	var detail := "%s · %s" % [entry[1], entry[2]]
	var row := SettingRow.new(entry[0], detail)
	if not String(entry[3]).is_empty():
		var site := Label.new()
		site.theme_type_variation = &"LnNumCyan"
		site.text = entry[3]
		row.controls.add_child(site)
	return row


func _card(title: String, icon: String) -> VBoxContainer:
	var card := PanelContainer.new()
	card.theme_type_variation = &"LnCard"
	card.size_flags_horizontal = SIZE_EXPAND_FILL
	add_child(card)
	var column := VBoxContainer.new()
	column.theme_type_variation = &"LnVGapSm"
	card.add_child(column)
	var header := HBoxContainer.new()
	header.theme_type_variation = &"LnHGapSm"
	column.add_child(header)
	var box := PanelContainer.new()
	box.theme_type_variation = &"LnIconBox"
	header.add_child(box)
	var glyph := Label.new()
	glyph.theme_type_variation = &"LnIconGold"
	glyph.text = icon
	box.add_child(glyph)
	var label := Label.new()
	label.theme_type_variation = &"LnHeadlineSm"
	label.text = title
	header.add_child(label)
	var divider := HSeparator.new()
	divider.theme_type_variation = &"LnDivider"
	column.add_child(divider)
	return column


## Godot Engine: licenca MIT e os componentes de terceiros, com o texto oficial do Engine.
static func _engine() -> Control:
	var column := VBoxContainer.new()
	column.theme_type_variation = &"LnVGapSm"
	column.size_flags_vertical = SIZE_EXPAND_FILL
	var copyright := "Juan Linietsky, Ariel Manzur e contribuidores"
	column.add_child(_entry(["Godot Engine", copyright, "MIT", "godotengine.org"]))
	var well := PanelContainer.new()
	well.theme_type_variation = &"LnWell"
	well.size_flags_vertical = SIZE_EXPAND_FILL
	column.add_child(well)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.get_v_scroll_bar().theme_type_variation = &"LnScrollBar"
	well.add_child(scroll)
	var text := Label.new()
	text.theme_type_variation = &"LnBodySmMuted"
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.size_flags_horizontal = SIZE_EXPAND_FILL
	text.text = license_text()
	scroll.add_child(text)
	return column


## Licenca do Godot e a de cada componente de terceiros que ele embute (Engine).
static func license_text() -> String:
	var parts: PackedStringArray = [Engine.get_license_text()]
	for component: Dictionary in Engine.get_copyright_info():
		for part: Dictionary in component["parts"]:
			var holders := ", ".join(part["copyright"] as PackedStringArray)
			parts.append("%s — %s (%s)" % [component["name"], holders, part["license"]])
	return "\n\n".join(parts)
