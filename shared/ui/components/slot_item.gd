class_name SlotItem
extends TextureButton
## Slot de equipamento (COMPONENTS.md, PATTERNS P6): moldura pela raridade, raridade em texto
## e tooltip rico. Icone e placeholder com o nome do slot (DEBITO DS-06).
## Cena: chame bind()/set_*() depois de entrar na arvore (os nos internos sao @onready).

signal hovered(item: ItemData)
signal pressed_slot(slot: ItemData.Slot)

## Indice = ItemData.Rarity.
const RARITY_FRAMES: Array[StringName] = [&"FrameCommon", &"FrameRare", &"FrameEpic"]
const EMPTY_FRAME: StringName = &"FrameEmpty"
## Indice = ItemData.Slot.
const SLOT_NAMES: Array[String] = ["Arma", "Elmo", "Peito", "Bota"]
## Clareia o slot sob o mouse.
const HOVER_BRIGHTNESS: float = 1.25

@export var slot: ItemData.Slot = ItemData.Slot.WEAPON:
	set(value):
		slot = value
		if is_node_ready():
			_slot_label.text = SLOT_NAMES[value]
			if is_empty():
				clear()

var item: ItemData

@onready var _frame: Panel = %Frame
@onready var _slot_label: Label = %SlotName
@onready var _rarity_label: Label = %Rarity


func _ready() -> void:
	_slot_label.text = SLOT_NAMES[slot]
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	pressed.connect(_on_pressed)
	clear()


func bind(p_item: ItemData) -> void:
	item = p_item
	_frame.theme_type_variation = RARITY_FRAMES[p_item.rarity]
	_rarity_label.text = ItemData.RARITY_NAMES[p_item.rarity]
	_slot_label.theme_type_variation = &""
	tooltip_text = p_item.display_name


func clear() -> void:
	item = null
	_frame.theme_type_variation = EMPTY_FRAME
	_rarity_label.text = ""
	_slot_label.theme_type_variation = &"LabelMuted"
	tooltip_text = tr("%s: vazio") % SLOT_NAMES[slot]


func is_empty() -> bool:
	return item == null


func _make_custom_tooltip(_for_text: String) -> Object:
	if item == null:
		return null  # tooltip padrao com tooltip_text
	var tooltip := ItemTooltip.new()
	tooltip.bind(item)
	return tooltip


func _on_mouse_entered() -> void:
	modulate = Color(HOVER_BRIGHTNESS, HOVER_BRIGHTNESS, HOVER_BRIGHTNESS)
	if item != null:
		hovered.emit(item)


func _on_mouse_exited() -> void:
	modulate = Color.WHITE


func _on_pressed() -> void:
	pressed_slot.emit(slot)
