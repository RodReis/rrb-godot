extends GutTest
## F27: CatalogService carrega todo shared/data (fonte unica dos numeros, GDB vence — ADR-0004) e
## agrupa as variantes de monstro por especie para o Bestiario.

const HERO_COUNT: int = 7
const MONSTER_COUNT: int = 7
const SPECIES_COUNT: int = 6
const ITEM_COUNT: int = 21
const SET_COUNT: int = 2
const GOLEM: StringName = &"golem_t3"
const GOLEM_CORNER: StringName = &"golem_corner"
const GOLEM_TOTAL: int = 4

var _catalog: CatalogService


func before_each() -> void:
	_catalog = CatalogService.new()
	_catalog.load_all()


func test_carrega_todo_o_shared_data() -> void:
	assert_eq(_catalog.heroes.size(), HERO_COUNT)
	assert_eq(_catalog.monsters.size(), MONSTER_COUNT)
	assert_eq(_catalog.items.size(), ITEM_COUNT)
	assert_eq(_catalog.set_bonuses.size(), SET_COUNT)
	assert_not_null(_catalog.xp_curve)
	assert_not_null(_catalog.match_rules)


func test_nenhum_recurso_vem_nulo() -> void:
	for hero: HeroData in _catalog.heroes:
		assert_false(hero.display_name.is_empty(), "heroi sem nome")
	for monster: MonsterData in _catalog.monsters:
		assert_gt(monster.hp, 0.0, String(monster.id))
	for item: ItemData in _catalog.items:
		assert_false(item.display_name.is_empty(), String(item.id))


func test_carregar_de_novo_nao_duplica() -> void:
	_catalog.load_all()
	assert_eq(_catalog.monsters.size(), MONSTER_COUNT)
	assert_eq(_catalog.heroes.size(), HERO_COUNT)


func test_herois_padrao_vem_primeiro() -> void:
	assert_eq(_catalog.heroes[0].id, &"knight")
	assert_eq(_catalog.heroes[1].id, &"ranger")
	assert_eq(_catalog.heroes.size(), HERO_COUNT)


func test_busca_por_id() -> void:
	assert_eq(_catalog.hero(&"knight").display_name, "Cavaleiro")
	assert_null(_catalog.hero(&"nao_existe"))
	assert_eq(_catalog.monster(GOLEM_CORNER).species, GOLEM)
	assert_null(_catalog.monster(&"nao_existe"))
	assert_eq(_catalog.set_bonus(&"guard").pieces_required, 3)
	assert_null(_catalog.set_bonus(&"nao_existe"))


func test_itens_por_slot_e_conjunto() -> void:
	assert_eq(_catalog.items_in_slot(ItemData.Slot.WEAPON).size(), 3)
	assert_eq(_catalog.items_in_slot(ItemData.Slot.HELM).size(), 6)
	assert_eq(_catalog.items_of_set(&"guard").size(), 9)
	assert_eq(_catalog.items_of_set(&"hunter").size(), 9)


func test_especies_fundem_a_variante_do_golem() -> void:
	var groups := _catalog.monster_species()
	assert_eq(groups.size(), SPECIES_COUNT)
	var golem: MonsterSpecies = null
	for group: MonsterSpecies in groups:
		if group.id == GOLEM:
			golem = group
	assert_not_null(golem)
	assert_eq(golem.members.size(), 2)
	assert_eq(golem.lead().id, GOLEM)
	assert_eq(golem.total_count(), GOLEM_TOTAL)


func test_especies_ordenadas_por_tier_e_chefe_por_ultimo() -> void:
	var groups := _catalog.monster_species()
	var last_tier := -1
	for group: MonsterSpecies in groups:
		assert_gte(group.lead().tier, last_tier, "ordem por tier")
		last_tier = group.lead().tier
	assert_eq(groups.back().lead().tier, MonsterData.Tier.BOSS)


func test_chefe_surge_no_tempo_das_regras() -> void:
	assert_eq(_catalog.match_rules.boss_spawn_time, 210.0)


func test_ordem_das_especies_e_estavel_no_mesmo_tier() -> void:
	var names := PackedStringArray()
	for group: MonsterSpecies in _catalog.monster_species():
		names.append(String(group.id))
	assert_eq(
		names,
		PackedStringArray(
			[
				"skeleton_t1",
				"skeleton_mage_t2",
				"skeleton_warrior_t2",
				"wolf_t2",
				"golem_t3",
				"skeleton_king_boss",
			]
		)
	)


func test_pecas_que_ativam_os_conjuntos() -> void:
	assert_eq(_catalog.set_piece_counts(), PackedInt32Array([3]))
