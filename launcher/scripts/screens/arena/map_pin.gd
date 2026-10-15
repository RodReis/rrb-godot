class_name MapPin
extends BaseButton
## Pino de um ponto de interesse sobre o mapa (prototipo "Arena & Mapa"): circulo com o glifo do
## ponto, brilho do acento, anel quando escolhido ou com foco do teclado, escala 1,1 no mouse e,
## nos marcos grandes (bases e cratera), o pulso "animate-ping". O rotulo fica abaixo e so aparece
## nos marcos, no pino escolhido ou sob o mouse (dezenas de rotulos fixos cobririam o mapa).

const SIZE_BIG: float = 44.0
const SIZE_SMALL: float = 32.0
const HOVER_SCALE: float = 1.1
const GLOW_RADIUS: float = 10.0
const GLOW_ALPHA: float = 0.35
const RING_WIDTH: float = 2.0
const RING_GAP: float = 3.0
## animate-ping: o anel cresce a 2x e some em 1 s, repetindo.
const PING_SECONDS: float = 1.5
const PING_SCALE: float = 1.8
const PING_ALPHA: float = 0.6
## Pino pequeno: bg-surface-container-high/90.
const SMALL_FILL_ALPHA: float = 0.9
const LABEL_GAP: float = 2.0
## Camadas dos pinos: o escolhido fica por cima do que tem so mouse ou foco.
const Z_SELECTED: int = 3
const Z_ACTIVE: int = 2

## Identificador do ponto de interesse (ArenaMapPois.ORDER).
var poi_id: String = ""
var selected: bool = false:
	set(value):
		selected = value
		_sync_label()
		queue_redraw()

var _accent: Color = UiTokens.GOLD_BRIGHT
var _fill: Color = UiTokens.GOLD
var _big: bool = false
var _ping: float = 0.0
var _scale_tween: Tween
var _pulse: Tween
var _glyph: Label = Label.new()
var _label_box: PanelContainer = PanelContainer.new()
var _label: Label = Label.new()


func _init() -> void:
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_glyph.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_glyph)
	_label_box.theme_type_variation = &"LnAmPinLabel"
	_label_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.theme_type_variation = &"LnNumText"
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label_box.add_child(_label)
	add_child(_label_box)
	_label_box.resized.connect(_place_label)
	resized.connect(_place_label)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	focus_entered.connect(_sync_label)
	focus_exited.connect(_sync_label)
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)
	visibility_changed.connect(_on_visibility_changed)


func _draw() -> void:
	var center := size / 2.0
	var radius := minf(size.x, size.y) / 2.0
	if _big or selected:
		for step: int in 3:
			var spread := GLOW_RADIUS * float(step + 1) / 3.0
			var alpha := GLOW_ALPHA / float(step + 2)
			draw_circle(center, radius + spread, Color(_accent, alpha))
	if _ping > 0.0:
		var ring := radius * (1.0 + (PING_SCALE - 1.0) * _ping)
		draw_arc(center, ring, 0.0, TAU, 48, Color(_accent, PING_ALPHA * (1.0 - _ping)), RING_WIDTH)
	draw_circle(center, radius, _fill)
	if selected:
		draw_arc(center, radius + RING_GAP, 0.0, TAU, 48, UiTokens.GOLD_BRIGHT, RING_WIDTH)
	elif has_focus():
		draw_arc(center, radius + RING_GAP, 0.0, TAU, 48, UiTokens.TEXT, RING_WIDTH)


## [param accent_name]: gold, cyan, error ou muted (ArenaMapTexts); [param big]: marco do mapa.
func setup(id: String, glyph: String, label: String, accent_name: StringName, big: bool) -> void:
	poi_id = id
	_big = big
	var suffix := String(accent_name).capitalize()
	var colors: Array = ArenaMapTheme.ACCENTS[StringName(suffix)]
	_fill = colors[0] if big else Color(UiTokens.BG_CARD, SMALL_FILL_ALPHA)
	_accent = colors[2]
	var diameter := SIZE_BIG if big else SIZE_SMALL
	custom_minimum_size = Vector2(diameter, diameter)
	size = custom_minimum_size
	pivot_offset = size / 2.0
	focus_mode = Control.FOCUS_ALL
	tooltip_text = label
	_glyph.text = glyph
	_glyph.theme_type_variation = StringName(("LnAmPinOn%s" if big else "LnAmPin%s") % suffix)
	_label.text = label
	_sync_label()
	queue_redraw()
	if big:
		_start_pulse()


func is_big() -> bool:
	return _big


func label_visible() -> bool:
	return _label_box.visible


func _start_pulse() -> void:
	if _pulse != null:
		_pulse.kill()
	_pulse = create_tween().set_loops()
	_pulse.tween_method(_set_ping, 0.0, 1.0, PING_SECONDS)


func _set_ping(value: float) -> void:
	_ping = value
	queue_redraw()


func _sync_label() -> void:
	_label_box.visible = _big or selected or is_hovered() or has_focus()
	# O rotulo de um pino escolhido ou sob o mouse nao pode ficar atras do circulo de outro.
	z_index = Z_SELECTED if selected else (Z_ACTIVE if is_hovered() or has_focus() else 0)


## Centro abaixo do circulo; o no nao entra no layout do pai (fora do retangulo do botao).
func _place_label() -> void:
	_label_box.position = Vector2(
		(size.x - _label_box.size.x) / 2.0, size.y + LABEL_GAP + GLOW_RADIUS / 2.0
	)


## Tela escondida pela pilha (outra tela por cima): o pulso para, nao redesenha a toa.
func _on_visibility_changed() -> void:
	if _pulse == null or not _pulse.is_valid():
		return
	if is_visible_in_tree():
		_pulse.play()
	else:
		_pulse.pause()


func _on_mouse_entered() -> void:
	_scale_to(HOVER_SCALE)
	_sync_label()


func _on_mouse_exited() -> void:
	_scale_to(1.0)
	_sync_label()


func _scale_to(target: float) -> void:
	if _scale_tween != null:
		_scale_tween.kill()
	_scale_tween = create_tween()
	_scale_tween.tween_property(self, ^"scale", Vector2.ONE * target, UiTokens.DUR_FAST)
