class_name ItemTooltip
extends PanelCard
## Tooltip rico do SlotItem (COMPONENTS.md): nome, raridade em texto (PATTERNS P6) e bonus.

## Atributo plano do ItemData -> sigla na UI.
const STAT_LABELS: Dictionary[StringName, String] = {
	&"hp": "HP",
	&"defense": "DEF",
	&"attack": "ATK",
	&"intelligence": "INT",
	&"agility": "AGI",
}
const PERCENT: float = 100.0
## Indice = ItemData.Rarity.
const RARITY_ACCENTS: Array[Accent] = [Accent.NONE, Accent.NONE, Accent.PURPLE]

var _name: Label = Label.new()
var _rarity: Label = Label.new()
var _bonuses: Label = Label.new()


func _init() -> void:
	var column := VBoxContainer.new()
	_name.theme_type_variation = &"LabelH2"
	_rarity.theme_type_variation = &"LabelMuted"
	column.add_child(_name)
	column.add_child(_rarity)
	column.add_child(_bonuses)
	add_child(column)


static func bonus_lines(item: ItemData) -> PackedStringArray:
	var lines := PackedStringArray()
	for stat: StringName in STAT_LABELS:
		var amount := roundi(item.get(stat) as float)
		if amount != 0:
			lines.append("+%d %s" % [amount, STAT_LABELS[stat]])
	var agility_pct := roundi(item.agility_pct * PERCENT)
	if agility_pct != 0:
		lines.append("+%d%% AGI" % agility_pct)
	if not item.passive_name.is_empty():
		var value := roundi(item.passive_value * PERCENT)
		var text := String(TranslationServer.translate("Passiva: %s (%d%%)"))
		lines.append(text % [item.passive_name, value])
	return lines


func bind(item: ItemData) -> void:
	_name.text = item.display_name
	_rarity.text = ItemData.RARITY_NAMES[item.rarity]
	_bonuses.text = "\n".join(bonus_lines(item))
	accent = RARITY_ACCENTS[item.rarity]
