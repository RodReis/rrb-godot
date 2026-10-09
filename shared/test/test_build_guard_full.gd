extends GutTest
## I5: o mesmo build da o mesmo atributo final no servidor e na Forja. Cavaleiro nivel 10,
## arma epica e Guarda rara 3/3 (DV tela 6) recalculado pelo GDB §2.2, §4.1, §6.1.

const FIXTURE: String = "res://shared/test/fixtures/build_guard_full.tres"
const BONUSES: Array[String] = [
	"res://shared/data/items/guard_set/guard_bonus.tres",
	"res://shared/data/items/hunter_set/hunter_bonus.tres",
]
const EPS: float = 0.0001

var _attrs: HeroAttributes


func before_all() -> void:
	var build := load(FIXTURE) as BuildFixture
	var bonuses: Array[SetBonusData] = []
	for path: String in BONUSES:
		bonuses.append(load(path) as SetBonusData)
	_attrs = Stats.attributes(build.hero, build.level, build.items, bonuses)


func test_hp_soma_peitoral_e_aplica_15_por_cento() -> void:
	# (1005 + 110) x 1.15 = 1282.25 -> 1282. A DV mostra 1397; vale o GDB (ADR-0004).
	assert_eq(_attrs.max_hp, 1282)


func test_def_soma_pecas_e_bonus_plano() -> void:
	assert_almost_eq(_attrs.defense, 99.0, EPS)
	assert_almost_eq(_attrs.mitigation, 99.0 / 199.0, EPS)


func test_atk_soma_arma_epica() -> void:
	assert_almost_eq(_attrs.attack, 116.5, EPS)


func test_int_e_cdr() -> void:
	assert_almost_eq(_attrs.intelligence, 24.0, EPS)
	assert_almost_eq(_attrs.cdr_percent, 12.0, EPS)


func test_agi_com_botas_raras() -> void:
	assert_almost_eq(_attrs.agility, 20.9, EPS)


func test_velocidades_sem_bonus_cacador() -> void:
	assert_almost_eq(_attrs.move_speed, 5.8 * (1.0 + 20.9 * 0.004), EPS)
	assert_almost_eq(_attrs.attack_interval, 1.0 / (1.0 + 20.9 * 0.006), EPS)
