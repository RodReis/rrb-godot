extends GutTest
## Bestiario em partida (DV tela 5, PI 2026-10-09): B abre, Esc/B fecha, heroi parado enquanto
## aberto, ficha e preview do monstro selecionado sem criar monstro de verdade.

const BESTIARY: PackedScene = preload("res://scenes/ui/bestiary.tscn")

var _bestiary: Bestiary


func before_each() -> void:
	_bestiary = add_child_autofree(BESTIARY.instantiate())


func after_each() -> void:
	PlayerInput.suspended = false


func test_nothing_loaded_until_first_open() -> void:
	assert_eq(_bestiary.get_node("%List").get_child_count(), 0)


func test_lists_every_monster_and_shows_the_first() -> void:
	_bestiary.open()
	var list := _bestiary.get_node("%List") as CatalogList
	assert_eq(list.get_child_count(), _bestiary.monsters.size())
	assert_eq(list.selected_id(), _bestiary.monsters[0].id)


func test_open_and_close_suspend_player_input() -> void:
	assert_false(_bestiary.visible)
	_bestiary.toggle()
	assert_true(_bestiary.visible)
	assert_true(PlayerInput.suspended)
	_bestiary.toggle()
	assert_false(_bestiary.visible)
	assert_false(PlayerInput.suspended)


func test_select_boss_shows_detail_and_model_without_spawning_a_monster() -> void:
	var monsters_before := get_tree().get_nodes_in_group(Monster.GROUP).size()
	_bestiary.open()
	var boss := _bestiary.monsters[_bestiary.monsters.size() - 1]
	(_bestiary.get_node("%List") as CatalogList).select(boss.id)
	await wait_process_frames(1)
	assert_eq((_bestiary.get_node("%Detail") as DetailCard).accent, PanelCard.Accent.PURPLE)
	var stage := _bestiary.get_node("%Preview").get_node("%Stage") as Node3D
	assert_eq(stage.get_child_count(), 1)
	assert_not_null(stage.get_child(0).find_child("Crown", true, false))
	assert_eq(get_tree().get_nodes_in_group(Monster.GROUP).size(), monsters_before)


## F62 (ADR-0014): com heroi ligado, B abre na aba Heroi; sem heroi (selecao), em Monstros.
func test_without_hero_opens_on_monsters() -> void:
	_bestiary.open()
	assert_false(_bestiary.is_hero_tab())
	assert_true((_bestiary.get_node("%HeroTab") as Button).disabled)


func test_with_hero_opens_on_the_hero_sheet() -> void:
	var hero := _knight()
	_bestiary.bind_hero(hero)
	_bestiary.open()
	assert_true(_bestiary.is_hero_tab())
	assert_false((_bestiary.get_node("%Body") as Control).visible)
	assert_eq((_bestiary.get_node("%Title") as Label).text, "FICHA DO HERÓI")
	var sheet := _bestiary.get_node("%HeroSheet") as HeroSheet
	assert_eq(sheet._name.text, hero.hero_data.display_name.to_upper())
	assert_eq(sheet._items.get_child_count(), Inventory.SLOTS)
	assert_eq(sheet._skills.get_child_count(), 4)
	_bestiary.show_monsters()
	assert_false(_bestiary.is_hero_tab())
	assert_true((_bestiary.get_node("%Body") as Control).visible)


## A ficha rele o heroi a cada abertura: item novo, nivel e rank aparecem.
func test_sheet_follows_items_level_and_ranks() -> void:
	var hero := _knight()
	_bestiary.bind_hero(hero)
	_bestiary.open()
	_bestiary.close()
	hero.equipment = Inventory.equip(
		hero.equipment, hero.item_catalog.find(Ids.to_int(&"sword_t2"))
	)
	hero.level = 4
	hero.ranks = Vector3i(2, 0, 0)
	_bestiary.open()
	var sheet := _bestiary.get_node("%HeroSheet") as HeroSheet
	assert_eq(sheet._level.text, "Nível 4")
	var weapon := (
		(sheet._items.get_child(ItemData.Slot.WEAPON) as HBoxContainer).get_child(1) as Label
	)
	assert_string_contains(
		weapon.text, hero.item_catalog.find(Ids.to_int(&"sword_t2")).display_name
	)
	var q_facts := _facts_of(sheet, 1)
	assert_string_contains(q_facts, "Rank 2/5")
	var r_facts := _facts_of(sheet, 3)
	assert_string_contains(r_facts, "Não aprendida")


func test_skill_facts_use_the_rank_values() -> void:
	var q := (load("res://shared/data/heroes/knight.tres") as HeroData).skill_q
	assert_eq(HeroSheet.skill_facts(q, 2), "Rank 2/5 · Recarga 8,0 s · Base 80")
	assert_eq(HeroSheet.skill_facts(q, 0), "Não aprendida · Recarga 8,0 s · Base 50")


## Toda habilidade dos 4 herois do MVP2 tem descricao para a ficha.
func test_every_skill_has_a_description() -> void:
	for hero_id: String in ["knight", "ranger", "barbarian", "fire_wizard"]:
		var data := load("res://shared/data/heroes/%s.tres" % hero_id) as HeroData
		for skill: SkillData in [data.basic_attack, data.skill_q, data.skill_e, data.skill_r]:
			assert_false(skill.description.strip_edges().is_empty(), skill.id)


func _knight() -> Hero:
	var hero := (load("res://scenes/heroes/knight.tscn") as PackedScene).instantiate() as Hero
	hero.name = "1"
	add_child_autofree(hero)
	return hero


func _facts_of(sheet: HeroSheet, slot: int) -> String:
	var row := sheet._skills.get_child(slot) as HBoxContainer
	var text := row.get_child(1) as VBoxContainer
	return (text.get_child(1) as Label).text
