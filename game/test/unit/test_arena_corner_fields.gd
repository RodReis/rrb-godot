extends GutTest
## Campos de canto (SPEC-055, ADR-0011) na Ilha: NO (-27,5, -27,5) e SE por rotacao, neutros,
## Golem de canto + 2 Lobos + 2 Baus Reforcados cada; folgas do §2 sobre a cena gerada; heroi no
## meio do corredor N/O nao puxa os lobos (aggro 3 u), o golem acorda a 4 u e o leash de 10 u
## devolve o monstro com HP cheio. Contagens totais e rotacao: test_ilha_arcana.

const ARENA: String = "res://scenes/arena/ilha_arcana.tscn"
const KNIGHT: String = "res://scenes/heroes/knight.tscn"
const DT: float = 1.0 / 30.0
const CORNER_NO: Vector3 = Vector3(-27.5, 0, -27.5)
## Ajuste de visual permitido pela spec (§2): ate 1 u por posicao.
const FIELD_REACH: float = 3.5
const LAGOON_A: Vector3 = Vector3(-26, 0, -18)
const LAGOON_RADIUS: float = 5.0
const LAGOON_GAP: float = 2.0
## Bandas TOP (SPEC-046 §2.3): O x -40..-32, N z -40..-32; meio das bandas em -36.
const BAND_EDGE: float = -32.0
const BAND_MIDDLE: float = -36.0
const LAGOON_GRASS_A: Vector3 = Vector3(-19, 0, -29)

var _director: SpawnDirector
var _hero: Hero
var _tick: int = 100


func before_each() -> void:
	add_child_autofree((load(ARENA) as PackedScene).instantiate())
	_director = SpawnDirector.new()
	add_child_autofree(_director)
	_hero = (load(KNIGHT) as PackedScene).instantiate() as Hero
	_hero.name = "1"
	_hero.team = GateRules.TEAM_A
	add_child_autofree(_hero)


func _markers() -> Array[SpawnMarker]:
	var result: Array[SpawnMarker] = []
	for node: Node in get_tree().get_nodes_in_group(SpawnMarker.GROUP):
		result.append(node as SpawnMarker)
	return result


## Monstros e baus de canto, do campo de centro [param center].
func _corner(center: Vector3) -> Array[SpawnMarker]:
	var result: Array[SpawnMarker] = []
	for m: SpawnMarker in _markers():
		if m.kind != SpawnMarker.Kind.HERO and m.position.distance_to(center) <= FIELD_REACH:
			result.append(m)
	return result


func _monsters(id: StringName) -> Array[Monster]:
	var result: Array[Monster] = []
	for node: Node in _director.get_children():
		if node is Monster and (node as Monster).data.id == id:
			result.append(node as Monster)
	return result


## Monstros do canto NO de [param id].
func _no(id: StringName) -> Array[Monster]:
	return _monsters(id).filter(
		func(m: Monster) -> bool: return m.global_position.distance_to(CORNER_NO) <= FIELD_REACH
	)


func _think(monster: Monster) -> void:
	_tick += 1
	monster._on_network_tick(DT, _tick)


func test_cada_canto_tem_golem_dois_lobos_e_dois_reforcados_neutros() -> void:
	for center: Vector3 in [CORNER_NO, -CORNER_NO]:
		var golems := 0
		var wolves := 0
		var chests := 0
		for m: SpawnMarker in _corner(center):
			assert_eq(m.team, GateRules.TEAM_NEUTRAL, m.name)
			if m.monster_id == &"golem_corner":
				golems += 1
				assert_almost_eq(m.position, center, Vector3.ONE * 1.0)
			elif m.monster_id == &"wolf_t2":
				wolves += 1
			elif m.kind == SpawnMarker.Kind.CHEST:
				assert_eq(m.chest_kind, ChestRules.Kind.REINFORCED, m.name)
				chests += 1
		assert_eq([golems, wolves, chests], [1, 2, 2], str(center))


## Folgas do §2: >= 2 u da borda da lagoa; o aggro dos lobos nao alcanca as bandas do corredor.
func test_folgas_do_campo_de_canto() -> void:
	var wolf := load("res://shared/data/monsters/wolf_t2.tres") as MonsterData
	for flip: float in [1.0, -1.0]:
		for m: SpawnMarker in _corner(CORNER_NO * flip):
			var gap := m.position.distance_to(LAGOON_A * flip) - LAGOON_RADIUS
			assert_gt(gap, LAGOON_GAP, "%s perto da lagoa" % m.name)
			if m.monster_id == &"wolf_t2":
				var to_band := minf(m.position.x * flip, m.position.z * flip) - BAND_EDGE
				assert_gt(to_band, wolf.aggro_range, "%s puxa quem passa no corredor" % m.name)


## Moita de lagoa movida para (-19, -29) (§2), fora da banda N (4 x 4 u: borda em z -31).
func test_moita_da_lagoa_movida() -> void:
	var found := 0
	for node: Node in get_tree().get_nodes_in_group(&"tall_grass"):
		var at := (node as Node3D).global_position
		for flip: float in [1.0, -1.0]:
			if at.distance_to(LAGOON_GRASS_A * flip) < 1.01:
				found += 1
				assert_gt(at.z * flip - 2.0, BAND_EDGE)
	assert_eq(found, 2)


## Heroi no meio das bandas N e O, no ponto mais perto do campo: nenhum lobo acorda.
func test_heroi_no_corredor_nao_puxa_os_lobos() -> void:
	for at: Vector3 in [Vector3(-27.5, 0, BAND_MIDDLE), Vector3(BAND_MIDDLE, 0, -27.5)]:
		_hero.global_position = at
		for wolf: Monster in _no(&"wolf_t2"):
			_think(wolf)
			assert_eq(wolf.state, MonsterRules.State.IDLE, "%s em %s" % [wolf.name, at])


## Golem de canto acorda a 4 u (e nao antes).
func test_golem_de_canto_acorda_a_4_u() -> void:
	var golem := _no(&"golem_corner")[0]
	var toward_field := Vector3(1, 0, 1).normalized()
	_hero.global_position = golem.global_position + toward_field * 4.3
	_think(golem)
	assert_eq(golem.state, MonsterRules.State.IDLE)
	_hero.global_position = golem.global_position + toward_field * 3.9
	_think(golem)
	assert_eq(golem.state, MonsterRules.State.CHASE)


## Leash de 10 u: passou, volta ao campo e regenera o HP.
func test_leash_devolve_lobo_e_golem_com_hp_cheio() -> void:
	for id: StringName in [&"wolf_t2", &"golem_corner"]:
		var monster := _no(id)[0]
		_hero.global_position = monster.global_position + Vector3(1.0, 0.0, 1.0)
		_think(monster)
		assert_eq(monster.state, MonsterRules.State.CHASE, id)
		monster.receive_hit(1, 99, HitEffect.new(20))
		monster.global_position += Vector3(monster.data.leash_range + 1.0, 0.0, 0.0)
		_think(monster)
		assert_eq(monster.state, MonsterRules.State.RESET, id)
		assert_eq(monster.hp, roundi(monster.data.hp), id)
