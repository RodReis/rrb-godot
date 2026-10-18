class_name HeroChoice
extends Button
## Card de heroi da grade da selecao (F51, prototipo "Seleção de Heróis"): retrato 3D parado,
## nome, classe e o selo ATIVO no escolhido. So mostra; quem decide e a HeroSelect. Fora do foco
## de teclado: Espaco e sempre o lock-in.

const PREVIEW: PackedScene = preload("res://shared/ui/components/monster_preview_3d.tscn")
const CARD_HEIGHT: float = 250.0
const PORTRAIT_SIZE: Vector2 = Vector2(150, 150)
## Retrato: camera perto, de frente, enquadrando cabeca e tronco (multiplos da altura do modelo).
const PORTRAIT_DISTANCE: float = 1.15
const PORTRAIT_HEIGHT: float = 0.7
const PORTRAIT_LOOK: float = 0.62
const PORTRAIT_FACING: float = 180.0
## Mesma altura de enquadramento para todos (topo do Cavaleiro): o corpo sai do mesmo tamanho
## em toda moldura, com chapeu ou capuz (PI 2026-10-12).
const PORTRAIT_FRAME_HEIGHT: float = 1.9
## Escala do card escolhido (scale-102 do prototipo).
const ACTIVE_SCALE: float = 1.03
## Selo ATIVO: canto superior direito, meio para fora da borda.
const TAG_OFFSET: Vector2 = Vector2(-12, -12)
## Cor do texto da classe por papel (PRD §4.1); Mago fica no texto neutro porque PURPLE nao passa
## contraste em texto pequeno (TOKENS §1).
const ROLE_LABELS: Dictionary[String, StringName] = {
	"Tanque": &"LabelHeroAccent",
	"Ranger": &"LabelHeroReady",
	"Algoz": &"LabelHeroHighlight",
}

var hero: HeroData

var _frame: PanelContainer
var _preview: MonsterPreview3D
var _tag: PanelContainer
var _tween: Tween


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and _tag != null:
		_tag.position = Vector2(size.x - _tag.get_combined_minimum_size().x, 0.0) + TAG_OFFSET


## Monta o card de [param data]; chame antes de entrar na arvore.
func setup(data: HeroData) -> void:
	hero = data
	theme_type_variation = &"HeroChoice"
	custom_minimum_size = Vector2(0.0, CARD_HEIGHT)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	focus_mode = Control.FOCUS_NONE
	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(column)
	_frame = PanelContainer.new()
	_frame.custom_minimum_size = PORTRAIT_SIZE
	_frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(_frame)
	_preview = PREVIEW.instantiate() as MonsterPreview3D
	_preview.turn_speed = 0.0
	_preview.camera_distance = PORTRAIT_DISTANCE
	_preview.camera_height = PORTRAIT_HEIGHT
	_preview.look_height = PORTRAIT_LOOK
	_preview.facing = PORTRAIT_FACING
	_preview.frame_height = PORTRAIT_FRAME_HEIGHT
	_preview.custom_minimum_size = Vector2.ZERO
	_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame.add_child(_preview)
	column.add_child(_label(data.display_name, &"LabelHeroStrong"))
	column.add_child(_label(data.role.to_upper(), ROLE_LABELS.get(data.role, &"LabelMuted")))
	_tag = PanelContainer.new()
	_tag.theme_type_variation = &"HeroGoldBadge"
	_tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tag.add_child(_label(tr("ATIVO"), &"LabelHeroDark"))
	add_child(_tag)
	set_active(false)


## Retrato do heroi (nulo = vazio); so dentro da arvore. Heroi mais alto que o rig medio traz a
## altura dele (HeroVisual.portrait_height, Berserker F75).
func show_model(model: Node3D) -> void:
	var height: float = model.get_meta(&"portrait_height", 0.0) if model != null else 0.0
	_preview.frame_height = height if height > 0.0 else PORTRAIT_FRAME_HEIGHT
	_preview.show_model(model)


func set_active(value: bool) -> void:
	theme_type_variation = &"HeroChoiceActive" if value else &"HeroChoice"
	_frame.theme_type_variation = &"HeroPortraitActive" if value else &"HeroPortrait"
	_tag.visible = value
	if not is_inside_tree():
		return
	pivot_offset = size / 2.0
	if _tween != null:
		_tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	var target := Vector2.ONE * (ACTIVE_SCALE if value else 1.0)
	_tween.tween_property(self, ^"scale", target, UiTokens.DUR_FAST)


func _label(text: String, type: StringName) -> Label:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = type
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
