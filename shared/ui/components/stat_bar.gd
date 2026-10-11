class_name StatBar
extends HBoxContainer
## Barra de atributo com rotulo e numeros (COMPONENTS.md, PATTERNS P9): HP proprio GREEN,
## inimigo RED, XP GOLD_BRIGHT, atributo BLUE. Ghost bar (TOKENS v2): no dano a barra cai na
## hora e uma camada clara segura o valor antigo e desce depois; cura atualiza tudo na hora.
## Cena: chame bind()/set_*() depois de entrar na arvore (os nos internos sao @onready).

enum Kind { HP, HP_ENEMY, XP, STAT }

## Indice = Kind; vazio = ProgressBar (GREEN).
const VARIANT_TYPES: Array[StringName] = [&"", &"ProgressEnemy", &"ProgressXp", &"ProgressStat"]
const GHOST_TYPE: StringName = &"ProgressGhost"
## Atraso e duracao da descida da ghost bar (s).
const GHOST_DELAY: float = 0.35
const GHOST_DURATION: float = 0.4

@export var show_numbers: bool = true:
	set(value):
		show_numbers = value
		if is_node_ready():
			_numbers.visible = value

var variant: Kind = Kind.HP

var _tween: Tween

@onready var _label: Label = %Label
@onready var _ghost: ProgressBar = %Ghost
@onready var _bar: ProgressBar = %Bar
@onready var _numbers: Label = %Numbers


func _ready() -> void:
	_numbers.visible = show_numbers
	_ghost.theme_type_variation = GHOST_TYPE
	# A barra fica por cima da ghost: sem fundo proprio, senao a esconde.
	_bar.add_theme_stylebox_override(&"background", StyleBoxEmpty.new())


func bind(label: String, value: float, max_value: float, p_variant: Kind = Kind.HP) -> void:
	variant = p_variant
	_label.text = label
	_label.visible = not label.is_empty()
	_bar.theme_type_variation = VARIANT_TYPES[p_variant]
	_bar.max_value = max_value
	_ghost.max_value = max_value
	_set_now(value)


## Numeros e barra mudam na hora; numa queda a ghost bar desce depois do atraso.
func animate_to(value: float) -> void:
	if value >= _bar.value:
		_set_now(value)
		return
	_numbers.text = _format(value)
	_bar.value = value
	if _tween != null:
		_tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.tween_interval(GHOST_DELAY)
	_tween.tween_property(_ghost, ^"value", value, GHOST_DURATION)


func _set_now(value: float) -> void:
	if _tween != null:
		_tween.kill()
	_numbers.text = _format(value)
	_bar.value = value
	_ghost.value = value


func _format(value: float) -> String:
	return "%d / %d" % [roundi(value), roundi(_bar.max_value)]
