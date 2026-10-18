extends BerserkerTestBase
## Bot de Berserker (SPEC-075 regra 6): Arremesso para alcancar (fora do alcance do basico, ate 7 u),
## Grito de Guerra ao entrar em Lutar, Ragnarok sob controle ou com HP abaixo de 40 % com perigo
## perto. Limiares do bot_profile.tres.

const PROFILE: BotProfile = preload("res://shared/data/rules/bot_profile.tres")
const BASIC_RANGE: float = 2.4


func test_limiares_do_berserker_no_perfil() -> void:
	assert_eq([PROFILE.throw_range, PROFILE.rage_hp_pct], [7.0, 0.4])


func test_arremesso_so_para_alcancar() -> void:
	assert_eq(BotRules.berserker_skills(5.0, BASIC_RANGE, false, 1.0, false, PROFILE).x, 1)
	assert_eq(BotRules.berserker_skills(7.0, BASIC_RANGE, false, 1.0, false, PROFILE).x, 1, "limite")
	assert_eq(BotRules.berserker_skills(7.5, BASIC_RANGE, false, 1.0, false, PROFILE).x, 0, "longe")
	assert_eq(BotRules.berserker_skills(2.0, BASIC_RANGE, false, 1.0, false, PROFILE).x, 0, "ja no golpe")


func test_grito_ao_entrar_em_lutar() -> void:
	assert_eq(BotRules.berserker_skills(5.0, BASIC_RANGE, true, 1.0, false, PROFILE).y, 1)
	assert_eq(BotRules.berserker_skills(5.0, BASIC_RANGE, false, 1.0, false, PROFILE).y, 0)


func test_ragnarok_sob_controle_ou_com_hp_baixo() -> void:
	assert_eq(BotRules.berserker_skills(5.0, BASIC_RANGE, false, 1.0, true, PROFILE).z, 1, "controlado")
	assert_eq(BotRules.berserker_skills(5.0, BASIC_RANGE, false, 0.39, false, PROFILE).z, 1, "HP < 40 %")
	assert_eq(BotRules.berserker_skills(5.0, BASIC_RANGE, false, 0.4, false, PROFILE).z, 0, "40 % ainda nao")


func test_lutando_longe_arremessa_e_corre() -> void:
	var brain := _bot_brain()
	var golem := _spawn_monster(GOLEM, -1, AHEAD * 5.0)
	await wait_physics_frames(2)
	brain._attack(START, golem, true)
	assert_true(brain.skill_q, "Arremesso para alcancar")
	assert_false(brain.skill_r, "HP cheio e livre")
	assert_false(brain.movement.is_zero_approx(), "fora do alcance: anda")


func test_farmando_so_o_basico() -> void:
	var brain := _bot_brain()
	var golem := _spawn_monster(GOLEM, -1, AHEAD * 5.0)
	await wait_physics_frames(2)
	brain._attack(START, golem, false)
	assert_false(brain.skill_q)
	assert_false(brain.skill_e)


func _danger(hp_pct: float) -> BotView:
	var view := BotView.new()
	view.hp_pct = hp_pct
	view.in_danger = true
	return view


func test_ragnarok_quando_preso_com_perigo_perto() -> void:
	var brain := _bot_brain()
	_berserker.slow_ticks = 30
	_berserker.slow_pct = 1.0
	brain._reset()
	brain._rage_when_needed(_danger(1.0))
	assert_true(brain.skill_r, "enraizado: Ragnarok")


func test_ragnarok_com_hp_baixo_e_perigo_perto() -> void:
	var brain := _bot_brain()
	brain._reset()
	brain._rage_when_needed(_danger(0.3))
	assert_true(brain.skill_r)


func test_ragnarok_nao_sem_perigo_nem_livre_com_hp_alto() -> void:
	var brain := _bot_brain()
	_berserker.slow_ticks = 30
	var calm := _danger(0.3)
	calm.in_danger = false
	brain._reset()
	brain._rage_when_needed(calm)
	assert_false(brain.skill_r, "sem perigo")
	_berserker.slow_ticks = 0
	brain._rage_when_needed(_danger(0.9))
	assert_false(brain.skill_r, "livre e com HP alto")


func test_ragnarok_em_recarga_nao_e_pedido() -> void:
	var brain := _bot_brain()
	_berserker.slow_ticks = 30
	_berserker.r_cooldown = 300
	brain._reset()
	brain._rage_when_needed(_danger(0.3))
	assert_false(brain.skill_r)
