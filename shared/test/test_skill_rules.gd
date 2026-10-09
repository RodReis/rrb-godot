extends GutTest
## Numeros das habilidades do Cavaleiro (GDB §4.1) a partir de knight.tres.

const KNIGHT: String = "res://shared/data/heroes/knight.tres"
const XP: String = "res://shared/data/rules/xp_table.tres"
const TICKRATE: int = 30
const EPS: float = 0.0001

var _knight: HeroData
var _lv1: HeroAttributes


func before_all() -> void:
	_knight = load(KNIGHT) as HeroData
	_lv1 = Stats.attributes(_knight, 1, [], [])


func test_investida_rank_1_soma_75_por_cento_do_atk() -> void:
	assert_almost_eq(SkillRules.amount(_knight.skill_q, 1, _lv1), 50.0 + 0.75 * 40.0, EPS)


func test_investida_rank_5() -> void:
	assert_almost_eq(SkillRules.amount(_knight.skill_q, 5, _lv1), 170.0 + 0.75 * 40.0, EPS)


func test_muralha_soma_15_por_cento_do_hp_maximo() -> void:
	assert_almost_eq(SkillRules.amount(_knight.skill_e, 1, _lv1), 120.0 + 0.15 * 600.0, EPS)


func test_terremoto_soma_110_por_cento_da_int() -> void:
	assert_almost_eq(SkillRules.amount(_knight.skill_r, 2, _lv1), 260.0 + 1.1 * 10.0, EPS)


func test_ataque_basico_e_100_por_cento_do_atk() -> void:
	assert_almost_eq(SkillRules.amount(_knight.basic_attack, 1, _lv1), 40.0, EPS)


func test_cooldown_em_ticks_com_cdr_da_int() -> void:
	# 8 s x (1 - 5 % de CDR com INT 10) = 7,6 s = 228 ticks a 30 Hz.
	assert_eq(SkillRules.cooldown_ticks(_knight.skill_q, 1, 10.0, TICKRATE), 228)


func test_cooldown_do_terremoto_cai_no_rank_2() -> void:
	var rank1 := SkillRules.cooldown_ticks(_knight.skill_r, 1, 0.0, TICKRATE)
	var rank2 := SkillRules.cooldown_ticks(_knight.skill_r, 2, 0.0, TICKRATE)
	assert_eq([rank1, rank2], [1500, 1260])


func test_segundos_para_ticks_arredonda() -> void:
	assert_eq(SkillRules.seconds_to_ticks(3.0, TICKRATE), 90)
	assert_eq(SkillRules.seconds_to_ticks(6.0 / 14.0, TICKRATE), 13)


func test_terremoto_so_a_partir_do_nivel_6() -> void:
	assert_false(SkillRules.can_use(_knight.skill_r, 1, 5))
	assert_true(SkillRules.can_use(_knight.skill_r, 1, 6))


func test_rank_2_do_terremoto_so_no_nivel_10() -> void:
	assert_false(SkillRules.can_use(_knight.skill_r, 2, 9))
	assert_true(SkillRules.can_use(_knight.skill_r, 2, 10))


func test_rank_zero_nao_usa() -> void:
	assert_false(SkillRules.can_use(_knight.skill_e, 0, 10))


func test_muralha_so_a_partir_do_nivel_2() -> void:
	assert_false(SkillRules.can_use(_knight.skill_e, 1, 1))
	assert_true(SkillRules.can_use(_knight.skill_e, 1, 2))


func test_ranks_tipicos_do_gdb() -> void:
	var curve := load(XP) as XpCurve
	assert_eq(XpTable.typical_ranks(curve, 1), Vector3i(1, 0, 0))
	assert_eq(XpTable.typical_ranks(curve, 6), Vector3i(3, 2, 1))
	assert_eq(XpTable.typical_ranks(curve, 10), Vector3i(5, 3, 2))
