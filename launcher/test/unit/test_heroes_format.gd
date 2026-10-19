extends GutTest
## F71: textos e números da Tela Heróis (FRONTEND-LAUNCHER §8.3 regra 2). Os atributos vêm de
## Stats.attributes (a mesma fórmula do servidor, GDB §2.2); nada vem do protótipo.

const HEROES_DIR: String = "res://shared/data/heroes/"
const EPS: float = 0.001

var _catalog: CatalogService


func before_each() -> void:
	_catalog = CatalogService.new()
	_catalog.load_all()


func _hero(id: StringName) -> HeroData:
	return load("%s%s.tres" % [HEROES_DIR, id]) as HeroData


func _row(rows: Array[HeroesFormat.StatRow], id: StringName) -> HeroesFormat.StatRow:
	for row: HeroesFormat.StatRow in rows:
		if row.id == id:
			return row
	return null


func test_atributos_nivel_1_e_10_do_cavaleiro_batem_com_o_gdb() -> void:
	# GDB §4.1: HP 600 -> 1005, DEF 30 -> 57, ATQ 40 -> 71,5, INT 10 -> 19, AGI 10 -> 19.
	var rows := HeroesFormat.stat_rows(_hero(&"knight"))
	assert_almost_eq(_row(rows, &"hp").low, 600.0, EPS)
	assert_almost_eq(_row(rows, &"hp").high, 1005.0, EPS)
	assert_almost_eq(_row(rows, &"defense").low, 30.0, EPS)
	assert_almost_eq(_row(rows, &"defense").high, 57.0, EPS)
	assert_almost_eq(_row(rows, &"attack").low, 40.0, EPS)
	assert_almost_eq(_row(rows, &"attack").high, 71.5, EPS)
	assert_almost_eq(_row(rows, &"intelligence").high, 19.0, EPS)
	assert_almost_eq(_row(rows, &"agility").high, 19.0, EPS)


func test_velocidade_usa_a_formula_do_servidor() -> void:
	var hero := _hero(&"ranger")
	var rows := HeroesFormat.stat_rows(hero)
	var expected_low := Stats.move_speed(hero.base_move_speed, hero.base_agility, 0.0)
	assert_almost_eq(_row(rows, &"move_speed").low, expected_low, EPS)
	assert_gt(_row(rows, &"move_speed").high, expected_low)


func test_texto_do_valor_sem_casa_decimal_inutil() -> void:
	assert_eq(HeroesFormat.value_text(600.0), "600")
	assert_eq(HeroesFormat.value_text(71.5), "71,5")
	assert_eq(HeroesFormat.value_text(1005.0), "1.005")
	assert_eq(HeroesFormat.value_text(6.2), "6,2")


func test_maximos_do_catalogo_normalizam_as_barras() -> void:
	var maxima := HeroesFormat.maxima(_catalog.heroes)
	for hero: HeroData in _catalog.heroes:
		for row: HeroesFormat.StatRow in HeroesFormat.stat_rows(hero):
			assert_lte(row.high, maxima[row.id] + EPS, "%s %s" % [hero.id, row.id])
	assert_almost_eq(maxima[&"hp"], 1034.0, EPS, "o Paladino tem a maior vida")


func test_habilidades_na_ordem_ataque_q_e_r_com_teclas() -> void:
	var hero := _hero(&"ranger")
	var slots := HeroesFormat.skill_slots(hero)
	assert_eq(slots.size(), 4)
	assert_eq(slots[0].skill, hero.basic_attack)
	assert_eq(slots[1].skill, hero.skill_q)
	assert_eq(slots[2].skill, hero.skill_e)
	assert_eq(slots[3].skill, hero.skill_r)
	assert_eq(slots[0].key, "RMB")
	assert_eq(slots[1].key, "Q")
	assert_eq(slots[2].key, "E")
	assert_eq(slots[3].key, "R")
	assert_true(slots[3].ultimate)
	assert_false(slots[0].ultimate or slots[1].ultimate or slots[2].ultimate)


func test_icone_de_classe_existe_para_todos_os_herois_e_tem_reserva() -> void:
	for hero: HeroData in _catalog.heroes:
		assert_false(HeroesFormat.class_icon(hero.role).is_empty(), hero.role)
	assert_eq(HeroesFormat.class_icon("Classe nova"), UiIcons.STARS)


func test_retrato_grande_existe_para_cada_heroi() -> void:
	for hero: HeroData in _catalog.heroes:
		assert_not_null(HeroesFormat.portrait(hero.id), "retrato de %s" % hero.id)
	assert_null(HeroesFormat.portrait(&"../etc"))
