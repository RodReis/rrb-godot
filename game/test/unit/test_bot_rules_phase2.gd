extends GutTest
## FSM do bot na fase 2 com estado falso (PRD §3.7, F19): Fugir da zona > Lutar > Perseguir > o
## resto. Sem Recuar (a fonte fecha aos 5:00) e o recuo da fase 1 acaba.

const PROFILE: String = "res://shared/data/rules/bot_profile.tres"
const S := BotRules.State

var _profile: BotProfile


func before_all() -> void:
	_profile = load(PROFILE) as BotProfile


## Bot em 6:40, dentro da zona, com o adversario vivo e longe.
func _view() -> BotView:
	var v := BotView.new()
	v.level = 2
	v.enemy_level = 2
	v.elapsed = 400.0
	v.contest_time = 180.0
	v.base_monsters_left = 5
	v.base_chests_left = 6
	v.phase2 = true
	v.zone_edge = 20.0
	v.enemy_alive = true
	return v


func _next(state: BotRules.State, v: BotView) -> BotRules.State:
	return BotRules.next_state(state, v, _profile)


func test_perfil_da_fase_2() -> void:
	assert_eq(_profile.zone_margin, 2.0)


func test_perto_da_borda_da_zona_foge_antes_de_lutar() -> void:
	var v := _view()
	v.enemy_distance = 3.0
	v.level = 5
	v.zone_edge = 1.9
	assert_eq(_next(S.FIGHT, v), S.FLEE_ZONE)
	v.zone_edge = -4.0
	assert_eq(_next(S.CHASE, v), S.FLEE_ZONE, "fora da zona")
	v.zone_edge = 2.0
	assert_eq(_next(S.FLEE_ZONE, v), S.FIGHT, "a margem ja basta")


func test_foge_da_zona_mesmo_com_hp_baixo_e_perigo() -> void:
	var v := _view()
	v.hp_pct = 0.1
	v.in_danger = true
	v.zone_edge = -1.0
	assert_eq(_next(S.RETREAT, v), S.FLEE_ZONE)


func test_nao_recua_nem_fica_preso_no_recuo_da_fase_1() -> void:
	var v := _view()
	v.hp_pct = 0.1
	v.in_danger = true
	v.enemy_distance = 20.0
	assert_eq(_next(S.FARM, v), S.CHASE)
	assert_eq(_next(S.RETREAT, v), S.CHASE, "o recuo da fase 1 acaba aos 5:00")


func test_persegue_o_adversario_vivo_dentro_da_zona() -> void:
	var v := _view()
	v.enemy_distance = 12.0
	v.level = 1
	v.enemy_level = 6
	assert_eq(_next(S.FARM, v), S.CHASE, "sem vantagem tambem persegue")
	v.enemy_in_zone = false
	assert_ne(_next(S.CHASE, v), S.CHASE, "fora da zona ele toma dano sozinho")
	v.enemy_in_zone = true
	v.enemy_alive = false
	assert_ne(_next(S.CHASE, v), S.CHASE, "morto, espera o renascimento")


func test_luta_com_vantagem_ao_alcance() -> void:
	var v := _view()
	v.enemy_distance = 8.0
	v.level = 5
	assert_eq(_next(S.CHASE, v), S.FIGHT)
	v.level = 1
	assert_eq(_next(S.FIGHT, v), S.CHASE, "sem vantagem so persegue")


func test_sem_adversario_a_perseguir_cai_no_resto_da_fsm() -> void:
	var v := _view()
	v.enemy_alive = false
	v.base_monsters_left = 0
	v.base_chests_left = 0
	assert_eq(_next(S.CHASE, v), S.CONTEST, "depois dos 3:00, o resto da FSM vale")


func test_fase_1_ignora_a_zona() -> void:
	var v := _view()
	v.phase2 = false
	v.zone_edge = -10.0
	assert_ne(_next(S.FARM, v), S.FLEE_ZONE)
	assert_ne(_next(S.FARM, v), S.CHASE)


func test_ponto_de_fuga_fica_a_duas_margens_da_borda_no_rumo_do_centro() -> void:
	var center := Vector3.ZERO
	var out := BotRules.flee_point(Vector3(30.0, 0.0, 0.0), center, 20.0, 2.0)
	assert_almost_eq(out, Vector3(16.0, 0.0, 0.0), Vector3.ONE * 0.001)
	var diag := BotRules.flee_point(Vector3(0.0, 3.0, -50.0), center, 20.0, 2.0)
	assert_almost_eq(diag, Vector3(0.0, 0.0, -16.0), Vector3.ONE * 0.001, "plano, sem y")


func test_ponto_de_fuga_e_o_centro_com_a_zona_pequena_ou_no_centro() -> void:
	var center := Vector3(1.0, 0.0, 2.0)
	assert_eq(BotRules.flee_point(Vector3(9.0, 0.0, 9.0), center, 4.0, 2.0), center)
	assert_eq(BotRules.flee_point(center, center, 30.0, 2.0), center)
