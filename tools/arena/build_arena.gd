extends SceneTree
## Gera game/scenes/arena/ilha_arcana.tscn — Ilha Flutuante Arcana (SPEC-044 + arte do F40).
## Ferramenta de autoria: as medidas da spec vivem aqui; o jogo so le a cena gerada ("edite o
## builder, nao a cena"). Simetria por espelho em x: tudo da metade A em (x, z) vale para a B
## em (-x, z). Uso (na raiz do repo):
##   godot --headless --path game -s <repo>/tools/arena/build_arena.gd
## Sai com 1 se o rio nao separar as metades sem as pontes, ou se as pontes nao ligarem.
## Azimute: graus anti-horarios a partir do norte (-Z), vistos de cima (N 0, O 90, S 180, L 270).
## Colisao toda por codigo (box do chao, prismas do rio, cilindros, caixas); os .glb do Blender
## (art/arena/build_island.py) sao so visual e cobrem a colisao, nunca menores.

const OUT: String = "res://scenes/arena/ilha_arcana.tscn"
const RRB_ARENA: String = "res://shared/assets/rrb/arena/"
const GATE_SCENE: String = "res://scenes/world/gate.tscn"
const FOUNTAIN_SCENE: String = "res://scenes/world/fountain.tscn"
const MATERIALS: String = "res://shared/resources/materials/"
const SKY_MATERIAL: String = MATERIALS + "abyss_sky.tres"
const AMBIENCE_SCRIPT: String = "res://scripts/world/arena_ambience.gd"

# Escala (SPEC-044 §1).
const ARENA_RADIUS: float = 35.0

# Rio (SPEC-044 §2): coroa 14-18 u + canal N-S (|x| <= 2 u, r > 18 u). Colisao em setores
# poligonais de 2,5 graus (erro de corda < 1 cm), recortados pela borda reta das 4 pontes.
const RING_IN: float = 14.0
const RING_OUT: float = 18.0
const CHANNEL_HALF: float = 2.0
const CHANNEL_END: float = 38.0
const RIVER_SECTOR_DEG: float = 2.5
const RIVER_HEIGHT: float = 2.0
## Meia largura util das pontes (largura efetiva 5 u; nominal 4 u).
const BRIDGE_HALF: float = 2.5
const BRIDGE_CENTER: float = 16.0
const BRIDGE_AZIMUTHS: Array[float] = [45.0, 135.0, 225.0, 315.0]
## Pontes da metade A (NO e SO); as da B sao o espelho.
const BRIDGE_AZIMUTHS_A: Array[float] = [45.0, 135.0]

# Cratera (SPEC-044 §2): 8 pilares no raio 6 u, entradas de 4 u alinhadas as pontes.
const CRATER_RADIUS: float = 6.0
const PILLAR_RADIUS: float = 1.4
const PILLAR_HEIGHT: float = 3.0
## Angulo entre o centro de uma entrada e o pilar vizinho: 12 sin(a) = 4 + 2 x 1,4.
const PILLAR_OFFSET_DEG: float = 34.52

# Base A em coordenadas locais: s ao longo de centro -> spawn A (-24, -24); l para a esquerda
# de quem esta no spawn olhando o centro. A base B e o espelho em x.
const AXIS_A: Vector3 = Vector3(-0.70710678, 0, -0.70710678)
const LATERAL: Vector3 = Vector3(0.70710678, 0, -0.70710678)
const SPAWN_S: float = 33.941
const GATE_S: float = 21.213
const GATE_HALF: float = 2.5
const ARC_STEP_DEG: float = 8.0
const BASE_WALLS: Array[Array] = [
	[Vector2(29, -2), Vector2(29, 2)],
	[Vector2(27.5, 6), Vector2(27.5, 10)],
	[Vector2(27.5, -6), Vector2(27.5, -10)],
]
const BASE_T1: Array[Vector2] = [
	Vector2(31, 6), Vector2(31, -6), Vector2(26.5, 4.5), Vector2(26.5, -4.5)
]
const BASE_T2: Vector2 = Vector2(25.2, 0)
const BASE_CHESTS: Array[Vector2] = [
	Vector2(29.5, 8.5),
	Vector2(29.5, -8.5),
	Vector2(33, 9),
	Vector2(33, -9),
	Vector2(24.5, 7.5),
	Vector2(24.5, -7.5),
]
## Fonte no canto esquerdo da base (#74), em (s, l); a da B e o espelho.
const FOUNTAIN_LOCAL: Vector2 = Vector2(32, 11)
## Torres do castelo: ao lado do portao (l) e onde o muro em arco encontra a borda.
const GATE_TOWER_L: float = 4.0

# Campos laterais (F36 reposicionado pela SPEC-044 §3): O e SO na metade A, em (x, z) do mundo;
# o conteudo fica em volta do centro do campo.
const SIDE_FIELDS: Array[Vector2] = [Vector2(-26, 0), Vector2(-16, 24)]
const SIDE_T1_OFFSETS: Array[Vector2] = [Vector2(-2.5, -1.5), Vector2(2.5, -1.5)]
const SIDE_T2_OFFSET: Vector2 = Vector2(0, 1.5)
const SIDE_CHEST_OFFSETS: Array[Vector2] = [Vector2(-3, 2.5), Vector2(3, 2.5)]

# Patio de cada ponte da metade A (s radial, l lateral da ponte): moita do lado de fora e rocha
# do outro lado, fora da faixa util (|l| > 2,5) e do muro em arco.
const YARD_GRASS_LOCAL: Vector2 = Vector2(19.5, 4.6)
const YARD_ROCK_LOCAL: Vector2 = Vector2(19.5, -4.6)
const YARD_GRASS_SIZE: Vector2 = Vector2(4, 4)

# Anel central (azimute, raio): campos em 0/180 sobre o eixo de espelho; raros em 90/270.
const FIELD_AZIMUTHS: Array[float] = [0.0, 180.0]
const FIELD_RADIUS: float = 10.0
const FIELD_SPREAD_DEG: float = 15.0
const FIELD_CHEST_RADIUS: float = 12.5
const LATERAL_CHESTS: Array[Vector2] = [Vector2(90, 8), Vector2(270, 8)]
const CENTER_ROCKS: Array[Vector2] = [
	Vector2(25, 8.5), Vector2(335, 8.5), Vector2(155, 8.5), Vector2(205, 8.5)
]
const CENTER_GRASS: Array[Vector2] = [Vector2(90, 12), Vector2(270, 12)]
const CENTER_GRASS_SIZE: Vector2 = Vector2(4, 3)

# Bloqueios.
const WALL_HEIGHT: float = 2.5
const WALL_THICKNESS: float = 0.8
const ROCK_RADIUS: float = 1.3
const BORDER_SEGMENTS: int = 72
const BORDER_THICKNESS: float = 2.0
const BORDER_HEIGHT: float = 4.0
const GRASS_HEIGHT: float = 1.2

# Enfeite (F40), metade A em (azimute, raio) na borda da ilha (fora da area jogavel, sem
# colisao); a B e o espelho. Ilhotas de fundo em (x, y, z) do mundo, escala.
const RIM_RADIUS: float = 36.3
const RIM_PINES_A: Array[float] = [12.0, 28.0, 58.0, 72.0, 86.0, 104.0, 118.0, 140.0, 156.0, 170.0]
const RIM_CRYSTALS_A: Array[Vector2] = [Vector2(66, 1), Vector2(126, 0)]
const RIM_BARRICADES_A: Array[float] = [20.0, 96.0, 150.0]
const RIM_WATCHTOWER_A: float = 92.0
const RIM_BALLISTA_A: float = 148.0
const ISLETS: Array[Array] = [
	["islet_a", Vector3(-60, -9, -30), 1.0],
	["islet_b", Vector3(64, -12, 12), 1.0],
	["islet_c", Vector3(8, -14, 68), 1.0],
	["islet_a", Vector3(-50, -16, 54), 0.7],
	["islet_c", Vector3(52, -10, -52), 0.8],
]
const CRYSTAL_MATERIALS: Array[String] = ["magenta", "cyan", "green"]

# Ambientacao (cliente): luzes e particulas.
const MAGMA_LIGHT_RANGE: float = 12.0
const TORCH_LIGHT_RANGE: float = 6.0
const CRYSTAL_LIGHT_RANGE: float = 7.0
const EMBERS_AMOUNT: int = 60
const WATERFALL_AMOUNT: int = 140

var _root: Node3D
var _scenes: Dictionary = {}
var _crystal_count: int = 0


func _initialize() -> void:
	_root = Node3D.new()
	_root.name = "Arena"
	if not _river_separates():
		quit(1)
		return
	_build_environment()
	_build_floor()
	_build_river()
	_build_crater()
	_build_border()
	var walls := _body("Walls", GateRules.LAYER_WORLD)
	for flip: float in [1.0, -1.0]:
		_build_base(walls, flip)
		_build_yards(walls, flip)
		_build_rim_decor(flip)
	_build_center(walls)
	_build_islets()
	_build_ambience()
	var packed := PackedScene.new()
	var err := packed.pack(_root)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT.get_base_dir()))
	if err == OK:
		err = ResourceSaver.save(packed, OUT)
	print("[arena] %s -> %s" % [OUT, error_string(err)])
	_root.free()
	quit(0 if err == OK else 1)


# --- rio: predicados e prova de separacao -------------------------------------------------


func _is_bridge(p: Vector2) -> bool:
	for azimuth: float in BRIDGE_AZIMUTHS:
		var axis := _flat(_polar(azimuth, 1.0))
		var s := p.dot(axis)
		var l := absf(p.dot(Vector2(-axis.y, axis.x)))
		if s > RING_IN - 1.0 and s < RING_OUT + 1.0 and l <= BRIDGE_HALF:
			return true
	return false


func _is_river(p: Vector2, with_bridges: bool) -> bool:
	var r := p.length()
	if r <= RING_IN:
		return false
	var on_channel := absf(p.x) <= CHANNEL_HALF
	if r > RING_OUT and not on_channel:
		return false
	return not (with_bridges and _is_bridge(p))


## Flood fill numa grade de 1 u pelas celulas andaveis: sem pontes, o spawn A nao alcanca o
## centro nem o spawn B; com pontes, alcanca os dois.
func _river_separates() -> bool:
	var spawn_a := _flat(AXIS_A * SPAWN_S)
	var spawn_b := Vector2(-spawn_a.x, spawn_a.y)
	var without := _reachable(spawn_a, false)
	var linked := _reachable(spawn_a, true)
	var center := Vector2i.ZERO
	var b := Vector2i(roundi(spawn_b.x), roundi(spawn_b.y))
	var ok := (
		not without.has(center) and not without.has(b) and linked.has(center) and linked.has(b)
	)
	print("[arena] rio separa sem pontes e liga com pontes: %s" % ok)
	return ok


func _reachable(from: Vector2, with_bridges: bool) -> Dictionary:
	var seen: Dictionary = {}
	var queue: Array[Vector2i] = [Vector2i(roundi(from.x), roundi(from.y))]
	while not queue.is_empty():
		var key: Vector2i = queue.pop_back()
		if seen.has(key):
			continue
		var p := Vector2(key)
		if _is_river(p, with_bridges) or p.length() > ARENA_RADIUS:
			continue
		seen[key] = true
		for step: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			if not seen.has(key + step):
				queue.append(key + step)
	return seen


# --- ambiente, chao, rio, cratera, borda ---------------------------------------------------


func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	sky.sky_material = load(SKY_MATERIAL)
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.38, 0.4, 0.55)
	env.ambient_light_energy = 0.7
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.05
	env.ssao_enabled = true
	env.ssao_radius = 1.8
	env.ssao_intensity = 2.0
	env.glow_enabled = true
	env.glow_intensity = 0.7
	env.glow_bloom = 0.08
	env.glow_hdr_threshold = 1.1
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	var world := WorldEnvironment.new()
	world.name = "WorldEnvironment"
	world.environment = env
	_add(_root, world)


func _build_floor() -> void:
	var floor_body := _body("Floor", GateRules.LAYER_WORLD)
	var box := BoxShape3D.new()
	box.size = Vector3(ARENA_RADIUS * 2.2, 1, ARENA_RADIUS * 2.2)
	_shape(floor_body, box, Vector3(0, -0.5, 0))
	var island := _group("Island")
	_asset(island, RRB_ARENA + "island_chassis.glb", "Chassis")
	_asset(island, RRB_ARENA + "river_mana.glb", "RiverMana")
	_asset(island, RRB_ARENA + "lava_lake.glb", "LavaLake")


## Colisao do rio: setores da coroa e caixas do canal, cada setor recortado pelas pontes.
func _build_river() -> void:
	var river := _body("River", GateRules.LAYER_RIVER)
	var sectors := int(360.0 / RIVER_SECTOR_DEG)
	for i: int in range(sectors):
		var a0 := deg_to_rad(RIVER_SECTOR_DEG * i)
		var a1 := deg_to_rad(RIVER_SECTOR_DEG * (i + 1))
		var polygon: PackedVector2Array = [
			_ring_point(a0, RING_IN), _ring_point(a1, RING_IN),
			_ring_point(a1, RING_OUT), _ring_point(a0, RING_OUT),
		]
		for azimuth: float in BRIDGE_AZIMUTHS:
			polygon = _clip_bridge(polygon, azimuth)
			if polygon.size() < 3:
				break
		if polygon.size() >= 3:
			_shape(river, _prism(polygon), Vector3.ZERO)
	var channel := BoxShape3D.new()
	channel.size = Vector3(CHANNEL_HALF * 2, RIVER_HEIGHT, CHANNEL_END - RING_OUT)
	for sign: float in [-1.0, 1.0]:
		_shape(river, channel, Vector3(0, 0, sign * (RING_OUT + CHANNEL_END) / 2))
	var bridges := _group("Bridges")
	for azimuth: float in BRIDGE_AZIMUTHS:
		var axis := _polar(azimuth, 1.0)
		var bridge := _asset(bridges, RRB_ARENA + "bridge_stone.glb", "Bridge%d" % int(azimuth))
		bridge.transform = Transform3D(_tangent_basis(Vector3(-axis.z, 0, axis.x)), axis * BRIDGE_CENTER)


func _ring_point(angle: float, r: float) -> Vector2:
	# Angulo em radianos no plano (x, z); corda do setor coberta por uma folga minima no raio.
	return Vector2(cos(angle), sin(angle)) * r


## Recorta [param polygon] (x, z) tirando a faixa |l| <= BRIDGE_HALF da ponte em [param azimuth]:
## fica a parte de cada lado da faixa (no maximo uma, pois os setores sao estreitos).
func _clip_bridge(polygon: PackedVector2Array, azimuth: float) -> PackedVector2Array:
	var axis := _flat(_polar(azimuth, 1.0))
	var side := Vector2(-axis.y, axis.x)
	var left := _clip_half_plane(polygon, side, BRIDGE_HALF)
	var right := _clip_half_plane(polygon, -side, BRIDGE_HALF)
	if left.size() >= 3 and right.size() >= 3:
		push_error("[arena] setor cortado nos dois lados da ponte %s" % azimuth)
	return left if left.size() >= 3 else right


## Sutherland-Hodgman: mantem os pontos com p.dot(normal) >= offset.
func _clip_half_plane(polygon: PackedVector2Array, normal: Vector2, offset: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	var n := polygon.size()
	for i: int in range(n):
		var a := polygon[i]
		var b := polygon[(i + 1) % n]
		var da := a.dot(normal) - offset
		var db := b.dot(normal) - offset
		if da >= 0.0:
			out.append(a)
		if (da >= 0.0) != (db >= 0.0):
			out.append(a.lerp(b, da / (da - db)))
	return out


func _prism(polygon: PackedVector2Array) -> ConvexPolygonShape3D:
	var shape := ConvexPolygonShape3D.new()
	var points := PackedVector3Array()
	for y: float in [-RIVER_HEIGHT / 2, RIVER_HEIGHT / 2]:
		for p: Vector2 in polygon:
			points.append(Vector3(p.x, y, p.y))
	shape.points = points
	return shape


func _build_crater() -> void:
	var crater := _body("Crater", GateRules.LAYER_WORLD)
	var shape := CylinderShape3D.new()
	shape.radius = PILLAR_RADIUS
	shape.height = PILLAR_HEIGHT
	var i := 0
	for entry: float in BRIDGE_AZIMUTHS:
		for side: float in [-1.0, 1.0]:
			var azimuth := entry + side * PILLAR_OFFSET_DEG
			var at := _polar(azimuth, CRATER_RADIUS)
			_shape(crater, shape, at + Vector3.UP * PILLAR_HEIGHT / 2)
			# Base do asset em y = 0; yaw fixo = azimute (sem RNG, SPEC-034 §2).
			var pillar := _asset(crater, RRB_ARENA + "obsidian_pillar.glb", "Pillar%d" % i)
			pillar.transform = Transform3D(Basis(Vector3.UP, deg_to_rad(azimuth)), at)
			i += 1


func _build_border() -> void:
	var border := _body("Border", GateRules.LAYER_WORLD)
	var radius := ARENA_RADIUS + BORDER_THICKNESS / 2
	var length := TAU * radius / BORDER_SEGMENTS * 1.1
	var box := BoxShape3D.new()
	box.size = Vector3(length, BORDER_HEIGHT, BORDER_THICKNESS)
	for i: int in range(BORDER_SEGMENTS):
		var azimuth := 360.0 * i / BORDER_SEGMENTS
		var shape := _shape(border, box, _polar(azimuth, radius) + Vector3.UP * BORDER_HEIGHT / 2)
		shape.basis = Basis(Vector3.UP, deg_to_rad(azimuth))


# --- bases -------------------------------------------------------------------------------


func _build_base(walls: StaticBody3D, flip: float) -> void:
	var team := GateRules.TEAM_A if flip > 0 else GateRules.TEAM_B
	var tag := _team_tag(flip)
	for i: int in range(BASE_WALLS.size()):
		var seg: Array = BASE_WALLS[i]
		_wall(walls, _local(seg[0], flip), _local(seg[1], flip), "W%s%d" % [tag, i], tag)
	var arc_ends := _build_base_arc(walls, flip, tag)
	var gate_basis := _tangent_basis(_mirror_if(LATERAL, flip))
	var gate_at := _local(Vector2(GATE_S, 0), flip)
	var gate := (_scene(GATE_SCENE).instantiate()) as Gate
	gate.name = "Gate%s" % tag
	gate.team = team
	gate.transform = Transform3D(gate_basis, gate_at)
	_add(_group("Gates"), gate)
	var castle := _group("Castle")
	var frame := _asset(castle, RRB_ARENA + "castle_gate_%s.glb" % tag.to_lower(), "Portal%s" % tag)
	frame.transform = Transform3D(gate_basis, gate_at)
	var towers: Array[Vector3] = [
		_local(Vector2(GATE_S, GATE_TOWER_L), flip), _local(Vector2(GATE_S, -GATE_TOWER_L), flip)
	]
	towers.append_array(arc_ends)
	for i: int in range(towers.size()):
		var tower := _asset(castle, RRB_ARENA + "castle_tower_%s.glb" % tag.to_lower(), "Tower%s%d" % [tag, i])
		tower.position = towers[i]

	var markers := _group("Markers")
	var hero := _marker(markers, "Hero%s" % tag, _local(Vector2(SPAWN_S, 0), flip))
	hero.kind = SpawnMarker.Kind.HERO
	hero.team = team
	hero.basis = Basis.looking_at(-hero.position.normalized())
	for i: int in range(BASE_T1.size()):
		_monster(markers, "T1%s%d" % [tag, i], _local(BASE_T1[i], flip), team, 1, &"skeleton_t1")
	_monster(markers, "T2%s" % tag, _local(BASE_T2, flip), team, 2, &"skeleton_warrior_t2")
	for i: int in range(BASE_CHESTS.size()):
		_common_chest(markers, "Chest%s%d" % [tag, i], _local(BASE_CHESTS[i], flip), team)
	var fountain := _scene(FOUNTAIN_SCENE).instantiate() as Fountain
	fountain.name = "Fountain%s" % tag
	fountain.team = team
	fountain.position = _local(FOUNTAIN_LOCAL, flip)
	_add(_group("Fountains"), fountain)
	for i: int in range(SIDE_FIELDS.size()):
		_build_side_field(markers, flip, i)


## Campo lateral [param index] (0 = O, 1 = SO) da metade de [param flip]. Marcadores com o time
## da metade: o bot conta base + laterais como "a propria metade" (GDB §5.2).
func _build_side_field(markers: Node3D, flip: float, index: int) -> void:
	var team := GateRules.TEAM_A if flip > 0 else GateRules.TEAM_B
	var tag := "%s%s" % [_team_tag(flip), "O" if index == 0 else "SO"]
	var center: Vector2 = SIDE_FIELDS[index]
	for i: int in range(SIDE_T1_OFFSETS.size()):
		var at := _world(center + SIDE_T1_OFFSETS[i], flip)
		_monster(markers, "T1%s%d" % [tag, i], at, team, 1, &"skeleton_t1")
	var warrior_at := _world(center + SIDE_T2_OFFSET, flip)
	_monster(markers, "T2%s" % tag, warrior_at, team, 2, &"skeleton_warrior_t2")
	for i: int in range(SIDE_CHEST_OFFSETS.size()):
		var at := _world(center + SIDE_CHEST_OFFSETS[i], flip)
		_common_chest(markers, "Chest%s%d" % [tag, i], at, team)


## Patio de cada ponte da metade: moita de um lado e rocha do outro, fora da faixa util.
func _build_yards(walls: StaticBody3D, flip: float) -> void:
	var tag := _team_tag(flip)
	for i: int in range(BRIDGE_AZIMUTHS_A.size()):
		var azimuth: float = BRIDGE_AZIMUTHS_A[i]
		var axis := _polar(azimuth, 1.0)
		var side := Vector3(-axis.z, 0, axis.x)
		var grass_at := _mirror_if(axis * YARD_GRASS_LOCAL.x + side * YARD_GRASS_LOCAL.y, flip)
		var basis := _tangent_basis(_mirror_if(side, flip))
		_tall_grass(grass_at, YARD_GRASS_SIZE, basis, "Grass%s%d" % [tag, i], "tall_grass_4x4")
		var rock_at := _mirror_if(axis * YARD_ROCK_LOCAL.x + side * YARD_ROCK_LOCAL.y, flip)
		_rock(walls, rock_at, "Yard%s%d" % [tag, i])


## Muro em arco em volta do spawn, raio = spawn -> portao, com a abertura do portao.
## Devolve os pontos em que o arco encontra a borda (torres).
func _build_base_arc(walls: StaticBody3D, flip: float, tag: String) -> Array[Vector3]:
	var radius := SPAWN_S - GATE_S
	var start := asin(GATE_HALF / radius)
	var ends: Array[Vector3] = []
	for side: float in [1.0, -1.0]:
		var prev := _arc_point(radius, start * side)
		var phi := start
		var i := 0
		while true:
			phi += deg_to_rad(ARC_STEP_DEG)
			var next := _arc_point(radius, phi * side)
			var done := next.length() > ARENA_RADIUS
			if done:
				next = _arc_point(
					radius, _arc_exit(radius, phi - deg_to_rad(ARC_STEP_DEG), phi) * side
				)
			_wall(
				walls,
				_local(prev, flip),
				_local(next, flip),
				"Arc%s%s%d" % [tag, "L" if side > 0 else "R", i],
				tag
			)
			prev = next
			i += 1
			if done:
				ends.append(_local(next, flip))
				break
	return ends


func _arc_point(radius: float, phi: float) -> Vector2:
	return Vector2(SPAWN_S - radius * cos(phi), radius * sin(phi))


## Angulo em que o arco cruza a borda da arena (bissecao).
func _arc_exit(radius: float, inside: float, outside: float) -> float:
	for _i: int in range(30):
		var mid := (inside + outside) / 2
		if _arc_point(radius, mid).length() > ARENA_RADIUS:
			outside = mid
		else:
			inside = mid
	return inside


# --- centro ------------------------------------------------------------------------------


func _build_center(walls: StaticBody3D) -> void:
	var markers := _group("Markers")
	var boss := _marker(markers, "Boss", Vector3.ZERO)
	boss.kind = SpawnMarker.Kind.BOSS
	boss.monster_id = &"skeleton_king_boss"
	for i: int in range(FIELD_AZIMUTHS.size()):
		var az: float = FIELD_AZIMUTHS[i]
		var neutral := GateRules.TEAM_NEUTRAL
		_monster(markers, "Golem%d" % i, _polar(az, FIELD_RADIUS), neutral, 3, &"golem_t3")
		var warrior_at := _polar(az + FIELD_SPREAD_DEG, FIELD_RADIUS)
		_monster(markers, "Warrior%d" % i, warrior_at, neutral, 2, &"skeleton_warrior_t2")
		var mage_at := _polar(az - FIELD_SPREAD_DEG, FIELD_RADIUS)
		_monster(markers, "Mage%d" % i, mage_at, neutral, 2, &"skeleton_mage_t2")
		_rare_chest(markers, "RareField%d" % i, _polar(az, FIELD_CHEST_RADIUS))
	for i: int in range(LATERAL_CHESTS.size()):
		var c: Vector2 = LATERAL_CHESTS[i]
		_rare_chest(markers, "RareSide%d" % i, _polar(c.x, c.y))
	for i: int in range(CENTER_ROCKS.size()):
		_rock(walls, _polar(CENTER_ROCKS[i].x, CENTER_ROCKS[i].y), "Center%d" % i)
	for i: int in range(CENTER_GRASS.size()):
		var g: Vector2 = CENTER_GRASS[i]
		var at := _polar(g.x, g.y)
		var basis := _tangent_basis(Vector3(-at.z, 0, at.x))
		_tall_grass(at, CENTER_GRASS_SIZE, basis, "GrassCenter%d" % i, "tall_grass_4x3")


# --- enfeite (F40): borda da ilha e ilhotas de fundo, sem colisao --------------------------


func _build_rim_decor(flip: float) -> void:
	var decor := _group("RimDecor")
	var tag := _team_tag(flip)
	for i: int in range(RIM_PINES_A.size()):
		var at := _mirror_if(_polar(RIM_PINES_A[i], RIM_RADIUS), flip)
		var pine := _asset(decor, RRB_ARENA + "pine_tree.glb", "Pine%s%d" % [tag, i])
		pine.transform = Transform3D(Basis(Vector3.UP, deg_to_rad(RIM_PINES_A[i] * 3.0)), at)
	for i: int in range(RIM_CRYSTALS_A.size()):
		var c: Vector2 = RIM_CRYSTALS_A[i]
		var at := _mirror_if(_polar(c.x, RIM_RADIUS - 0.6), flip)
		_crystal(decor, at, c.y == 1.0, "Crystal%s%d" % [tag, i], deg_to_rad(c.x))
	for i: int in range(RIM_BARRICADES_A.size()):
		var az: float = RIM_BARRICADES_A[i]
		var at := _mirror_if(_polar(az, RIM_RADIUS - 0.4), flip)
		var fence := _asset(decor, RRB_ARENA + "barricade.glb", "Barricade%s%d" % [tag, i])
		fence.transform = Transform3D(_tangent_basis(_mirror_if(_tangent(az), flip)), at)
	var tower := _asset(decor, RRB_ARENA + "watchtower.glb", "Watchtower%s" % tag)
	tower.position = _mirror_if(_polar(RIM_WATCHTOWER_A, RIM_RADIUS + 0.5), flip)
	var ballista := _asset(decor, RRB_ARENA + "ballista.glb", "Ballista%s" % tag)
	var ballista_at := _mirror_if(_polar(RIM_BALLISTA_A, RIM_RADIUS - 0.2), flip)
	ballista.transform = Transform3D(Basis.looking_at(-ballista_at.normalized()), ballista_at)


func _build_islets() -> void:
	var decor := _group("Islets")
	for i: int in range(ISLETS.size()):
		var islet: Array = ISLETS[i]
		var node := _asset(decor, RRB_ARENA + "%s.glb" % islet[0], "Islet%d" % i)
		var at: Vector3 = islet[1]
		var scale: float = islet[2]
		node.transform = Transform3D(Basis(Vector3.UP, 0.7 * i).scaled(Vector3.ONE * scale), at)
		for k: int in range(2):
			var pine := _asset(node, RRB_ARENA + "pine_tree.glb", "Pine%d" % k)
			pine.position = Vector3(2.5 - 5.0 * k, 0.2, 1.5 * k - 1.0)
		if i % 2 == 0:
			_crystal(node, Vector3(0.5, 0.2, 2.5), true, "Crystal", 0.0)


## Cristal arcano: material por variante (magenta, ciano, verde) em rodizio; so visual.
func _crystal(parent: Node3D, at: Vector3, large: bool, label: String, yaw: float) -> void:
	var model := "crystal_large" if large else "crystal_small"
	var crystal := _asset(parent, RRB_ARENA + model + ".glb", label)
	crystal.transform = Transform3D(Basis(Vector3.UP, yaw), at)
	var variant: String = CRYSTAL_MATERIALS[_crystal_count % CRYSTAL_MATERIALS.size()]
	_crystal_count += 1
	if variant == CRYSTAL_MATERIALS[0]:
		return  # magenta ja vem do .import (use_external)
	# Instancia editavel: o override de superficie fica gravado na cena empacotada.
	_root.set_editable_instance(crystal, true)
	for node: Node in crystal.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		for i: int in range(mi.get_surface_override_material_count()):
			var active := mi.get_active_material(i)
			if active != null and active.resource_path.ends_with("arcane_crystal_magenta.tres"):
				mi.set_surface_override_material(i, load(MATERIALS + "arcane_crystal_%s.tres" % variant))


# --- ambientacao (cliente): luzes e particulas -------------------------------------------


func _build_ambience() -> void:
	var ambience := Node3D.new()
	ambience.name = "Ambience"
	ambience.set_script(load(AMBIENCE_SCRIPT))
	_add(_root, ambience)
	_light(ambience, "MagmaLight", Vector3(0, 1.5, 0), Color(1.0, 0.45, 0.1), MAGMA_LIGHT_RANGE, 2.5)
	for flip: float in [1.0, -1.0]:
		var tag := _team_tag(flip)
		var gate_at := _local(Vector2(GATE_S, 0), flip)
		var lateral := _mirror_if(LATERAL, flip)
		var forward := _mirror_if(AXIS_A, flip)
		for side: float in [1.0, -1.0]:
			var at := gate_at + lateral * (3.25 * side) + Vector3.UP * 2.4 - forward * 0.9
			_light(ambience, "Torch%s%d" % [tag, int(side > 0)], at, Color(1.0, 0.6, 0.25), TORCH_LIGHT_RANGE, 1.2)
		for i: int in range(RIM_CRYSTALS_A.size()):
			var c: Vector2 = RIM_CRYSTALS_A[i]
			var at := _mirror_if(_polar(c.x, RIM_RADIUS - 0.6), flip) + Vector3.UP * 1.5
			var color := Color(0.85, 0.25, 0.95) if i == 0 else Color(0.2, 0.85, 1.0)
			_light(ambience, "CrystalLight%s%d" % [tag, i], at, color, CRYSTAL_LIGHT_RANGE, 1.0)
	_embers(ambience)
	for sign: float in [-1.0, 1.0]:
		_waterfall(ambience, sign)


func _light(parent: Node3D, label: String, at: Vector3, color: Color, range_u: float, energy: float) -> void:
	var light := OmniLight3D.new()
	light.name = label
	light.position = at
	light.light_color = color
	light.omni_range = range_u
	light.light_energy = energy
	light.shadow_enabled = false
	_add(parent, light)


func _embers(parent: Node3D) -> void:
	var particles := GPUParticles3D.new()
	particles.name = "Embers"
	particles.position = Vector3(0, 0.3, 0)
	particles.amount = EMBERS_AMOUNT
	particles.lifetime = 3.0
	particles.preprocess = 2.0
	var material := ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = CRATER_RADIUS - 0.5
	material.direction = Vector3.UP
	material.spread = 15.0
	material.initial_velocity_min = 0.4
	material.initial_velocity_max = 1.0
	material.gravity = Vector3(0, 0.5, 0)
	material.scale_min = 0.6
	material.scale_max = 1.2
	material.color = Color(1.0, 0.55, 0.15)
	particles.process_material = material
	particles.draw_pass_1 = _spark_mesh(0.12, Color(1.0, 0.6, 0.2))
	_add(parent, particles)


func _waterfall(parent: Node3D, sign: float) -> void:
	var particles := GPUParticles3D.new()
	particles.name = "Waterfall%s" % ("S" if sign > 0 else "N")
	particles.position = Vector3(0, -0.5, sign * (CHANNEL_END + 0.8))
	particles.amount = WATERFALL_AMOUNT
	particles.lifetime = 2.6
	particles.preprocess = 2.0
	var material := ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	material.emission_box_extents = Vector3(CHANNEL_HALF - 0.3, 0.2, 0.3)
	material.direction = Vector3(0, -0.4, sign * 0.5)
	material.spread = 12.0
	material.initial_velocity_min = 1.5
	material.initial_velocity_max = 3.0
	material.gravity = Vector3(0, -6.0, 0)
	material.scale_min = 0.8
	material.scale_max = 1.6
	material.color = Color(0.5, 1.0, 0.95)
	particles.process_material = material
	particles.draw_pass_1 = _spark_mesh(0.22, Color(0.4, 1.0, 0.9))
	_add(parent, particles)


func _spark_mesh(size: float, color: Color) -> QuadMesh:
	var mesh := QuadMesh.new()
	mesh.size = Vector2(size, size)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.vertex_color_use_as_albedo = true
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 2.0
	mesh.material = material
	return mesh


# --- construtores ------------------------------------------------------------------------


func _wall(walls: StaticBody3D, a: Vector3, b: Vector3, label: String, tag: String) -> void:
	var dir := (b - a).normalized()
	var length := a.distance_to(b)
	var basis := Basis(Vector3.UP, atan2(-dir.z, dir.x))
	var box := BoxShape3D.new()
	box.size = Vector3(length, WALL_HEIGHT, WALL_THICKNESS)
	var mid := (a + b) / 2
	var shape := _shape(walls, box, mid + Vector3.UP * WALL_HEIGHT / 2)
	shape.basis = basis
	var visual := _asset(_group("Castle"), RRB_ARENA + "castle_wall_%s.glb" % tag.to_lower(), label)
	visual.transform = Transform3D(basis.scaled(Vector3(length / 2, 1, 1)), mid)


func _rock(walls: StaticBody3D, at: Vector3, label: String) -> void:
	var cylinder := CylinderShape3D.new()
	cylinder.radius = ROCK_RADIUS
	cylinder.height = WALL_HEIGHT
	_shape(walls, cylinder, at + Vector3.UP * WALL_HEIGHT / 2)
	var visual := _asset(_group("RockDecor"), RRB_ARENA + "boulder.glb", label)
	visual.transform = Transform3D(Basis(Vector3.UP, at.x * 0.7 + at.z * 0.3), at)
	# Cristal pequeno encostado na rocha, dentro do cilindro de colisao (so visual).
	var yaw := at.x * 0.7 + at.z * 0.3
	_crystal(_group("RockDecor"), at + Vector3(cos(yaw), 0, sin(yaw)) * 1.0, false, label + "Crystal", yaw)


## Area3D do mato (colisao da SPEC-007) + asset do Blender [param model] como visual.
func _tall_grass(at: Vector3, size: Vector2, basis: Basis, label: String, model: String) -> void:
	var area := Area3D.new()
	area.name = label
	area.collision_layer = 0
	area.collision_mask = GateRules.LAYER_WORLD
	area.transform = Transform3D(basis, at)
	_add(_group("TallGrass"), area)
	area.add_to_group(&"tall_grass", true)
	var box := BoxShape3D.new()
	box.size = Vector3(size.x, GRASS_HEIGHT * 2, size.y)
	_shape(area, box, Vector3.UP * GRASS_HEIGHT)
	_asset(area, RRB_ARENA + model + ".glb", "Visual")


func _monster(
	parent: Node3D, label: String, at: Vector3, team: int, tier: int, id: StringName
) -> void:
	var m := _marker(parent, label, at)
	m.kind = SpawnMarker.Kind.MONSTER
	m.team = team
	m.tier = tier
	m.monster_id = id


func _common_chest(parent: Node3D, label: String, at: Vector3, team: int) -> void:
	var m := _marker(parent, label, at)
	m.kind = SpawnMarker.Kind.CHEST
	m.team = team
	m.chest_kind = SpawnMarker.ChestKind.COMMON


func _rare_chest(parent: Node3D, label: String, at: Vector3) -> void:
	var m := _marker(parent, label, at)
	m.kind = SpawnMarker.Kind.CHEST
	m.team = GateRules.TEAM_NEUTRAL
	m.chest_kind = SpawnMarker.ChestKind.RARE


func _marker(parent: Node3D, label: String, at: Vector3) -> SpawnMarker:
	var m := SpawnMarker.new()
	m.name = label
	m.position = at
	_add(parent, m)
	return m


func _body(label: String, layer: int) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = label
	body.collision_layer = layer
	body.collision_mask = 0
	_add(_root, body)
	return body


func _group(label: String) -> Node3D:
	var existing := _root.get_node_or_null(label) as Node3D
	if existing:
		return existing
	var node := Node3D.new()
	node.name = label
	_add(_root, node)
	return node


func _shape(parent: Node3D, shape: Shape3D, at: Vector3) -> CollisionShape3D:
	var node := CollisionShape3D.new()
	node.shape = shape
	node.position = at
	_add(parent, node)
	return node


func _asset(parent: Node3D, path: String, label: String) -> Node3D:
	var node := _scene(path).instantiate() as Node3D
	node.name = label
	_add(parent, node)
	return node


func _scene(path: String) -> PackedScene:
	if not _scenes.has(path):
		_scenes[path] = load(path)
	return _scenes[path]


func _add(parent: Node, child: Node) -> void:
	parent.add_child(child)
	child.owner = _root


# --- geometria ---------------------------------------------------------------------------


## Ponto da base A em (s, l); flip -1 da a base B (espelho em x).
func _local(p: Vector2, flip: float) -> Vector3:
	return _mirror_if(AXIS_A * p.x + LATERAL * p.y, flip)


## Ponto (x, z) do mundo da metade A; flip -1 espelha para a B.
func _world(p: Vector2, flip: float) -> Vector3:
	return Vector3(p.x * flip, 0, p.y)


func _mirror_if(v: Vector3, flip: float) -> Vector3:
	return Vector3(v.x * flip, v.y, v.z)


func _polar(azimuth_deg: float, r: float) -> Vector3:
	var a := deg_to_rad(azimuth_deg)
	return Vector3(-sin(a), 0, -cos(a)) * r


## Tangente (anti-horaria vista de cima) ao circulo no azimute.
func _tangent(azimuth_deg: float) -> Vector3:
	var p := _polar(azimuth_deg, 1.0)
	return Vector3(-p.z, 0, p.x)


## Base com +X ao longo de [param along] (horizontal).
func _tangent_basis(along: Vector3) -> Basis:
	var dir := Vector3(along.x, 0, along.z).normalized()
	return Basis(Vector3.UP, atan2(-dir.z, dir.x))


func _flat(v: Vector3) -> Vector2:
	return Vector2(v.x, v.z)


func _team_tag(flip: float) -> String:
	return "A" if flip > 0 else "B"
