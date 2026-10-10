extends GutTest
## Confere os .tres de shared/data contra o GDB (ADR-0004) e contra a tabela de Ids.

const DATA_DIR: String = "res://shared/data"
const EPS: float = 0.0001

## id -> [hp, def, atk, int, agi, agi_pct] (GDB §6.1).
const ITEMS: Dictionary = {
	&"sword_t1": [0, 0, 12, 0, 0, 0],
	&"sword_t2": [0, 0, 25, 0, 0, 0],
	&"sword_t3_epic": [0, 0, 45, 0, 0, 0],
	&"guard_helm_t1": [0, 8, 0, 0, 0, 0],
	&"guard_helm_t2": [0, 15, 0, 5, 0, 0],
	&"guard_helm_t3": [0, 25, 0, 12, 0, 0],
	&"guard_chest_t1": [50, 5, 0, 0, 0, 0],
	&"guard_chest_t2": [110, 12, 0, 0, 0, 0],
	&"guard_chest_t3": [220, 22, 0, 0, 0, 0],
	&"guard_boots_t1": [0, 0, 0, 0, 0, 0.05],
	&"guard_boots_t2": [0, 5, 0, 0, 0, 0.10],
	&"guard_boots_t3": [0, 10, 0, 0, 0, 0.16],
	&"hunter_helm_t1": [0, 0, 4, 0, 0, 0],
	&"hunter_helm_t2": [0, 0, 8, 0, 6, 0],
	&"hunter_helm_t3": [0, 0, 15, 0, 12, 0],
	&"hunter_chest_t1": [35, 0, 5, 0, 0, 0],
	&"hunter_chest_t2": [75, 0, 12, 0, 0, 0],
	&"hunter_chest_t3": [140, 0, 22, 0, 0, 0],
	&"hunter_boots_t1": [0, 0, 0, 0, 0, 0.08],
	&"hunter_boots_t2": [0, 0, 4, 0, 0, 0.15],
	&"hunter_boots_t3": [0, 0, 8, 0, 0, 0.24],
}

## id -> [tier, qtd, hp, dano, intervalo, xp, comum, raro, epico] (GDB §5.1; mago: PI 2026-10-09).
const MONSTERS: Dictionary = {
	&"skeleton_t1": [MonsterData.Tier.T1, 16, 160, 14, 1.2, 35, 0.2, 0, 0],
	&"skeleton_warrior_t2": [MonsterData.Tier.T2, 8, 360, 28, 1.1, 85, 1, 0, 0],
	&"skeleton_mage_t2": [MonsterData.Tier.T2, 2, 260, 38, 1.5, 80, 0.35, 0.65, 0],
	&"golem_t3": [MonsterData.Tier.T3, 2, 680, 50, 1.6, 190, 0, 1, 0],
	&"skeleton_king_boss": [MonsterData.Tier.BOSS, 1, 2400, 75, 1.4, 550, 0, 0, 1],
}

var _by_id: Dictionary = {}


func before_all() -> void:
	for path: String in _tres_files(DATA_DIR):
		_by_id[StringName(path.get_file().get_basename())] = load(path)


func _tres_files(dir: String) -> PackedStringArray:
	var found := PackedStringArray()
	for sub: String in DirAccess.get_directories_at(dir):
		found.append_array(_tres_files(dir.path_join(sub)))
	for file: String in DirAccess.get_files_at(dir):
		if file.ends_with(".tres"):
			found.append(dir.path_join(file))
	return found


func _hero(id: StringName) -> HeroData:
	return _by_id[id] as HeroData


func test_todo_heroi_item_e_monstro_tem_id_na_tabela() -> void:
	var expected: int = 0
	for file_id: StringName in _by_id:
		var res: Resource = _by_id[file_id]
		if res is HeroData or res is ItemData or res is MonsterData:
			expected += 1
			assert_eq(res.get(&"id"), file_id, "id difere do nome do arquivo")
			assert_ne(Ids.to_int(file_id), -1, "sem id em Ids: %s" % file_id)
	assert_eq(Ids.ALL.size(), expected, "Ids.ALL tem id sem .tres")


func test_cavaleiro_no_nivel_10_bate_com_o_gdb() -> void:
	var a := Stats.attributes(_hero(&"knight"), 10, [], [])
	assert_eq(a.max_hp, 1005)
	assert_almost_eq(a.defense, 57.0, EPS)
	assert_almost_eq(a.attack, 71.5, EPS)
	assert_almost_eq(a.intelligence, 19.0, EPS)
	assert_almost_eq(a.agility, 19.0, EPS)
	assert_almost_eq(_hero(&"knight").base_move_speed, 5.8, EPS)


func test_arqueira_no_nivel_10_bate_com_o_gdb() -> void:
	var a := Stats.attributes(_hero(&"ranger"), 10, [], [])
	assert_eq(a.max_hp, 632)
	assert_almost_eq(a.defense, 20.8, EPS)
	assert_almost_eq(a.attack, 100.0, EPS)
	assert_almost_eq(a.intelligence, 28.5, EPS)
	assert_almost_eq(a.agility, 44.8, EPS)
	assert_almost_eq(_hero(&"ranger").base_move_speed, 6.2, EPS)


func test_habilidades_do_cavaleiro() -> void:
	var k := _hero(&"knight")
	assert_almost_eq(k.basic_attack.arc_degrees, 70.0, EPS)
	assert_almost_eq(k.basic_attack.attack_range, 2.2, EPS)
	assert_eq(k.skill_q.base_amount, PackedFloat64Array([50, 80, 110, 140, 170]))
	assert_almost_eq(k.skill_q.attack_ratio, 0.75, EPS)
	assert_eq(k.skill_e.base_amount, PackedFloat64Array([120, 170, 220, 270, 320]))
	assert_almost_eq(k.skill_e.max_hp_ratio, 0.15, EPS)
	assert_eq(k.skill_r.cooldown, PackedFloat64Array([50, 42]))
	assert_eq(k.skill_r.stun_duration, PackedFloat64Array([1.2, 1.6]))
	assert_eq(k.skill_r.required_hero_level, PackedInt32Array([6, 10]))


func test_habilidades_da_arqueira() -> void:
	var r := _hero(&"ranger")
	assert_almost_eq(r.basic_attack.speed, 20.0, EPS)
	assert_almost_eq(r.skill_q.pierce_decay, 0.15, EPS)
	assert_almost_eq(r.skill_q.pierce_min, 0.4, EPS)
	assert_eq(r.skill_e.cooldown, PackedFloat64Array([9.0, 8.2, 7.4, 6.6, 5.8]))
	assert_true(r.skill_e.resets_basic_attack)
	assert_eq(r.skill_r.pulse_count, 6)
	assert_eq(r.skill_r.base_amount, PackedFloat64Array([30, 48]))


func test_itens_batem_com_o_gdb() -> void:
	for id: StringName in ITEMS:
		var item := _by_id[id] as ItemData
		var v: Array = ITEMS[id]
		assert_not_null(item, id)
		assert_eq([item.hp, item.defense, item.attack], [float(v[0]), float(v[1]), float(v[2])], id)
		assert_eq([item.intelligence, item.agility], [float(v[3]), float(v[4])], id)
		assert_almost_eq(item.agility_pct, float(v[5]), EPS, id)


func test_arma_epica_tem_furia() -> void:
	var epic := _by_id[&"sword_t3_epic"] as ItemData
	assert_eq(epic.passive, &"fury")
	assert_almost_eq(epic.passive_value, 0.06, EPS)


func test_bonus_de_conjunto() -> void:
	var guard := _by_id[&"guard_bonus"] as SetBonusData
	var hunter := _by_id[&"hunter_bonus"] as SetBonusData
	assert_eq([guard.set_id, hunter.set_id], [&"guard", &"hunter"])
	assert_eq([guard.pieces_required, hunter.pieces_required], [3, 3])
	assert_almost_eq(guard.max_hp_pct, 0.15, EPS)
	assert_almost_eq(guard.defense, 10.0, EPS)
	assert_almost_eq(hunter.attack_speed_pct, 0.10, EPS)
	assert_almost_eq(hunter.move_speed_pct, 0.08, EPS)


func test_monstros_batem_com_o_gdb() -> void:
	for id: StringName in MONSTERS:
		var m := _by_id[id] as MonsterData
		var v: Array = MONSTERS[id]
		assert_eq([m.tier, m.count, m.xp], [v[0], v[1], v[5]], id)
		assert_eq([m.hp, m.damage, m.attack_interval], [float(v[2]), float(v[3]), float(v[4])], id)
		assert_eq(
			[m.drop_common_chance, m.drop_rare_chance, m.drop_epic_chance],
			[float(v[6]), float(v[7]), float(v[8])],
			id
		)
	assert_almost_eq((_by_id[&"skeleton_mage_t2"] as MonsterData).ranged_range, 7.0, EPS)


func test_ia_dos_monstros_nao_boss() -> void:
	# Aggro, leash, velocidade e alcance: proposta aprovada pelo PI em 2026-10-09 (F9).
	for id: StringName in [
		&"skeleton_t1", &"skeleton_warrior_t2", &"skeleton_mage_t2", &"golem_t3"
	]:
		var m := _by_id[id] as MonsterData
		assert_eq([m.aggro_range, m.leash_range, m.move_speed], [6.0, 10.0, 4.0], id)
		assert_almost_eq(m.melee_range, 1.8, EPS, id)
	var golem := _by_id[&"golem_t3"] as MonsterData
	assert_true(golem.area_attack)
	assert_almost_eq(golem.area_radius, 2.5, EPS)
	assert_eq(golem.knockback, 0.0)


func test_ia_do_rei_esqueleto() -> void:
	# Proposta aprovada pelo PI em 2026-10-09 (F11): nao sai da cratera, golpe em area empurra.
	var king := _by_id[&"skeleton_king_boss"] as MonsterData
	assert_eq([king.aggro_range, king.leash_range, king.move_speed], [7.0, 8.0, 3.5])
	assert_almost_eq(king.melee_range, 2.2, EPS)
	assert_true(king.area_attack)
	assert_almost_eq(king.area_radius, 3.0, EPS)
	assert_almost_eq(king.knockback, 2.5, EPS)


func test_curva_de_xp() -> void:
	# Nivel 3 em 225 (PI 2026-10-09): farm de uma base = 4 x 35 + 85 (GDB §5.2).
	var curve := _by_id[&"xp_table"] as XpCurve
	assert_eq(
		curve.cumulative_xp, PackedInt32Array([0, 90, 225, 440, 740, 1160, 1720, 2440, 3340, 4440])
	)
	assert_eq(curve.catch_up_level_gap, 2)
	assert_almost_eq(curve.catch_up_bonus, 0.25, EPS)
	assert_eq(curve.typical_q_rank, PackedInt32Array([1, 1, 2, 2, 3, 3, 4, 4, 5, 5]))
	assert_eq(curve.typical_e_rank, PackedInt32Array([0, 1, 1, 2, 2, 2, 2, 3, 3, 3]))
	assert_eq(curve.typical_r_rank, PackedInt32Array([0, 0, 0, 0, 0, 1, 1, 1, 1, 2]))


func test_ritmo_da_partida() -> void:
	var rules := _by_id[&"match_pacing"] as MatchRules
	assert_eq([rules.phase1_duration, rules.max_match_duration], [300.0, 600.0])
	assert_eq(rules.transition_duration, 5.0)
	assert_eq([rules.boss_warning_time, rules.boss_spawn_time], [180.0, 210.0])
	assert_eq([rules.respawn_phase1, rules.respawn_phase2, rules.respawn_off_at], [8.0, 6.0, 240.0])
	# Monstro nao-boss renasce 90 s depois de morrer, so na fase 1 (PI 2026-10-10, F36).
	assert_eq(rules.monster_respawn_phase1, 90.0)
	assert_eq(
		[rules.phase1_kill_xp, rules.phase2_kill_xp_base, rules.phase2_kill_xp_per_level],
		[80, 150, 20]
	)
	assert_eq(rules.kill_goal, 5)
	assert_eq(rules.zone_times, PackedFloat64Array([0, 60, 120, 180, 240, 300]))
	assert_eq(rules.zone_radius, PackedFloat64Array([35, 26, 17.5, 8.75, 3.5, 0]))
	assert_eq(rules.zone_damage_pct, PackedFloat64Array([0.01, 0.02, 0.03, 0.04, 0.05, 0.05]))
	# Aos 10:00 a resolucao e imediata (PI 2026-10-10): sem colapso progressivo.
	assert_false("zone_collapse_doubling" in rules)
	assert_eq([rules.common_chests_per_base, rules.rare_chests], [6, 4])
	assert_eq([rules.common_chest_item_chance, rules.common_chest_heal_chance], [0.7, 0.3])
	assert_eq(
		[
			rules.rare_chest_rare_chance,
			rules.rare_chest_common_chance,
			rules.rare_chest_epic_chance
		],
		[0.65, 0.25, 0.1]
	)
	assert_eq([rules.heal_amount, rules.swap_hold_time], [120.0, 0.4])
	# Abrir bau: toque em F a ate 1,5 u (PI 2026-10-09, F10).
	assert_eq(rules.chest_interact_range, 1.5)


func test_catalogo_tem_cada_item_e_bonus_uma_vez() -> void:
	var catalog := _by_id[&"catalog"] as ItemCatalog
	var expected: Array[StringName] = []
	for file_id: StringName in _by_id:
		if _by_id[file_id] is ItemData:
			expected.append(file_id)
	var got: Array[StringName] = []
	for item: ItemData in catalog.items:
		got.append(item.id)
	expected.sort()
	got.sort()
	assert_eq(got, expected)
	assert_eq(catalog.set_bonuses.size(), 2)
	assert_eq(catalog.find(Ids.to_int(&"guard_helm_t2")).id, &"guard_helm_t2")
	assert_null(catalog.find(Ids.to_int(&"knight")))
	assert_null(catalog.find(-1))
