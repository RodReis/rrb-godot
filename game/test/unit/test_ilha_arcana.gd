extends GutTest
## Criterio de aceite do F44 (SPEC-044 §6) pelos marcadores da cena gerada da Ilha Flutuante
## Arcana: contagens do GDB, espelho em x, spawns nos cantos norte, campos do centro em 0/180,
## fontes, moitas e portoes. Colisao e tempos: test_ilha_arcana_physics.

const ARENA: String = "res://scenes/arena/ilha_arcana.tscn"
const SPAWN_A: Vector3 = Vector3(-24, 0, -24)
const BASE_RADIUS: float = 12.7
const ARENA_RADIUS: float = 35.0

var _arena: Node3D


func before_all() -> void:
	_arena = (load(ARENA) as PackedScene).instantiate() as Node3D
	add_child(_arena)


func after_all() -> void:
	_arena.free()


func _mirror(v: Vector3) -> Vector3:
	return Vector3(-v.x, v.y, v.z)


func _markers() -> Array[SpawnMarker]:
	var result: Array[SpawnMarker] = []
	for node: Node in _arena.find_children("*", "Marker3D", true, false):
		if node is SpawnMarker:
			result.append(node as SpawnMarker)
	return result


func _count(kind: SpawnMarker.Kind, team: int, tier: int = -1) -> int:
	var n := 0
	for m: SpawnMarker in _markers():
		if m.kind == kind and m.team == team and (tier < 0 or m.tier == tier):
			n += 1
	return n


func test_contagem_de_herois() -> void:
	assert_eq(_count(SpawnMarker.Kind.HERO, GateRules.TEAM_A), 1)
	assert_eq(_count(SpawnMarker.Kind.HERO, GateRules.TEAM_B), 1)


## Metade de cada time: base (4 T1 + 1 T2) + 2 campos laterais (2 T1 + 1 T2 cada), GDB §5.1.
func test_contagem_de_monstros_por_zona() -> void:
	for team: int in [GateRules.TEAM_A, GateRules.TEAM_B]:
		assert_eq(_count(SpawnMarker.Kind.MONSTER, team, 1), 8)
		assert_eq(_count(SpawnMarker.Kind.MONSTER, team, 2), 3)
	assert_eq(_count(SpawnMarker.Kind.MONSTER, GateRules.TEAM_NEUTRAL, 2), 4)
	assert_eq(_count(SpawnMarker.Kind.MONSTER, GateRules.TEAM_NEUTRAL, 3), 2)
	assert_eq(_count(SpawnMarker.Kind.BOSS, GateRules.TEAM_NEUTRAL), 1)


## 16 T1 + 8 T2 + 2 Magos + 2 Golems + boss; 12 de base + 8 laterais + 4 raros (GDB §6.2).
func test_total_de_29_monstros_e_24_baus() -> void:
	var monsters := 0
	var chests := 0
	for m: SpawnMarker in _markers():
		if m.kind == SpawnMarker.Kind.MONSTER or m.kind == SpawnMarker.Kind.BOSS:
			monsters += 1
		elif m.kind == SpawnMarker.Kind.CHEST:
			chests += 1
	assert_eq(monsters, 29)
	assert_eq(chests, 24)


func test_baus_comuns_nas_bases_e_raros_no_centro() -> void:
	for m: SpawnMarker in _markers():
		if m.kind != SpawnMarker.Kind.CHEST:
			continue
		if m.team == GateRules.TEAM_NEUTRAL:
			assert_eq(m.chest_kind, SpawnMarker.ChestKind.RARE)
		else:
			assert_eq(m.chest_kind, SpawnMarker.ChestKind.COMMON)


func test_monstros_tem_id_do_catalogo() -> void:
	for m: SpawnMarker in _markers():
		if m.kind == SpawnMarker.Kind.MONSTER or m.kind == SpawnMarker.Kind.BOSS:
			assert_ne(Ids.to_int(m.monster_id), -1, str(m.monster_id))


## SPEC-044 §6 item 6: para cada marcador em (x, z) existe (-x, z) com mesmo kind/tier (nos
## campos do centro, sobre o eixo, guerreiro e mago T2 sao o espelho um do outro).
func test_simetria_por_espelho_em_x() -> void:
	var markers := _markers()
	for m: SpawnMarker in markers:
		var mirror := _mirror(m.position)
		var found := false
		for other: SpawnMarker in markers:
			if (
				other.position.distance_to(mirror) < 0.01
				and other.kind == m.kind
				and other.tier == m.tier
				and other.chest_kind == m.chest_kind
			):
				found = true
		assert_true(found, "sem espelho: %s em %s" % [m.name, m.position])


## Moitas tambem espelhadas: a regra do mato (F32) e geometria de jogo.
func test_seis_moitas_espelhadas() -> void:
	var areas: Array[Area3D] = []
	for node: Node in _arena.find_children("*", "Area3D", true, false):
		if node.is_in_group(&"tall_grass"):
			areas.append(node as Area3D)
	assert_eq(areas.size(), 6)
	for a: Area3D in areas:
		var found := false
		for b: Area3D in areas:
			found = found or b.position.distance_to(_mirror(a.position)) < 0.01
		assert_true(found, "moita sem espelho: %s" % a.position)


func test_spawn_dos_herois_nos_cantos_norte() -> void:
	for m: SpawnMarker in _markers():
		if m.kind == SpawnMarker.Kind.HERO:
			var expected := SPAWN_A if m.team == GateRules.TEAM_A else _mirror(SPAWN_A)
			assert_almost_eq(m.position, expected, Vector3.ONE * 0.01)


## Uma fonte por base, do time dono, espelhada, dentro da base e da arena (#74).
func test_uma_fonte_por_base_espelhada() -> void:
	var by_team: Dictionary = {}
	for node: Node in _arena.find_children("*", "Node3D", true, false):
		if node is Fountain:
			by_team[(node as Fountain).team] = (node as Fountain).position
	assert_eq(by_team.size(), 2)
	var a: Vector3 = by_team[GateRules.TEAM_A]
	assert_almost_eq(by_team[GateRules.TEAM_B], _mirror(a), Vector3.ONE * 0.01)
	assert_lt(a.distance_to(SPAWN_A), BASE_RADIUS)
	assert_lt(a.length(), ARENA_RADIUS - 1.0)


func test_baus_de_base_a_3u_um_do_outro() -> void:
	var chests: Array[SpawnMarker] = []
	for m: SpawnMarker in _markers():
		if m.kind == SpawnMarker.Kind.CHEST and m.team != GateRules.TEAM_NEUTRAL:
			chests.append(m)
	for a: SpawnMarker in chests:
		for b: SpawnMarker in chests:
			if a != b:
				var label := "%s/%s" % [a.name, b.name]
				assert_true(a.position.distance_to(b.position) >= 3.0, label)


## Campos do centro sobre o eixo de espelho (0 e 180 graus, r ≈ 10) e raros em 90/270.
func test_campos_do_centro_no_eixo_norte_sul() -> void:
	var golems: Array[Vector3] = []
	var rares: Array[Vector3] = []
	for m: SpawnMarker in _markers():
		if m.monster_id == &"golem_t3":
			golems.append(m.position)
		elif m.kind == SpawnMarker.Kind.CHEST and m.team == GateRules.TEAM_NEUTRAL:
			rares.append(m.position)
	assert_eq(golems.size(), 2)
	for g: Vector3 in golems:
		assert_almost_eq(g.x, 0.0, 0.01)
		assert_almost_eq(absf(g.z), 10.0, 0.5)
	assert_eq(rares.size(), 4)
	var on_axis := 0
	for r: Vector3 in rares:
		if absf(r.z) < 0.01:
			on_axis += 1
			assert_almost_eq(absf(r.x), 8.0, 0.5)
	assert_eq(on_axis, 2)


func test_dois_portoes_um_por_time() -> void:
	var teams: Array[int] = []
	for node: Node in _arena.find_children("*", "StaticBody3D", true, false):
		if node is Gate:
			teams.append((node as Gate).team)
	teams.sort()
	assert_eq(teams, [GateRules.TEAM_A, GateRules.TEAM_B])
