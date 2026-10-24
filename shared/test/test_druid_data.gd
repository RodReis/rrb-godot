extends GutTest
## F74: druid.tres confere com o GDB §4.7 (ADR-0004, ADR-0015 item 12): atributos no nivel 1 e 10,
## recargas, alcances e numeros das 4 habilidades do Protetor da Selva.

const DRUID: HeroData = preload("res://shared/data/heroes/druid.tres")
const EPS: float = 0.0001


func test_protetor_no_nivel_1_e_10_bate_com_o_gdb() -> void:
	var d := DRUID
	assert_eq(d.id, &"druid")
	assert_eq(d.display_name, "Protetor da Selva")
	assert_eq(d.role, "Controle")
	assert_eq(d.weapon_name, "Cajado")
	assert_false(d.summary.is_empty())
	assert_almost_eq(d.base_move_speed, 6.0, EPS)
	var a1 := Stats.attributes(d, 1, [], [])
	assert_eq(a1.max_hp, 440)
	assert_almost_eq(a1.defense, 16.0, EPS)
	assert_almost_eq(a1.attack, 40.0, EPS)
	assert_almost_eq(a1.intelligence, 20.0, EPS)
	assert_almost_eq(a1.agility, 16.0, EPS)
	var a10 := Stats.attributes(d, 10, [], [])
	assert_eq(a10.max_hp, 746)
	assert_almost_eq(a10.defense, 30.4, EPS)
	assert_almost_eq(a10.attack, 74.2, EPS)
	assert_almost_eq(a10.intelligence, 38.0, EPS)
	assert_almost_eq(a10.agility, 28.6, EPS)


func test_seiva() -> void:
	var b := DRUID.basic_attack
	assert_almost_eq(b.speed, 20.0, EPS)
	assert_almost_eq(b.attack_range, 6.5, EPS)
	assert_almost_eq(b.radius, 0.35, EPS)
	assert_eq(b.cooldown, PackedFloat64Array([1.0]))
	assert_almost_eq(b.attack_ratio, 1.0, EPS)
	assert_eq(b.max_rank, 1)


func test_raizes_vivas() -> void:
	var q := DRUID.skill_q
	assert_almost_eq(q.speed, 18.0, EPS)
	assert_almost_eq(q.attack_range, 7.0, EPS)
	assert_almost_eq(q.radius, 0.4, EPS)
	assert_almost_eq(q.slow, 1.0, EPS, "enraizar = lentidao de 100 %")
	assert_eq(q.duration, PackedFloat64Array([1.0]))
	assert_eq(q.cooldown, PackedFloat64Array([10.0, 9.5, 9.0, 8.5, 8.0]))
	assert_eq(q.base_amount, PackedFloat64Array([40, 65, 90, 115, 140]))
	assert_almost_eq(q.attack_ratio, 0.5, EPS)
	assert_almost_eq(q.intelligence_ratio, 0.0, EPS)
	assert_eq(q.max_rank, 5)
	assert_eq(q.required_hero_level, PackedInt32Array([1]))


func test_pocao_verde() -> void:
	var e := DRUID.skill_e
	assert_almost_eq(e.cast_range, 5.0, EPS)
	assert_almost_eq(e.radius, 3.0, EPS)
	assert_eq(e.duration, PackedFloat64Array([3.0]))
	assert_eq(e.pulse_count, 6)
	assert_almost_eq(e.pulse_interval, 0.5, EPS)
	assert_eq(e.cooldown, PackedFloat64Array([16.0, 15.0, 14.0, 13.0, 12.0]))
	assert_eq(e.base_amount, PackedFloat64Array([90, 135, 180, 225, 270]), "cura total do rank")
	assert_almost_eq(e.attack_ratio, 0.5, EPS)
	assert_almost_eq(e.intelligence_ratio, 0.0, EPS)
	assert_eq(e.max_rank, 5)
	assert_eq(e.required_hero_level, PackedInt32Array([2]))


func test_pantano() -> void:
	var r := DRUID.skill_r
	assert_almost_eq(r.cast_range, 7.0, EPS)
	assert_almost_eq(r.radius, 5.0, EPS)
	assert_eq(r.duration, PackedFloat64Array([6.0]))
	assert_eq(r.pulse_count, 6)
	assert_almost_eq(r.pulse_interval, 1.0, EPS)
	assert_almost_eq(r.slow, 0.4, EPS)
	assert_eq(r.cooldown, PackedFloat64Array([60.0, 50.0]))
	assert_eq(r.base_amount, PackedFloat64Array([30, 50]))
	assert_almost_eq(r.intelligence_ratio, 0.25, EPS)
	assert_almost_eq(r.attack_ratio, 0.0, EPS, "o R escala so a INT")
	assert_eq(r.max_rank, 2)
	assert_eq(r.required_hero_level, PackedInt32Array([6, 10]))


func test_habilidades_tem_descricao_e_icone() -> void:
	for skill: SkillData in [DRUID.basic_attack, DRUID.skill_q, DRUID.skill_e, DRUID.skill_r]:
		assert_false(skill.description.is_empty(), "descricao de %s" % skill.id)
		assert_not_null(skill.icon, "icone de %s" % skill.id)


func test_id_estavel_em_ids_all() -> void:
	assert_eq(Ids.to_int(&"druid"), 34, "id nunca muda de posicao (ordem estavel na rede)")
	assert_eq(Ids.to_name(Ids.to_int(&"druid")), &"druid")
