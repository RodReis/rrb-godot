class_name LiftFrame
extends Control
## Moldura que ergue o card 4 px com o mouse por cima (hover:-translate-y-1 do prototipo, 300 ms).
## Dentro de um container o filho nao se move sozinho (o layout o devolve ao lugar), entao o card
## mora num Control: em repouso ocupa a moldura menos a folga de cima; com o mouse sobe a folga.
## O card tem mouse_filter PASS (a roda do mouse segue para a rolagem) e os descendentes IGNORE.

const LIFT: float = 4.0

var _card: Control
var _tween: Tween


func _init(card: Control) -> void:
	_card = card
	mouse_filter = MOUSE_FILTER_PASS
	add_child(card)
	card.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	card.offset_top = LIFT
	card.mouse_filter = MOUSE_FILTER_PASS
	card.mouse_entered.connect(_set_lifted.bind(true))
	card.mouse_exited.connect(_set_lifted.bind(false))
	card.minimum_size_changed.connect(_sync_size)
	_sync_size()


## Deixa so o card receber o mouse: o resto do conteudo e decoracao.
static func ignore_mouse(root: Node) -> void:
	for child: Node in root.get_children():
		if child is Control:
			(child as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
		ignore_mouse(child)


func card() -> Control:
	return _card


func is_lifted() -> bool:
	return _card.offset_top < LIFT


func _sync_size() -> void:
	custom_minimum_size = _card.get_combined_minimum_size() + Vector2(0.0, LIFT)


func _set_lifted(lifted: bool) -> void:
	if _tween != null:
		_tween.kill()
	_tween = create_tween().set_parallel()
	_tween.tween_property(_card, ^"offset_top", 0.0 if lifted else LIFT, UiTokens.DUR_BASE)
	_tween.tween_property(_card, ^"offset_bottom", -LIFT if lifted else 0.0, UiTokens.DUR_BASE)
