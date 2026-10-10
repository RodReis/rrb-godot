class_name TimerLabel
extends Label
## Contador monoespacado (COMPONENTS.md, PATTERNS P7): relogio da fase, boss, fila.
## WARNING pisca em GOLD; DANGER fica em RED (texto >= 24 px bold, TOKENS §1).

enum Format { MM_SS, SS }
enum State { NORMAL, WARNING, DANGER }

const STATE_TYPES: Array[StringName] = [
	&"LabelCounter", &"LabelCounterWarning", &"LabelCounterDanger"
]
const SECONDS_PER_MINUTE: int = 60
## Opacidade minima do pisca do WARNING.
const BLINK_ALPHA: float = 0.35

@export var format: Format = Format.MM_SS

var state: State = State.NORMAL

var _blink: Tween


func _ready() -> void:
	theme_type_variation = STATE_TYPES[state]


## Segundos inteiros (arredonda para baixo); negativo vira 0.
static func format_seconds(seconds: float, p_format: Format) -> String:
	var whole := maxi(floori(seconds), 0)
	if p_format == Format.SS:
		return "%02d" % whole
	@warning_ignore("integer_division")
	return "%02d:%02d" % [whole / SECONDS_PER_MINUTE, whole % SECONDS_PER_MINUTE]


func set_seconds(seconds: float) -> void:
	text = format_seconds(seconds, format)


func set_state(value: State) -> void:
	if value == state:
		return
	state = value
	theme_type_variation = STATE_TYPES[value]
	if _blink != null:
		_blink.kill()
		_blink = null
	modulate.a = 1.0
	if value == State.WARNING:
		_blink = create_tween().set_loops()
		_blink.tween_property(self, ^"modulate:a", BLINK_ALPHA, UiTokens.DUR_SLOW)
		_blink.tween_property(self, ^"modulate:a", 1.0, UiTokens.DUR_SLOW)
