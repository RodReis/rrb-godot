extends GutTest
## F27: textos do Bestiario e da Forja — funcoes puras sobre os Resources de shared/data
## (FRONTEND-LAUNCHER §8.3 regra 2: nenhum numero vem do prototipo).

var _catalog: CatalogService


func before_each() -> void:
	_catalog = CatalogService.new()
	_catalog.load_all()


func test_decimal_usa_virgula_e_nao_sobra_zero() -> void:
	assert_eq(CompendiumFormat.decimal(1.5), "1,5")
	assert_eq(CompendiumFormat.decimal(2.0), "2")
	assert_eq(CompendiumFormat.decimal(0.9), "0,9")


func test_milhar_com_ponto() -> void:
	assert_eq(CompendiumFormat.thousands(1800), "1.800")
	assert_eq(CompendiumFormat.thousands(220), "220")
	assert_eq(CompendiumFormat.thousands(1234567), "1.234.567")


func test_relogio_mm_ss() -> void:
	assert_eq(CompendiumFormat.clock(210.0), "03:30")
	assert_eq(CompendiumFormat.clock(300.0), "05:00")
	assert_eq(CompendiumFormat.clock(0.0), "00:00")


func test_percentual_de_fracao() -> void:
	assert_eq(CompendiumFormat.percent(0.15), "15%")
	assert_eq(CompendiumFormat.percent(0.065), "6,5%")
	assert_eq(CompendiumFormat.percent(1.0), "100%")


func test_estatisticas_do_item_na_ordem_do_gdb() -> void:
	var chest := _catalog.item(&"guard_chest_t2")
	assert_eq(CompendiumFormat.item_stats(chest), PackedStringArray(["+110 HP", "+12 DEF"]))
	var boots := _catalog.item(&"guard_boots_t2")
	assert_eq(CompendiumFormat.item_stats(boots), PackedStringArray(["+5 DEF", "+10% AGI"]))
	var helm := _catalog.item(&"hunter_helm_t2")
	assert_eq(CompendiumFormat.item_stats(helm), PackedStringArray(["+8 ATQ", "+6 AGI"]))
	var sword := _catalog.item(&"sword_t1")
	assert_eq(CompendiumFormat.item_stats(sword), PackedStringArray(["+12 ATQ"]))


func test_todo_item_do_catalogo_tem_estatistica_escrita() -> void:
	for item: ItemData in _catalog.items:
		assert_false(CompendiumFormat.item_stats(item).is_empty(), String(item.id))


func test_bonus_de_conjunto() -> void:
	assert_eq(CompendiumFormat.bonus_text(_catalog.set_bonus(&"guard")), "+15% HP máximo · +10 DEF")
	assert_eq(
		CompendiumFormat.bonus_text(_catalog.set_bonus(&"hunter")),
		"+10% vel. de ataque · +8% vel. de movimento"
	)


func test_passiva_da_arma_epica() -> void:
	var text := CompendiumFormat.passive_text(_catalog.item(&"sword_t3_epic"))
	assert_string_contains(text, "Fúria")
	assert_string_contains(text, "6%")
	assert_eq(CompendiumFormat.passive_text(_catalog.item(&"sword_t1")), "")


func test_drops_por_raridade() -> void:
	assert_eq(CompendiumFormat.drop_text(_catalog.monster(&"skeleton_t1")), "Comum 20%")
	assert_eq(
		CompendiumFormat.drop_text(_catalog.monster(&"skeleton_mage_t2")), "Comum 35% · Raro 65%"
	)
	assert_eq(CompendiumFormat.drop_text(_catalog.monster(&"golem_corner")), "—")
	assert_eq(CompendiumFormat.drop_text(_catalog.monster(&"skeleton_king_boss")), "Épico 100%")


func test_alcance_e_golpe() -> void:
	assert_eq(CompendiumFormat.reach_text(_catalog.monster(&"skeleton_t1")), "Corpo a corpo 1,8 u")
	assert_eq(CompendiumFormat.reach_text(_catalog.monster(&"skeleton_mage_t2")), "À distância 7 u")
	assert_eq(CompendiumFormat.strike_text(_catalog.monster(&"skeleton_t1")), "Alvo único")
	assert_eq(CompendiumFormat.strike_text(_catalog.monster(&"golem_t3")), "Em área, raio 2,5 u")
	assert_eq(
		CompendiumFormat.strike_text(_catalog.monster(&"skeleton_king_boss")),
		"Em área, raio 3 u · empurra 2,5 u"
	)


func test_nome_do_tier_e_do_slot() -> void:
	assert_eq(CompendiumFormat.tier_name(MonsterData.Tier.T1), "Tier 1")
	assert_eq(CompendiumFormat.tier_name(MonsterData.Tier.BOSS), "Chefe")
	assert_eq(CompendiumFormat.slot_name(ItemData.Slot.CHEST), "Peitoral")
	assert_eq(CompendiumFormat.rarity_name(ItemData.Rarity.EPIC), "Épico")


func test_origem_do_item_por_raridade() -> void:
	var rules := _catalog.match_rules
	var boss := _catalog.boss()
	assert_eq(
		CompendiumFormat.chest_sources(ItemData.Rarity.COMMON, rules, boss),
		"Baús comuns (6 por base): 70% de item comum"
	)
	assert_eq(
		CompendiumFormat.chest_sources(ItemData.Rarity.RARE, rules, boss),
		"Baús raros (4 no centro): 65% · baús reforçados: 50%"
	)
	assert_eq(
		CompendiumFormat.chest_sources(ItemData.Rarity.EPIC, rules, boss),
		"Rei Esqueleto: 100% garantido · baús raros: 10%"
	)


func test_arte_dos_monstros_existe_para_cada_especie() -> void:
	for group: MonsterSpecies in _catalog.monster_species():
		assert_not_null(CompendiumArt.monster(group.lead().id), String(group.id))
	assert_null(CompendiumArt.monster(&"nao_existe"))


func test_icones_dos_itens_existem() -> void:
	for item: ItemData in _catalog.items:
		var hero := &"knight" if item.slot == ItemData.Slot.WEAPON else &""
		assert_not_null(CompendiumArt.item(item, hero), String(item.id))
