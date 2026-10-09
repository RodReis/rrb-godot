extends GutTest
## Integracao headless: arena + SpawnDirector + Cavaleiro. Rei Esqueleto (GDB §5.1): surge no
## marcador BOSS, golpe em area com empurrao pelo ledger, 550 XP, e ao morrer vira um bau
## epico no lugar (PI 2026-10-09).

const ARENA: String = "res://scenes/arena/arena.tscn"
const KNIGHT: String = "res://scenes/heroes/knight.tscn"
const CATALOG: String = "res://shared/data/items/catalog.tres"
const DT: float = 1.0 / 30.0

var _director: SpawnDirector
var _hero: Hero
var _tick: int = 100
var _killed_by: Array[int] = []


func before_each() -> void:
	_killed_by = []
	add_child_autofree((load(ARENA) as PackedScene).instantiate())
	_director = SpawnDirector.new()
	_director.loot_seed = 99
	add_child_autofree(_director)
	_director.boss_killed.connect(func(peer: int) -> void: _killed_by.append(peer))
	_hero = (load(KNIGHT) as PackedScene).instantiate() as Hero
	_hero.name = "1"
	_hero.team = GateRules.TEAM_A
	add_child_autofree(_hero)


func _boss() -> Monster:
	return _director.get_node_or_null(SpawnDirector.BOSS_NAME) as Monster


func _boss_marker() -> SpawnMarker:
	for node: Node in get_tree().get_nodes_in_group(SpawnMarker.GROUP):
		if (node as SpawnMarker).kind == SpawnMarker.Kind.BOSS:
			return node as SpawnMarker
	return null


func _kill_boss() -> void:
	var boss := _boss()
	_tick += 1
	var effect := HitEffect.new(boss.hp)
	effect.attacker_id = _hero.peer_id
	boss.receive_hit(_tick, HitLedger.source_key(_hero.peer_id, HitLedger.Slot.BASIC), effect)
	_hero._rollback_tick(DT, _tick, true)


func _mesh_span(root: Node, prefix: String) -> Vector2:
	var span := Vector2(INF, -INF)
	for node: Node in root.find_children(prefix + "*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		var box := mi.global_transform * mi.get_aabb()
		span = Vector2(minf(span.x, box.position.y), maxf(span.y, box.end.y))
	return span


func test_rei_maior_que_o_heroi_com_a_coroa_na_cabeca() -> void:
	# Alinhamento (PRD §11): Esqueleto a 1,35 (~3 u) e coroa (art/monsters/crown.blend) no osso
	# head, apoiada no alto do cranio.
	_director.spawn_boss()
	await wait_process_frames(2)
	var head := _mesh_span(_boss(), "Skeleton_Minion_Head")
	var crown := _mesh_span(_boss(), "Crown")
	gut.p("cabeca %.2f..%.2f u, coroa %.2f..%.2f u" % [head.x, head.y, crown.x, crown.y])
	assert_between(head.y, 2.7, 3.2)
	assert_between(crown.x, head.y - 0.25, head.y)
	assert_gt(crown.y, head.y)


func test_nao_existe_antes_de_3_30() -> void:
	assert_null(_boss())


func test_surge_no_marcador_com_hp_cheio() -> void:
	_director.spawn_boss()
	var boss := _boss()
	assert_not_null(boss)
	assert_eq(boss.data.id, &"skeleton_king_boss")
	assert_eq(boss.hp, 2400)
	assert_true(boss.global_position.is_equal_approx(_boss_marker().global_position))
	assert_lt(boss.uid, 0)


func test_surgir_de_novo_nao_duplica() -> void:
	_director.spawn_boss()
	_director.spawn_boss()
	var bosses := 0
	for node: Node in _director.get_children():
		if node is Monster and (node as Monster).data.tier == MonsterData.Tier.BOSS:
			bosses += 1
	assert_eq(bosses, 1)


func test_cliente_que_entra_depois_da_morte_nao_cria_boss_vivo() -> void:
	_director._boss_defeated(0, 1, -99, Vector3.ZERO)
	_director.spawn_boss()
	assert_null(_boss())
	assert_eq((_director.get_node(SpawnDirector.BOSS_CHEST_NAME) as Chest).uid, -99)


func test_golpe_em_area_fere_e_empurra_pelo_ledger() -> void:
	_director.spawn_boss()
	var boss := _boss()
	_hero.global_position = boss.global_position + Vector3(2.0, 0.0, 0.0)
	var hp := _hero.hp
	boss._on_network_tick(DT, _tick)
	_hero._rollback_tick(DT, _tick + 1, true)
	var expected := CombatRules.mitigated(75, _hero.attributes.defense)
	assert_eq(_hero.hp, hp - expected)
	# Empurrao e movimento no estado de rollback (o cliente ressimula), nao salto de 2,5 u.
	var first_step := (_hero.global_position - boss.global_position).length() - 2.0
	assert_gt(first_step, 0.0)
	assert_lt(first_step, boss.data.knockback / 2.0)
	assert_gt(_hero.knockback_ticks, 0)
	_run_hero(_hero.knockback_ticks + 1)
	# Nesta direcao a geometria da cratera para o heroi a ~4,47 u (move_and_slide).
	var dist := (_hero.global_position - boss.global_position).length()
	assert_between(dist, 2.0 + boss.data.knockback * 0.9, 2.0 + boss.data.knockback + 0.01)
	assert_eq(_hero.knockback_ticks, 0)


func _run_hero(ticks: int) -> void:
	for i: int in ticks:
		_tick += 1
		_hero._rollback_tick(DT, _tick + 1, true)


func test_morte_da_550_xp_e_avisa_quem_matou() -> void:
	_director.spawn_boss()
	var xp := _hero.xp
	_kill_boss()
	assert_eq(_hero.xp, xp + 550)
	assert_eq(_killed_by, [_hero.peer_id])
	assert_false(_boss().is_alive())


func test_morte_vira_bau_epico_no_lugar() -> void:
	_director.spawn_boss()
	var where := _boss().global_position
	_kill_boss()
	var chest := _director.get_node_or_null(SpawnDirector.BOSS_CHEST_NAME) as Chest
	assert_not_null(chest)
	assert_true(chest.epic)
	assert_false(chest.opened)
	assert_true(chest.global_position.is_equal_approx(where))
	var item := (load(CATALOG) as ItemCatalog).find(chest.drop)
	assert_eq(item.rarity, ItemData.Rarity.EPIC)
