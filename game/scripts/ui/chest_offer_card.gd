class_name ChestOfferCard
extends PanelCard
## Card da oferta do bau (SPEC-047 §3), ancorado ao bau aberto ao alcance do heroi local: icone,
## nome, raridade (cor e texto, P6), atributos contra o equipado (+/-), conjuntos antes -> depois
## e, so quando ItemRules.offer vale para ele, o prompt "Segure F" com anel de swap_hold_time.
## Substitui a linha de texto do HeroPlate. So le estado replicado e nunca decide regra: o
## servidor avalia a mesma ItemRules em Chest.interact.

const SLOT_ITEM: PackedScene = preload("res://shared/ui/components/slot_item.tscn")
## Indice = ItemData.Rarity.
const RARITY_COLORS: Array[Color] = [
	UiTokens.RARITY_COMMON, UiTokens.RARITY_RARE, UiTokens.RARITY_EPIC
]
## Altura acima do bau (m) onde o card se prende, e margem das bordas da viewport (px).
const ANCHOR_HEIGHT: float = 1.4
const ANCHOR_GAP: float = 12.0

var _hero: Hero
var _chests: Array[Chest] = []
var _shown_chest: Chest
var _shown_item: int = Ids.NONE
var _shown_equipment: Vector4i = Inventory.NONE
var _shown_offer: bool = false
var _items: ItemVisuals  # icones dos itens do heroi local

var _slot: SlotItem = SLOT_ITEM.instantiate() as SlotItem
var _name: Label = Label.new()
var _rarity: Label = Label.new()
var _rows: VBoxContainer = VBoxContainer.new()
var _sets: Label = Label.new()
var _prompt: HBoxContainer = HBoxContainer.new()
var _ring: HoldRing = HoldRing.new()


func _init() -> void:
	variant = Surface.PANEL
	accent = Accent.GOLD
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	var column := VBoxContainer.new()
	var header := HBoxContainer.new()
	var titles := VBoxContainer.new()
	_name.theme_type_variation = &"LabelH2"
	_sets.theme_type_variation = &"LabelMuted"
	titles.add_child(_name)
	titles.add_child(_rarity)
	header.add_child(_slot)
	header.add_child(titles)
	var key := HotkeyBadge.new()
	key.key = "F"
	key.size_variant = HotkeyBadge.Size.MD
	var hint := Label.new()
	hint.text = TranslationServer.translate("Segure F")
	_prompt.add_child(_ring)
	_prompt.add_child(key)
	_prompt.add_child(hint)
	column.add_child(header)
	column.add_child(_rows)
	column.add_child(_sets)
	column.add_child(_prompt)
	add_child(column)


## Liga ao heroi local e esconde o que sobrou de antes.
func bind(hero: Hero) -> void:
	_hero = hero
	_items = ItemVisuals.for_hero(hero.hero_data.id)
	_shown_chest = null
	visible = false


## Baus da partida (a HUD dona recolhe do SpawnDirector).
func set_chests(chests: Array[Chest]) -> void:
	_chests = chests


## Chamado pela HUD dona a cada quadro.
func update() -> void:
	var chest := _chest_in_reach()
	if chest == null:
		visible = false
		return
	var incoming := chest.catalog.find(chest.item)
	if incoming == null:
		visible = false
		return
	if chest != _shown_chest or chest.item != _shown_item or _hero.equipment != _shown_equipment:
		_rebuild(chest, incoming)
	_prompt.visible = _shown_offer
	_ring.progress = _hold_progress(chest) if _shown_offer else 0.0
	visible = _place(chest)


## Bau aberto, com item, ao alcance e na visao (neblina F37) do heroi local.
func _chest_in_reach() -> Chest:
	for chest: Chest in _chests:
		var shown := chest.opened and chest.item != Ids.NONE and chest.seen_by(_hero)
		if shown and chest.in_reach(_hero.global_position):
			return chest
	return null


func _rebuild(chest: Chest, incoming: ItemData) -> void:
	_shown_chest = chest
	_shown_item = chest.item
	_shown_equipment = _hero.equipment
	var current := Inventory.item_at(_hero.equipment, incoming.slot, chest.catalog)
	_shown_offer = ItemRules.offer(current, incoming)
	_slot.slot = incoming.slot
	_slot.bind(incoming, _items.icon(incoming) if _items != null else null)
	_name.text = incoming.display_name
	_rarity.text = ItemData.RARITY_NAMES[incoming.rarity]
	_rarity.add_theme_color_override(&"font_color", RARITY_COLORS[incoming.rarity])
	for child: Node in _rows.get_children():
		_rows.remove_child(child)
		child.queue_free()
	for row: OfferCompare.Row in OfferCompare.rows(current, incoming):
		_rows.add_child(_row_node(row))
	_sets.text = OfferCompare.set_change(_hero.equipment, incoming, chest.catalog)
	_sets.visible = not _sets.text.is_empty()
	reset_size()


func _row_node(row: OfferCompare.Row) -> HBoxContainer:
	var line := HBoxContainer.new()
	var label := Label.new()
	label.text = "%s %d%s" % [row.label, row.value, "%" if row.percent else ""]
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(label)
	var delta := Label.new()
	delta.text = OfferCompare.delta_text(row)
	delta.add_theme_color_override(&"font_color", UiTokens.GREEN if row.delta > 0 else UiTokens.RED)
	line.add_child(delta)
	return line


## 0..1 do F segurado desde depois da abertura (o servidor ignora o F segurado desde antes).
func _hold_progress(chest: Chest) -> float:
	var ticks := _hero.interact_ticks
	if ticks == 0 or NetworkTime.tick - ticks + 1 <= chest.opened_tick:
		return 0.0
	return float(ticks) / chest.hold_ticks()


## Prende o card acima do bau, dentro da viewport; false se o bau esta atras da camera.
func _place(chest: Chest) -> bool:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return false
	var point := chest.global_position + Vector3.UP * ANCHOR_HEIGHT
	if camera.is_position_behind(point):
		return false
	var anchor := camera.unproject_position(point)
	var bounds := get_viewport_rect().size - size - Vector2.ONE * ANCHOR_GAP
	var target := anchor - Vector2(size.x / 2.0, size.y)
	position = target.clamp(Vector2.ONE * ANCHOR_GAP, bounds.max(Vector2.ONE * ANCHOR_GAP))
	return true
