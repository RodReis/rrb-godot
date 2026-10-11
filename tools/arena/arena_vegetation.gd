extends "arena_terrain.gd"
## Grama decorativa (F42, SPEC-042): tufos (1 draw call no MultiMesh do Vegetation) sobre o chao
## de grama da mascara do terreno e no musgo (sem terra, pedra nem rocha: fora das trilhas, das
## bases e da cratera), fora do rio, das pontes e das rochas dos bolsoes e longe do mato alto
## (regra de jogo F32: o vazio em volta da moita separa os dois na leitura). Grava
## game/scenes/arena/vegetation.tscn e a arena a instancia. So visual, sem colisao; o node
## Vegetation sai no servidor headless e com graphics.grass desligado. Posicoes por hash e ruido
## de semente fixa (cena deterministica).

const VEGETATION_OUT: String = "res://scenes/arena/vegetation.tscn"
const VEGETATION_SCRIPT: String = "res://scripts/world/vegetation.gd"
const GRASS_SHADER: String = "res://shared/shaders/grass_wind.gdshader"
## Grade com jitter (u): um candidato por celula.
const GRASS_STEP: float = 0.4
## Peso maximo de camada que nao e grama nem musgo na mascara para ainda nascer tufo.
const GRASS_MASK_MAX: float = 0.2
## Folga em volta da caixa do mato alto (u).
const TALL_GRASS_CLEAR: float = 2.0
## Moitas de grama, nao tapete: ruido (0..1) abaixo de PATCH_FROM nao tem tufo, acima de
## PATCH_FULL tem todos.
const PATCH_FREQUENCY: float = 0.09
const PATCH_FROM: float = 0.3
const PATCH_FULL: float = 0.55
const PATCH_SEED: int = 42
## Escala do tufo por instancia (min, max); a malha e do Vegetation.
const TUFT_SCALE: Vector2 = Vector2(0.7, 1.15)


## Grava a cena da grama com os tufos como dado (o MultiMesh e montado no cliente: o servidor de
## renderizacao headless nao salva buffer de MultiMesh nem malha) e a instancia na arena.
func _build_vegetation() -> void:
	var tufts := PackedVector4Array()
	for at: Vector2 in _grass_points():
		var yaw := TAU * _hash(at + Vector2(5.3, 1.7))
		var s := lerpf(TUFT_SCALE.x, TUFT_SCALE.y, _hash(at + Vector2(8.1, 3.9)))
		tufts.append(Vector4(at.x, at.y, yaw, s))
	var material := ShaderMaterial.new()
	material.shader = load(GRASS_SHADER)
	var node := MultiMeshInstance3D.new()
	node.name = "Vegetation"
	node.set_script(load(VEGETATION_SCRIPT))
	node.set(&"tufts", tufts)
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Fora do bake e das sondas: uma sonda so para a arena inteira daria luz errada.
	node.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	var packed := PackedScene.new()
	var err := packed.pack(node)
	if err == OK:
		err = ResourceSaver.save(packed, VEGETATION_OUT)
	print("[arena] %s (%d tufos) -> %s" % [VEGETATION_OUT, tufts.size(), error_string(err)])
	node.free()
	var scene := ResourceLoader.load(VEGETATION_OUT, "", ResourceLoader.CACHE_MODE_REPLACE)
	_add(_root, (scene as PackedScene).instantiate())


## Um candidato por celula da grade (com jitter), mantido se o chao for grama ou musgo, fora da
## agua, das pontes, das rochas dos bolsoes e da folga do mato alto, e dentro de uma moita do
## ruido.
func _grass_points() -> PackedVector2Array:
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.seed = PATCH_SEED
	noise.frequency = PATCH_FREQUENCY
	var areas := _tall_grass_boxes()
	var walls := _polylines("walls")
	var points := PackedVector2Array()
	var cells := ceili(ARENA_HALF * 2 / GRASS_STEP)
	for row: int in range(cells):
		for col: int in range(cells):
			var cell := Vector2(col, row) * GRASS_STEP - Vector2.ONE * ARENA_HALF
			var jitter := Vector2(_hash(cell), _hash(cell + Vector2(4.4, 9.1)))
			var p := cell + (jitter * 0.9 + Vector2.ONE * 0.05) * GRASS_STEP
			if maxf(absf(p.x), absf(p.y)) > ARENA_HALF - 0.5:
				continue
			var patch := (noise.get_noise_2dv(p) + 1.0) / 2.0
			if _hash(p + Vector2(7.7, 2.2)) > smoothstep(PATCH_FROM, PATCH_FULL, patch):
				continue
			if _splat_at(p, MOSS_CHANNEL) > GRASS_MASK_MAX:
				continue
			if _is_river(p, false) or _is_bridge(p) or _near_tall_grass(p, areas):
				continue
			if _under_rocks(p, walls) or _in_base(p):
				continue
			points.append(p)
	return points


func _under_rocks(p: Vector2, walls: Array[Array]) -> bool:
	for wall: Array in walls:
		if _polyline_distance(p, wall[0]) < wall[1] + OUTCROP_MARGIN:
			return true
	return false


## Dentro do muro em arco de uma base: a mascara so pinta pedra em z >= 15 (metade A), mas o arco
## desce ate z ~11,3.
func _in_base(p: Vector2) -> bool:
	var spawn := _flat(AXIS_A * SPAWN_S)
	var reach := BASE_ARC_RADIUS + WALL_THICKNESS
	return p.distance_to(spawn) < reach or p.distance_to(-spawn) < reach


## [transformacao para o espaco da caixa, meia extensao (x, z)] de cada moita ja montada.
func _tall_grass_boxes() -> Array[Array]:
	var boxes: Array[Array] = []
	for node: Node in _root.get_node("TallGrass").get_children():
		var area := node as Area3D
		var shape := area.get_child(0) as CollisionShape3D
		var half := (shape.shape as BoxShape3D).size / 2
		var to_local := (area.transform * shape.transform).affine_inverse()
		boxes.append([to_local, Vector2(half.x, half.z)])
	return boxes


func _near_tall_grass(p: Vector2, boxes: Array[Array]) -> bool:
	for box: Array in boxes:
		var to_local: Transform3D = box[0]
		var half: Vector2 = box[1]
		var q := to_local * Vector3(p.x, 0, p.y)
		if absf(q.x) < half.x + TALL_GRASS_CLEAR and absf(q.z) < half.y + TALL_GRASS_CLEAR:
			return true
	return false
