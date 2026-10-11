extends "arena_vegetation.gd"
## Gera game/scenes/arena/ilha_arcana.tscn — Ilha Flutuante Arcana, layout "Rift Medieval
## adaptado" (SPEC-046 + arte do F40/F44) com os bolsoes de selva do F40 (PI 2026-10-11).
## Ferramenta de autoria: as medidas vivem em arena_layout.gd e jungle.json; o jogo so le a cena
## gerada ("edite o builder, nao a cena"). Simetria por rotacao de 180 graus:
## tudo da metade A em (x, z) vale para a B em (-x, -z). Uso (na raiz do repo):
##   godot --headless --path game -s <repo>/tools/arena/build_arena.gd
## Sai com 1 se o rio nao fechar a ilha central sem as pontes, se TOP/BOT nao contornarem as
## lagoas, se as pontes nao ligarem, se algum colisor/moita invadir um corredor (§2.3), se um
## bolsao invadir trilha ou clareira ou se algum marcador ficar inalcancavel a pe.
## Azimute: graus anti-horarios a partir do norte (-Z), vistos de cima (N 0, O 90, S 180, L 270).
## Colisao toda por codigo (box do chao, prismas do rio, cilindros, caixas); os .glb do Blender
## (art/arena/build_island.py) sao so visual e cobrem a colisao, nunca menores.

const JUNGLE_CHECK_STEP: float = 0.5
## Raio do agente do navmesh (ArenaNav): passagem entre bolsoes tem de caber o bot.
const AGENT_CLEARANCE: float = 0.5
## Altura da colisao dos bolsoes: abaixo da rocha mais baixa (nada de parede invisivel por cima).
const JUNGLE_HEIGHT: float = 2.2
## Comprimento do modulo castle_wall (art/arena/build_island.py, build_wall: x de -1 a 1).
const WALL_MODULE: float = 2.0


func _initialize() -> void:
	_root = Node3D.new()
	_root.name = "Arena"
	if not _load_jungle() or not _river_separates():
		quit(1)
		return
	_paint_terrain()
	_save_materials()
	_build_environment()
	_build_lighting()
	_build_floor()
	_build_river()
	_build_crater()
	_build_border()
	var walls := _body("Walls", GateRules.LAYER_WORLD)
	for flip: float in [1.0, -1.0]:
		_build_base(walls, flip)
		_build_yard(walls, flip)
		_build_rim_decor(flip)
	_build_center(walls)
	_build_jungle(walls)
	_build_jungle_visuals()
	_build_vegetation()
	_build_islets()
	_build_ambience()
	var violations := _corridor_violations()
	for v: String in violations:
		push_error("[arena] corredor invadido: %s" % v)
	var jungle := _jungle_violations()
	for v: String in jungle:
		push_error("[arena] selva: %s" % v)
	violations.append_array(jungle)
	if not violations.is_empty():
		quit(1)
		return
	var packed := PackedScene.new()
	var err := packed.pack(_root)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT.get_base_dir()))
	if err == OK:
		err = ResourceSaver.save(packed, OUT)
	print("[arena] %s -> %s" % [OUT, error_string(err)])
	_root.free()
	quit(0 if err == OK else 1)


# --- rio: prova de separacao -------------------------------------------------------


## Flood fill numa grade de 1 u pelas celulas andaveis: sem pontes, o spawn A nao alcanca a ilha
## central (o anel fecha), mas alcanca o spawn B contornando as lagoas (TOP/BOT); com pontes,
## alcanca o centro (SPEC-046 §2.1).
func _river_separates() -> bool:
	var spawn_a := _flat(AXIS_A * SPAWN_S)
	var spawn_b := -spawn_a
	var without := _reachable(spawn_a, false)
	var linked := _reachable(spawn_a, true)
	var center := Vector2i.ZERO
	var b := Vector2i(roundi(spawn_b.x), roundi(spawn_b.y))
	var ok := not without.has(center) and without.has(b) and linked.has(center)
	print("[arena] rio fecha a ilha sem pontes, TOP/BOT contornam e as pontes ligam: %s" % ok)
	return ok


func _reachable(from: Vector2, with_bridges: bool) -> Dictionary:
	var seen: Dictionary = {}
	var queue: Array[Vector2i] = [Vector2i(roundi(from.x), roundi(from.y))]
	while not queue.is_empty():
		var key: Vector2i = queue.pop_back()
		if seen.has(key):
			continue
		var p := Vector2(key)
		if _is_river(p, with_bridges) or maxf(absf(p.x), absf(p.y)) > ARENA_HALF:
			continue
		seen[key] = true
		for step: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			if not seen.has(key + step):
				queue.append(key + step)
	return seen


func _build_floor() -> void:
	var floor_body := _body("Floor", GateRules.LAYER_WORLD)
	var box := BoxShape3D.new()
	box.size = Vector3(ARENA_HALF * 2.5, 1, ARENA_HALF * 2.5)
	_shape(floor_body, box, Vector3(0, -0.5, 0))
	var island := _group("Island")
	_asset(island, RRB_ARENA + "island_chassis.glb", "Chassis")
	_asset(island, RRB_ARENA + "river_mana.glb", "RiverMana")
	_asset(island, RRB_ARENA + "lava_lake.glb", "LavaLake")


## Colisao do rio: setores do anel (recortados pelas pontes), setores dos bracos (recortados
## pelo circulo interno do anel) e cilindros das lagoas.
func _build_river() -> void:
	var river := _body("River", GateRules.LAYER_RIVER)
	var sectors := int(360.0 / RIVER_SECTOR_DEG)
	for i: int in range(sectors):
		var a0 := deg_to_rad(RIVER_SECTOR_DEG * i)
		var a1 := deg_to_rad(RIVER_SECTOR_DEG * (i + 1))
		var polygon: PackedVector2Array = [
			_ring_point(a0, RING_IN),
			_ring_point(a1, RING_IN),
			_ring_point(a1, RING_OUT),
			_ring_point(a0, RING_OUT),
		]
		for azimuth: float in BRIDGE_AZIMUTHS:
			polygon = _clip_bridge(polygon, azimuth)
			if polygon.size() < 3:
				break
		if polygon.size() >= 3:
			_shape(river, _prism(polygon), Vector3.ZERO)
	for flip: float in [1.0, -1.0]:
		for quad: PackedVector2Array in _arm_quads():
			var polygon := PackedVector2Array()
			for p: Vector2 in quad:
				polygon.append(p * flip)
			_shape(river, _prism(polygon), Vector3.ZERO)
		var lagoon := CylinderShape3D.new()
		lagoon.radius = LAGOON_RADIUS
		lagoon.height = RIVER_HEIGHT
		_shape(river, lagoon, Vector3(LAGOON_A.x, 0, LAGOON_A.y) * flip)
	var bridges := _group("Bridges")
	for azimuth: float in BRIDGE_AZIMUTHS:
		var axis := _polar(azimuth, 1.0)
		var bridge := _asset(bridges, RRB_ARENA + "bridge_stone.glb", "Bridge%d" % int(azimuth))
		bridge.transform = Transform3D(
			_tangent_basis(Vector3(-axis.z, 0, axis.x)), axis * BRIDGE_CENTER
		)


## Setores do braco NO (x, z): quadrilateros ao longo do arco, fora do circulo interno do anel.
func _arm_quads() -> Array[PackedVector2Array]:
	var quads: Array[PackedVector2Array] = []
	var angles := _arm_angles()
	var sweep := angles.y - angles.x
	var steps := ceili(absf(rad_to_deg(sweep)) / RIVER_SECTOR_DEG)
	for i: int in range(steps):
		var a0 := angles.x + sweep * i / steps
		var a1 := angles.x + sweep * (i + 1) / steps
		var polygon: PackedVector2Array = [
			ARM_CENTER_A + Vector2.from_angle(a0) * (ARM_RADIUS - RIVER_HALF),
			ARM_CENTER_A + Vector2.from_angle(a1) * (ARM_RADIUS - RIVER_HALF),
			ARM_CENTER_A + Vector2.from_angle(a1) * (ARM_RADIUS + RIVER_HALF),
			ARM_CENTER_A + Vector2.from_angle(a0) * (ARM_RADIUS + RIVER_HALF),
		]
		var centroid := Vector2.ZERO
		for p: Vector2 in polygon:
			centroid += p / polygon.size()
		polygon = _clip_half_plane(polygon, centroid.normalized(), RING_IN)
		if polygon.size() >= 3:
			quads.append(polygon)
	return quads


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
func _clip_half_plane(
	polygon: PackedVector2Array, normal: Vector2, offset: float
) -> PackedVector2Array:
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
	for entry: float in CRATER_ENTRIES:
		for side: float in [-1.0, 1.0]:
			var azimuth := entry + side * PILLAR_OFFSET_DEG
			var at := _polar(azimuth, CRATER_RADIUS)
			_shape(crater, shape, at + Vector3.UP * PILLAR_HEIGHT / 2)
			# Base do asset em y = 0; yaw fixo = azimute (sem RNG, SPEC-034 §2).
			var pillar := _asset(crater, RRB_ARENA + "obsidian_pillar.glb", "Pillar%d" % i)
			pillar.transform = Transform3D(Basis(Vector3.UP, deg_to_rad(azimuth)), at)
			i += 1


## 4 muros retos em |x| = 41 e |z| = 41 (SPEC-046 §1); o visual e a beira da ilha e a cortina
## do castelo nas bases.
func _build_border() -> void:
	var border := _body("Border", GateRules.LAYER_WORLD)
	var center := ARENA_HALF + BORDER_THICKNESS / 2
	var length := center * 2 + BORDER_THICKNESS
	var along_x := BoxShape3D.new()
	along_x.size = Vector3(length, BORDER_HEIGHT, BORDER_THICKNESS)
	var along_z := BoxShape3D.new()
	along_z.size = Vector3(BORDER_THICKNESS, BORDER_HEIGHT, length)
	for sign: float in [-1.0, 1.0]:
		_shape(border, along_x, Vector3(0, BORDER_HEIGHT / 2, sign * center))
		_shape(border, along_z, Vector3(sign * center, BORDER_HEIGHT / 2, 0))


# --- bases -------------------------------------------------------------------------------


func _build_base(walls: StaticBody3D, flip: float) -> void:
	var team := GateRules.TEAM_A if flip > 0 else GateRules.TEAM_B
	var tag := _team_tag(flip)
	for i: int in range(BASE_WALLS.size()):
		var seg: Array = BASE_WALLS[i]
		_wall(walls, _local(seg[0], flip), _local(seg[1], flip), "W%s%d" % [tag, i], tag)
	var arc_ends := _build_base_arc(walls, flip, tag)
	for i: int in range(CLOSURE_WALLS_A.size()):
		var seg: Array = CLOSURE_WALLS_A[i]
		_wall(walls, _world(seg[0], flip), _world(seg[1], flip), "Close%s%d" % [tag, i], tag)
	var gate_basis := _tangent_basis(_rotate_if(LATERAL, flip))
	var gate_at := _local(Vector2(GATE_S, 0), flip)
	var gate := (_scene(GATE_SCENE).instantiate()) as Gate
	gate.name = "Gate%s" % tag
	gate.team = team
	gate.transform = Transform3D(gate_basis, gate_at)
	_add(_group("Gates"), gate)
	_build_castle(walls, flip, tag, gate_basis, gate_at, arc_ends)

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


## Castelo (kit F40 + torreao e casas do F46): portal com torres, torres nos extremos do arco e
## onde o fechamento encontra a borda, cortina ao longo da borda, torreao no bastiao do canto e
## casas atras do spawn.
func _build_castle(
	walls: StaticBody3D,
	flip: float,
	tag: String,
	gate_basis: Basis,
	gate_at: Vector3,
	arc_ends: Array[Vector3]
) -> void:
	var castle := _group("Castle")
	var kit := tag.to_lower()
	var frame := _asset(castle, RRB_ARENA + "castle_gate_%s.glb" % kit, "Portal%s" % tag)
	frame.transform = Transform3D(gate_basis, gate_at)
	var towers: Array[Vector3] = [
		_local(Vector2(GATE_S, GATE_TOWER_L), flip), _local(Vector2(GATE_S, -GATE_TOWER_L), flip)
	]
	towers.append_array(arc_ends)
	for seg: Array in CURTAIN_A:
		towers.append(_world(seg[0], flip))
	for i: int in range(towers.size()):
		var tower := _asset(castle, RRB_ARENA + "castle_tower_%s.glb" % kit, "Tower%s%d" % [tag, i])
		tower.transform = Transform3D(Basis().scaled(Vector3.ONE * TOWER_SCALE), towers[i])
	for i: int in range(CURTAIN_A.size()):
		var seg: Array = CURTAIN_A[i]
		_curtain(_world(seg[0], flip), _world(seg[1], flip), "Curtain%s%d" % [tag, i], tag)
	var keep := _asset(castle, RRB_ARENA + "castle_keep_%s.glb" % kit, "Keep%s" % tag)
	var keep_basis := _tangent_basis(_rotate_if(LATERAL, flip)).scaled(Vector3.ONE * KEEP_SCALE)
	keep.transform = Transform3D(keep_basis, _world(KEEP_A, flip))
	for i: int in range(HOUSES_LOCAL.size()):
		var spec: Array = HOUSES_LOCAL[i]
		var at := _local(spec[0], flip)
		var yaw: float = spec[1]
		var basis := _tangent_basis(_rotate_if(LATERAL, flip)).rotated(Vector3.UP, yaw)
		var house := _asset(castle, RRB_ARENA + "stone_house.glb", "House%s%d" % [tag, i])
		house.transform = Transform3D(basis, at)
		var box := BoxShape3D.new()
		box.size = Vector3(HOUSE_HALF.x * 2, HOUSE_HEIGHT, HOUSE_HALF.y * 2)
		var shape := _shape(walls, box, at + Vector3.UP * HOUSE_HEIGHT / 2)
		shape.basis = basis


## Campo lateral [param index] da metade de [param flip]. Marcadores com o time da metade: o bot
## conta base + laterais como "a propria metade" (GDB §5.2). O bolso e dos bolsoes de selva
## (jungle.json; F40, PI 2026-10-11), no lugar das 2 rochas da SPEC-046 §2.5.
func _build_side_field(markers: Node3D, flip: float, index: int) -> void:
	var team := GateRules.TEAM_A if flip > 0 else GateRules.TEAM_B
	var field: Array = SIDE_FIELDS[index]
	var tag := "%s%s" % [_team_tag(flip), field[0]]
	var center: Vector2 = field[1]
	for i: int in range(SIDE_T1_OFFSETS.size()):
		var at := _world(center + SIDE_T1_OFFSETS[i], flip)
		_monster(markers, "T1%s%d" % [tag, i], at, team, 1, &"skeleton_t1")
	var warrior_at := _world(center + SIDE_T2_OFFSET, flip)
	_monster(markers, "T2%s" % tag, warrior_at, team, 2, &"skeleton_warrior_t2")
	for i: int in range(SIDE_CHEST_OFFSETS.size()):
		var at := _world(center + SIDE_CHEST_OFFSETS[i], flip)
		_common_chest(markers, "Chest%s%d" % [tag, i], at, team)


## Patio da ponte da metade: moita de um lado e rocha do outro, fora da banda MID; moita da
## lagoa ao lado da lagoa, fora do corredor TOP.
func _build_yard(walls: StaticBody3D, flip: float) -> void:
	var tag := _team_tag(flip)
	var axis := _polar(BRIDGE_AZIMUTH_A, 1.0)
	var side := Vector3(-axis.z, 0, axis.x)
	var grass_at := _rotate_if(axis * YARD_GRASS_LOCAL.x + side * YARD_GRASS_LOCAL.y, flip)
	var basis := _tangent_basis(_rotate_if(side, flip))
	_tall_grass(grass_at, YARD_GRASS_SIZE, basis, "GrassBridge%s" % tag, "tall_grass_4x4")
	var rock_at := _rotate_if(axis * YARD_ROCK_LOCAL.x + side * YARD_ROCK_LOCAL.y, flip)
	_rock(walls, rock_at, "Yard%s" % tag)
	var lagoon_grass := _world(LAGOON_GRASS_A, flip)
	_tall_grass(lagoon_grass, YARD_GRASS_SIZE, Basis(), "GrassLagoon%s" % tag, "tall_grass_4x4")


## Muro em arco em volta do spawn, raio = spawn -> portao, com a abertura do portao, ate os
## extremos em |l| = raio (SPEC-046 §2.4). Devolve os extremos (torres).
func _build_base_arc(walls: StaticBody3D, flip: float, tag: String) -> Array[Vector3]:
	var radius := SPAWN_S - GATE_S
	var start := asin(GATE_HALF / radius)
	var ends: Array[Vector3] = []
	for side: float in [1.0, -1.0]:
		var prev := _arc_point(radius, start * side)
		var phi := start
		var i := 0
		while true:
			phi = minf(phi + deg_to_rad(ARC_STEP_DEG), PI / 2)
			var next := _arc_point(radius, phi * side)
			_wall(
				walls,
				_local(prev, flip),
				_local(next, flip),
				"Arc%s%s%d" % [tag, "L" if side > 0 else "R", i],
				tag
			)
			prev = next
			i += 1
			if phi >= PI / 2:
				ends.append(_local(next, flip))
				break
	return ends


func _arc_point(radius: float, phi: float) -> Vector2:
	return Vector2(SPAWN_S - radius * cos(phi), radius * sin(phi))


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


# --- selva (F40, PI 2026-10-11): colisao dos bolsoes e provas ------------------------------


## Bolsao = caixa por trecho da polilinha + cilindro em cada vertice (cantos redondos), na
## camada do mundo como os muros: bloqueia heroi, monstro, flecha e entra no navmesh.
func _build_jungle(walls: StaticBody3D) -> void:
	var walls_list := _polylines("walls")
	for w: int in range(walls_list.size()):
		var points: PackedVector2Array = walls_list[w][0]
		var half: float = walls_list[w][1]
		for k: int in range(points.size()):
			var cylinder := CylinderShape3D.new()
			cylinder.radius = half
			cylinder.height = JUNGLE_HEIGHT
			var at := Vector3(points[k].x, JUNGLE_HEIGHT / 2, points[k].y)
			_shape(walls, cylinder, at).name = "Jungle%dC%d" % [w, k]
		for i: int in range(points.size() - 1):
			var a := Vector3(points[i].x, 0, points[i].y)
			var b := Vector3(points[i + 1].x, 0, points[i + 1].y)
			var dir := (b - a).normalized()
			var box := BoxShape3D.new()
			box.size = Vector3(a.distance_to(b), JUNGLE_HEIGHT, half * 2)
			var shape := _shape(walls, box, (a + b) / 2 + Vector3.UP * JUNGLE_HEIGHT / 2)
			shape.basis = Basis(Vector3.UP, atan2(-dir.z, dir.x))
			shape.name = "Jungle%dS%d" % [w, i]


## Bolsao dentro de trilha ou clareira, e marcador que nao se alcanca a pe a partir do spawn A
## (rio com pontes, borda e bolsoes bloqueiam; grade de JUNGLE_CHECK_STEP). E piso, nao prova
## completa: muros da base, casas, rochas soltas e pilares nao entram no flood.
func _jungle_violations() -> Array[String]:
	var violations: Array[String] = []
	var walls := _polylines("walls")
	for wall: Array in walls:
		var samples := _along(wall[0], JUNGLE_CHECK_STEP / 2)
		for trail: Array in _polylines("trails"):
			for p: Vector2 in samples:
				if _polyline_distance(p, trail[0]) < wall[1] + trail[1]:
					violations.append("bolsao %s invade a trilha %s" % [wall[0], trail[0]])
					break
		for clearing: Array in _clearings():
			if _polyline_distance(clearing[0], wall[0]) < wall[1] + clearing[1]:
				violations.append("bolsao %s invade a clareira %s" % [wall[0], clearing[0]])
	violations.append_array(_yard_rock_violations())
	var reach := _walkable_from(_flat(AXIS_A * SPAWN_S), walls)
	for node: Node in _root.get_node("Markers").get_children():
		var at := _flat((node as Node3D).position)
		var key := Vector2i((at / JUNGLE_CHECK_STEP).round())
		if not reach.has(key):
			violations.append("marcador %s inalcancavel em %s" % [node.name, at])
	return violations


## Rocha do patio da ponte (SPEC-046 §2.7) dentro de uma trilha: fecha a saida do portao.
func _yard_rock_violations() -> Array[String]:
	var violations: Array[String] = []
	var axis := _polar(BRIDGE_AZIMUTH_A, 1.0)
	var side := Vector3(-axis.z, 0, axis.x)
	var rock := _flat(axis * YARD_ROCK_LOCAL.x + side * YARD_ROCK_LOCAL.y)
	for flip: float in [1.0, -1.0]:
		var at := rock * flip
		for trail: Array in _polylines("trails"):
			if _polyline_distance(at, trail[0]) < ROCK_RADIUS + trail[1]:
				violations.append("rocha do patio %s invade a trilha %s" % [at, trail[0]])
	return violations


func _walkable_from(from: Vector2, walls: Array[Array]) -> Dictionary:
	var seen: Dictionary = {}
	var queue: Array[Vector2i] = [Vector2i((from / JUNGLE_CHECK_STEP).round())]
	var steps: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	while not queue.is_empty():
		var key: Vector2i = queue.pop_back()
		if seen.has(key):
			continue
		var p := Vector2(key) * JUNGLE_CHECK_STEP
		if _is_river(p, true) or maxf(absf(p.x), absf(p.y)) > ARENA_HALF:
			continue
		var blocked := false
		for wall: Array in walls:
			if _polyline_distance(p, wall[0]) < wall[1] + AGENT_CLEARANCE:
				blocked = true
				break
		if blocked:
			continue
		seen[key] = true
		for step: Vector2i in steps:
			if not seen.has(key + step):
				queue.append(key + step)
	return seen


# --- corredores livres (SPEC-046 §2.3) ----------------------------------------------------


## Lista de colisores e moitas que invadem um corredor alem da tolerancia. Conferido sobre a
## cena montada (mesma geometria que o jogo carrega).
func _corridor_violations() -> Array[String]:
	var violations: Array[String] = []
	var bodies: Array[String] = ["Walls", "River", "Crater", "TallGrass"]
	for body_name: String in bodies:
		var body := _root.get_node_or_null(body_name)
		if body == null:
			continue
		for node: Node in body.find_children("*", "CollisionShape3D", true, false):
			var shape := node as CollisionShape3D
			var corners := _shape_corners(shape)
			for flip: float in [1.0, -1.0]:
				for rect: Rect2 in CORRIDOR_TOP_A:
					var r := rect if flip > 0 else Rect2(-rect.end, rect.size)
					var depth := _overlap(corners, Vector2.RIGHT, Vector2(r.position.x, r.end.x))
					var z_range := Vector2(r.position.y, r.end.y)
					depth = minf(depth, _overlap(corners, Vector2.DOWN, z_range))
					if depth > CORRIDOR_TOLERANCE:
						var where := (
							"%s/%s@%s" % [body_name, shape.get_parent().name, shape.position]
						)
						violations.append("%s em %s (%.2f u)" % [where, r, depth])
			if body_name == "River":
				continue
			var along := Vector2(1, -1).normalized()
			var across := Vector2(1, 1).normalized()
			for band: Array in [
				[MID_OUTER_RANGE, MID_OUTER_HALF],
				[-Vector2(MID_OUTER_RANGE.y, MID_OUTER_RANGE.x), MID_OUTER_HALF],
				[MID_ISLAND_RANGE, MID_ISLAND_HALF],
			]:
				var half: float = band[1]
				var depth := _overlap(corners, along, band[0])
				depth = minf(depth, _overlap(corners, across, Vector2(-half, half)))
				if depth > CORRIDOR_TOLERANCE:
					var where: String = "%s/%s" % [body_name, shape.get_parent().name]
					violations.append("%s na MID %s" % [where, band[0]])
	return violations


## Vertices do colisor no mundo (x, z): projetados em qualquer eixo dao o alcance exato.
func _shape_corners(shape_node: CollisionShape3D) -> PackedVector2Array:
	var xform := _world_transform(shape_node)
	var points := PackedVector3Array()
	var shape := shape_node.shape
	if shape is BoxShape3D:
		var half: Vector3 = (shape as BoxShape3D).size / 2
		for sx: float in [-1.0, 1.0]:
			for sz: float in [-1.0, 1.0]:
				points.append(Vector3(half.x * sx, 0, half.z * sz))
	elif shape is CylinderShape3D:
		var r := (shape as CylinderShape3D).radius
		for i: int in range(16):
			points.append(Vector3(cos(TAU * i / 16) * r, 0, sin(TAU * i / 16) * r))
	elif shape is ConvexPolygonShape3D:
		points = (shape as ConvexPolygonShape3D).points
	var corners := PackedVector2Array()
	for p: Vector3 in points:
		corners.append(_flat(xform * p))
	return corners


func _world_transform(node: Node3D) -> Transform3D:
	var xform := node.transform
	var parent := node.get_parent() as Node3D
	while parent != null and parent != _root:
		xform = parent.transform * xform
		parent = parent.get_parent() as Node3D
	return xform


## Profundidade da sobreposicao entre a projecao de [param corners] em [param axis] e o
## intervalo [param range]; negativa se nao se tocam.
func _overlap(corners: PackedVector2Array, axis: Vector2, span: Vector2) -> float:
	var lo := INF
	var hi := -INF
	for c: Vector2 in corners:
		var t := c.dot(axis)
		lo = minf(lo, t)
		hi = maxf(hi, t)
	return minf(hi, span.y) - maxf(lo, span.x)


# --- construtores de colisao e marcadores -------------------------------------------------


func _wall(walls: StaticBody3D, a: Vector3, b: Vector3, label: String, tag: String) -> void:
	var dir := (b - a).normalized()
	var length := a.distance_to(b)
	var basis := Basis(Vector3.UP, atan2(-dir.z, dir.x))
	var box := BoxShape3D.new()
	box.size = Vector3(length, WALL_HEIGHT, WALL_THICKNESS)
	var mid := (a + b) / 2
	var shape := _shape(walls, box, mid + Vector3.UP * WALL_HEIGHT / 2)
	shape.basis = basis
	_curtain(a, b, label, tag)


## Visual de muralha (castle_wall) entre [param a] e [param b], sem colisao propria: modulos de
## WALL_MODULE repetidos, cada um ajustado so no proprio eixo X para fechar o vao (#130: escala
## global cisalhava muro diagonal e engrossava muro ao longo de Z; um modulo por vao esticava).
func _curtain(a: Vector3, b: Vector3, label: String, tag: String) -> void:
	var dir := (b - a).normalized()
	var length := a.distance_to(b)
	var count := maxi(1, roundi(length / WALL_MODULE))
	var piece := length / count
	var stretch := Basis.from_scale(Vector3(piece / WALL_MODULE, 1, 1))
	var basis := Basis(Vector3.UP, atan2(-dir.z, dir.x)) * stretch
	var path := RRB_ARENA + "castle_wall_%s.glb" % tag.to_lower()
	for i: int in range(count):
		var visual := _asset(_group("Castle"), path, label if count == 1 else "%s_%d" % [label, i])
		visual.transform = Transform3D(basis, a + dir * piece * (i + 0.5))


func _rock(walls: StaticBody3D, at: Vector3, label: String) -> void:
	var cylinder := CylinderShape3D.new()
	cylinder.radius = ROCK_RADIUS
	cylinder.height = WALL_HEIGHT
	_shape(walls, cylinder, at + Vector3.UP * WALL_HEIGHT / 2)
	var visual := _asset(_group("RockDecor"), RRB_ARENA + "boulder.glb", label)
	visual.transform = Transform3D(Basis(Vector3.UP, at.x * 0.7 + at.z * 0.3), at)
	# Cristal pequeno encostado na rocha, dentro do cilindro de colisao (so visual).
	var yaw := at.x * 0.7 + at.z * 0.3
	_crystal(
		_group("RockDecor"),
		at + Vector3(cos(yaw), 0, sin(yaw)) * 1.0,
		false,
		label + "Crystal",
		yaw
	)


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
