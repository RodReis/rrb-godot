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
