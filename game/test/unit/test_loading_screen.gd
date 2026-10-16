extends GutTest
## Tela de loading do Game (F68, SPEC-068): sorteio, dica da lista, barra e Esc. Nada disso existe
## no servidor headless (os testes rodam em headless, entao wanted() tem de ser falso).

var _screen: LoadingScreen
var _tips: TipList


func before_each() -> void:
	_tips = load(LoadingRules.TIPS_PATH) as TipList
	_screen = add_child_autofree(LoadingScreen.new())


func test_starts_hidden() -> void:
	assert_false(_screen.visible)


func test_nothing_is_created_on_the_headless_server() -> void:
	assert_eq(DisplayServer.get_name(), "headless")
	assert_false(LoadingScreen.wanted())


func test_show_random_picks_the_drawn_art_and_a_tip_from_the_list() -> void:
	_screen.show_random(7, _tips)
	assert_true(_screen.visible)
	assert_eq(_screen.art_index, LoadingRules.art_index(7))
	assert_has(_tips.tips, _screen.tip_text)


func test_same_seed_shows_the_same_tip() -> void:
	_screen.show_random(11, _tips)
	var first := _screen.tip_text
	_screen.show_random(11, _tips)
	assert_eq(_screen.tip_text, first)


func test_progress_bar_follows_the_stages_and_never_goes_back() -> void:
	_screen.show_random(1, _tips)
	var bar := _screen.find_children("*", "ProgressBar", true, false)[0] as ProgressBar
	assert_eq(bar.value, 0.0)
	_screen.report(LoadingProgress.Stage.WARMUP, 0.5)
	var half := bar.value
	assert_gt(half, 0.0)
	_screen.report(LoadingProgress.Stage.WARMUP, 0.1)
	assert_eq(bar.value, half)
	_screen.complete(LoadingProgress.Stage.WARMUP)
	_screen.complete(LoadingProgress.Stage.CONNECT)
	_screen.complete(LoadingProgress.Stage.WAIT)
	assert_almost_eq(bar.value, 1.0, 0.0001)


func test_show_random_resets_the_progress() -> void:
	_screen.show_random(1, _tips)
	_screen.complete(LoadingProgress.Stage.WARMUP)
	_screen.show_random(2, _tips)
	assert_eq(_screen.progress.value(), 0.0)


func test_dismiss_hides_the_screen() -> void:
	_screen.show_random(1, _tips)
	_screen.dismiss()
	assert_false(_screen.visible)


func test_escape_requests_exit_only_while_visible() -> void:
	var event := InputEventAction.new()
	event.action = &"ui_cancel"
	event.pressed = true
	watch_signals(_screen)
	_screen._unhandled_input(event)
	assert_signal_not_emitted(_screen, "exit_requested")
	_screen.show_random(1, _tips)
	_screen._unhandled_input(event)
	assert_signal_emitted(_screen, "exit_requested")
