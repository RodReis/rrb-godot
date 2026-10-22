extends GutTest
## Placa de HP no mundo (PI 2026-10-22): sem texto solto; nivel no selo (heroi = nivel, monstro =
## tier, chefe = coroa), rastro do dano que escorre e escudo na propria barra.

const KNIGHT: PackedScene = preload("res://scenes/heroes/knight.tscn")
const SKELETON: PackedScene = preload("res://scenes/monsters/skeleton_t1.tscn")
const BOSS: PackedScene = preload("res://scenes/monsters/skeleton_king_boss.tscn")


func _bar() -> WorldHealthBar:
	return add_child_autofree(WorldHealthBar.new()) as WorldHealthBar


func test_heroi_mostra_o_nivel_no_selo() -> void:
	var hero := KNIGHT.instantiate() as Hero
	hero.name = "1"
	hero.level = 4
	add_child_autofree(hero)
	hero._process(0.016)
	assert_eq(hero.hp_bar.badge_text(), str(hero.level))
	assert_null(hero.get_node_or_null("HpLabel"), "sem o texto antigo sobre a cabeca")


func test_monstro_mostra_o_tier_e_o_chefe_a_coroa() -> void:
	var skeleton := SKELETON.instantiate() as Monster
	add_child_autofree(skeleton)
	assert_eq(skeleton.hp_bar.badge_text(), "1")
	assert_null(skeleton.get_node_or_null("HpLabel"))
	var boss := BOSS.instantiate() as Monster
	add_child_autofree(boss)
	assert_eq(boss.hp_bar.badge_text(), "", "chefe: coroa no lugar do numero")
	assert_eq(boss.hp_bar.get_instance_shader_parameter(&"crown"), 1.0)


func test_queda_de_hp_deixa_o_rastro_que_escorre() -> void:
	var bar := _bar()
	bar.set_hp(100.0, 100.0)
	bar.set_hp(60.0, 100.0)
	assert_almost_eq(bar.ratio, 0.6, 0.0001)
	assert_almost_eq(bar.trail, 1.0, 0.0001, "o rastro fica no HP de antes")
	bar._process(WorldHealthBar.TRAIL_HOLD)
	bar._process(1.0)
	assert_almost_eq(bar.trail, 0.6, 0.0001, "depois escorre ate o HP atual")


func test_cura_nao_deixa_rastro() -> void:
	var bar := _bar()
	bar.set_hp(50.0, 100.0)
	bar._process(WorldHealthBar.TRAIL_HOLD)
	bar._process(1.0)
	bar.set_hp(80.0, 100.0)
	assert_almost_eq(bar.trail, 0.8, 0.0001)


func test_escudo_vai_para_a_barra_em_fracao_do_hp_maximo() -> void:
	var bar := _bar()
	bar.set_hp(500.0, 600.0, 120.0)
	assert_almost_eq(bar.get_instance_shader_parameter(&"shield"), 0.2, 0.0001)


func test_sem_selo_a_barra_ocupa_o_quad() -> void:
	var bar := _bar()
	assert_eq(bar.badge_text(), "")
	assert_eq((bar.mesh as QuadMesh).size, bar.bar_size)
