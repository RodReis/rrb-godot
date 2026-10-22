extends GutTest
## F85 (SPEC-085 §2): os 6 passos do tutorial como regra pura. Cada passo avanca quando o jogador
## faz a acao; o roteiro so ordena eventos (nao muda numeros).

const KNIGHT: HeroData = preload("res://shared/data/heroes/knight.tres")
const CURVE: XpCurve = preload("res://shared/data/rules/xp_table.tres")


## Progress com os campos de [param fields] (nome -> valor).
func _progress(fields: Dictionary) -> TutorialRules.Progress:
	var progress := TutorialRules.Progress.new()
	for field: String in fields:
		progress.set(field, fields[field])
	return progress


func _done(step: TutorialRules.Step, fields: Dictionary) -> bool:
	return TutorialRules.is_complete(step, _progress(fields))


func test_seis_passos_na_ordem_da_spec() -> void:
	assert_eq(TutorialRules.STEP_COUNT, 6)
	var order: Array[TutorialRules.Step] = [
		TutorialRules.Step.MOVE_CAMERA,
		TutorialRules.Step.TARGET_ATTACK,
		TutorialRules.Step.SKILLS,
		TutorialRules.Step.MONSTER_XP,
		TutorialRules.Step.CHEST_SHEET,
		TutorialRules.Step.PHASE2,
	]
	var step := TutorialRules.Step.MOVE_CAMERA
	for expected: TutorialRules.Step in order:
		assert_eq(step, expected)
		step = TutorialRules.next(step)
	assert_eq(step, TutorialRules.Step.DONE)
	assert_eq(TutorialRules.next(TutorialRules.Step.DONE), TutorialRules.Step.DONE)


func test_progresso_novo_nao_completa_nenhum_passo() -> void:
	for index: int in TutorialRules.STEP_COUNT:
		assert_false(_done(index as TutorialRules.Step, {}), str(index))


func test_passo_1_pede_andar_girar_e_zoom() -> void:
	var step := TutorialRules.Step.MOVE_CAMERA
	var walked := {"moved": TutorialRules.MOVE_DISTANCE, "orbited": TutorialRules.ORBIT_RADIANS}
	assert_false(_done(step, {"moved": 100.0}))
	assert_false(_done(step, walked))
	assert_true(
		_done(step, {"moved": walked["moved"], "orbited": walked["orbited"], "zoomed": true})
	)


func test_passo_1_nao_conta_andar_curto_nem_giro_curto() -> void:
	var step := TutorialRules.Step.MOVE_CAMERA
	var short_walk := {
		"moved": TutorialRules.MOVE_DISTANCE - 0.1,
		"orbited": TutorialRules.ORBIT_RADIANS,
		"zoomed": true,
	}
	var short_orbit := {
		"moved": TutorialRules.MOVE_DISTANCE,
		"orbited": TutorialRules.ORBIT_RADIANS - 0.01,
		"zoomed": true,
	}
	assert_false(_done(step, short_walk))
	assert_false(_done(step, short_orbit))


func test_passo_2_pede_alvo_e_golpe() -> void:
	var step := TutorialRules.Step.TARGET_ATTACK
	assert_false(_done(step, {"targeted": true}))
	assert_false(_done(step, {"struck": true}))
	assert_true(_done(step, {"targeted": true, "struck": true}))


func test_passo_3_pede_q_e_e_r() -> void:
	var step := TutorialRules.Step.SKILLS
	assert_false(_done(step, {"used_q": true, "used_e": true}))
	assert_true(_done(step, {"used_q": true, "used_e": true, "used_r": true}))


func test_passo_4_pede_abate_nivel_e_ponto_gasto() -> void:
	var step := TutorialRules.Step.MONSTER_XP
	assert_false(_done(step, {"monster_killed": true, "leveled": true}))
	assert_true(_done(step, {"monster_killed": true, "leveled": true, "point_spent": true}))


func test_passo_5_pede_bau_item_e_ficha() -> void:
	var step := TutorialRules.Step.CHEST_SHEET
	assert_false(_done(step, {"chest_opened": true, "item_taken": true}))
	var all := {"chest_opened": true, "item_taken": true, "sheet_opened": true}
	assert_true(_done(step, all))


func test_passo_6_so_com_a_vitoria() -> void:
	var step := TutorialRules.Step.PHASE2
	assert_false(_done(step, {}))
	assert_true(_done(step, {"won": true}))


func test_concluido_nunca_pede_nada() -> void:
	assert_false(_done(TutorialRules.Step.DONE, {"won": true}))


func test_nivel_inicial_libera_o_r_do_cavaleiro() -> void:
	# O passo 3 vem antes de qualquer XP: o roteiro garante o nivel do R (SPEC-085 §2).
	assert_gte(TutorialRules.START_LEVEL, KNIGHT.skill_r.required_hero_level[0])
	var ranks := XpTable.typical_ranks(CURVE, TutorialRules.START_LEVEL)
	assert_gte(ranks.x, 1, "Q aprendido")
	assert_gte(ranks.y, 1, "E aprendido")
	assert_gte(ranks.z, 1, "R aprendido")


func test_xp_de_ajuste_deixa_faltando_so_1_xp_para_o_proximo_nivel() -> void:
	var start := XpTable.xp_for_level(CURVE, TutorialRules.START_LEVEL)
	var add := TutorialRules.xp_top_up(CURVE, start)
	assert_gt(add, 0)
	assert_eq(XpTable.level_for_xp(CURVE, start + add), TutorialRules.START_LEVEL)
	assert_eq(XpTable.level_for_xp(CURVE, start + add + 1), TutorialRules.START_LEVEL + 1)


func test_xp_de_ajuste_e_zero_quando_ja_esta_perto_ou_no_nivel_maximo() -> void:
	var next_level_xp := XpTable.xp_for_level(CURVE, TutorialRules.START_LEVEL + 1)
	assert_eq(TutorialRules.xp_top_up(CURVE, next_level_xp - 1), 0)
	assert_eq(TutorialRules.xp_top_up(CURVE, next_level_xp - 5), 4)
	var top := XpTable.xp_for_level(CURVE, XpTable.max_level(CURVE))
	assert_eq(TutorialRules.xp_top_up(CURVE, top), 0)


func test_textos_de_todos_os_passos() -> void:
	for index: int in TutorialRules.STEP_COUNT:
		var step := index as TutorialRules.Step
		assert_false(TutorialRules.title(step).is_empty(), "titulo %d" % index)
		assert_false(TutorialRules.instruction(step).is_empty(), "instrucao %d" % index)
