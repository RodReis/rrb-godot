extends GutTest
## TargetFrame (F66): aparece ao travar, mostra nome/etiqueta/HP e some ao destravar.

const SCENE: PackedScene = preload("res://shared/ui/components/target_frame.tscn")

var _frame: TargetFrame


func before_each() -> void:
	_frame = SCENE.instantiate() as TargetFrame
	add_child_autofree(_frame)


func test_nasce_escondida() -> void:
	assert_false(_frame.visible)


func test_bind_mostra_nome_etiqueta_e_hp() -> void:
	_frame.bind("Cavaleiro", "Nv 3", 240, 600)
	assert_true(_frame.visible)
	assert_eq((_frame.get_node("%TargetName") as Label).text, "Cavaleiro")
	assert_eq((_frame.get_node("%TargetTag") as Label).text, "Nv 3")
	var bar := _frame.get_node("%TargetHp").get_node("%Bar") as ProgressBar
	assert_eq(bar.max_value, 600.0)
	assert_eq(bar.value, 240.0)


func test_set_hp_do_mesmo_alvo_so_move_a_barra() -> void:
	_frame.bind("Esqueleto", "T1", 100, 100)
	_frame.set_hp(60, 100)
	assert_eq((_frame.get_node("%TargetHp").get_node("%Bar") as ProgressBar).value, 60.0)


func test_set_hp_com_maximo_novo_refaz_a_barra() -> void:
	_frame.bind("Cavaleiro", "Nv 1", 600, 600)
	_frame.set_hp(700, 800)
	var bar := _frame.get_node("%TargetHp").get_node("%Bar") as ProgressBar
	assert_eq(bar.max_value, 800.0)
	assert_eq(bar.value, 700.0)


func test_clear_esconde() -> void:
	_frame.bind("Cavaleiro", "Nv 1", 1, 1)
	_frame.clear()
	assert_false(_frame.visible)
