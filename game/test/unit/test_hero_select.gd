extends GutTest
## Tela de selecao (DV tela 2) ligada ao MatchController: abre com o primeiro heroi disponivel,
## heroi sem cena fica indisponivel, o lock-in so vale quando o servidor confirma, e o pick do
## adversario aparece no card dele (espelho permitido).

const SCENE: String = "res://scenes/ui/hero_select.tscn"
const RULES: String = "res://shared/data/rules/match_pacing.tres"
const ROSTER: Array[HeroData] = [
	preload("res://shared/data/heroes/knight.tres"),
	preload("res://shared/data/heroes/ranger.tres"),
]
const KNIGHT_ONLY: Array[StringName] = [&"knight"]
const RATE: int = 30
const START: int = 1000
const RIVAL: int = 22

var _match: MatchController
var _screen: HeroSelect


func before_each() -> void:
	var rules := load(RULES) as MatchRules
	var clock := MatchClock.new()
	clock.rules = rules
	add_child_autofree(clock)
	_match = MatchController.new()
	_match.rules = rules
	_match.clock = clock
	_match.available_heroes = KNIGHT_ONLY.duplicate()
	add_child_autofree(_match)
	_match.open(START, RATE)
	_match.join(multiplayer.get_unique_id(), GateRules.TEAM_A, false, START)
	_match.join(RIVAL, GateRules.TEAM_B, false, START)
	_screen = (load(SCENE) as PackedScene).instantiate() as HeroSelect
	add_child_autofree(_screen)
	_screen.bind(_match, ROSTER, KNIGHT_ONLY.duplicate())
	_screen.open(24.0)


## Troca de modelo no preview usa queue_free: deixa o frame liberar antes da contagem de orfaos.
func after_each() -> void:
	await wait_process_frames(1)


func _press(key: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = key
	event.pressed = true
	_screen._unhandled_input(event)


func _my_hero() -> StringName:
	for seat: MatchController.Seat in _match.seats():
		if seat.peer == multiplayer.get_unique_id():
			return seat.hero
	return &"?"


func test_abre_com_o_cavaleiro_e_a_arqueira_indisponivel() -> void:
	assert_true(_screen.visible)
	assert_eq(_screen._player_name.text, "CAVALEIRO")
	assert_false(_screen._buttons[0].disabled)
	assert_true(_screen._buttons[1].disabled)
	assert_string_contains(_screen._buttons[1].text, "INDISPONÍVEL")


func test_tecla_2_nao_escolhe_heroi_indisponivel() -> void:
	_press(KEY_2)
	assert_eq(_screen._player_name.text, "CAVALEIRO")


func test_atributos_comparaveis_entre_os_herois() -> void:
	var hp := _screen._stats[0]
	assert_eq(hp._bar.max_value, maxf(ROSTER[0].base_hp, ROSTER[1].base_hp))
	assert_eq(hp._bar.value, ROSTER[0].base_hp)


func test_espaco_confirma_e_o_servidor_registra() -> void:
	_press(KEY_1)
	var space := InputEventAction.new()
	space.action = &"ui_accept"
	space.pressed = true
	_screen._unhandled_input(space)
	assert_eq(_my_hero(), &"knight")
	assert_string_contains(_screen._status.text, "PRONTO")
	assert_true(_screen._lock_in.disabled)
	_screen.lock_in()
	assert_eq(_match.state, MatchState.State.HERO_PICK, "segundo lock-in nao muda nada")


func test_pick_do_adversario_aparece_no_card_dele() -> void:
	_match.submit_pick(RIVAL, &"knight", START)
	assert_eq(_screen._enemy_name.text, "CAVALEIRO")
	assert_eq(_screen._enemy_status.text, "PRONTO")


func test_timeout_mostra_o_heroi_padrao_como_meu() -> void:
	_match.update(START + 24 * RATE)
	assert_eq(_match.state, MatchState.State.PHASE1)
	assert_eq(_screen._player_name.text, "CAVALEIRO")
	assert_true(_screen._lock_in.disabled)


func test_close_esconde() -> void:
	_screen.close()
	assert_false(_screen.visible)


func test_modelo_so_do_heroi_com_cena() -> void:
	var model := HeroSelect.model_of(&"knight")
	assert_not_null(model)
	assert_false(model.is_in_group(Hero.GROUP))
	model.free()
	assert_null(HeroSelect.model_of(&"ranger"))
