extends CarrascoTestBase
## Carrasco (GDB §4.11, F98; SPEC-098 §6 item 1): atributos, Espada (100 % do ATK, +1 Dor por alvo),
## Dor (teto e expiracao) e a Couraca (so basico de heroi, depois da DEF). Servidor = processo do teste.


func test_nivel_1_tem_os_atributos_base() -> void:
	var carrasco := _spawn_carrasco()
	assert_eq(carrasco.hp, CARRASCO_HP)
	assert_almost_eq(carrasco.attributes.defense, CARRASCO_DEF, EPS)
	assert_eq(carrasco.ranks, Vector3i(1, 0, 0))
	assert_eq(carrasco.pain, 0)


func test_espada_fere_100_por_cento_do_atk_e_da_dor() -> void:
	_spawn_carrasco()
	var knight := _spawn_enemy(KNIGHT, AHEAD * 2.0)
	_carrasco.input.attack = true
	_run(START, 3)
	assert_eq(KNIGHT_HP - knight.hp, CombatRules.mitigated(roundi(CARRASCO_ATK), KNIGHT_DEF))
	assert_eq(_carrasco.pain, 1)


func test_espada_nao_alcanca_alem_de_2_2_u() -> void:
	_spawn_carrasco()
	var knight := _spawn_enemy(KNIGHT, AHEAD * 2.5)
	_carrasco.input.attack = true
	_run(START, 3)
	assert_eq(knight.hp, KNIGHT_HP)
	assert_eq(_carrasco.pain, 0, "errou: sem Dor")


func test_cada_alvo_do_arco_da_uma_dor() -> void:
	_spawn_carrasco()
	_spawn_enemy(KNIGHT, AHEAD * 1.5, VICTIM)
	_spawn_monster(GOLEM, 900, AHEAD * 1.8 + Vector3(0.6, 0, 0))
	_carrasco.input.attack = true
	_run(START, 1)
	assert_eq(_carrasco.pain, 2, "heroi e monstro")


func test_dor_para_no_teto_6() -> void:
	_spawn_carrasco()
	_spawn_enemy(KNIGHT, AHEAD * 1.5)
	for i: int in 8:
		_carrasco.input.attack = true
		_run(START + i * RATE, RATE)  # 1 golpe por segundo (recarga 1 s)
	assert_eq(_carrasco.pain, 6)


func test_dor_cai_toda_depois_de_6_s_sem_ganho() -> void:
	_spawn_carrasco()
	_spawn_enemy(KNIGHT, AHEAD * 1.5)
	_carrasco.input.attack = true
	_run(START, 1)
	assert_eq(_carrasco.pain, 1)
	_run(START + 1, 6 * RATE - 1)
	assert_eq(_carrasco.pain, 1, "ainda no 6o segundo")
	_run(START + 6 * RATE, 1)
	assert_eq(_carrasco.pain, 0)


func test_couraca_tira_15_por_cento_do_basico_de_heroi() -> void:
	_spawn_carrasco()
	_strike_carrasco(START, 9, HitEffect.new(100, AHEAD))
	_run(START, 1)
	var after_def := CombatRules.mitigated(100, CARRASCO_DEF)
	assert_eq(CARRASCO_HP - _carrasco.hp, roundi(after_def * 0.85))


func test_couraca_nao_vale_para_skill_nem_monstro() -> void:
	_spawn_carrasco()
	_strike_carrasco(START, 9, HitEffect.new(100, AHEAD), HitLedger.Slot.Q)
	_run(START, 1)
	var after_def := CombatRules.mitigated(100, CARRASCO_DEF)
	assert_eq(CARRASCO_HP - _carrasco.hp, after_def, "skill de heroi")
	var hp := _carrasco.hp
	var effect := HitEffect.new(100, AHEAD)
	effect.attacker_id = 0
	_carrasco.receive_hit(START + 1, HitLedger.source_key(-900, HitLedger.Slot.BASIC), effect)
	_run(START + 1, 1)
	assert_eq(hp - _carrasco.hp, after_def, "basico de monstro (receive_hit direto)")


func test_couraca_vale_no_basico_de_um_heroi_de_verdade() -> void:
	_spawn_carrasco()
	var knight := _spawn_enemy(KNIGHT, AHEAD * 1.5)
	knight.input.attack = true
	_run(START, 2)
	var raw := roundi(SkillRules.amount(knight.hero_data.basic_attack, 1, knight.attributes))
	assert_eq(
		CARRASCO_HP - _carrasco.hp, roundi(CombatRules.mitigated(raw, CARRASCO_DEF) * 0.85)
	)


func test_morte_zera_a_dor() -> void:
	_spawn_carrasco()
	_carrasco.pain = 4
	_carrasco.pain_ticks = 100
	var effect := HitEffect.new(0, AHEAD)
	effect.true_damage = 5000
	_strike_carrasco(START, 9, effect, HitLedger.Slot.ZONE)
	_run(START, 1)
	assert_false(_carrasco.is_alive())
	assert_eq(_carrasco.pain, 0)
