class_name HeroSheet
extends HBoxContainer
## Ficha do heroi local na aba Heroi do Bestiario (F62, ADR-0014): preview 3D, nome, classe e
## resumo, nivel e atributos finais (Hero.attributes), os 4 itens equipados com raridade, os
## conjuntos e as 4 habilidades com tecla, rank, recarga, dano base do rank e descricao
## (SkillData.description). So le o heroi; refresh() ao abrir.

const PREVIEW: PackedScene = preload("res://shared/ui/components/monster_preview_3d.tscn")
const SLOT_ITEM: PackedScene = preload("res://shared/ui/components/slot_item.tscn")
const SKILL_KEYS: Array[String] = ["RMB", "Q", "E", "R"]
const SLOT_NAMES: Array[String] = ["Arma", "Elmo", "Peito", "Bota"]
## Indice = ItemData.Rarity.
const RARITY_COLORS: Array[Color] = [
	UiTokens.RARITY_COMMON, UiTokens.RARITY_RARE, UiTokens.RARITY_EPIC
]
const PREVIEW_SIZE: Vector2 = Vector2(360, 460)
const ICON_SIZE: Vector2 = Vector2(48, 48)
## De frente para a camera nos KayKit (como na selecao).
const PREVIEW_FACING: float = 180.0

var _hero: Hero
var _shown_hero_id: StringName = &""

var _preview: MonsterPreview3D = PREVIEW.instantiate() as MonsterPreview3D
var _name: Label = Label.new()
var _role: Label = Label.new()
var _summary: Label = Label.new()
var _level: Label = Label.new()
var _attributes: GridContainer = GridContainer.new()
var _items: VBoxContainer = VBoxContainer.new()
var _sets: Label = Label.new()
var _skills: VBoxContainer = VBoxContainer.new()


func _init() -> void:
	add_theme_constant_override(&"separation", UiTokens.SPACE_LG)
	_preview.custom_minimum_size = PREVIEW_SIZE
	_preview.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_preview.facing = PREVIEW_FACING
	add_child(_preview)
	add_child(_card(_profile_column()))
	var skills_card := _card(_skills_column())
	skills_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(skills_card)


## Passa a mostrar [param hero] (o heroi do jogador deste processo).
func bind(hero: Hero) -> void:
	_hero = hero


func has_hero() -> bool:
	return is_instance_valid(_hero)


## Rele nivel, itens, atributos e ranks; o modelo so troca se o heroi mudou.
func refresh() -> void:
	if not has_hero():
		return
	var data := _hero.hero_data
	if data.id != _shown_hero_id:
		_shown_hero_id = data.id
		_preview.show_model(HeroSelect.model_of(data.id))
	_name.text = data.display_name.to_upper()
	_role.text = data.role
	_summary.text = data.summary
	_level.text = tr("Nível %d") % _hero.level
	_fill_attributes(_hero.attributes)
	_fill_items()
	_fill_skills(data)


func _profile_column() -> VBoxContainer:
	var column := VBoxContainer.new()
	column.custom_minimum_size = Vector2(320, 0)
	column.add_theme_constant_override(&"separation", UiTokens.SPACE_SM)
	_name.theme_type_variation = &"LabelH1"
	_role.theme_type_variation = &"LabelH2"
	_summary.theme_type_variation = &"LabelMuted"
	_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_level.theme_type_variation = &"LabelH2"
	_attributes.columns = 3
	_attributes.add_theme_constant_override(&"h_separation", UiTokens.SPACE_LG)
	_sets.theme_type_variation = &"LabelMuted"
	for node: Control in [_name, _role, _summary, _level, _attributes]:
		column.add_child(node)
	column.add_child(_section(tr("EQUIPAMENTOS")))
	column.add_child(_items)
	column.add_child(_sets)
	return column


func _skills_column() -> VBoxContainer:
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", UiTokens.SPACE_SM)
	column.add_child(_section(tr("HABILIDADES")))
	_skills.add_theme_constant_override(&"separation", UiTokens.SPACE_MD)
	column.add_child(_skills)
	return column


func _card(content: Control) -> PanelCard:
	var card := PanelCard.new()
	card.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	card.add_child(content)
	return card


func _section(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = &"LabelMuted"
	return label


func _fill_attributes(attributes: HeroAttributes) -> void:
	_clear(_attributes)
	var hp := tr("HP %d / %d") % [_hero.hp, attributes.max_hp]
	for text: String in [
		tr("ATQ %d") % roundi(attributes.attack),
		tr("INT %d") % roundi(attributes.intelligence),
		tr("AGI %d") % roundi(attributes.agility),
		tr("DEF %d") % roundi(attributes.defense),
		tr("VEL %s") % HudMath.decimal(attributes.move_speed),
		tr("RCG %d%%") % roundi(attributes.cdr_percent),
		hp,
	]:
		var label := Label.new()
		label.text = text
		_attributes.add_child(label)


func _fill_items() -> void:
	_clear(_items)
	var catalog := _hero.item_catalog
	var icons := ItemVisuals.for_hero(_hero.hero_data.id)
	for slot: int in Inventory.SLOTS:
		var row := HBoxContainer.new()
		row.add_theme_constant_override(&"separation", UiTokens.SPACE_SM)
		var icon := SLOT_ITEM.instantiate() as SlotItem
		icon.slot = slot
		var text := Label.new()
		row.add_child(icon)
		row.add_child(text)
		_items.add_child(row)  # na arvore antes do bind: o SlotItem usa @onready
		var item := Inventory.item_at(_hero.equipment, slot, catalog)
		if item == null:
			icon.clear()
			text.text = tr("%s — vazio") % tr(SLOT_NAMES[slot])
			text.theme_type_variation = &"LabelMuted"
		else:
			icon.bind(item, icons.icon(item) if icons != null else null)
			text.text = "%s · %s" % [item.display_name, ItemData.RARITY_NAMES[item.rarity]]
			text.add_theme_color_override(&"font_color", RARITY_COLORS[item.rarity])
	_sets.text = HeroPlate.set_text(_hero.equipment, catalog)
	_sets.visible = not _sets.text.is_empty()


func _fill_skills(data: HeroData) -> void:
	_clear(_skills)
	var skills: Array[SkillData] = [data.basic_attack, data.skill_q, data.skill_e, data.skill_r]
	for i: int in skills.size():
		_skills.add_child(_skill_row(skills[i], i))


func _skill_row(skill: SkillData, slot: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", UiTokens.SPACE_MD)
	var icon := TextureRect.new()
	icon.texture = skill.icon
	icon.custom_minimum_size = ICON_SIZE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(icon)
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var title := Label.new()
	title.text = "[%s] %s" % [SKILL_KEYS[slot], skill.display_name]
	title.theme_type_variation = &"LabelH2"
	var facts := Label.new()
	facts.text = skill_facts(skill, _rank_of(slot))
	facts.theme_type_variation = &"LabelMuted"
	var description := Label.new()
	description.text = skill.description
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for node: Control in [title, facts, description]:
		text.add_child(node)
	row.add_child(text)
	return row


## Rank aprendido do slot (basico sempre 1; 0 = ainda nao aprendida).
func _rank_of(slot: int) -> int:
	return 1 if slot == 0 else _hero.ranks[slot - 1]


## "Rank 2/5 · Recarga 8,0 s · Base 80" do [param rank] (0 = "Não aprendida"); campos vazios saem.
static func skill_facts(skill: SkillData, rank: int) -> String:
	var parts: PackedStringArray = []
	if rank == 0:
		parts.append(TranslationServer.translate("Não aprendida"))
	else:
		parts.append(TranslationServer.translate("Rank %d/%d") % [rank, skill.max_rank])
	var index := maxi(rank, 1) - 1
	if not skill.cooldown.is_empty():
		var cooldown := skill.cooldown[mini(index, skill.cooldown.size() - 1)]
		parts.append(TranslationServer.translate("Recarga %s s") % HudMath.decimal(cooldown))
	if not skill.base_amount.is_empty():
		var base := skill.base_amount[mini(index, skill.base_amount.size() - 1)]
		if base > 0.0:
			parts.append(TranslationServer.translate("Base %d") % roundi(base))
	return " · ".join(parts)


func _clear(container: Node) -> void:
	for child: Node in container.get_children():
		container.remove_child(child)
		child.queue_free()
