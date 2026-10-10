class_name Toast
extends PanelCard
## Aviso que some sozinho (COMPONENTS.md, PATTERNS P12): notificacao de loot na HUD e feedback
## no Launcher. O tipo vai no acento da borda; o texto tem de dizer o que aconteceu. A largura
## vem do pai (o texto quebra linha). Nao bloqueia o mouse do que esta atras.

enum Kind { INFO, SUCCESS, WARN, ERROR }

## Indice = Kind.
const KIND_ACCENTS: Array[Accent] = [Accent.NONE, Accent.GREEN, Accent.GOLD, Accent.RED]
const DEFAULT_DURATION: float = 3.0

var kind: Kind = Kind.INFO

var _message: Label = Label.new()
var _tween: Tween


func _init() -> void:
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_message)
	mouse_filter = MOUSE_FILTER_IGNORE
	visible = false


func show_message(
	text: String, p_kind: Kind = Kind.INFO, duration: float = DEFAULT_DURATION
) -> void:
	kind = p_kind
	accent = KIND_ACCENTS[p_kind]
	_message.text = text
	if not visible:
		modulate.a = 0.0
	visible = true
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, ^"modulate:a", 1.0, UiTokens.DUR_FAST)
	_tween.tween_interval(duration)
	_tween.tween_property(self, ^"modulate:a", 0.0, UiTokens.DUR_BASE)
	_tween.tween_callback(hide)
