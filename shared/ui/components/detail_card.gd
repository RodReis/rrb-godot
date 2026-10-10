class_name DetailCard
extends PanelCard
## Ficha do padrao lista + detalhe (COMPONENTS.md, PATTERNS P3): titulo, etiqueta e linhas
## "rotulo: valor" do Resource recebido. Despacha por tipo; hoje so MonsterData (bestiario,
## F13); outros tipos mostram so o nome. Valores saem do Resource, nunca da cena.

## Indice = MonsterData.Tier.
const TIER_NAMES: Array[String] = ["Tier 1", "Tier 2", "Tier 3", "Chefe"]
const PERCENT: float = 100.0

var _title: Label = Label.new()
var _tag: Label = Label.new()
var _rows: GridContainer = GridContainer.new()


func _init() -> void:
	var column := VBoxContainer.new()
	var header := HBoxContainer.new()
	_title.theme_type_variation = &"LabelH2"
	_title.size_flags_horizontal = SIZE_EXPAND_FILL
	_tag.theme_type_variation = &"LabelBadge"
	header.add_child(_title)
	header.add_child(_tag)
	column.add_child(header)
	column.add_child(HSeparator.new())
	_rows.columns = 2
	column.add_child(_rows)
	add_child(column)


## Linhas da ficha do monstro (GDB §5.1): [rotulo, valor].
static func monster_rows(monster: MonsterData) -> Array[PackedStringArray]:
	var rows: Array[PackedStringArray] = []
	rows.append(PackedStringArray(["Vida", "%d HP" % roundi(monster.hp)]))
	var damage := "%d" % roundi(monster.damage)
	if monster.area_attack:
		damage += " em área"
	if monster.ranged_range > 0.0:
		damage += " a distância (%s u)" % _decimal(monster.ranged_range)
	rows.append(PackedStringArray(["Dano por golpe", damage]))
	rows.append(PackedStringArray(["Cadência", "%s s" % _decimal(monster.attack_interval)]))
	if monster.knockback > 0.0:
		rows.append(PackedStringArray(["Empurrão", "%s u" % _decimal(monster.knockback)]))
	rows.append(PackedStringArray(["XP", "%d XP" % monster.xp]))
	rows.append(PackedStringArray(["Na arena", "%d" % monster.count]))
	var drops := PackedStringArray()
	var chances: Array[float] = [
		monster.drop_common_chance, monster.drop_rare_chance, monster.drop_epic_chance
	]
	for rarity: int in chances.size():
		if chances[rarity] > 0.0:
			var pct := roundi(chances[rarity] * PERCENT)
			drops.append("%s %d%%" % [ItemData.RARITY_NAMES[rarity], pct])
	rows.append(PackedStringArray(["Drop", " · ".join(drops) if not drops.is_empty() else "—"]))
	return rows


## pt-BR: virgula decimal, sem zeros sobrando.
static func _decimal(value: float) -> String:
	return String.num(value, 2).replace(".", ",")


func bind(resource: Resource) -> void:
	for child: Node in _rows.get_children():
		_rows.remove_child(child)
		child.queue_free()
	var monster := resource as MonsterData
	if monster == null:
		_title.text = str(resource.get(&"display_name"))
		_tag.text = ""
		accent = Accent.NONE
		return
	_title.text = monster.display_name
	_tag.text = TIER_NAMES[monster.tier]
	accent = Accent.PURPLE if monster.tier == MonsterData.Tier.BOSS else Accent.NONE
	for row: PackedStringArray in monster_rows(monster):
		var label := Label.new()
		label.theme_type_variation = &"LabelMuted"
		label.text = row[0]
		_rows.add_child(label)
		var value := Label.new()
		value.text = row[1]
		_rows.add_child(value)
