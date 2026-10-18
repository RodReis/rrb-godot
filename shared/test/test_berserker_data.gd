extends GutTest
## F75: berserker.tres confere com o GDB §4.8 e §2.2-E (ADR-0004, ADR-0015 item 13): atributos no
## nivel 1 e 10, recargas, alcances, numeros das 4 habilidades e a passiva Frenesi (PassiveData).

const BERSERKER: HeroData = preload("res://shared/data/heroes/berserker.tres")
const HEROES: Array[String] = [
	"res://shared/data/heroes/knight.tres",
	"res://shared/data/heroes/ranger.tres",
	"res://shared/data/heroes/barbarian.tres",
	"res://shared/data/heroes/fire_wizard.tres",
	"res://shared/data/heroes/rogue.tres",
	"res://shared/data/heroes/engineer.tres",
	"res://shared/data/heroes/druid.tres",
	"res://shared/data/heroes/occultist.tres",
]
const EPS: float = 0.0001


func test_berserker_no_nivel_1_e_10_bate_com_o_gdb() -> void:
	var d := BERSERKER
	assert_eq(d.id, &"berserker")
	assert_eq(d.display_name, "Berserker")
	assert_eq(d.role, "Lutador")
	assert_eq(d.weapon_name, "Machados")
	assert_false(d.summary.is_empty())
	assert_almost_eq(d.base_move_speed, 6.1, EPS)
	var a1 := Stats.attributes(d, 1, [], [])
	assert_eq(a1.max_hp, 560)
	assert_almost_eq(a1.defense, 18.0, EPS)
	assert_almost_eq(a1.attack, 58.0, EPS)
	assert_almost_eq(a1.intelligence, 8.0, EPS)
	assert_almost_eq(a1.agility, 20.0, EPS)
	var a10 := Stats.attributes(d, 10, [], [])
	assert_eq(a10.max_hp, 956)
	assert_almost_eq(a10.defense, 34.2, EPS)
	assert_almost_eq(a10.attack, 103.0, EPS)
	assert_almost_eq(a10.intelligence, 15.2, EPS)
	assert_almost_eq(a10.agility, 36.2, EPS)


func test_frenesi() -> void:
	var p := BERSERKER.passive
	assert_not_null(p, "unica passiva do jogo")
	assert_eq(p.kind, PassiveData.Kind.FRENZY)
	assert_false(p.display_name.is_empty())
	assert_false(p.description.is_empty())
	assert_almost_eq(p.attack_speed_bonus, 0.6, EPS)
	assert_almost_eq(p.lifesteal, 0.25, EPS)
	assert_almost_eq(p.full_at_hp_ratio, 0.2, EPS, "teto a 20 % de HP")


func test_outros_herois_sem_passiva() -> void:
	for path: String in HEROES:
		var data := load(path) as HeroData
		assert_null(data.passive, "%s sem passiva" % data.id)


func test_machados_gemeos() -> void:
	var b := BERSERKER.basic_attack
	assert_almost_eq(b.attack_range, 2.4, EPS)
	assert_almost_eq(b.arc_degrees, 90.0, EPS)
	assert_eq(b.cooldown, PackedFloat64Array([0.9]))
	assert_almost_eq(b.attack_ratio, 1.0, EPS)
	assert_eq(b.max_rank, 1)


func test_arremesso_de_machado() -> void:
	var q := BERSERKER.skill_q
	assert_almost_eq(q.speed, 22.0, EPS)
	assert_almost_eq(q.attack_range, 7.0, EPS)
	assert_almost_eq(q.radius, 0.4, EPS)
	assert_almost_eq(q.slow, 0.3, EPS)
	assert_eq(q.duration, PackedFloat64Array([1.5]))
	assert_eq(q.cooldown, PackedFloat64Array([9.0, 8.5, 8.0, 7.5, 7.0]))
	assert_eq(q.base_amount, PackedFloat64Array([60, 90, 120, 150, 180]))
	assert_almost_eq(q.attack_ratio, 0.6, EPS)
	assert_almost_eq(q.intelligence_ratio, 0.0, EPS)
	assert_eq(q.max_rank, 5)
	assert_eq(q.required_hero_level, PackedInt32Array([1]))


func test_grito_de_guerra() -> void:
	var e := BERSERKER.skill_e
	assert_eq(e.duration, PackedFloat64Array([2.0]))
	assert_eq(e.base_amount, PackedFloat64Array([30, 40, 50, 60, 70]), "DEF somada no rank")
	assert_almost_eq(e.move_speed_bonus, 0.15, EPS)
	assert_eq(e.cooldown, PackedFloat64Array([14.0, 13.0, 12.0, 11.0, 10.0]))
	assert_almost_eq(e.attack_ratio, 0.0, EPS, "sem dano")
	assert_eq(e.max_rank, 5)
	assert_eq(e.required_hero_level, PackedInt32Array([2]))


func test_ragnarok() -> void:
	var r := BERSERKER.skill_r
	assert_eq(r.duration, PackedFloat64Array([4.0]))
	assert_almost_eq(r.move_speed_bonus, 0.25, EPS)
	assert_eq(r.cooldown, PackedFloat64Array([70.0, 58.0]))
	assert_true(r.base_amount.is_empty(), "sem dano")
	assert_eq(r.max_rank, 2)
	assert_eq(r.required_hero_level, PackedInt32Array([6, 10]))


func test_habilidades_tem_descricao_e_icone() -> void:
	var d := BERSERKER
	for skill: SkillData in [d.basic_attack, d.skill_q, d.skill_e, d.skill_r]:
		assert_false(skill.description.is_empty(), "descricao de %s" % skill.id)
		assert_not_null(skill.icon, "icone de %s" % skill.id)


func test_id_estavel_em_ids_all() -> void:
	assert_eq(
		Ids.to_int(&"berserker"), 35, "ordem de Ids.ALL estavel na rede (so acrescenta no fim)"
	)
	assert_eq(Ids.to_name(Ids.to_int(&"berserker")), &"berserker")
