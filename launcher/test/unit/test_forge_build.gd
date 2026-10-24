extends GutTest
## F27 / I5: o simulador da Forja devolve exatamente o que shared/core calcula para o mesmo build
## (o servidor usa Stats.attributes). Caso de referencia: shared/test/fixtures/build_guard_full.tres
## (Cavaleiro nivel 10, arma epica e Guarda rara 3/3), recalculado pelo GDB §2.2, §4.1, §6.1.

const FIXTURE: String = "res://shared/test/fixtures/build_guard_full.tres"
const EPS: float = 0.0001
const MAX_ITEMS: int = 4

var _catalog: CatalogService
var _fixture: BuildFixture


func before_each() -> void:
	_catalog = CatalogService.new()
	_catalog.load_all()
	_fixture = load(FIXTURE) as BuildFixture


func _build_from_fixture() -> ForgeBuild:
	var build := ForgeBuild.new(_fixture.hero, _fixture.level)
	for item: ItemData in _fixture.items:
		build.equip(item)
	return build


func test_atributos_iguais_ao_stats_do_servidor() -> void:
	var build := _build_from_fixture()
	var forge := build.attributes(_catalog.set_bonuses)
	var server := Stats.attributes(
		_fixture.hero, _fixture.level, _fixture.items, _catalog.set_bonuses
	)
	assert_eq(forge.max_hp, server.max_hp)
	assert_almost_eq(forge.defense, server.defense, EPS)
	assert_almost_eq(forge.attack, server.attack, EPS)
	assert_almost_eq(forge.intelligence, server.intelligence, EPS)
	assert_almost_eq(forge.agility, server.agility, EPS)
	assert_almost_eq(forge.move_speed, server.move_speed, EPS)
	assert_almost_eq(forge.attack_interval, server.attack_interval, EPS)
	assert_almost_eq(forge.mitigation, server.mitigation, EPS)


func test_valores_de_referencia_do_gdb() -> void:
	var attrs := _build_from_fixture().attributes(_catalog.set_bonuses)
	assert_eq(attrs.max_hp, 1305, "(1005 + 110) x 1,15 — a DV mostra 1397, vale o GDB")
	assert_almost_eq(attrs.defense, 99.0, EPS)
	assert_almost_eq(attrs.attack, 128.0, EPS)


func test_equipar_no_mesmo_slot_troca() -> void:
	var build := ForgeBuild.new(_fixture.hero, _fixture.level)
	build.equip(_catalog.item(&"guard_helm_t1"))
	build.equip(_catalog.item(&"guard_helm_t3"))
	assert_eq(build.items().size(), 1)
	assert_eq(build.item_in(ItemData.Slot.HELM).id, &"guard_helm_t3")


func test_no_maximo_um_item_por_slot() -> void:
	var build := _build_from_fixture()
	assert_eq(build.items().size(), MAX_ITEMS)
	for item: ItemData in _catalog.items:
		build.equip(item)
	assert_eq(build.items().size(), MAX_ITEMS)


func test_tirar_item_esvazia_o_slot() -> void:
	var build := _build_from_fixture()
	build.unequip(ItemData.Slot.BOOTS)
	assert_null(build.item_in(ItemData.Slot.BOOTS))
	assert_eq(build.items().size(), MAX_ITEMS - 1)


func test_conjunto_so_ativa_com_tres_pecas() -> void:
	var build := _build_from_fixture()
	assert_eq(build.set_pieces(&"guard"), 3)
	assert_eq(build.active_bonuses(_catalog.set_bonuses).size(), 1)
	build.unequip(ItemData.Slot.CHEST)
	assert_eq(build.set_pieces(&"guard"), 2)
	assert_eq(build.active_bonuses(_catalog.set_bonuses).size(), 0)


func test_mistura_de_conjuntos_nao_ativa_nenhum() -> void:
	var build := ForgeBuild.new(_fixture.hero, _fixture.level)
	build.equip(_catalog.item(&"guard_helm_t2"))
	build.equip(_catalog.item(&"hunter_chest_t2"))
	build.equip(_catalog.item(&"guard_boots_t2"))
	assert_eq(build.active_bonuses(_catalog.set_bonuses).size(), 0)


func test_nivel_fora_da_faixa_vira_o_limite() -> void:
	var max_level := XpTable.max_level(_catalog.xp_curve)
	var build := ForgeBuild.new(_fixture.hero, 0)
	build.clamp_level(max_level)
	assert_eq(build.level, 1)
	build.level = max_level + 5
	build.clamp_level(max_level)
	assert_eq(build.level, max_level)


func test_dano_recebido_usa_a_formula_do_gdb() -> void:
	var build := _build_from_fixture()
	var attrs := build.attributes(_catalog.set_bonuses)
	assert_almost_eq(build.damage_taken(100.0, attrs), 100.0 * 100.0 / (100.0 + 99.0), EPS)


func test_hp_efetivo_e_hp_sobre_a_fracao_que_passa() -> void:
	var build := _build_from_fixture()
	var attrs := build.attributes(_catalog.set_bonuses)
	assert_almost_eq(build.effective_hp(attrs), attrs.max_hp * (100.0 + 99.0) / 100.0, EPS)
