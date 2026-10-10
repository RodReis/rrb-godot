extends GutTest
## Integracao headless: arena + SpawnDirector + Cavaleiro (time A) + heroi parado do time B
## (no lugar do bot, F12). Monstros, XP, nivel, pontos e catch-up (GDB §3, §5).

const ARENA: String = "res://scenes/arena/arena.tscn"
const KNIGHT: String = "res://scenes/heroes/knight.tscn"
const DT: float = 1.0 / 30.0
## Spawn -> portao (SPEC-007 §2).
const BASE_RADIUS: float = 12.7

var _director: SpawnDirector
var _hero: Hero
var _rival: Hero
var _tick: int = 100


func before_each() -> void:
	add_child_autofree((load(ARENA) as PackedScene).instantiate())
	_director = SpawnDirector.new()
	add_child_autofree(_director)
	_hero = _spawn_hero(1, GateRules.TEAM_A, 1)
	_rival = _spawn_hero(2, GateRules.TEAM_B, 1)


func _spawn_hero(id: int, team: int, level: int) -> Hero:
	var hero := (load(KNIGHT) as PackedScene).instantiate() as Hero
	hero.name = str(id)
	hero.team = team
	hero.level = level
	add_child_autofree(hero)
	return hero


func _monsters() -> Array[Monster]:
	var result: Array[Monster] = []
	for node: Node in _director.get_children():
		if node is Monster:
			result.append(node as Monster)
	return result


## Monstros dos marcadores da base do [param team] (sem os campos laterais da metade, F36).
func _base_monsters(team: int) -> Array[Monster]:
	var spawn := Vector3(-24, 0, 24) if team == GateRules.TEAM_A else Vector3(24, 0, -24)
	var result: Array[Monster] = []
	for node: Node in get_tree().get_nodes_in_group(SpawnMarker.GROUP):
		var marker := node as SpawnMarker
		if marker.kind != SpawnMarker.Kind.MONSTER or marker.team != team:
			continue
		if marker.global_position.distance_to(spawn) > BASE_RADIUS:
			continue
		for monster: Monster in _monsters():
			if monster.global_position.is_equal_approx(marker.global_position):
				result.append(monster)
	return result


## Golpe letal do [param hero] e o tick dele em que o XP entra.
func _kill(monster: Monster, hero: Hero) -> void:
	_tick += 1
	var effect := HitEffect.new(monster.hp)
	effect.attacker_id = hero.peer_id
	monster.receive_hit(_tick, HitLedger.source_key(hero.peer_id, HitLedger.Slot.BASIC), effect)
	hero._rollback_tick(DT, _tick, true)


func test_um_monstro_por_marcador_na_quantidade_do_gdb() -> void:
	var counts: Dictionary = {}
	for monster: Monster in _monsters():
		counts[monster.data.id] = counts.get(monster.data.id, 0) + 1
		assert_eq(monster.hp, roundi(monster.data.hp), monster.name)
	for monster: Monster in _monsters():
		assert_eq(counts[monster.data.id], monster.data.count, monster.data.id)
	assert_eq(_monsters().size(), 28)


func test_uid_negativo_e_unico() -> void:
	var seen: Dictionary = {}
	for monster: Monster in _monsters():
		assert_lt(monster.uid, 0)
		assert_false(seen.has(monster.uid))
		seen[monster.uid] = true


func test_farm_completo_de_uma_base_da_225_xp_e_nivel_3() -> void:
	var base := _base_monsters(GateRules.TEAM_A)
	assert_eq(base.size(), 5)
	for monster: Monster in base:
		_kill(monster, _hero)
	assert_eq(_hero.xp, 225)
	assert_eq(_hero.level, 3)
	assert_eq(SkillRules.free_points(_hero.level, _hero.ranks), 2)
	assert_eq(_hero.attributes.max_hp, 600 + 45 * 2)


## Sem o SpawnDirector.update passar dos 90 s, morto continua morto (respawn: test_monster_respawn).
func test_monstro_morto_nao_da_xp_de_novo_nem_volta() -> void:
	var monster := _base_monsters(GateRules.TEAM_A)[0]
	_kill(monster, _hero)
	var xp := _hero.xp
	_kill(monster, _hero)
	assert_eq(_hero.xp, xp)
	assert_false(monster.is_alive())


func test_ressimular_o_mesmo_golpe_nao_duplica_dano() -> void:
	var monster := _base_monsters(GateRules.TEAM_A)[0]
	var source := HitLedger.source_key(1, HitLedger.Slot.BASIC)
	monster.receive_hit(10, source, HitEffect.new(40))
	monster.receive_hit(10, source, HitEffect.new(40))
	assert_eq(monster.hp, roundi(monster.data.hp) - 40)


func test_catch_up_mais_25_por_cento_dois_niveis_atras() -> void:
	_rival.xp = 225
	_rival._refresh_attributes()
	assert_eq(_rival.level, 3)
	var t1: Monster = null
	for monster: Monster in _base_monsters(GateRules.TEAM_A):
		if monster.data.tier == MonsterData.Tier.T1:
			t1 = monster
	_kill(t1, _hero)
	assert_eq(_hero.xp, roundi(35 * 1.25))


func test_monstro_golpeia_heroi_pelo_ledger() -> void:
	var monster := _base_monsters(GateRules.TEAM_A)[0]
	_hero.global_position = monster.global_position + Vector3(1.0, 0.0, 0.0)
	monster._on_network_tick(DT, _tick)
	assert_eq(monster.state, MonsterRules.State.CHASE)
	var hp := _hero.hp
	_hero._rollback_tick(DT, _tick + 1, true)
	var expected := CombatRules.mitigated(roundi(monster.data.damage), _hero.attributes.defense)
	assert_eq(_hero.hp, hp - expected)


func test_heroi_morto_nao_e_alvo() -> void:
	var monster := _base_monsters(GateRules.TEAM_A)[0]
	_hero.global_position = monster.global_position + Vector3(1.0, 0.0, 0.0)
	_hero.hp = 0
	monster._on_network_tick(DT, _tick)
	assert_eq(monster.state, MonsterRules.State.IDLE)


func test_leash_volta_com_hp_cheio() -> void:
	var monster := _base_monsters(GateRules.TEAM_A)[0]
	_hero.global_position = monster.global_position + Vector3(3.0, 0.0, 0.0)
	monster._on_network_tick(DT, _tick)
	monster.receive_hit(1, 99, HitEffect.new(20))
	monster.global_position += Vector3(monster.data.leash_range + 1.0, 0.0, 0.0)
	monster._on_network_tick(DT, _tick + 1)
	assert_eq(monster.state, MonsterRules.State.RESET)
	assert_eq(monster.hp, roundi(monster.data.hp))


func test_aprender_gasta_ponto_no_tick_do_pedido() -> void:
	for monster: Monster in _base_monsters(GateRules.TEAM_A):
		_kill(monster, _hero)
	_hero.input.learn = SkillRules.SLOT_E
	_hero._rollback_tick(DT, _tick + 1, true)
	assert_eq(_hero.ranks, Vector3i(1, 1, 0))
	_hero.input.learn = PlayerInput.LEARN_NONE
	_hero._rollback_tick(DT, _tick + 2, true)
	assert_eq(_hero.ranks, Vector3i(1, 1, 0))


func test_learn_fora_da_faixa_e_ignorado() -> void:
	_hero.xp = 225
	_hero.input.learn = 42
	_hero._rollback_tick(DT, _tick, true)
	assert_eq(_hero.ranks, Vector3i(1, 0, 0))
