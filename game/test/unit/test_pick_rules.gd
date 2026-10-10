extends GutTest
## Selecao de herois (CONVENTION §3, R-PEND-04): sem escolha, P1 Cavaleiro e P2 Arqueira; heroi
## indisponivel (Arqueira ate o F14) cai no primeiro disponivel; so heroi disponivel e aceito.

const DEFAULTS: Array[StringName] = [&"knight", &"ranger"]
const BOTH: Array[StringName] = [&"knight", &"ranger"]
const KNIGHT_ONLY: Array[StringName] = [&"knight"]
const NONE: Array[StringName] = []


func test_padrao_do_slot_com_os_dois_disponiveis() -> void:
	assert_eq(PickRules.default_hero(DEFAULTS, 0, BOTH), &"knight")
	assert_eq(PickRules.default_hero(DEFAULTS, 1, BOTH), &"ranger")


func test_padrao_indisponivel_cai_no_primeiro_disponivel() -> void:
	assert_eq(PickRules.default_hero(DEFAULTS, 1, KNIGHT_ONLY), &"knight")


func test_slot_sem_padrao_cai_no_primeiro_disponivel() -> void:
	assert_eq(PickRules.default_hero(DEFAULTS, 5, KNIGHT_ONLY), &"knight")
	assert_eq(PickRules.default_hero(DEFAULTS, -1, BOTH), &"knight")


func test_sem_heroi_disponivel_nao_ha_padrao() -> void:
	assert_eq(PickRules.default_hero(DEFAULTS, 0, NONE), &"")


func test_aceita_so_heroi_disponivel() -> void:
	assert_true(PickRules.can_pick(&"knight", KNIGHT_ONLY))
	assert_false(PickRules.can_pick(&"ranger", KNIGHT_ONLY))
	assert_false(PickRules.can_pick(&"", BOTH))
	assert_false(PickRules.can_pick(&"golem_t3", BOTH))
