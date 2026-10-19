extends PaladinTestBase
## Bot de Paladino (SPEC-076 regra 5): Golpe Consagrado com o alvo a ate 2,5 u; Retribuicao ao
## entrar em Lutar ou ao tomar golpe corpo a corpo; Bencao com HP < 30 % ou dentro da zona.
## Limiares do bot_profile.tres.

const PROFILE: BotProfile = preload("res://shared/data/rules/bot_profile.tres")


func _bot_brain(level: int = 6) -> BotInput:
	_paladin = (load(PALADIN) as PackedScene).instantiate() as Paladin
	_paladin.name = str(CASTER)
	_paladin.team = GateRules.TEAM_A
	_paladin.level = level
	_paladin.is_bot = true
	_paladin.get_node("Input").set_script(BotInput)
	add_child_autofree(_paladin)
	var brain := _paladin.input as BotInput
	brain._hero = _paladin
	return brain


func _view(hp_pct: float) -> BotView:
	var view := BotView.new()
	view.hp_pct = hp_pct
	return view


func test_limiares_do_paladino_no_perfil() -> void:
	assert_eq([PROFILE.consecrate_range, PROFILE.blessing_hp_pct], [2.5, 0.3])


func test_regras_do_paladino() -> void:
	var rules := func(d: float, fight: bool, struck: bool, hp: float, zone: bool) -> Vector3i:
		return BotRules.paladin_skills(d, fight, struck, hp, zone, PROFILE)
	assert_eq(rules.call(2.5, false, false, 1.0, false), Vector3i(1, 0, 0), "Q inclusivo")
	assert_eq(rules.call(2.6, false, false, 1.0, false), Vector3i(0, 0, 0))
	assert_eq(rules.call(9.0, true, false, 1.0, false), Vector3i(0, 1, 0), "entrou em Lutar")
	assert_eq(rules.call(9.0, false, true, 1.0, false), Vector3i(0, 1, 0), "tomou golpe")
	assert_eq(rules.call(9.0, false, false, 0.29, false), Vector3i(0, 0, 1), "HP baixo")
	assert_eq(rules.call(9.0, false, false, 0.3, false), Vector3i(0, 0, 0), "30 % nao")
	assert_eq(rules.call(9.0, false, false, 1.0, true), Vector3i(0, 0, 1), "na zona")


func test_lutando_golpe_consagrado_so_colado() -> void:
	var brain := _bot_brain()
	var knight := _spawn_enemy(KNIGHT, AHEAD * 2.0)
	await wait_physics_frames(2)
	brain._attack(START, knight, true)
	assert_true(brain.skill_q, "2 u")
	assert_false(brain.skill_e, "E so em _paladin_reacts")
	assert_false(brain.skill_r)
	knight.global_position = AHEAD * 4.0
	brain._reset()
	brain._attack(START, knight, true)
	assert_false(brain.skill_q, "4 u")


func test_retribuicao_ao_tomar_golpe_com_inimigo_colado() -> void:
	var brain := _bot_brain()
	var knight := _spawn_enemy(KNIGHT, AHEAD * 1.5)
	brain._paladin_reacts(_view(1.0), knight)  # 1o think: guarda o HP
	_paladin.hp -= 50
	brain._paladin_reacts(_view(0.9), knight)
	assert_true(brain.skill_e)


func test_dano_sem_ninguem_colado_nao_gasta_a_retribuicao() -> void:
	var brain := _bot_brain()
	var knight := _spawn_enemy(KNIGHT, AHEAD * 6.0)
	brain._paladin_reacts(_view(1.0), knight)
	_paladin.hp -= 50
	brain._paladin_reacts(_view(0.9), knight)
	assert_false(brain.skill_e, "projetil de longe")


func test_bencao_com_hp_baixo_ou_na_zona() -> void:
	var brain := _bot_brain()
	brain._paladin_reacts(_view(0.2), null)
	assert_true(brain.skill_r, "HP baixo")
	brain._reset()
	_paladin.zone_ticks = 30
	brain._paladin_reacts(_view(1.0), null)
	assert_true(brain.skill_r, "na zona")


func test_bencao_sem_o_r_aprendido_nao_sai() -> void:
	var brain := _bot_brain(5)
	brain._paladin_reacts(_view(0.1), null)
	assert_false(brain.skill_r)
