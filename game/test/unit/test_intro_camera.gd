extends GutTest
## IntroCamera (F69): comeca na INTRO, conduz a camera ate o blend, trava o input do heroi local,
## acusa ready ao servidor quando acaba e, se o servidor corta antes (8 s), pula para o blend.

const RULES: String = "res://shared/data/rules/match_pacing.tres"
const KNIGHT: String = "res://scenes/heroes/knight.tscn"
const RATE: int = 30
const START: int = 1000
const ME: int = 1  # id do peer local sem rede
const RIVAL: int = 22
const SPAWN_A: Vector3 = Vector3(0.0, 0.0, 30.0)
const SPAWN_B: Vector3 = Vector3(0.0, 0.0, -30.0)

var _match: MatchController
var _clock: MatchClock
var _camera: FollowCamera
var _players: Node3D
var _intro: IntroCamera


func before_each() -> void:
	PlayerInput.cinematic = false
	var rules := load(RULES) as MatchRules
	_clock = MatchClock.new()
	_clock.rules = rules
	add_child_autofree(_clock)
	_match = MatchController.new()
	_match.rules = rules
	_match.clock = _clock
	_match.available_heroes = [&"knight"]
	add_child_autofree(_match)
	_match.open(START, RATE)
	_camera = FollowCamera.new()
	add_child_autofree(_camera)
	_players = Node3D.new()
	add_child_autofree(_players)
	_marker(GateRules.TEAM_A, SPAWN_A)
	_marker(GateRules.TEAM_B, SPAWN_B)
	_intro = IntroCamera.new()
	add_child_autofree(_intro)
	_intro.bind(_camera, _match, _players)


func after_each() -> void:
	PlayerInput.cinematic = false


func _marker(team: int, where: Vector3) -> void:
	var marker := SpawnMarker.new()
	marker.kind = SpawnMarker.Kind.HERO
	marker.team = team
	marker.position = where
	add_child_autofree(marker)


func _spawn_me() -> Hero:
	var hero := (load(KNIGHT) as PackedScene).instantiate() as Hero
	hero.name = str(ME)
	hero.team = GateRules.TEAM_B
	hero.transform = Transform3D(Basis.looking_at(Vector3.BACK), SPAWN_B)
	_players.add_child(hero)
	return hero


func _to_intro() -> void:
	_match.join(ME, GateRules.TEAM_B, false, START)
	_match.join(RIVAL, GateRules.TEAM_A, true, START)
	_match.submit_pick(ME, &"knight", START)
	_match.submit_pick(RIVAL, &"knight", START)


func _seat(peer: int) -> MatchController.Seat:
	for seat: MatchController.Seat in _match.seats():
		if seat.peer == peer:
			return seat
	return null


func test_so_comeca_na_intro() -> void:
	assert_false(_intro.is_running())
	assert_false(PlayerInput.cinematic)
	_spawn_me()
	_to_intro()
	assert_true(_intro.is_running())
	assert_true(PlayerInput.cinematic, "heroi sem input na cinematica")


func test_voo_comeca_com_a_cinematica_sozinha_na_camera() -> void:
	_spawn_me()
	_to_intro()
	_intro.advance(1.0)
	assert_true(_camera.intro_active)
	assert_eq(_camera.intro_rig_weight, 0.0)
	assert_gt(_camera.intro_pose.origin.y, IntroRules.FLIGHT_HEIGHT - 0.01)


func test_voo_do_jogador_do_time_b_termina_na_base_dele() -> void:
	_spawn_me()
	_to_intro()
	_intro.advance(0.01)
	var early := _camera.intro_pose.origin
	_intro.advance(IntroRules.FLIGHT_SECONDS - 0.02)
	var late := _camera.intro_pose.origin
	assert_gt(early.z, late.z, "sai da base A (+Z) e chega perto da base B (-Z)")
	assert_lt(absf(late.z - (SPAWN_B.z + IntroRules.FLIGHT_BACK)), 1.0)


func test_ready_so_depois_do_blend() -> void:
	_spawn_me()
	_to_intro()
	_intro.advance(IntroRules.READY_AT - 0.1)
	assert_false(_seat(ME).ready, "ainda no blend")
	_intro.advance(0.2)
	assert_true(_seat(ME).ready)


func test_atraso_artificial_posterga_o_ready() -> void:
	_intro.ready_delay = 3.0
	_spawn_me()
	_to_intro()
	_intro.advance(IntroRules.READY_AT + 2.9)
	assert_false(_seat(ME).ready)
	_intro.advance(0.2)
	assert_true(_seat(ME).ready)


func test_corte_aos_8_s_pula_para_o_blend_e_devolve_o_controle() -> void:
	_intro.ready_delay = 99.0
	_spawn_me()
	_to_intro()
	_intro.advance(1.0)
	_match.update(_match.deadline_tick)
	assert_eq(_match.state, MatchState.State.PHASE1)
	assert_true(_intro.is_running(), "falta o blend")
	assert_gte(_intro.seconds(), IntroRules.FLIGHT_SECONDS + IntroRules.CLOSE_SECONDS)
	_intro.advance(IntroRules.BLEND_SECONDS + 0.05)
	assert_false(_intro.is_running())
	assert_false(_camera.intro_active)
	assert_false(PlayerInput.cinematic)


func test_saida_por_ready_dos_dois_devolve_a_camera_ao_jogo_e_libera_o_input() -> void:
	_spawn_me()
	_to_intro()  # o adversario e bot: ja pronto
	_intro.advance(IntroRules.READY_AT + 0.1)
	assert_true(_seat(ME).ready)
	_match.update(_match.deadline_tick - 1)  # ainda antes do corte
	assert_eq(_match.state, MatchState.State.PHASE1, "o ready do cliente abriu a fase 1")
	_intro.advance(0.1)
	assert_false(_intro.is_running())
	assert_false(_camera.intro_active)
	assert_false(PlayerInput.cinematic)


func test_bestiario_nao_abre_na_cinematica() -> void:
	_spawn_me()
	_to_intro()
	assert_true(PlayerInput.cinematic)
	InputActions.ensure()
	var bestiary := (load("res://scenes/ui/bestiary.tscn") as PackedScene).instantiate() as Bestiary
	add_child_autofree(bestiary)
	var key := InputEventAction.new()
	key.action = InputActions.OPEN_BESTIARY
	key.pressed = true
	bestiary._unhandled_input(key)
	assert_false(bestiary.visible)


func test_espera_o_heroi_local_antes_de_tocar() -> void:
	_to_intro()
	_intro.advance(0.5)
	assert_eq(_intro.seconds(), 0.0, "sem heroi ainda")
	assert_false(_camera.intro_active)
	_spawn_me()
	_intro.advance(0.1)
	assert_gt(_intro.seconds(), 0.0)
	assert_true(_camera.intro_active)


func test_sem_heroi_depois_de_1_s_toca_mesmo_assim() -> void:
	_to_intro()
	_intro.advance(IntroCamera.HERO_WAIT_SECONDS + 0.1)
	_intro.advance(0.1)
	assert_gt(_intro.seconds(), 0.0)
	assert_true(_camera.intro_active)
