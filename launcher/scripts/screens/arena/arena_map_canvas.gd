class_name ArenaMapCanvas
extends Control
## Quadro do mapa (prototipo "Arena & Mapa"): o render da arena real
## (shared/assets/ui/arena_map.png),
## o brilho de varredura por cima e os pinos de cada ponto de interesse, no pixel de cada marcador
## (ArenaMapView.world_to_uv: a mesma projecao do render). So desenha e emite: o card de detalhe e
## da tela. Desvio do prototipo: a imagem nao da zoom no hover (o zoom desalinharia os pinos).

signal poi_selected(id: String)

const IMAGE_PATH: String = "res://shared/assets/ui/arena_map.png"
## Varredura: degrade vertical transparente -> secondary/5 -> transparente, a 40 % (opacity-40).
const SCAN_ALPHA: float = 0.02
const LEGEND_INSET: float = 12.0

var _image: TextureRect = TextureRect.new()
var _scanner: TextureRect = TextureRect.new()
var _pin_layer: Control = Control.new()
var _legend: PanelContainer = PanelContainer.new()
var _pins: Array[MapPin] = []
var _grounds: Dictionary[MapPin, Vector2] = {}


func _init() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_PASS
	_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_image.stretch_mode = TextureRect.STRETCH_SCALE
	_image.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_image)
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	gradient.colors = PackedColorArray(
		[Color(UiTokens.CYAN, 0.0), Color(UiTokens.CYAN, SCAN_ALPHA), Color(UiTokens.CYAN, 0.0)]
	)
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_from = Vector2.ZERO
	texture.fill_to = Vector2(0.0, 1.0)
	_scanner.texture = texture
	_scanner.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_scanner.stretch_mode = TextureRect.STRETCH_SCALE
	_scanner.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_scanner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_scanner)
	_pin_layer.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_pin_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_pin_layer)
	_legend.theme_type_variation = &"LnAmPinLabel"
	_legend.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_legend.set_anchors_and_offsets_preset(PRESET_BOTTOM_LEFT)
	_legend.grow_vertical = GROW_DIRECTION_BEGIN
	_legend.position += Vector2(LEGEND_INSET, -LEGEND_INSET)
	add_child(_legend)
	resized.connect(_reposition)


## Monta imagem e pinos; false se a imagem nao carregou (a tela mostra o erro).
func bind(data: ArenaMapData, rules: MatchRules) -> bool:
	var texture := load(IMAGE_PATH) as Texture2D
	if texture == null:
		return false
	_image.texture = texture
	_build_legend()
	for poi: Dictionary in data.pois:
		var id: String = poi["id"]
		var style: Array = ArenaMapTexts.PIN_STYLE[id]
		for group: Dictionary in poi["groups"]:
			var pin := MapPin.new()
			pin.setup(id, style[0], ArenaMapTexts.pin_label(id, rules), style[2], style[3])
			pin.pressed.connect(poi_selected.emit.bind(id))
			_pin_layer.add_child(pin)
			_pins.append(pin)
			_grounds[pin] = group["anchor"]
	_reposition()
	return true


func pins() -> Array[MapPin]:
	return _pins


## Pinos do ponto de interesse.
func pins_of(id: String) -> Array[MapPin]:
	var found: Array[MapPin] = []
	for pin: MapPin in _pins:
		if pin.poi_id == id:
			found.append(pin)
	return found


## Marca os pinos do ponto escolhido (e desmarca o resto).
func select(id: String) -> void:
	for pin: MapPin in _pins:
		pin.selected = pin.poi_id == id


## Centro do pino em fracao da imagem (u, v); o teste confere contra ArenaMapView.
func uv_of(pin: MapPin) -> Vector2:
	return ArenaMapView.world_to_uv(_grounds[pin])


func _reposition() -> void:
	for pin: MapPin in _pins:
		pin.position = uv_of(pin) * size - pin.size / 2.0


## Indicador do canto inferior esquerdo: o que a imagem e (render estatico, de dia).
func _build_legend() -> void:
	for child: Node in _legend.get_children():
		child.queue_free()
	var row := HBoxContainer.new()
	row.theme_type_variation = &"LnHGapXs"
	var icon := Label.new()
	icon.theme_type_variation = &"LnIconSmGold"
	icon.text = UiIcons.TUNE
	row.add_child(icon)
	var text := Label.new()
	text.theme_type_variation = &"LnNum"
	text.text = tr("RENDER ESTÁTICO DA ARENA • DIA")
	row.add_child(text)
	_legend.add_child(row)
