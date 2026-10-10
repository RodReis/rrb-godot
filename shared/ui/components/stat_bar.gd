class_name StatBar
extends HBoxContainer
## Barra de atributo com rotulo e numeros (COMPONENTS.md, PATTERNS P9): HP proprio GREEN,
## inimigo RED, XP GOLD_BRIGHT, atributo BLUE.
## Cena: chame bind()/set_*() depois de entrar na arvore (os nos internos sao @onready).

enum Kind { HP, HP_ENEMY, XP, STAT }

## Indice = Kind; vazio = ProgressBar (GREEN).
const VARIANT_TYPES: Array[StringName] = [&"", &"ProgressEnemy", &"ProgressXp", &"ProgressStat"]

@export var show_numbers: bool = true:
	set(value):
		show_numbers = value
		if is_node_ready():
			_numbers.visible = value

var variant: Kind = Kind.HP

var _tween: Tween

@onready var _label: Label = %Label
@onready var _bar: ProgressBar = %Bar
@onready var _numbers: Label = %Numbers


func _ready() -> void:
	_numbers.visible = show_numbers


func bind(label: String, value: float, max_value: float, p_variant: Kind = Kind.HP) -> void:
	variant = p_variant
	_label.text = label
	_label.visible = not label.is_empty()
	_bar.theme_type_variation = VARIANT_TYPES[p_variant]
	_bar.max_value = max_value
	animate_to(value, 0.0)


## Numeros mudam na hora; a barra anda em [param duration] s (0 = na hora).
func animate_to(value: float, duration: float = UiTokens.DUR_BASE) -> void:
	_numbers.text = "%d / %d" % [roundi(value), roundi(_bar.max_value)]
	if _tween != null:
		_tween.kill()
	if duration <= 0.0:
		_bar.value = value
		return
	_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_bar, ^"value", value, duration)
