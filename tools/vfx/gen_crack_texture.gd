extends SceneTree
## Gera game/scenes/vfx/crack.png, a rachadura do Terremoto (F41): bordas de celulas de ruido
## celular + rachaduras radiais, com mascara radial irregular e chao queimado no centro; e
## crack_glow.png, so as fendas em laranja (emissao do Decal: le no piso escuro da arena).
## Reprodutivel (seed fixa). Uso, na raiz:
##   & $env:GODOT_PATH --headless --path game --script ../tools/vfx/gen_crack_texture.gd

const OUT: String = "res://scenes/vfx/crack.png"
const OUT_GLOW: String = "res://scenes/vfx/crack_glow.png"
const SIZE: int = 512
const SEED: int = 41
const CELL_FREQUENCY: float = 0.011
const WARP_FREQUENCY: float = 0.006
const LINE_WIDTH: float = 0.07
const SPOKES: float = 7.0
const SPOKE_WIDTH: float = 0.14
const SPOKE_WARP: float = 2.5
const MASK_START: float = 0.5
const MASK_WARP: float = 0.25
const SCORCH_RADIUS: float = 0.3
const SCORCH_ALPHA: float = 0.55
const CRACK_COLOR: Color = Color(0.06, 0.045, 0.035)
const GLOW_COLOR: Color = Color(1.0, 0.45, 0.12)


func _init() -> void:
	var cells := FastNoiseLite.new()
	cells.noise_type = FastNoiseLite.TYPE_CELLULAR
	cells.cellular_return_type = FastNoiseLite.RETURN_DISTANCE2_SUB
	cells.fractal_type = FastNoiseLite.FRACTAL_NONE
	cells.frequency = CELL_FREQUENCY
	cells.seed = SEED
	var warp := FastNoiseLite.new()
	warp.frequency = WARP_FREQUENCY
	warp.seed = SEED + 1
	var values := PackedFloat32Array()
	values.resize(SIZE * SIZE)
	var low := INF
	var high := -INF
	for y: int in SIZE:
		for x: int in SIZE:
			var v := cells.get_noise_2d(x, y)
			values[y * SIZE + x] = v
			low = minf(low, v)
			high = maxf(high, v)
	var image := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	var glow := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	for y: int in SIZE:
		for x: int in SIZE:
			var p := Vector2(x, y) / SIZE * 2.0 - Vector2.ONE
			var r := p.length()
			var w := warp.get_noise_2d(x, y)
			var edge := inverse_lerp(low, high, values[y * SIZE + x])
			var line := 1.0 - smoothstep(0.0, LINE_WIDTH, edge)
			var spoke := absf(sin(atan2(p.y, p.x) * SPOKES + w * SPOKE_WARP))
			var spokes := (1.0 - smoothstep(0.0, SPOKE_WIDTH, spoke)) * (1.0 - r)
			var mask := 1.0 - smoothstep(MASK_START, 1.0, r + w * MASK_WARP)
			var scorch := (1.0 - smoothstep(0.0, SCORCH_RADIUS, r)) * SCORCH_ALPHA
			var alpha := clampf(maxf(line, spokes) * mask + scorch, 0.0, 1.0)
			image.set_pixel(x, y, Color(CRACK_COLOR, alpha))
			glow.set_pixel(x, y, GLOW_COLOR * (maxf(line, spokes) * mask))
	var err := image.save_png(ProjectSettings.globalize_path(OUT))
	if err == OK:
		err = glow.save_png(ProjectSettings.globalize_path(OUT_GLOW))
	print("[crack] %s, %s: %s" % [OUT, OUT_GLOW, error_string(err)])
	quit(0 if err == OK else 1)
