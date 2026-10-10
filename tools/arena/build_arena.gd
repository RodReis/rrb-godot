extends "arena_dressing.gd"
## Gera game/scenes/arena/ilha_arcana.tscn — Ilha Flutuante Arcana, layout "Rift Medieval
## adaptado" (SPEC-046 + arte do F40/F44). Ferramenta de autoria: as medidas da spec vivem aqui;
## o jogo so le a cena gerada ("edite o builder, nao a cena"). Simetria por rotacao de 180 graus:
## tudo da metade A em (x, z) vale para a B em (-x, -z). Uso (na raiz do repo):
##   godot --headless --path game -s <repo>/tools/arena/build_arena.gd
## Sai com 1 se o rio nao fechar a ilha central sem as pontes, se TOP/BOT nao contornarem as
## lagoas, se as pontes nao ligarem ou se algum colisor/moita invadir um corredor (§2.3).
## Azimute: graus anti-horarios a partir do norte (-Z), vistos de cima (N 0, O 90, S 180, L 270).
## Colisao toda por codigo (box do chao, prismas do rio, cilindros, caixas); os .glb do Blender
## (art/arena/build_island.py) sao so visual e cobrem a colisao, nunca menores.

# Escala (SPEC-046 §1): quadrado |x|, |z| <= 40; 4 muros retos em 41.
const ARENA_HALF: float = 40.0
const BORDER_THICKNESS: float = 2.0
const BORDER_HEIGHT: float = 4.0

# Rio (SPEC-046 §2.1): anel 14-18 u + 2 bracos em arco + 2 lagoas. Colisao do anel e dos bracos
# em setores poligonais de 2,5 graus (erro de corda < 1 cm); o anel e recortado pela borda reta
# das 2 pontes, o braco pelo circulo interno do anel (meio-plano por setor).
const RING_IN: float = 14.0
const RING_OUT: float = 18.0
const RING_MID: float = 16.0
const RIVER_HALF: float = 2.0
const RIVER_SECTOR_DEG: float = 2.5
const RIVER_HEIGHT: float = 2.0
## Braco NO: arco de circulo (eixo) de centro ARM_CENTER_A e raio ARM_RADIUS, da juncao com o
## anel (azimute 45, r 16) ate o centro da lagoa NO, barriga para NE. O SE e a rotacao.
const ARM_CENTER_A: Vector2 = Vector2(-22.5, -6.2)
const ARM_RADIUS: float = 12.35
const ARM_JOIN_AZIMUTH: float = 45.0
## Graus a mais no comeco do arco, para dentro do anel, garantindo a juncao sem fresta.
const ARM_OVERLAP_DEG: float = 12.0

const LAGOON_RADIUS: float = 5.0
## Meia largura util das pontes (largura efetiva 5 u; nominal 4 u).
const BRIDGE_HALF: float = 2.5
const BRIDGE_CENTER: float = 16.0
## So na MID: SO (metade A) e NE (metade B).
const BRIDGE_AZIMUTHS: Array[float] = [135.0, 315.0]
const BRIDGE_AZIMUTH_A: float = 135.0

# Cratera (SPEC-046 §2.2 = SPEC-044): 8 pilares no raio 6 u, 4 entradas de 4 u.

const CRATER_ENTRIES: Array[float] = [45.0, 135.0, 225.0, 315.0]
const PILLAR_RADIUS: float = 1.4
const PILLAR_HEIGHT: float = 3.0
## Angulo entre o centro de uma entrada e o pilar vizinho: 12 sin(a) = 4 + 2 x 1,4.
const PILLAR_OFFSET_DEG: float = 34.52

# Base A (canto SO) em coordenadas locais: s ao longo de centro -> spawn A (-24, +24); l para a
# esquerda de quem esta no spawn olhando o centro. A base B e a rotacao de 180 graus.

const GATE_HALF: float = 2.5
const ARC_STEP_DEG: float = 8.0
## Muros de fechamento (SPEC-046 §2.4): dos extremos do arco ate a borda, em (x, z) do mundo.
const CLOSURE_WALLS_A: Array[Array] = [
	[Vector2(-33, 15), Vector2(-40, 15)],
	[Vector2(-15, 33), Vector2(-15, 40)],
]
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
## Fonte no canto esquerdo da base (#74), em (s, l).
const FOUNTAIN_LOCAL: Vector2 = Vector2(32, 11)
## Torres do castelo ao lado do portao (l).
const GATE_TOWER_L: float = 4.0
## Casas de pedra atras do spawn (decisao do PI 2026-10-10: kit novo), em (s, l) com yaw; tem
## colisao (caixa) para o heroi nao atravessar a parede — ficam fora de toda rota.
const HOUSES_LOCAL: Array[Array] = [[Vector2(37.5, 7.0), 0.35], [Vector2(37.5, -7.0), -0.35]]
const HOUSE_HALF: Vector2 = Vector2(1.9, 1.6)
const HOUSE_HEIGHT: float = 3.4
## Torreao no canto da ilha, atras da borda (bastiao do chassi), em (x, z) do mundo.
const KEEP_A: Vector2 = Vector2(-44.5, 44.5)
## Cortina do castelo ao longo da borda da base ate a face do torreao (so visual: o colisor e o
## muro da borda).
const CURTAIN_A: Array[Array] = [
	[Vector2(-41, 15), Vector2(-41, 43.5)],
	[Vector2(-15, 41), Vector2(-43.5, 41)],
]

# Campos laterais (F36 na SPEC-046 §2.5), metade A em (x, z) do mundo: A-top entre TOP (O) e MID,
# A-bot entre MID e BOT (S). Rochas formam um bolso paralelo ao corredor vizinho (em z no A-top,
# em x no A-bot): a 5,5 u em z o A-bot entraria 0,8 u na banda S (SPEC-046 §2.3), que vence.
const SIDE_FIELDS: Array[Array] = [
	["Top", Vector2(-26, -4), Vector2(0, 1)], ["Bot", Vector2(4, 26), Vector2(1, 0)]
]
const SIDE_T1_OFFSETS: Array[Vector2] = [Vector2(-2.5, -1.5), Vector2(2.5, -1.5)]
const SIDE_T2_OFFSET: Vector2 = Vector2(0, 1.5)
const SIDE_CHEST_OFFSETS: Array[Vector2] = [Vector2(-3, 2.5), Vector2(3, 2.5)]
const SIDE_ROCK_OFFSET: float = 5.5

# Patio da ponte da metade A (s radial, l lateral): moita de um lado e rocha do outro, fora da
# banda MID de 8 u (|l| > 4; SPEC-046 §2.7 herdava l 4,6 da SPEC-044, que invadiria 2 u).
const YARD_GRASS_LOCAL: Vector2 = Vector2(19.5, 6.5)
const YARD_ROCK_LOCAL: Vector2 = Vector2(19.5, -6.0)
const YARD_GRASS_SIZE: Vector2 = Vector2(4, 4)
## Moita de lagoa (SPEC-046 §2.7), em (x, z) do mundo, fora do corredor TOP.
const LAGOON_GRASS_A: Vector2 = Vector2(-30, -26)

# Centro (azimute, raio): campos em 45/225 (equidistantes das pontes); raros em 45/225 e 90/270.
const FIELD_AZIMUTHS: Array[float] = [45.0, 225.0]
const FIELD_RADIUS: float = 10.0
const FIELD_SPREAD_DEG: float = 15.0
const FIELD_CHEST_RADIUS: float = 12.5
const LATERAL_CHESTS: Array[Vector2] = [Vector2(90, 8), Vector2(270, 8)]
const CENTER_ROCKS: Array[Vector2] = [
	Vector2(0, 9.5), Vector2(180, 9.5), Vector2(112, 9.5), Vector2(292, 9.5)
]
const CENTER_GRASS: Array[Vector2] = [Vector2(90, 12), Vector2(270, 12)]
const CENTER_GRASS_SIZE: Vector2 = Vector2(4, 3)

# Corredores livres (SPEC-046 §2.3), retangulos (x0, z0, x1, z1) da metade A; BOT e a rotacao.
# MID: 8 u entre o portao e a ponte; na ilha, 4 u (a largura da entrada da cratera, que a
# propria spec fixa). O rio (pontes de 5 u) fica fora da conferencia da MID.
const CORRIDOR_TOP_A: Array[Rect2] = [
	Rect2(-40, -40, 8, 55),  # O: x -40..-32, z -40..15
	Rect2(-40, -40, 55, 8),  # N: z -40..-32, x -40..15
]
const MID_OUTER_HALF: float = 4.0
const MID_OUTER_RANGE: Vector2 = Vector2(18.0, 20.71)
const MID_ISLAND_HALF: float = 2.0
const MID_ISLAND_RANGE: Vector2 = Vector2(-14.0, 14.0)
## Profundidade de invasao tolerada (u): o fim do arco (extremo em x -33, SPEC-046 §2.4) e o muro
## de fechamento encostam na banda TOP; a largura util fica >= 6,5 u nesse ponto.
const CORRIDOR_TOLERANCE: float = 1.5

# Bloqueios.
const WALL_HEIGHT: float = 2.5
const WALL_THICKNESS: float = 0.8
const ROCK_RADIUS: float = 1.3
const GRASS_HEIGHT: float = 1.2


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
		_build_yard(walls, flip)
		_build_rim_decor(flip)
	_build_center(walls)
	_build_islets()
	_build_ambience()
	var violations := _corridor_violations()
	for v: String in violations:
		push_error("[arena] corredor invadido: %s" % v)
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


# --- rio: predicados e prova de separacao -------------------------------------------------


func _is_bridge(p: Vector2) -> bool:
	for azimuth: float in BRIDGE_AZIMUTHS:
		var axis := _flat(_polar(azimuth, 1.0))
		var s := p.dot(axis)
		var l := absf(p.dot(Vector2(-axis.y, axis.x)))
		if s > RING_IN - 1.0 and s < RING_OUT + 1.0 and l <= BRIDGE_HALF:
			return true
	return false


## Angulos (rad) do arco do braco NO em torno de ARM_CENTER_A: x = no anel (com a sobra),
## y = no centro da lagoa. O arco e o curto, percorrido de x para y.
func _arm_angles() -> Vector2:
	var join := _flat(_polar(ARM_JOIN_AZIMUTH, RING_MID)) - ARM_CENTER_A
	var end := LAGOON_A - ARM_CENTER_A
	var start := join.angle()
	var sweep := wrapf(end.angle() - start, -PI, PI)
	return Vector2(start - signf(sweep) * deg_to_rad(ARM_OVERLAP_DEG), start + sweep)


func _in_arm(p: Vector2) -> bool:
	var v := p - ARM_CENTER_A
	var d := v.length()
	if d < ARM_RADIUS - RIVER_HALF or d > ARM_RADIUS + RIVER_HALF:
		return false
	var angles := _arm_angles()
	var sweep := angles.y - angles.x
	var t := wrapf(v.angle() - angles.x, -PI, PI)
	return t * signf(sweep) >= 0.0 and absf(t) <= absf(sweep)


func _in_lagoon(p: Vector2) -> bool:
	return p.distance_to(LAGOON_A) <= LAGOON_RADIUS


func _is_river(p: Vector2, with_bridges: bool) -> bool:
	var r := p.length()
	if r <= RING_IN:
		return false
	if r <= RING_OUT:
		return not (with_bridges and _is_bridge(p))
	return _in_arm(p) or _in_arm(-p) or _in_lagoon(p) or _in_lagoon(-p)


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
		_build_side_field(walls, markers, flip, i)


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
		tower.position = towers[i]
	for i: int in range(CURTAIN_A.size()):
		var seg: Array = CURTAIN_A[i]
		_curtain(_world(seg[0], flip), _world(seg[1], flip), "Curtain%s%d" % [tag, i], tag)
	var keep := _asset(castle, RRB_ARENA + "castle_keep_%s.glb" % kit, "Keep%s" % tag)
	keep.transform = Transform3D(_tangent_basis(_rotate_if(LATERAL, flip)), _world(KEEP_A, flip))
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
## conta base + laterais como "a propria metade" (GDB §5.2). 2 rochas por campo (SPEC-046 §2.5).
func _build_side_field(walls: StaticBody3D, markers: Node3D, flip: float, index: int) -> void:
	var team := GateRules.TEAM_A if flip > 0 else GateRules.TEAM_B
	var field: Array = SIDE_FIELDS[index]
	var tag := "%s%s" % [_team_tag(flip), field[0]]
	var center: Vector2 = field[1]
	var rock_axis: Vector2 = field[2]
	for i: int in range(SIDE_T1_OFFSETS.size()):
		var at := _world(center + SIDE_T1_OFFSETS[i], flip)
		_monster(markers, "T1%s%d" % [tag, i], at, team, 1, &"skeleton_t1")
	var warrior_at := _world(center + SIDE_T2_OFFSET, flip)
	_monster(markers, "T2%s" % tag, warrior_at, team, 2, &"skeleton_warrior_t2")
	for i: int in range(SIDE_CHEST_OFFSETS.size()):
		var at := _world(center + SIDE_CHEST_OFFSETS[i], flip)
		_common_chest(markers, "Chest%s%d" % [tag, i], at, team)
	for side: float in [-1.0, 1.0]:
		var at := _world(center + rock_axis * SIDE_ROCK_OFFSET * side, flip)
		_rock(walls, at, "Field%s%d" % [tag, int(side > 0)])


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


## Visual de muralha (castle_wall) entre [param a] e [param b], sem colisao propria.
func _curtain(a: Vector3, b: Vector3, label: String, tag: String) -> void:
	var dir := (b - a).normalized()
	var length := a.distance_to(b)
	var basis := Basis(Vector3.UP, atan2(-dir.z, dir.x))
	var mid := (a + b) / 2
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
