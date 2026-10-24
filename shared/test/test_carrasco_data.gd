extends GutTest
## F98: carrasco.tres confere com o GDB §4.11 (ADR-0032, SPEC-098): atributos no nivel 1 e 10,
## recargas, alcances e numeros da Espada, Espinhos, Penitencia, Correntes do Julgamento e da
## passiva Couraca (com a Dor).

const CARRASCO: HeroData = preload("res://shared/data/heroes/carrasco.tres")
const EPS: float = 0.0001


func test_carrasco_no_nivel_1_e_10_bate_com_o_gdb() -> void:
	var d := CARRASCO
	assert_eq(d.id, &"carrasco")
	assert_eq(d.display_name, "Carrasco")
	assert_eq(d.role, "Tanque")
	assert_eq(d.weapon_name, "Espada")
	assert_false(d.summary.is_empty())
	assert_almost_eq(d.base_move_speed, 5.8, EPS)
	var a1 := Stats.attributes(d, 1, [], [])
	assert_eq(a1.max_hp, 560)
	assert_almost_eq(a1.defense, 24.0, EPS)
	assert_almost_eq(a1.attack, 38.0, EPS)
	assert_almost_eq(a1.intelligence, 14.0, EPS)
	assert_almost_eq(a1.agility, 10.0, EPS)
	var a10 := Stats.attributes(d, 10, [], [])
	assert_eq(a10.max_hp, 920)
	assert_almost_eq(a10.defense, 47.4, EPS)
	assert_almost_eq(a10.attack, 70.4, EPS)
	assert_almost_eq(a10.intelligence, 26.6, EPS)
	assert_almost_eq(a10.agility, 19.0, EPS)
	assert_almost_eq(a10.cdr_percent, 13.3, EPS)


func test_couraca_e_dor() -> void:
	var p := CARRASCO.passive
	assert_not_null(p)
	assert_eq(p.kind, PassiveData.Kind.CUIRASS)
	assert_false(p.display_name.is_empty())
	assert_false(p.description.is_empty())
	assert_not_null(p.icon)
	assert_almost_eq(p.taken_factor, 0.85, EPS, "basico de heroi x 0,85")
	assert_eq(p.pain_max, 6)
	assert_almost_eq(p.pain_seconds, 6.0, EPS, "Dor dura 6 s fora da Penitencia")


func test_espada() -> void:
	var b := CARRASCO.basic_attack
	assert_almost_eq(b.arc_degrees, 70.0, EPS)
	assert_almost_eq(b.attack_range, 2.2, EPS)
	assert_eq(b.cooldown, PackedFloat64Array([1.0]))
	assert_almost_eq(b.attack_ratio, 1.0, EPS)
	assert_eq(b.max_rank, 1)


func test_espinhos() -> void:
	var q := CARRASCO.skill_q
	assert_almost_eq(q.arc_degrees, 90.0, EPS)
	assert_almost_eq(q.attack_range, 3.0, EPS)
	assert_almost_eq(q.slow, 0.3, EPS)
	assert_almost_eq(q.slow_duration, 1.5, EPS)
	assert_eq(q.base_amount, PackedFloat64Array([50, 80, 110, 140, 170]))
	assert_almost_eq(q.attack_ratio, 0.6, EPS)
	assert_almost_eq(q.recast_window, 3.0, EPS)
	assert_eq(q.recast_amount, PackedFloat64Array([30, 50, 70, 90, 110]))
	assert_almost_eq(q.recast_attack_ratio, 0.4, EPS)
	assert_almost_eq(q.speed, 20.0, EPS, "projetil do recast")
	assert_almost_eq(q.distance, 7.0, EPS)
	assert_almost_eq(q.radius, 0.4, EPS)
	assert_eq(q.cooldown, PackedFloat64Array([10.0, 9.5, 9.0, 8.5, 8.0]))
	assert_eq(q.max_rank, 5)
	assert_eq(q.required_hero_level, PackedInt32Array([1]))


func test_penitencia() -> void:
	var e := CARRASCO.skill_e
	assert_eq(e.duration, PackedFloat64Array([2.0]), "canaliza ate 2 s")
	assert_almost_eq(e.mitigation, 0.4, EPS)
	assert_almost_eq(e.pulse_interval, 0.5, EPS, "+1 Dor a cada 0,5 s")
	assert_eq(e.heal_amount, PackedFloat64Array([60, 90, 120, 150, 180]))
	assert_almost_eq(e.heal_attack_ratio, 0.4, EPS)
	assert_eq(e.base_amount, PackedFloat64Array([50, 80, 110, 140, 170]))
	assert_almost_eq(e.attack_ratio, 0.5, EPS)
	assert_almost_eq(e.per_pain, 10.0, EPS, "cura e dano + 10 por Dor")
	assert_almost_eq(e.radius, 3.0, EPS)
	assert_eq(e.root_min_pain, 4)
	assert_almost_eq(e.root_duration, 1.0, EPS)
	assert_almost_eq(e.slow, 0.4, EPS)
	assert_almost_eq(e.slow_duration, 1.5, EPS)
	assert_eq(e.cooldown, PackedFloat64Array([14.0, 13.0, 12.0, 11.0, 10.0]))
	assert_eq(e.max_rank, 5)
	assert_eq(e.required_hero_level, PackedInt32Array([2]))


func test_correntes_do_julgamento() -> void:
	var r := CARRASCO.skill_r
	assert_almost_eq(r.speed, 24.0, EPS)
	assert_almost_eq(r.distance, 6.0, EPS)
	assert_eq(r.duration, PackedFloat64Array([1.25, 1.5]), "raiz e luz")
	assert_almost_eq(r.light_radius, 2.5, EPS)
	assert_almost_eq(r.execute_hp_ratio, 0.25, EPS)
	assert_eq(r.base_amount, PackedFloat64Array([120, 200]))
	assert_almost_eq(r.intelligence_ratio, 1.0, EPS)
	assert_almost_eq(r.attack_ratio, 0.0, EPS, "INT so no R")
	assert_eq(r.cooldown, PackedFloat64Array([70.0, 60.0]))
	assert_eq(r.max_rank, 2)
	assert_eq(r.required_hero_level, PackedInt32Array([6, 10]))


func test_habilidades_tem_descricao_e_icone() -> void:
	var d := CARRASCO
	for skill: SkillData in [d.basic_attack, d.skill_q, d.skill_e, d.skill_r]:
		assert_false(skill.description.is_empty(), "descricao de %s" % skill.id)
		assert_not_null(skill.icon, "icone de %s" % skill.id)


func test_id_no_fim_de_ids_all() -> void:
	assert_eq(Ids.ALL[Ids.ALL.size() - 1], &"carrasco", "id novo so no fim")
	assert_eq(Ids.to_name(Ids.to_int(&"carrasco")), &"carrasco")
