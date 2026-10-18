extends GutTest
## F77: occultist.tres confere com o GDB §4.10 e §2.2-F (ADR-0016): atributos no nivel 1 e 10,
## recargas, alcances, numeros do basico, Praga e Circulo Profano, e o R desligado (sem ponto).

const OCCULTIST: HeroData = preload("res://shared/data/heroes/occultist.tres")
const EPS: float = 0.0001


func test_ocultista_no_nivel_1_e_10_bate_com_o_gdb() -> void:
	var d := OCCULTIST
	assert_eq(d.id, &"occultist")
	assert_eq(d.display_name, "Ocultista")
	assert_eq(d.role, "Mago")
	assert_false(d.summary.is_empty())
	assert_almost_eq(d.base_move_speed, 6.0, EPS)
	var a1 := Stats.attributes(d, 1, [], [])
	assert_eq(a1.max_hp, 370)
	assert_almost_eq(a1.defense, 9.0, EPS)
	assert_almost_eq(a1.attack, 42.0, EPS)
	assert_almost_eq(a1.intelligence, 32.0, EPS)
	assert_almost_eq(a1.agility, 14.0, EPS)
	var a10 := Stats.attributes(d, 10, [], [])
	assert_eq(a10.max_hp, 613)
	assert_almost_eq(a10.defense, 18.0, EPS)
	assert_almost_eq(a10.attack, 76.2, EPS)
	assert_almost_eq(a10.intelligence, 60.8, EPS)
	assert_almost_eq(a10.agility, 24.8, EPS)
	assert_almost_eq(a10.cdr_percent, 30.0, EPS, "CDR no teto")


func test_projetil_sombrio() -> void:
	var b := OCCULTIST.basic_attack
	assert_almost_eq(b.speed, 15.0, EPS)
	assert_almost_eq(b.attack_range, 7.5, EPS)
	assert_almost_eq(b.radius, 0.4, EPS)
	assert_eq(b.cooldown, PackedFloat64Array([1.1]))
	assert_almost_eq(b.attack_ratio, 0.9, EPS)
	assert_eq(b.curse_marks, 1)
	assert_eq(b.duration, PackedFloat64Array([4.0]), "marcas duram 4 s")
	assert_eq(b.max_rank, 1)


func test_praga() -> void:
	var q := OCCULTIST.skill_q
	assert_almost_eq(q.speed, 17.0, EPS)
	assert_almost_eq(q.attack_range, 8.0, EPS)
	assert_almost_eq(q.radius, 0.4, EPS)
	assert_eq(q.cooldown, PackedFloat64Array([8.0, 7.5, 7.0, 6.5, 6.0]))
	assert_eq(q.base_amount, PackedFloat64Array([80, 120, 160, 200, 240]))
	assert_almost_eq(q.attack_ratio, 1.0, EPS)
	assert_eq(q.pulse_count, 8)
	assert_almost_eq(q.pulse_interval, 0.5, EPS)
	assert_almost_eq(q.pulse_count * q.pulse_interval, SkillData.at_rank(q.duration, 1), EPS)
	assert_eq(q.curse_marks, 0, "so o basico marca")
	assert_eq(q.max_rank, 5)
	assert_eq(q.required_hero_level, PackedInt32Array([1]))


func test_circulo_profano() -> void:
	var e := OCCULTIST.skill_e
	assert_almost_eq(e.radius, 2.5, EPS)
	assert_almost_eq(e.cast_range, 7.0, EPS)
	assert_eq(e.duration, PackedFloat64Array([3.0]))
	assert_almost_eq(e.slow, 0.35, EPS)
	assert_eq(e.pulse_count, 6)
	assert_almost_eq(e.pulse_interval, 0.5, EPS)
	assert_eq(e.cooldown, PackedFloat64Array([13.0, 12.5, 12.0, 11.5, 11.0]))
	assert_eq(e.base_amount, PackedFloat64Array([60, 90, 120, 150, 180]))
	assert_almost_eq(e.attack_ratio, 0.6, EPS)
	assert_eq(e.curse_marks, 0)
	assert_eq(e.max_rank, 5)
	assert_eq(e.required_hero_level, PackedInt32Array([2]))


func test_servos_do_vazio_existe_mas_sem_ponto() -> void:
	var r := OCCULTIST.skill_r
	assert_not_null(r, "R nao fica nulo: ficha, HUD e bot leem")
	assert_eq(r.max_rank, 0, "desligado ate o F78")
	assert_eq(r.required_hero_level, PackedInt32Array([6, 10]))
	assert_eq(r.cooldown, PackedFloat64Array([55.0, 46.0]))
	assert_false(SkillRules.can_use(r, 1, 10))
	var learned := SkillRules.learn(Vector3i(3, 2, 0), SkillRules.SLOT_R, r, 6)
	assert_eq(learned, Vector3i(3, 2, 0), "o ponto do Nv 6 nao vai para o R")


func test_ponto_do_nivel_6_vai_para_q_ou_e() -> void:
	var learned := SkillRules.learn(Vector3i(3, 2, 0), SkillRules.SLOT_Q, OCCULTIST.skill_q, 6)
	assert_eq(learned, Vector3i(4, 2, 0))


func test_habilidades_tem_descricao_e_icone() -> void:
	var d := OCCULTIST
	for skill: SkillData in [d.basic_attack, d.skill_q, d.skill_e, d.skill_r]:
		assert_false(skill.description.is_empty(), "descricao de %s" % skill.id)
		assert_not_null(skill.icon, "icone de %s" % skill.id)


func test_id_no_fim_de_ids_all() -> void:
	assert_eq(Ids.ALL[Ids.ALL.size() - 1], &"occultist", "id novo so no fim")
	assert_eq(Ids.to_name(Ids.to_int(&"occultist")), &"occultist")
