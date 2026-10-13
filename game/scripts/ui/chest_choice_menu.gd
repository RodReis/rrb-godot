class_name ChestChoiceMenu
extends Control
## Menu do bau (F61, ADR-0014; supera o card de oferta da SPEC-047 §3): F perto de um bau abre o
## menu com os 3 itens (Chest.choices) quando o servidor confirma que o bau e do heroi local
## (Chest.opener); o clique leva 1 (PlayerInput.queue_pick -> Chest.pick) e fecha. Enquanto
## aberto, cursor livre e heroi parado (PlayerInput.suspended, padrao do Bestiario); Esc fecha sem
## pegar e o F reabre o mesmo menu (o bau segue reservado). So le estado replicado; o servidor
## decide. Cobre a tela inteira (top_level) para nenhum clique cair na camera.

const DIM: Color = Color(UiTokens.BG_SURFACE, 0.55)

var _hero: Hero
var _icons: ItemVisuals
var _chests: Array[Chest] = []
## Bau do menu aberto; null = fechado.
var _chest: Chest
## Bau que recebeu o F e espera o servidor abrir; null = nenhum.
var _waiting: Chest
var _shown: PackedInt32Array = PackedInt32Array()

var _cards: HBoxContainer = HBoxContainer.new()


func _init() -> void:
	top_level = true
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = DIM
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var frame := PanelCard.new()
	frame.variant = PanelCard.Surface.GLASS
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(frame)
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override(&"separation", UiTokens.SPACE_MD)
	frame.add_child(column)
	var title := Label.new()
	title.text = TranslationServer.translate("Escolha 1 item")
	title.theme_type_variation = &"LabelH2"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	_cards.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cards.add_theme_constant_override(&"separation", UiTokens.SPACE_MD)
	column.add_child(_cards)
	var hint := Label.new()
	hint.text = TranslationServer.translate("Clique para levar · Esc fecha sem pegar")
	hint.theme_type_variation = &"LabelMuted"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(hint)


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(InputActions.CANCEL):
		close()
	elif not visible and event.is_action_pressed(InputActions.INTERACT):
		request_open()
		return  # o F segue para o PlayerInput: e ele que abre o bau no servidor
	else:
		return
	get_viewport().set_input_as_handled()


func _exit_tree() -> void:
	if visible:
		PlayerInput.suspended = false


## Liga ao heroi local e fecha o que sobrou de antes.
func bind(hero: Hero) -> void:
	_hero = hero
	_icons = ItemVisuals.for_hero(hero.hero_data.id)
	_waiting = null
	if visible:
		close()


## Baus da partida (a HUD dona recolhe do SpawnDirector).
func set_chests(chests: Array[Chest]) -> void:
	_chests = chests


## F perto de um bau: abre ja se o bau e do heroi local, senao espera o servidor abrir.
func request_open() -> void:
	_waiting = _chest_in_reach()


## Chamado pela HUD dona a cada quadro.
func update() -> void:
	if _hero == null:
		return
	if visible:
		if not _usable(_chest):
			close()
		elif _chest.choices != _shown:
			_rebuild()
		return
	if _waiting == null:
		return
	if _usable(_waiting):
		_open(_waiting)
	elif _waiting.opened or not _waiting.in_reach(_hero.global_position):
		_waiting = null  # bau de outro heroi, de cura, ja escolhido ou longe


func close() -> void:
	visible = false
	_chest = null
	PlayerInput.suspended = false


func _open(chest: Chest) -> void:
	_waiting = null
	_chest = chest
	_rebuild()
	visible = true
	PlayerInput.suspended = true


## Bau aberto pelo heroi local, com itens, ao alcance.
func _usable(chest: Chest) -> bool:
	return (
		chest != null
		and chest.opened
		and chest.opener == _hero.peer_id
		and not chest.choices.is_empty()
		and chest.in_reach(_hero.global_position)
	)


## Bau ao alcance e na visao (neblina F37) do heroi local.
func _chest_in_reach() -> Chest:
	for chest: Chest in _chests:
		if chest.seen_by(_hero) and chest.in_reach(_hero.global_position):
			return chest
	return null


func _rebuild() -> void:
	_shown = _chest.choices
	for child: Node in _cards.get_children():
		_cards.remove_child(child)
		child.queue_free()
	for i: int in _shown.size():
		var item := _chest.catalog.find(_shown[i])
		if item == null:
			continue
		var card := ChestChoiceCard.new()
		card.index = i
		card.chosen.connect(_on_card_chosen)
		_cards.add_child(card)
		card.show_item(_hero, item, _chest.catalog, _icons)


func _on_card_chosen(index: int) -> void:
	(_hero.input as PlayerInput).queue_pick(index)
	close()
