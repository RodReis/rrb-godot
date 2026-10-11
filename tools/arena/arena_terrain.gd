extends "arena_layout.gd"
## Terreno e selva da Ilha (F40, PI 2026-10-11: realista e sombrio, bolsoes de selva). Le os
## bolsoes e as trilhas de tools/arena/jungle.json, pinta a mascara do terreno (splat em espaco de
## mundo: R terra, G pedra, B musgo, A rocha), grava os materiais PBR do cenario e monta o visual
## dos bolsoes (rochas + pinheiros). A colisao dos bolsoes e as provas ficam no build_arena.gd.

const JUNGLE_FILE: String = "jungle.json"
const SPLAT_PATH: String = "res://shared/assets/rrb/arena/terrain_splat.png"
const SPLAT_SIZE: int = 512
## Retangulo (x0, z0, lado) do mundo coberto pela mascara: a ilha inteira com os bastioes.
const SPLAT_ORIGIN: Vector2 = Vector2(-50, -50)
const SPLAT_EXTENT: float = 100.0
## Borda macia das manchas da mascara (u); o shader ainda quebra a borda com ruido.
const SPLAT_SOFT: float = 0.9

const TEXTURES: String = "res://shared/assets/ambientcg/%s_%s.jpg"
const TERRAIN_LAYERS: Array[String] = ["grass", "moss", "dirt", "paving", "rock"]
const TERRAIN_SHADER: String = "res://shared/shaders/terrain_splat.gdshader"
const TRIPLANAR_SHADER: String = "res://shared/shaders/triplanar_pbr.gdshader"
const ATLAS: String = "res://shared/assets/kaykit/medieval_hexagon/hexagons_medieval.png"
## Materiais gerados aqui e ligados aos .glb pelo .import (use_external do "kaykit_atlas").
const TERRAIN_MATERIAL: String = MATERIALS + "terrain.tres"
const ROCK_MATERIAL: String = MATERIALS + "rock_moss.tres"
const STONE_MATERIAL: String = MATERIALS + "castle_stone.tres"
const PINE_MATERIAL: String = MATERIALS + "pine_foliage.tres"
const TALL_GRASS_MATERIAL: String = MATERIALS + "tall_grass.tres"

# Mascara: o que vira cada camada (metade A; a B e a rotacao).
const CLEARING_DIRT: float = 4.5
const CENTER_CLEARING: float = 3.5
const BANK_MOSS: float = 1.8
const WALL_MOSS: float = 1.4
const BORDER_MOSS: float = 2.5
const CRATER_ROCK: float = 7.6
## Agua visual (art/arena/build_island.py): mais estreita que a colisao do rio.
const WATER_HALF_VISUAL: float = 1.7
const LAGOON_WATER_VISUAL: float = 4.7
const BASE_ARC_RADIUS: float = 12.7

# Visual dos bolsoes: rochas a cada ROCK_STEP ao longo da polilinha, pinheiros por cima.
const OUTCROPS: Array[String] = ["rock_outcrop_a", "rock_outcrop_b", "rock_outcrop_c"]
## Raio da pegada de cada rocha com escala 1 (u): a escala cobre a meia largura + folga.
const OUTCROP_RADIUS: float = 1.0
const OUTCROP_MARGIN: float = 0.35
const ROCK_STEP: float = 1.6
const PINE_STEP: float = 2.1
const PINE_SCALE: Vector2 = Vector2(0.85, 1.35)

# Tom realista e sombrio (verificacao visual do PI).
const TERRAIN_BRIGHTNESS: float = 0.82
const TERRAIN_SATURATION: float = 0.85
const GRASS_TINT: Color = Color(0.78, 0.84, 0.72)
const DIRT_TINT: Color = Color(0.72, 0.66, 0.6)
const ROCK_TINT: Color = Color(0.7, 0.72, 0.75)
const MOSS_TINT: Color = Color(0.5, 0.62, 0.4)
const PAVING_TINT: Color = Color(0.72, 0.72, 0.74)

var _jungle: Dictionary = {}

# --- dados da selva ----------------------------------------------------------------------


## Le e valida tools/arena/jungle.json; sai do builder com erro se faltar campo.
func _load_jungle() -> bool:
	var path := (get_script() as Script).resource_path.get_base_dir().path_join(JUNGLE_FILE)
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		push_error("[arena] %s invalido" % path)
		return false
	for key: String in ["walls", "trails", "clearings"]:
		if not (parsed as Dictionary).has(key):
			push_error("[arena] %s sem '%s'" % [path, key])
			return false
	_jungle = parsed
	return true


## Polilinhas [pontos, meia largura] de [param key] ("walls" ou "trails") nas duas metades.
func _polylines(key: String) -> Array[Array]:
	var out: Array[Array] = []
	for item: Dictionary in _jungle[key]:
		var points := PackedVector2Array()
		for p: Array in item["points"]:
			points.append(Vector2(p[0], p[1]))
		var half: float = item["half_width"]
		out.append([points, half])
		var rotated := PackedVector2Array()
		for p: Vector2 in points:
			rotated.append(-p)
		out.append([rotated, half])
	return out


func _clearings() -> Array[Vector2]:
	var out: Array[Vector2] = []
	for item: Dictionary in _jungle["clearings"]:
		var c := Vector2(item["center"][0], item["center"][1])
		out.append_array([c, -c])
	return out


static func _segment_distance(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var t := (
		0.0 if ab.length_squared() == 0.0 else clampf((p - a).dot(ab) / ab.length_squared(), 0, 1)
	)
	return p.distance_to(a + ab * t)


static func _polyline_distance(p: Vector2, points: PackedVector2Array) -> float:
	var d := INF
	for i: int in range(points.size() - 1):
		d = minf(d, _segment_distance(p, points[i], points[i + 1]))
	return d


# --- mascara do terreno ------------------------------------------------------------------


## Pinta e grava a mascara; cada camada e um canal em float, convertido para RGBA8 no fim.
func _paint_terrain() -> void:
	var channels: Array[PackedFloat32Array] = []
	for c: int in range(4):
		var data := PackedFloat32Array()
		data.resize(SPLAT_SIZE * SPLAT_SIZE)
		channels.append(data)
	var dirt := channels[0]
	var paving := channels[1]
	var moss := channels[2]
	var rock := channels[3]
	_stamp_river_banks(moss)
	for wall: Array in _polylines("walls"):
		_stamp_polyline(moss, wall[0], wall[1] + WALL_MOSS)
	_stamp_border(moss)
	for trail: Array in _polylines("trails"):
		_stamp_polyline(dirt, trail[0], trail[1])
	for c: Vector2 in _clearings():
		_stamp_disc(dirt, c, CLEARING_DIRT)
	for az: float in FIELD_AZIMUTHS:
		_stamp_disc(dirt, _flat(_polar(az, FIELD_RADIUS)), CENTER_CLEARING)
	_stamp_bases(paving)
	_stamp_disc(rock, Vector2.ZERO, CRATER_ROCK)
	var bytes := PackedByteArray()
	bytes.resize(SPLAT_SIZE * SPLAT_SIZE * 4)
	for i: int in range(SPLAT_SIZE * SPLAT_SIZE):
		for c: int in range(4):
			bytes[i * 4 + c] = clampi(roundi(channels[c][i] * 255.0), 0, 255)
	var image := Image.create_from_data(SPLAT_SIZE, SPLAT_SIZE, false, Image.FORMAT_RGBA8, bytes)
	var err := image.save_png(ProjectSettings.globalize_path(SPLAT_PATH))
	print("[arena] mascara do terreno %s -> %s" % [SPLAT_PATH, error_string(err)])


## Pixel (coluna, linha) -> ponto (x, z) do mundo no centro do pixel.
func _pixel_world(col: int, row: int) -> Vector2:
	return SPLAT_ORIGIN + (Vector2(col, row) + Vector2(0.5, 0.5)) * SPLAT_EXTENT / SPLAT_SIZE


## Percorre os pixels do retangulo (x, z) [param area] chamando [param weight] por ponto e
## guardando o maior peso no canal.
func _stamp_area(channel: PackedFloat32Array, area: Rect2, weight: Callable) -> void:
	var scale := SPLAT_SIZE / SPLAT_EXTENT
	var c0 := clampi(floori((area.position.x - SPLAT_ORIGIN.x) * scale), 0, SPLAT_SIZE - 1)
	var c1 := clampi(ceili((area.end.x - SPLAT_ORIGIN.x) * scale), 0, SPLAT_SIZE - 1)
	var r0 := clampi(floori((area.position.y - SPLAT_ORIGIN.y) * scale), 0, SPLAT_SIZE - 1)
	var r1 := clampi(ceili((area.end.y - SPLAT_ORIGIN.y) * scale), 0, SPLAT_SIZE - 1)
	for row: int in range(r0, r1 + 1):
		for col: int in range(c0, c1 + 1):
			var w: float = weight.call(_pixel_world(col, row))
			var i := row * SPLAT_SIZE + col
			if w > channel[i]:
				channel[i] = w


static func _soft(distance: float) -> float:
	return 1.0 - smoothstep(-SPLAT_SOFT * 0.5, SPLAT_SOFT, distance)


func _stamp_polyline(channel: PackedFloat32Array, points: PackedVector2Array, half: float) -> void:
	var area := Rect2(points[0], Vector2.ZERO)
	for p: Vector2 in points:
		area = area.expand(p)
	area = area.grow(half + SPLAT_SOFT)
	_stamp_area(
		channel, area, func(p: Vector2) -> float: return _soft(_polyline_distance(p, points) - half)
	)


func _stamp_disc(channel: PackedFloat32Array, center: Vector2, radius: float) -> void:
	var area := Rect2(center, Vector2.ZERO).grow(radius + SPLAT_SOFT)
	_stamp_area(
		channel, area, func(p: Vector2) -> float: return _soft(p.distance_to(center) - radius)
	)


## Musgo na margem da agua visual: anel, bracos e lagoas (a terra da trilha passa por cima).
func _stamp_river_banks(channel: PackedFloat32Array) -> void:
	var reach := RING_OUT + 2.0 + BANK_MOSS
	var area := Rect2(-reach, -reach, reach * 2, reach * 2)
	_stamp_area(
		channel,
		area,
		func(p: Vector2) -> float: return _bank(absf(p.length() - RING_MID) - WATER_HALF_VISUAL)
	)
	for flip: float in [1.0, -1.0]:
		var lagoon := LAGOON_A * flip
		var lagoon_area := Rect2(lagoon, Vector2.ZERO).grow(LAGOON_WATER_VISUAL + BANK_MOSS + 1)
		_stamp_area(
			channel,
			lagoon_area,
			func(p: Vector2) -> float: return _bank(p.distance_to(lagoon) - LAGOON_WATER_VISUAL)
		)
		var arm_area := Rect2(ARM_CENTER_A * flip, Vector2.ZERO).grow(ARM_RADIUS + RIVER_HALF + 3)
		_stamp_area(
			channel,
			arm_area,
			func(p: Vector2) -> float:
				var q := p * flip
				if q.length() <= RING_IN or not _in_arm_fan(q):
					return 0.0
				return _bank(absf(q.distance_to(ARM_CENTER_A) - ARM_RADIUS) - WATER_HALF_VISUAL)
		)


func _bank(distance: float) -> float:
	return 0.0 if distance < -0.5 else _soft(distance - BANK_MOSS)


## Dentro do leque angular do braco NO (sem olhar a distancia ao eixo).
func _in_arm_fan(p: Vector2) -> bool:
	var v := p - ARM_CENTER_A
	var angles := _arm_angles()
	var sweep := angles.y - angles.x
	var t := wrapf(v.angle() - angles.x, -PI, PI)
	return t * signf(sweep) >= 0.0 and absf(t) <= absf(sweep)


## Faixa de musgo ao longo da borda quadrada, por dentro.
func _stamp_border(channel: PackedFloat32Array) -> void:
	var reach := ARENA_HALF + 2.0
	var area := Rect2(-reach, -reach, reach * 2, reach * 2)
	_stamp_area(
		channel,
		area,
		func(p: Vector2) -> float:
			return _soft(ARENA_HALF - maxf(absf(p.x), absf(p.y)) - BORDER_MOSS)
	)


## Pedra nas bases (atras do arco ate os muros de fechamento) e nos bastioes do castelo.
func _stamp_bases(channel: PackedFloat32Array) -> void:
	for flip: float in [1.0, -1.0]:
		var corner := Vector2(-ARENA_HALF, ARENA_HALF) * flip
		var area := Rect2(corner, Vector2.ZERO).expand(Vector2(-15, 15) * flip).grow(12)
		_stamp_area(
			channel,
			area,
			func(p: Vector2) -> float:
				var q := p * flip
				if q.x > -15.0 or q.y < 15.0:
					return 0.0  # fora do canto: os muros de fechamento escondem a quina
				var s := q.dot(_flat(AXIS_A))
				var spawn := _flat(AXIS_A * SPAWN_S)
				return maxf(_soft(q.distance_to(spawn) - BASE_ARC_RADIUS), _soft(SPAWN_S - s))
		)


# --- materiais ----------------------------------------------------------------------------


func _save_materials() -> void:
	_save(_terrain_material(), TERRAIN_MATERIAL)
	_save(_triplanar("rock", ROCK_TINT, 0.15, 0.62, 0.0), ROCK_MATERIAL)
	_save(_triplanar("bricks", Color(0.78, 0.78, 0.8), 0.45, 0.78, 0.65), STONE_MATERIAL)
	# Folhagem: detalhe da grama, cor (tronco marrom, galho verde-escuro) pela celula do atlas.
	_save(_triplanar("grass", Color(0.55, 0.6, 0.5), 0.9, 1.0, 1.0), PINE_MATERIAL)
	# Mato alto: mesma receita, mais claro que o pinheiro (leitura a distancia da camera).
	_save(_triplanar("grass", Color(0.85, 0.88, 0.62), 0.9, 1.0, 1.0), TALL_GRASS_MATERIAL)


func _save(material: Material, path: String) -> void:
	var err := ResourceSaver.save(material, path)
	print("[arena] material %s -> %s" % [path, error_string(err)])


func _terrain_material() -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = load(TERRAIN_SHADER)
	for layer: String in TERRAIN_LAYERS:
		m.set_shader_parameter("%s_albedo" % layer, _texture(TEXTURES % [layer, "albedo"]))
		m.set_shader_parameter("%s_normal" % layer, _texture(TEXTURES % [layer, "normal"]))
		m.set_shader_parameter("%s_rough" % layer, _texture(TEXTURES % [layer, "rough"]))
	m.set_shader_parameter("splat_map", _texture(SPLAT_PATH))
	m.set_shader_parameter(
		"splat_rect", Vector4(SPLAT_ORIGIN.x, SPLAT_ORIGIN.y, SPLAT_EXTENT, SPLAT_EXTENT)
	)
	m.set_shader_parameter("macro_noise", _noise())
	m.set_shader_parameter("grass_tint", GRASS_TINT)
	m.set_shader_parameter("dirt_tint", DIRT_TINT)
	m.set_shader_parameter("rock_tint", ROCK_TINT)
	m.set_shader_parameter("moss_tint", MOSS_TINT)
	m.set_shader_parameter("paving_tint", PAVING_TINT)
	m.set_shader_parameter("brightness", TERRAIN_BRIGHTNESS)
	m.set_shader_parameter("saturation", TERRAIN_SATURATION)
	return m


## Material triplanar (castelo, rochas): textura [param base], musgo a partir de [param moss_from]
## de normal.y (1.0 = sem musgo) e [param atlas_tint] da cor da celula do atlas KayKit.
func _triplanar(
	base: String, tint: Color, tile: float, moss_from: float, atlas_tint: float
) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = load(TRIPLANAR_SHADER)
	m.set_shader_parameter("base_albedo", _texture(TEXTURES % [base, "albedo"]))
	m.set_shader_parameter("base_normal", _texture(TEXTURES % [base, "normal"]))
	m.set_shader_parameter("base_rough", _texture(TEXTURES % [base, "rough"]))
	m.set_shader_parameter("base_tile", tile)
	m.set_shader_parameter("base_tint", tint)
	m.set_shader_parameter("moss_albedo", _texture(TEXTURES % ["moss", "albedo"]))
	m.set_shader_parameter("moss_normal", _texture(TEXTURES % ["moss", "normal"]))
	m.set_shader_parameter("moss_tint", MOSS_TINT)
	m.set_shader_parameter("moss_from", moss_from)
	m.set_shader_parameter("moss_amount", 0.8 if moss_from < 1.0 else 0.0)
	m.set_shader_parameter("atlas", _texture(ATLAS))
	m.set_shader_parameter("atlas_tint", atlas_tint)
	m.set_shader_parameter("brightness", TERRAIN_BRIGHTNESS)
	m.set_shader_parameter("saturation", TERRAIN_SATURATION)
	return m


## Textura importada; na primeira rodada (mascara recem-gravada, ainda sem import) devolve uma
## referencia vazia com o caminho, que o .tres salva como recurso externo.
func _texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path)
	var placeholder := CompressedTexture2D.new()
	placeholder.take_over_path(path)
	return placeholder


func _noise() -> NoiseTexture2D:
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.012
	noise.fractal_octaves = 4
	var texture := NoiseTexture2D.new()
	texture.width = 256
	texture.height = 256
	texture.seamless = true
	texture.generate_mipmaps = true
	texture.noise = noise
	return texture


# --- visual dos bolsoes --------------------------------------------------------------------


## Rochas ao longo de cada bolsao (cobrem a colisao: pegada >= meia largura + folga) e
## pinheiros no meio delas. Variacao por hash da posicao, sem RNG (cena deterministica).
func _build_jungle_visuals() -> void:
	var group := _group("Jungle")
	var index := 0
	for wall: Array in _polylines("walls"):
		var points: PackedVector2Array = wall[0]
		var half: float = wall[1]
		var scale := (half + OUTCROP_MARGIN) / OUTCROP_RADIUS
		for at: Vector2 in _along(points, ROCK_STEP):
			var h := _hash(at)
			var model: String = OUTCROPS[int(h * OUTCROPS.size()) % OUTCROPS.size()]
			var rock := _asset(group, RRB_ARENA + model + ".glb", "Rock%d" % index)
			var s := scale * (1.0 + 0.25 * _hash(at + Vector2(3.1, 7.7)))
			var basis := Basis(Vector3.UP, TAU * h).scaled(Vector3(s, s * (0.8 + 0.5 * h), s))
			rock.transform = Transform3D(basis, Vector3(at.x, 0, at.y))
			index += 1
		for at: Vector2 in _along(points, PINE_STEP):
			var h := _hash(at + Vector2(11.0, 5.0))
			var offset := Vector2(h - 0.5, _hash(at + Vector2(2.0, 9.0)) - 0.5) * half
			var pine := _asset(group, RRB_ARENA + "pine_dark.glb", "Pine%d" % index)
			var s := lerpf(PINE_SCALE.x, PINE_SCALE.y, h)
			var spot := at + offset
			pine.transform = Transform3D(
				Basis(Vector3.UP, TAU * h).scaled(Vector3.ONE * s), Vector3(spot.x, 0, spot.y)
			)
			index += 1


## Pontos a cada [param step] ao longo da polilinha (inclui as pontas).
static func _along(points: PackedVector2Array, step: float) -> PackedVector2Array:
	var out := PackedVector2Array([points[0]])
	for i: int in range(points.size() - 1):
		var a := points[i]
		var b := points[i + 1]
		var n := maxi(1, ceili(a.distance_to(b) / step))
		for k: int in range(1, n + 1):
			out.append(a.lerp(b, float(k) / n))
	return out


static func _hash(p: Vector2) -> float:
	return fposmod(sin(p.x * 12.9898 + p.y * 78.233) * 43758.5453, 1.0)
