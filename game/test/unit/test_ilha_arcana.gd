extends GutTest
## Criterio de aceite do F46 (SPEC-046 §6) pelos marcadores da cena gerada da Ilha (layout
## "Rift Medieval adaptado"): contagens do GDB, simetria por rotacao de 180 graus, spawns nos
## cantos SO/NE dentro da zona, campos do centro em 45/225, fontes, moitas e portoes.
## Colisao e tempos: test_ilha_arcana_physics. Corredores: test_arena_corridors.

const ARENA: String = "res://scenes/arena/ilha_arcana.tscn"
const SPAWN_A: Vector3 = Vector3(-24, 0, 24)
const BASE_RADIUS: float = 12.7
const ARENA_HALF: float = 40.0
const ZONE_RADIUS: float = 35.0

var _arena: Node3D


func before_all() -> void:
	_arena = (load(ARENA) as PackedScene).instantiate() as Node3D
	add_child(_arena)


func after_all() -> void:
	_arena.free()


func _rotate(v: Vector3) -> Vector3:
	return Vector3(-v.x, v.y, -v.z)


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
	# Centro: 2 Guerreiros + 2 Magos + 2 Golems; cantos (F55): 2 x (Golem de canto + 2 Lobos).
	assert_eq(_count(SpawnMarker.Kind.MONSTER, GateRules.TEAM_NEUTRAL, 2), 8)
	assert_eq(_count(SpawnMarker.Kind.MONSTER, GateRules.TEAM_NEUTRAL, 3), 4)
	assert_eq(_count(SpawnMarker.Kind.BOSS, GateRules.TEAM_NEUTRAL), 1)


## 16 T1 + 8 T2 + 2 Magos + 2 Golems + 2 Golems de canto + 4 Lobos + boss; 12 de base + 8
## laterais + 4 reforcados + 4 raros (GDB §6.2, SPEC-055 §6).
func test_total_de_35_monstros_e_28_baus() -> void:
	var monsters := 0
	var chests := 0
	for m: SpawnMarker in _markers():
		if m.kind == SpawnMarker.Kind.MONSTER or m.kind == SpawnMarker.Kind.BOSS:
			monsters += 1
		elif m.kind == SpawnMarker.Kind.CHEST:
			chests += 1
	assert_eq(monsters, 35)
	assert_eq(chests, 28)


## Raros no centro (r <= 14, dentro do anel do rio), reforcados nos cantos, comuns nas metades.
func test_baus_comuns_nas_bases_raros_no_centro_e_reforcados_nos_cantos() -> void:
	for m: SpawnMarker in _markers():
		if m.kind != SpawnMarker.Kind.CHEST:
			continue
		if m.team == GateRules.TEAM_NEUTRAL:
			var center := Vector2(m.position.x, m.position.z).length() < 14.0
			assert_eq(
				m.chest_kind, ChestRules.Kind.RARE if center else ChestRules.Kind.REINFORCED, m.name
			)
		else:
			assert_eq(m.chest_kind, ChestRules.Kind.COMMON)


func test_monstros_tem_id_do_catalogo() -> void:
	for m: SpawnMarker in _markers():
		if m.kind == SpawnMarker.Kind.MONSTER or m.kind == SpawnMarker.Kind.BOSS:
			assert_ne(Ids.to_int(m.monster_id), -1, str(m.monster_id))


## SPEC-046 §6 item 6: para cada marcador em (x, z) existe (-x, -z) com mesmo kind/tier.
func test_simetria_por_rotacao_de_180_graus() -> void:
	var markers := _markers()
	for m: SpawnMarker in markers:
		var twin := _rotate(m.position)
		var found := false
		for other: SpawnMarker in markers:
			if (
				other.position.distance_to(twin) < 0.01
				and other.kind == m.kind
				and other.tier == m.tier
				and other.chest_kind == m.chest_kind
			):
				found = true
		assert_true(found, "sem par por rotacao: %s em %s" % [m.name, m.position])


## Todo marcador dentro do quadrado jogavel (SPEC-046 §1).
func test_marcadores_dentro_do_quadrado() -> void:
	for m: SpawnMarker in _markers():
		var reach := maxf(absf(m.position.x), absf(m.position.z))
		assert_lt(reach, ARENA_HALF - 1.0, "%s fora do quadrado" % m.name)


## Moitas tambem por rotacao: a regra do mato (F32) e geometria de jogo. 6 = 2 de ponte + 2 de
## lagoa + 2 do centro (SPEC-046 §2.7).
func test_seis_moitas_por_rotacao() -> void:
	var areas: Array[Area3D] = []
	for node: Node in _arena.find_children("*", "Area3D", true, false):
		if node.is_in_group(&"tall_grass"):
			areas.append(node as Area3D)
	assert_eq(areas.size(), 6)
	for a: Area3D in areas:
		var found := false
		for b: Area3D in areas:
			found = found or b.position.distance_to(_rotate(a.position)) < 0.01
		assert_true(found, "moita sem par: %s" % a.position)


## Spawns em (-24, +24) e (+24, -24): a 33,9 u do centro, dentro da zona de 35 u (ADR-0009).
func test_spawn_dos_herois_nos_cantos_so_e_ne_dentro_da_zona() -> void:
	for m: SpawnMarker in _markers():
		if m.kind == SpawnMarker.Kind.HERO:
			var expected := SPAWN_A if m.team == GateRules.TEAM_A else _rotate(SPAWN_A)
			assert_almost_eq(m.position, expected, Vector3.ONE * 0.01)
			assert_lt(m.position.length(), ZONE_RADIUS)


## Uma fonte por base, do time dono, por rotacao, dentro da base e da zona (#74).
func test_uma_fonte_por_base_por_rotacao() -> void:
	var by_team: Dictionary = {}
	for node: Node in _arena.find_children("*", "Node3D", true, false):
		if node is Fountain:
			by_team[(node as Fountain).team] = (node as Fountain).position
	assert_eq(by_team.size(), 2)
	var a: Vector3 = by_team[GateRules.TEAM_A]
	assert_almost_eq(by_team[GateRules.TEAM_B], _rotate(a), Vector3.ONE * 0.01)
	assert_lt(a.distance_to(SPAWN_A), BASE_RADIUS)
	assert_lt(a.length(), ZONE_RADIUS)


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


## Campos do centro em 45 e 225 graus (r ≈ 10), equidistantes das pontes de 135/315; raros em
## 45/225 (r 12,5) e 90/270 (r 8) — SPEC-046 §2.6.
func test_campos_do_centro_em_45_e_225_graus() -> void:
	var golems: Array[Vector3] = []
	var rares: Array[Vector3] = []
	for m: SpawnMarker in _markers():
		if m.monster_id == &"golem_t3":
			golems.append(m.position)
		elif m.kind == SpawnMarker.Kind.CHEST and m.chest_kind == ChestRules.Kind.RARE:
			rares.append(m.position)
	assert_eq(golems.size(), 2)
	for g: Vector3 in golems:
		# Azimute 45 = (-7,07, -7,07); 225 = (+7,07, +7,07): x = z e r 10.
		assert_almost_eq(g.x, g.z, 0.01)
		assert_almost_eq(g.length(), 10.0, 0.5)
	assert_eq(rares.size(), 4)
	var on_axis := 0
	for r: Vector3 in rares:
		if absf(r.z) < 0.01:
			on_axis += 1
			assert_almost_eq(absf(r.x), 8.0, 0.5)
		else:
			assert_almost_eq(r.length(), 12.5, 0.5)
	assert_eq(on_axis, 2)


func test_dois_portoes_um_por_time() -> void:
	var teams: Array[int] = []
	for node: Node in _arena.find_children("*", "StaticBody3D", true, false):
		if node is Gate:
			teams.append((node as Gate).team)
	teams.sort()
	assert_eq(teams, [GateRules.TEAM_A, GateRules.TEAM_B])
