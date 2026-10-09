extends SceneTree
## Gera game/scenes/arena/arena.tscn (SPEC-007; decisoes do PI de 2026-10-09: spawn em
## (-24, +24) e campos do centro em 45/225 graus). Ferramenta de autoria: as medidas da spec
## vivem aqui; o jogo so le a cena gerada. Uso (na raiz do repo):
##   godot --headless --path game -s <repo>/tools/arena/build_arena.gd
## Sai com 1 se o rio nao separar as metades sem as pontes, ou se as pontes nao ligarem.
## Azimute: graus anti-horarios a partir do norte (-Z), vistos de cima (N 0, O 90, S 180, L 270).

const OUT: String = "res://scenes/arena/arena.tscn"
const KAYKIT: String = "res://shared/assets/kaykit/medieval_hexagon/"
## Arte propria do Blender (ADR-0005, SPEC-034): so visual; colisao continua aqui.
const RRB_ARENA: String = "res://shared/assets/rrb/arena/"
const GATE_SCENE: String = "res://scenes/world/gate.tscn"

# Grade (SPEC §1): hex de topo pontudo, faces planas em +-X; o tile do pack mede 2,0 u.
const TILE_FACE: float = 3.0
const TILE_SCALE: float = TILE_FACE / 2.0
const ROW_STEP: float = TILE_FACE * 0.8660254
const HEX_CIRCUMRADIUS: float = TILE_FACE / 1.7320508
const FILL_RADIUS: float = 36.5
const ARENA_RADIUS: float = 35.0

# Rio (SPEC §2): coroa 14-18 u em volta da ilha + banda de 4 u na diagonal x = z.
const RING_IN: float = 14.0
const RING_OUT: float = 18.0
const BAND_HALF: float = 2.0
## Meia largura das pontes. 2,5 u em vez de 2,0: com hex de 3 u, a celula de rio vizinha
## fica a >= 0,77 u do eixo e a capsula (0,4 u) passa.
const BRIDGE_HALF: float = 2.5
const BRIDGE_CENTER: float = 15.556
## Modelo da ponte (1,33 x 1,92 u) esticado para cobrir a faixa andavel sobre a coroa.
const BRIDGE_MODEL_SCALE: Vector3 = Vector3(4.1, 1, 3.9)
const RIVER_HEIGHT: float = 2.0

# Cratera (SPEC §2): 8 pilares no raio 6 u, entradas de 4 u em 45/135/225/315.
const CRATER_RADIUS: float = 6.0
const PILLAR_RADIUS: float = 1.4
const PILLAR_HEIGHT: float = 3.0
## Angulo entre o centro de uma entrada e o pilar vizinho: 12 sin(a) = 4 + 2 x 1,4.
const PILLAR_OFFSET_DEG: float = 34.52
const ENTRY_AZIMUTHS: Array[float] = [45.0, 135.0, 225.0, 315.0]

# Base A em coordenadas locais (s ao longo do eixo centro -> base, l ao longo de x = z).
const AXIS_A: Vector3 = Vector3(-0.70710678, 0, 0.70710678)
const LATERAL: Vector3 = Vector3(0.70710678, 0, 0.70710678)
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
const YARD_ROCKS: Array[Vector2] = [Vector2(20, 9), Vector2(20, -9)]
const YARD_GRASS: Array[Vector2] = [Vector2(20, 4.5), Vector2(20, -4.5)]
const YARD_GRASS_SIZE: Vector2 = Vector2(4, 4)

# Anel central (azimute, raio).
const FIELD_AZIMUTHS: Array[float] = [45.0, 225.0]
const FIELD_RADIUS: float = 10.0
const FIELD_SPREAD_DEG: float = 15.0
const FIELD_CHEST_RADIUS: float = 12.5
const LATERAL_CHESTS: Array[Vector2] = [Vector2(90, 8), Vector2(270, 8)]
const CENTER_ROCKS: Array[Vector2] = [
	Vector2(0, 11), Vector2(180, 11), Vector2(112, 11), Vector2(292, 11)
]
const CENTER_GRASS: Array[Vector2] = [Vector2(90, 11.5), Vector2(270, 11.5)]
const CENTER_GRASS_SIZE: Vector2 = Vector2(4, 3)

# Bloqueios.
const WALL_HEIGHT: float = 2.5
const WALL_THICKNESS: float = 0.8
const ROCK_RADIUS: float = 1.3
const ROCK_SCALE: float = 1.5
const BORDER_SEGMENTS: int = 72
const BORDER_THICKNESS: float = 2.0
const BORDER_HEIGHT: float = 4.0
const BORDER_DECOR_STEP_DEG: float = 6.0
const BORDER_DECOR_SCALE: float = 2.2
const GRASS_HEIGHT: float = 1.2

var _root: Node3D
var _scenes: Dictionary = {}


func _initialize() -> void:
	_root = Node3D.new()
	_root.name = "Arena"
	var cells := _cells()
	if not _river_separates(cells):
		quit(1)
		return
	_build_floor(cells)
	_build_river(cells)
	_build_crater()
	_build_border()
	var walls := _body("Walls", GateRules.LAYER_WORLD)
	for flip: float in [1.0, -1.0]:
		_build_base(walls, flip)
	_build_center(walls)
	var packed := PackedScene.new()
	var err := packed.pack(_root)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT.get_base_dir()))
	if err == OK:
		err = ResourceSaver.save(packed, OUT)
	print("[arena] %s -> %s" % [OUT, error_string(err)])
	_root.free()
	quit(0 if err == OK else 1)


# --- grade e rio -------------------------------------------------------------------------


func _cells() -> Dictionary:
	var cells: Dictionary = {}  # Vector2i -> Vector2 (centro x, z)
	var rows := ceili(FILL_RADIUS / ROW_STEP)
	var cols := ceili(FILL_RADIUS / TILE_FACE) + 1
	for row: int in range(-rows, rows + 1):
		for col: int in range(-cols, cols + 1):
			var x := col * TILE_FACE + (TILE_FACE / 2.0 if posmod(row, 2) == 1 else 0.0)
			var center := Vector2(x, row * ROW_STEP)
			if center.length() <= FILL_RADIUS:
				cells[Vector2i(col, row)] = center
	return cells


func _is_bridge(p: Vector2) -> bool:
	for axis: Vector2 in [_flat(AXIS_A), -_flat(AXIS_A)]:
		var s := p.dot(axis)
		var l := absf(p.dot(_flat(LATERAL)))
		if s > RING_IN - HEX_CIRCUMRADIUS and s < RING_OUT + HEX_CIRCUMRADIUS and l <= BRIDGE_HALF:
			return true
	return false


func _is_river(p: Vector2, with_bridges: bool) -> bool:
	var r := p.length()
	if r <= RING_IN:
		return false
	var on_band := absf(p.dot(_flat(AXIS_A))) <= BAND_HALF
	if r > RING_OUT and not on_band:
		return false
	return not (with_bridges and _is_bridge(p))


## Flood fill pelas celulas andaveis: sem pontes, a base A nao alcanca o centro nem a base B;
## com pontes, alcanca os dois.
func _river_separates(cells: Dictionary) -> bool:
	var spawn_a := _flat(AXIS_A * SPAWN_S)
	var without := _reachable(cells, spawn_a, false)
	var linked := _reachable(cells, spawn_a, true)
	var center := _nearest(cells, Vector2.ZERO)
	var spawn_b := _nearest(cells, -spawn_a)
	var ok := (
		not without.has(center)
		and not without.has(spawn_b)
		and linked.has(center)
		and linked.has(spawn_b)
	)
	print("[arena] rio separa sem pontes e liga com pontes: %s" % ok)
	return ok


func _reachable(cells: Dictionary, from: Vector2, with_bridges: bool) -> Dictionary:
	var seen: Dictionary = {}
	var queue: Array[Vector2i] = [_nearest(cells, from)]
	while not queue.is_empty():
		var key: Vector2i = queue.pop_back()
		if seen.has(key):
			continue
		var p: Vector2 = cells[key]
		if _is_river(p, with_bridges) or p.length() > ARENA_RADIUS:
			continue
		seen[key] = true
		for other: Vector2i in cells:
			if not seen.has(other) and (cells[other] as Vector2).distance_to(p) < TILE_FACE + 0.01:
				queue.append(other)
	return seen


func _nearest(cells: Dictionary, p: Vector2) -> Vector2i:
	var best := Vector2i.ZERO
	var best_d := INF
	for key: Vector2i in cells:
		var d := (cells[key] as Vector2).distance_to(p)
		if d < best_d:
			best_d = d
			best = key
	return best


func _build_floor(cells: Dictionary) -> void:
	var floor_body := _body("Floor", GateRules.LAYER_WORLD)
	var box := BoxShape3D.new()
	box.size = Vector3(FILL_RADIUS * 2.2, 1, FILL_RADIUS * 2.2)
	_shape(floor_body, box, Vector3(0, -0.5, 0))
	var tiles := _group("Tiles")
	for key: Vector2i in cells:
		var p: Vector2 = cells[key]
		# Mesmo predicado da colisao: toda agua desenhada bloqueia; a ponte vira chao.
		var model := "hex_water" if _is_river(p, true) else "hex_grass"
		var tile := _instance(tiles, model, "T%d_%d" % [key.x, key.y])
		tile.transform = Transform3D(Basis().scaled(Vector3.ONE * TILE_SCALE), Vector3(p.x, 0, p.y))


func _build_river(cells: Dictionary) -> void:
	var river := _body("River", GateRules.LAYER_RIVER)
	var prism := ConvexPolygonShape3D.new()
	var points := PackedVector3Array()
	for y: float in [-RIVER_HEIGHT / 2, RIVER_HEIGHT / 2]:
		for i: int in range(6):
			var a := deg_to_rad(90.0 + 60.0 * i)
			points.append(Vector3(cos(a) * HEX_CIRCUMRADIUS, y, sin(a) * HEX_CIRCUMRADIUS))
	prism.points = points
	for key: Vector2i in cells:
		var p: Vector2 = cells[key]
		if _is_river(p, true):
			_shape(river, prism, Vector3(p.x, 0, p.y))
	var bridges := _group("Bridges")
	for flip: float in [1.0, -1.0]:
		var bridge := _instance(bridges, "building_bridge_A", "Bridge%s" % _team_tag(flip))
		var basis := Basis.looking_at(AXIS_A * flip) * Basis.from_scale(BRIDGE_MODEL_SCALE)
		bridge.transform = Transform3D(basis, AXIS_A * flip * BRIDGE_CENTER)


# --- cratera e borda ---------------------------------------------------------------------


func _build_crater() -> void:
	var crater := _body("Crater", GateRules.LAYER_WORLD)
	var shape := CylinderShape3D.new()
	shape.radius = PILLAR_RADIUS
	shape.height = PILLAR_HEIGHT
	var i := 0
	for entry: float in ENTRY_AZIMUTHS:
		for side: float in [-1.0, 1.0]:
			var azimuth := entry + side * PILLAR_OFFSET_DEG
			var at := _polar(azimuth, CRATER_RADIUS)
			_shape(crater, shape, at + Vector3.UP * PILLAR_HEIGHT / 2)
			# Base do asset em y = 0; yaw fixo = azimute (sem RNG, SPEC-034 §2).
			var pillar := _asset(crater, RRB_ARENA + "crater_pillar.glb", "Pillar%d" % i)
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
	var decor := _group("BorderDecor")
	var steps := int(360.0 / BORDER_DECOR_STEP_DEG)
	for i: int in range(steps):
		var azimuth := BORDER_DECOR_STEP_DEG * i
		var mountain := _instance(decor, "mountain_A", "M%d" % i)
		mountain.transform = Transform3D(
			Basis(Vector3.UP, deg_to_rad(azimuth * 7.0)).scaled(Vector3.ONE * BORDER_DECOR_SCALE),
			_polar(azimuth, ARENA_RADIUS + BORDER_THICKNESS * 1.25)
		)


# --- bases -------------------------------------------------------------------------------


func _build_base(walls: StaticBody3D, flip: float) -> void:
	var team := GateRules.TEAM_A if flip > 0 else GateRules.TEAM_B
	var tag := _team_tag(flip)
	for i: int in range(BASE_WALLS.size()):
		var seg: Array = BASE_WALLS[i]
		_wall(walls, _local(seg[0], flip), _local(seg[1], flip), "W%s%d" % [tag, i])
	_build_base_arc(walls, flip, tag)
	var gate := (_scene(GATE_SCENE).instantiate()) as Gate
	gate.name = "Gate%s" % tag
	gate.team = team
	gate.transform = Transform3D(_tangent_basis(LATERAL * flip), _local(Vector2(GATE_S, 0), flip))
	_add(_group("Gates"), gate)
	for i: int in range(YARD_ROCKS.size()):
		_rock(walls, _local(YARD_ROCKS[i], flip), "Yard%s%d" % [tag, i])
	for i: int in range(YARD_GRASS.size()):
		var at := _local(YARD_GRASS[i], flip)
		var label := "Grass%s%d" % [tag, i]
		_tall_grass(at, YARD_GRASS_SIZE, _tangent_basis(LATERAL * flip), label, "tall_grass_4x4")

	var markers := _group("Markers")
	var hero := _marker(markers, "Hero%s" % tag, _local(Vector2(SPAWN_S, 0), flip))
	hero.kind = SpawnMarker.Kind.HERO
	hero.team = team
	hero.basis = Basis.looking_at(-hero.position.normalized())
	for i: int in range(BASE_T1.size()):
		_monster(markers, "T1%s%d" % [tag, i], _local(BASE_T1[i], flip), team, 1, &"skeleton_t1")
	_monster(markers, "T2%s" % tag, _local(BASE_T2, flip), team, 2, &"skeleton_warrior_t2")
	for i: int in range(BASE_CHESTS.size()):
		var chest := _marker(markers, "Chest%s%d" % [tag, i], _local(BASE_CHESTS[i], flip))
		chest.kind = SpawnMarker.Kind.CHEST
		chest.team = team
		chest.chest_kind = SpawnMarker.ChestKind.COMMON


## Muro em arco em volta do spawn, raio = spawn -> portao, com a abertura do portao.
func _build_base_arc(walls: StaticBody3D, flip: float, tag: String) -> void:
	var radius := SPAWN_S - GATE_S
	var start := asin(GATE_HALF / radius)
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
				"Arc%s%s%d" % [tag, "L" if side > 0 else "R", i]
			)
			prev = next
			i += 1
			if done:
				break


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


# --- construtores ------------------------------------------------------------------------


func _wall(walls: StaticBody3D, a: Vector3, b: Vector3, label: String) -> void:
	var dir := (b - a).normalized()
	var length := a.distance_to(b)
	var basis := Basis(Vector3.UP, atan2(-dir.z, dir.x))
	var box := BoxShape3D.new()
	box.size = Vector3(length, WALL_HEIGHT, WALL_THICKNESS)
	var mid := (a + b) / 2
	var shape := _shape(walls, box, mid + Vector3.UP * WALL_HEIGHT / 2)
	shape.basis = basis
	var visual := _instance(_group("WallDecor"), "wall_straight", label)
	visual.transform = Transform3D(basis.scaled(Vector3(length / 2, WALL_HEIGHT / 1.1, 1)), mid)


func _rock(walls: StaticBody3D, at: Vector3, label: String) -> void:
	var cylinder := CylinderShape3D.new()
	cylinder.radius = ROCK_RADIUS
	cylinder.height = WALL_HEIGHT
	_shape(walls, cylinder, at + Vector3.UP * WALL_HEIGHT / 2)
	var visual := _instance(_group("RockDecor"), "mountain_A", label)
	visual.transform = Transform3D(Basis().scaled(Vector3.ONE * ROCK_SCALE), at)


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


func _instance(parent: Node3D, model: String, label: String) -> Node3D:
	return _asset(parent, KAYKIT + model + ".gltf", label)


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


## Ponto da base A em (s, l); flip -1 da a base B (rotacao de 180 graus).
func _local(p: Vector2, flip: float) -> Vector3:
	return (AXIS_A * p.x + LATERAL * p.y) * flip


func _polar(azimuth_deg: float, r: float) -> Vector3:
	var a := deg_to_rad(azimuth_deg)
	return Vector3(-sin(a), 0, -cos(a)) * r


## Base com +X ao longo de [param along] (horizontal).
func _tangent_basis(along: Vector3) -> Basis:
	var dir := Vector3(along.x, 0, along.z).normalized()
	return Basis(Vector3.UP, atan2(-dir.z, dir.x))


func _flat(v: Vector3) -> Vector2:
	return Vector2(v.x, v.z)


func _team_tag(flip: float) -> String:
	return "A" if flip > 0 else "B"
