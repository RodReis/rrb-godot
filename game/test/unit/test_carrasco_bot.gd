extends CarrascoTestBase
## Bot de Carrasco (SPEC-098 §5): Espinhos colado e recast no toque quando o alvo foge; Penitencia
## com o inimigo perto e HP < 60 % ou depois de golpes seguidos, sem encerrar antes; Correntes
## contra heroi com HP ate 40 % (execucao provavel). Limiares do bot_profile.tres.

const PROFILE: BotProfile = preload("res://shared/data/rules/bot_profile.tres")


func _bot_brain(level: int = 6) -> BotInput:
	_carrasco = (load(CARRASCO) as PackedScene).instantiate() as Carrasco
	_carrasco.name = str(CASTER)
	_carrasco.team = GateRules.TEAM_A
	_carrasco.level = level
	_carrasco.is_bot = true
	_carrasco.get_node("Input").set_script(BotInput)
	add_child_autofree(_carrasco)
	_carrasco.ranks = Vector3i(1, 1, 1)
	var brain := _carrasco.input as BotInput
	brain._hero = _carrasco
	return brain


func _view(hp_pct: float, enemy_distance: float) -> BotView:
	var view := BotView.new()
	view.hp_pct = hp_pct
	view.enemy_distance = enemy_distance
	return view


func test_limiares_do_carrasco_no_perfil() -> void:
	assert_eq(
		[
			PROFILE.thorns_range,
			PROFILE.recast_range,
			PROFILE.penance_range,
			PROFILE.penance_hp_pct,
			PROFILE.penance_hits,
			PROFILE.chains_range,
			PROFILE.chains_hp_pct,
		],
		[2.8, 6.5, 3.0, 0.6, 2, 5.5, 0.4]
	)


func test_regras_do_carrasco() -> void:
	var rules := func(d: float, recast: bool, hp: float, hits: int, target: float) -> Vector3i:
		return BotRules.carrasco_skills(d, recast, hp, hits, target, PROFILE)
	assert_eq(rules.call(2.8, false, 1.0, 0, 1.0), Vector3i(1, 0, 0), "Espinhos colado")
	assert_eq(rules.call(3.0, false, 1.0, 0, 1.0), Vector3i(0, 0, 0))
	assert_eq(rules.call(2.0, true, 1.0, 0, 1.0), Vector3i(0, 0, 0), "janela aberta, ainda perto")
	assert_eq(rules.call(5.0, true, 1.0, 0, 1.0), Vector3i(1, 0, 0), "fugiu: recast")
	assert_eq(rules.call(7.0, true, 1.0, 0, 1.0), Vector3i(0, 0, 0), "longe demais")
	assert_eq(rules.call(2.0, false, 0.59, 0, 1.0).y, 1, "HP baixo e perto")
	assert_eq(rules.call(4.0, false, 0.59, 0, 1.0).y, 0, "longe nao canaliza")
	assert_eq(rules.call(2.0, false, 1.0, 2, 1.0).y, 1, "golpes seguidos")
	assert_eq(rules.call(5.0, false, 1.0, 0, 0.4).z, 1, "execucao provavel")
	assert_eq(rules.call(5.0, false, 1.0, 0, 0.41).z, 0)
	assert_eq(rules.call(6.0, false, 1.0, 0, 0.1).z, 0, "fora do alcance")
	assert_eq(rules.call(2.0, false, 1.0, 0, -1.0).z, 0, "monstro nao")


func test_espinhos_colado_e_recast_no_toque() -> void:
	var brain := _bot_brain()
	var knight := _spawn_enemy(KNIGHT, AHEAD * 2.0)
	await wait_physics_frames(2)
	brain._attack(START, knight, true)
	assert_true(brain.skill_q, "colado: Espinhos")
	_carrasco.q_window_ticks = 60
	knight.global_position = AHEAD * 5.0
	brain._attack(START + 1, knight, true)
	assert_false(brain.skill_q, "solta um think antes do recast")
	brain._attack(START + 2, knight, true)
	assert_true(brain.skill_q, "toque de novo: recast")


func test_correntes_so_quando_a_execucao_e_provavel() -> void:
	var brain := _bot_brain()
	var knight := _spawn_enemy(KNIGHT, AHEAD * 5.0, VICTIM, 6)
	await wait_physics_frames(2)
	brain._attack(START, knight, true)
	assert_false(brain.skill_r, "HP cheio")
	knight.hp = int(knight.attributes.max_hp * 0.3)
	brain._attack(START + 1, knight, true)
	assert_true(brain.skill_r)


func test_penitencia_com_hp_baixo_e_inimigo_perto() -> void:
	var brain := _bot_brain()
	brain._carrasco_hp = _carrasco.hp
	brain._carrasco_reacts(_view(0.5, 2.0))
	assert_true(brain.skill_e)


func test_canalizando_nao_aperta_nada() -> void:
	var brain := _bot_brain()
	_carrasco.penance_ticks = 30
	brain.skill_e = true
	brain.skill_q = true
	brain._carrasco_reacts(_view(0.3, 2.0))
	assert_false(brain.skill_e, "E de novo encerraria antes")
	assert_false(brain.skill_q)
