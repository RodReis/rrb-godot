extends GutTest
## FSM do bot da fase 1 com estado falso (PRD §3.7, CONVENTION §4.6; limiares do PI 2026-10-09):
## Recuar > Lutar > Contestar > Farmar a base > Saquear a base > Farmar o centro.

const PROFILE: String = "res://shared/data/rules/bot_profile.tres"
const S := BotRules.State

var _profile: BotProfile


func before_all() -> void:
	_profile = load(PROFILE) as BotProfile


## Bot no inicio: base cheia, ninguem perto, 0:30 de partida.
func _view() -> BotView:
	var v := BotView.new()
	v.level = 2
	v.enemy_level = 2
	v.elapsed = 30.0
	v.contest_time = 180.0
	v.base_monsters_left = 5
	v.base_chests_left = 6
	return v


func _next(state: BotRules.State, v: BotView) -> BotRules.State:
	return BotRules.next_state(state, v, _profile)


func test_perfil_aprovado() -> void:
	assert_eq(
		[
			_profile.retreat_hp_pct,
			_profile.danger_range,
			_profile.safe_seconds,
			_profile.fight_range,
			_profile.contest_hp_pct
		],
		[0.3, 8.0, 3.0, 8.0, 0.7]
	)


func test_comeca_farmando_a_base() -> void:
	assert_eq(_next(S.FARM, _view()), S.FARM)


func test_base_limpa_saqueia_os_baus_da_base() -> void:
	var v := _view()
	v.base_monsters_left = 0
	assert_eq(_next(S.FARM, v), S.LOOT)


func test_base_limpa_e_saqueada_farma_o_centro() -> void:
	var v := _view()
	v.base_monsters_left = 0
	v.base_chests_left = 0
	assert_eq(_next(S.LOOT, v), S.FARM)


func test_contesta_a_partir_de_3_00_com_nivel_igual_ou_maior() -> void:
	var v := _view()
	v.elapsed = 180.0
	assert_eq(_next(S.FARM, v), S.CONTEST)
	v.enemy_level = 3
	assert_eq(_next(S.FARM, v), S.FARM)
	v.elapsed = 179.9
	v.enemy_level = 2
	assert_eq(_next(S.FARM, v), S.FARM)


func test_so_contesta_o_boss_com_hp_de_70_por_cento_ou_mais() -> void:
	# PI 2026-10-10 (#74): sem cura passiva, voltar ao boss com HP baixo era morrer em loop.
	var v := _view()
	v.elapsed = 180.0
	v.hp_pct = 0.7
	assert_eq(_next(S.FARM, v), S.CONTEST)
	v.hp_pct = 0.69
	assert_eq(_next(S.FARM, v), S.FARM)
	assert_eq(_next(S.CONTEST, v), S.FARM, "larga o boss quando o HP cai")
	assert_false(BotRules.wants_contest(v, _profile))


func test_luta_com_nivel_maior() -> void:
	var v := _view()
	v.enemy_distance = 8.0
	v.level = 3
	assert_eq(_next(S.FARM, v), S.FIGHT)


func test_nivel_igual_luta_so_com_hp_percentual_maior() -> void:
	var v := _view()
	v.enemy_distance = 5.0
	v.hp_pct = 0.8
	v.enemy_hp_pct = 0.6
	assert_eq(_next(S.FARM, v), S.FIGHT)
	v.enemy_hp_pct = 0.8
	assert_eq(_next(S.FARM, v), S.FARM)


func test_sem_vantagem_ou_longe_nao_luta() -> void:
	var v := _view()
	v.enemy_distance = 5.0
	v.enemy_level = 3
	assert_eq(_next(S.FARM, v), S.FARM)
	v.enemy_level = 1
	v.enemy_distance = 8.1
	assert_eq(_next(S.FARM, v), S.FARM)


func test_recua_com_hp_baixo_e_perigo_perto() -> void:
	var v := _view()
	v.hp_pct = 0.29
	v.in_danger = true
	v.enemy_distance = 5.0
	v.level = 5
	assert_eq(_next(S.FIGHT, v), S.RETREAT)


func test_hp_baixo_sem_perigo_nao_recua() -> void:
	var v := _view()
	v.hp_pct = 0.2
	assert_eq(_next(S.FARM, v), S.FARM)


func test_continua_recuando_ate_3_s_sem_perigo() -> void:
	var v := _view()
	v.hp_pct = 0.2
	v.safe_seconds = 2.9
	assert_eq(_next(S.RETREAT, v), S.RETREAT)
	v.safe_seconds = 3.0
	assert_eq(_next(S.RETREAT, v), S.FARM)


func test_com_a_fonte_fica_recuado_ate_70_por_cento() -> void:
	# PI 2026-10-10 (#74): o bot recua ate a fonte e so sai com HP para contestar o boss.
	var v := _view()
	v.can_heal = true
	v.safe_seconds = 10.0
	v.hp_pct = 0.69
	assert_eq(_next(S.RETREAT, v), S.RETREAT)
	v.hp_pct = 0.7
	assert_eq(_next(S.RETREAT, v), S.FARM)
	v.hp_pct = 0.5
	assert_eq(_next(S.FARM, v), S.FARM, "fonte nao puxa quem nao recuou")


func test_recuo_gasto_nao_volta_a_recuar_com_o_mesmo_hp_baixo() -> void:
	var v := _view()
	v.hp_pct = 0.2
	v.in_danger = true
	v.retreat_spent = true
	assert_eq(_next(S.FARM, v), S.FARM)


func test_recuo_gasto_libera_quando_hp_passa_do_limiar() -> void:
	assert_true(BotRules.retreat_spent_after(S.RETREAT, S.FARM, 0.2, false, _profile))
	assert_true(BotRules.retreat_spent_after(S.FARM, S.FARM, 0.2, true, _profile))
	assert_false(BotRules.retreat_spent_after(S.FARM, S.FARM, 0.3, true, _profile))
