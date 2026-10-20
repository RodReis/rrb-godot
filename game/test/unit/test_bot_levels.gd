extends GutTest
## Niveis do bot no treino (F81, ADR-0021/0027): escada em Resource, regras puras de reacao, mira,
## habilidade, perseguicao e perfil por nivel. Medio = bot de antes do F81.

const LEVELS: String = "res://shared/data/rules/bot_levels.tres"
const PROFILE: String = "res://shared/data/rules/bot_profile.tres"
const EASY := 1
const MEDIUM := 2
const HARD := 3

var _levels: BotLevels
var _profile: BotProfile


func before_all() -> void:
	_levels = load(LEVELS) as BotLevels
	_profile = load(PROFILE) as BotProfile


func test_tres_tem_tres_niveis() -> void:
	assert_eq(_levels.count(), 3)
	assert_eq([_levels.pick(EASY).label, _levels.pick(HARD).label], ["Fácil", "Difícil"])


func test_numero_ausente_ou_fora_da_faixa_vira_medio() -> void:
	for number: int in [0, -1, 4, 99]:
		assert_eq(_levels.normalize(number), MEDIUM, "n=%d" % number)
		assert_eq(_levels.pick(number), _levels.pick(MEDIUM))


func test_medio_nao_muda_o_bot_de_hoje() -> void:
	var medium := _levels.pick(MEDIUM)
	assert_eq([medium.reaction_ticks, medium.aim_error_deg, medium.skill_chance], [1, 0.0, 1.0])
	assert_true(medium.chases)
	var same := BotRules.profile_for(_profile, medium)
	assert_eq(
		[same.retreat_hp_pct, same.fight_range], [_profile.retreat_hp_pct, _profile.fight_range]
	)


func test_ordem_da_escada_nos_parametros() -> void:
	var easy := _levels.pick(EASY)
	var hard := _levels.pick(HARD)
	assert_gt(easy.reaction_ticks, hard.reaction_ticks, "facil reage mais devagar")
	assert_gt(easy.aim_error_deg, hard.aim_error_deg, "facil erra mais a mira")
	assert_lt(easy.skill_chance, hard.skill_chance, "facil usa menos habilidade")
	assert_false(easy.chases)
	assert_gt(hard.retreat_hp_pct, easy.retreat_hp_pct, "dificil foge com mais vida")


func test_so_o_dificil_antecipa_a_mira() -> void:
	assert_eq(_levels.pick(EASY).lead_seconds, 0.0)
	assert_eq(_levels.pick(MEDIUM).lead_seconds, 0.0, "medio mira onde o alvo esta")
	assert_gt(_levels.pick(HARD).lead_seconds, 0.0)
	var lead := BotRules.lead_offset(Vector3(4, 2, -2), 0.5)
	assert_eq(lead, Vector3(2, 0, -1), "plano, so a velocidade horizontal")
	assert_eq(BotRules.lead_offset(Vector3(4, 0, 4), 0.0), Vector3.ZERO)


func test_so_o_dificil_farma_com_habilidade_e_briga_em_nivel_igual() -> void:
	assert_false(_levels.pick(EASY).farm_skills)
	assert_false(_levels.pick(MEDIUM).farm_skills, "medio farma so com o basico")
	assert_true(_levels.pick(HARD).farm_skills)
	assert_eq(_levels.pick(MEDIUM).level_slack, 0)
	assert_gt(_levels.pick(HARD).level_slack, 0)


func test_folga_de_nivel_faz_o_bot_brigar_em_nivel_igual() -> void:
	var v := BotView.new()
	v.level = 3
	v.enemy_level = 3
	v.hp_pct = 0.5
	v.enemy_hp_pct = 0.9
	assert_false(BotRules.has_advantage(v), "medio: nivel igual com menos HP nao briga")
	v.level_slack = 1
	assert_true(BotRules.has_advantage(v), "folga 1: ja conta como um nivel acima")
	v.enemy_level = 5
	assert_false(BotRules.has_advantage(v), "dois niveis abaixo continua sem briga")


func test_perfil_por_nivel_nao_mexe_no_original() -> void:
	var easy := BotRules.profile_for(_profile, _levels.pick(EASY))
	assert_eq([easy.retreat_hp_pct, easy.fight_range], [0.15, 6.0])
	assert_eq(easy.leap_range, _profile.leap_range, "o resto do perfil fica igual")
	assert_eq(_profile.retreat_hp_pct, 0.3, "o .tres compartilhado nao muda")


func test_reacao_decide_a_cada_n_ticks() -> void:
	var easy := _levels.pick(EASY)
	assert_true(BotRules.is_think_tick(0, easy))
	assert_false(BotRules.is_think_tick(1, easy))
	assert_true(BotRules.is_think_tick(easy.reaction_ticks, easy))
	assert_true(BotRules.is_think_tick(7, _levels.pick(MEDIUM)), "medio decide todo tick")


func test_erro_de_mira_gira_no_plano_e_respeita_o_maximo() -> void:
	var aim := Vector3(0, 0, 1)
	assert_eq(BotRules.aim_with_error(aim, 25.0, 0.0), aim, "sorteio 0 = sem erro")
	var turned := BotRules.aim_with_error(aim, 25.0, 1.0)
	assert_almost_eq(rad_to_deg(aim.angle_to(turned)), 25.0, 0.01)
	assert_eq(turned.y, 0.0)
	assert_eq(BotRules.aim_with_error(aim, 0.0, 1.0), aim, "medio mira certo")
	assert_eq(BotRules.aim_with_error(Vector3.ZERO, 25.0, 1.0), Vector3.ZERO)


func test_habilidade_sai_se_o_sorteio_cai_abaixo_da_chance() -> void:
	var easy := _levels.pick(EASY)
	assert_true(BotRules.keeps_skill(easy, easy.skill_chance - 0.01))
	assert_false(BotRules.keeps_skill(easy, easy.skill_chance))
	assert_true(BotRules.keeps_skill(_levels.pick(HARD), 0.999), "chance 1 sempre sai")


func test_facil_nao_persegue_na_fase_2() -> void:
	var v := BotView.new()
	v.phase2 = true
	v.enemy_alive = true
	v.enemy_in_zone = true
	v.zone_edge = 50.0
	v.can_chase = false
	var state := BotRules.next_state(BotRules.State.FARM, v, _profile)
	assert_ne(state, BotRules.State.CHASE)
	v.can_chase = true
	assert_eq(BotRules.next_state(BotRules.State.FARM, v, _profile), BotRules.State.CHASE)
