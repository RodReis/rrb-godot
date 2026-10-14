extends GutTest
## F59: engineer.tres confere com o GDB §4.6 (ADR-0004): atributos no nivel 1 e 10, recargas e danos
## por rank das 4 habilidades do Engenheiro.

const ENGINEER: HeroData = preload("res://shared/data/heroes/engineer.tres")
const EPS: float = 0.0001


func test_engenheiro_no_nivel_1_e_10_bate_com_o_gdb() -> void:
	var e := ENGINEER
	assert_eq(e.id, &"engineer")
	assert_eq(e.display_name, "Engenheiro")
	assert_almost_eq(e.base_move_speed, 5.9, EPS)
	var a1 := Stats.attributes(e, 1, [], [])
	assert_eq(a1.max_hp, 520)
	assert_almost_eq(a1.defense, 22.0, EPS)
	assert_almost_eq(a1.attack, 46.0, EPS)
	assert_almost_eq(a1.intelligence, 18.0, EPS)
	assert_almost_eq(a1.agility, 12.0, EPS)
	var a10 := Stats.attributes(e, 10, [], [])
	assert_eq(a10.max_hp, 862)
	assert_almost_eq(a10.defense, 41.8, EPS)
	assert_almost_eq(a10.attack, 82.0, EPS)
	assert_almost_eq(a10.intelligence, 34.2, EPS)
	assert_almost_eq(a10.agility, 21.0, EPS)


func test_bacamarte_e_cone_de_40_graus_e_4_5_u() -> void:
	var b := ENGINEER.basic_attack
	assert_almost_eq(b.arc_degrees, 40.0, EPS)
	assert_almost_eq(b.attack_range, 4.5, EPS)
	assert_eq(b.cooldown, PackedFloat64Array([1.2]))
	assert_almost_eq(b.attack_ratio, 1.0, EPS)
	assert_almost_eq(b.speed, 0.0, EPS, "instantaneo: sem projetil")


func test_garra_mecanica() -> void:
	var q := ENGINEER.skill_q
	assert_almost_eq(q.speed, 20.0, EPS)
	assert_almost_eq(q.attack_range, 7.0, EPS)
	assert_almost_eq(q.radius, 0.4, EPS)
	assert_almost_eq(q.distance, 2.0, EPS, "o puxado para a 2,0 u do Engenheiro")
	assert_eq(q.duration, PackedFloat64Array([0.3]), "puxao em 0,3 s")
	assert_eq(q.cooldown, PackedFloat64Array([11.0, 10.5, 10.0, 9.5, 9.0]))
	assert_eq(q.base_amount, PackedFloat64Array([50, 80, 110, 140, 170]))
	assert_almost_eq(q.attack_ratio, 0.7, EPS)
	assert_almost_eq(q.intelligence_ratio, 0.0, EPS)
	assert_eq(q.max_rank, 5)
	assert_eq(q.required_hero_level, PackedInt32Array([1]))


func test_torreta() -> void:
	var t := ENGINEER.skill_e
	assert_almost_eq(t.cast_range, 3.0, EPS)
	assert_eq(t.duration, PackedFloat64Array([6.0]))
	assert_almost_eq(t.pulse_interval, 0.75, EPS)
	assert_eq(t.pulse_count, 8)
	assert_almost_eq(t.attack_range, 7.0, EPS)
	assert_eq(t.cooldown, PackedFloat64Array([14.0]))
	assert_eq(t.base_amount, PackedFloat64Array([14, 20, 26, 32, 38]))
	assert_almost_eq(t.attack_ratio, 0.15, EPS)
	assert_eq(t.max_rank, 5)
	assert_eq(t.required_hero_level, PackedInt32Array([2]))


func test_caixa_de_dinamite() -> void:
	var r := ENGINEER.skill_r
	assert_almost_eq(r.cast_range, 6.0, EPS)
	assert_eq(r.duration, PackedFloat64Array([1.5]), "pavio de 1,5 s")
	assert_almost_eq(r.radius, 4.5, EPS)
	assert_almost_eq(r.knockback, 3.0, EPS)
	assert_eq(r.cooldown, PackedFloat64Array([55.0, 46.0]))
	assert_eq(r.base_amount, PackedFloat64Array([240, 380]))
	assert_almost_eq(r.intelligence_ratio, 1.3, EPS)
	assert_almost_eq(r.attack_ratio, 0.6, EPS)
	assert_eq(r.max_rank, 2)
	assert_eq(r.required_hero_level, PackedInt32Array([6, 10]))


func test_dano_por_rank_no_nivel_10() -> void:
	var a := Stats.attributes(ENGINEER, 10, [], [])
	assert_almost_eq(SkillRules.amount(ENGINEER.skill_q, 5, a), 170.0 + 0.7 * 82.0, EPS)
	assert_almost_eq(SkillRules.amount(ENGINEER.skill_e, 5, a), 38.0 + 0.15 * 82.0, EPS)
	assert_almost_eq(
		SkillRules.amount(ENGINEER.skill_r, 2, a), 380.0 + 1.3 * 34.2 + 0.6 * 82.0, EPS
	)
