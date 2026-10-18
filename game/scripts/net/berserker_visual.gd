class_name BerserkerVisual
extends HeroVisual
## Visual do Berserker (F75): o basico alterna o golpe de cada mao (Berserker.swing_left) e, logo
## depois do Arremesso de Machado, o machado da mao direita some (Berserker.axe_out_ticks) — o do
## pack ou a peca de equipamento no handslot.r. So le estado.

## Osso da mao que arremessa.
const THROWN_BONE: String = "handslot.r"

## Golpe da mao esquerda; o da direita e basic_attack.
@export var basic_attack_left: StringName = &"Dualwield_Melee_Attack_Slice"
## Machado do pack que voa no Q (no da malha presa ao handslot.r).
@export var thrown_axe: StringName = &"Axe_R"

var _thrown_shown: bool = true


func _process(delta: float) -> void:
	super(delta)
	var shown := (_hero as Berserker).axe_out_ticks == 0
	if shown != _thrown_shown:
		_thrown_shown = shown
		_show_thrown_axe(shown)


func _basic_clip() -> StringName:
	return basic_attack_left if (_hero as Berserker).swing_left else basic_attack


func _show_slot(slot: int, item: ItemData) -> void:
	super(slot, item)
	if slot == ItemData.Slot.WEAPON and not _thrown_shown:
		_show_thrown_axe(false)  # peca nova no meio do arremesso nasce escondida


## Mostra ou esconde o machado da direita: a peca de equipamento, se houver, senao o do pack.
func _show_thrown_axe(shown: bool) -> void:
	var pieces: Array = _attachments[ItemData.Slot.WEAPON]
	for attachment: BoneAttachment3D in pieces:
		if attachment.bone_name == THROWN_BONE:
			attachment.visible = shown
	var pack_axe := model.find_child(thrown_axe) as Node3D
	if pack_axe != null:
		pack_axe.visible = shown and pieces.is_empty()
