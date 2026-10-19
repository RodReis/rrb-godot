extends GutTest
## F76: paladin.tres confere com o GDB §4.9 (ADR-0016 itens 3–5): atributos no nivel 1 e 10,
## recargas, alcances e numeros da Maca, Golpe Consagrado, Retribuicao e Bencao Inviolavel.

const PALADIN: HeroData = preload("res://shared/data/heroes/paladin.tres")
const EPS: float = 0.0001


func test_paladino_no_nivel_1_e_10_bate_com_o_gdb() -> void:
	var d := PALADIN
	assert_eq(d.id, &"paladin")
	assert_eq(d.display_name, "Paladino Radiante")
	assert_eq(d.role, "Tanque")
	assert_eq(d.weapon_name, "Maça")
	assert_false(d.summary.is_empty())
	assert_null(d.passive, "sem passiva")
	assert_almost_eq(d.base_move_speed, 5.7, EPS)
	var a1 := Stats.attributes(d, 1, [], [])
	assert_eq(a1.max_hp, 620)
	assert_almost_eq(a1.defense, 28.0, EPS)
	assert_almost_eq(a1.attack, 38.0, EPS)
	assert_almost_eq(a1.intelligence, 16.0, EPS)
	assert_almost_eq(a1.agility, 8.0, EPS)
	var a10 := Stats.attributes(d, 10, [], [])
	assert_eq(a10.max_hp, 1034)
	assert_almost_eq(a10.defense, 53.2, EPS)
	assert_almost_eq(a10.attack, 68.6, EPS)
	assert_almost_eq(a10.intelligence, 30.4, EPS)
	assert_almost_eq(a10.agility, 15.2, EPS)
	assert_almost_eq(a10.cdr_percent, 15.2, EPS)


func test_maca() -> void:
	var b := PALADIN.basic_attack
	assert_almost_eq(b.arc_degrees, 60.0, EPS)
	assert_almost_eq(b.attack_range, 2.0, EPS)
	assert_eq(b.cooldown, PackedFloat64Array([1.2]))
	assert_almost_eq(b.attack_ratio, 1.2, EPS)
	assert_eq(b.max_rank, 1)


func test_golpe_consagrado() -> void:
	var q := PALADIN.skill_q
	assert_almost_eq(q.attack_range, 2.5, EPS, "comprimento da faixa")
	assert_almost_eq(q.strip_width, 1.0, EPS, "largura da faixa")
	assert_eq(q.stun_duration, PackedFloat64Array([0.8, 0.9, 1.0, 1.1, 1.2]))
	assert_eq(q.base_amount, PackedFloat64Array([50, 75, 100, 125, 150]))
	assert_almost_eq(q.attack_ratio, 0.7, EPS)
	assert_eq(q.cooldown, PackedFloat64Array([10.0, 9.5, 9.0, 8.5, 8.0]))
	assert_eq(q.max_rank, 5)
	assert_eq(q.required_hero_level, PackedInt32Array([1]))


func test_retribuicao() -> void:
	var e := PALADIN.skill_e
	assert_eq(e.duration, PackedFloat64Array([3.0]))
	assert_almost_eq(e.attack_range, 3.0, EPS, "origem do golpe ate 3 u")
	assert_eq(e.reflect_ratio, PackedFloat64Array([0.25, 0.30, 0.35, 0.40, 0.45]))
	assert_almost_eq(e.attack_ratio, 0.2, EPS)
	assert_eq(e.base_amount, PackedFloat64Array(), "sem base: so a fracao + ATK")
	assert_eq(e.cooldown, PackedFloat64Array([13.0, 12.5, 12.0, 11.5, 11.0]))
	assert_eq(e.max_rank, 5)
	assert_eq(e.required_hero_level, PackedInt32Array([2]))


func test_bencao_inviolavel_no_nivel_6_e_10() -> void:
	var r := PALADIN.skill_r
	assert_eq(r.base_amount, PackedFloat64Array([120, 200]), "cura")
	assert_almost_eq(r.intelligence_ratio, 1.2, EPS)
	assert_almost_eq(r.attack_ratio, 0.0, EPS, "INT so no R")
	assert_eq(r.duration, PackedFloat64Array([1.5, 2.0]), "imunidade a dano")
	assert_almost_eq(r.radius, 5.0, EPS, "aliados (2x2)")
	assert_eq(r.cooldown, PackedFloat64Array([60.0, 50.0]))
	assert_eq(r.max_rank, 2)
	assert_eq(r.required_hero_level, PackedInt32Array([6, 10]))


func test_habilidades_tem_descricao_e_icone() -> void:
	var d := PALADIN
	for skill: SkillData in [d.basic_attack, d.skill_q, d.skill_e, d.skill_r]:
		assert_false(skill.description.is_empty(), "descricao de %s" % skill.id)
		assert_not_null(skill.icon, "icone de %s" % skill.id)


func test_id_no_fim_de_ids_all() -> void:
	assert_eq(Ids.ALL[Ids.ALL.size() - 1], &"paladin", "id novo so no fim")
	assert_eq(Ids.to_name(Ids.to_int(&"paladin")), &"paladin")
