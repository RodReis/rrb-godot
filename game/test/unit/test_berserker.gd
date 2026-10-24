extends BerserkerTestBase
## berserker.tscn (GDB §4.8 e §2.2-E, F75; SPEC-075 aceite): Frenesi (velocidade de ataque e roubo
## de vida so no basico), Machados Gemeos, Arremesso de Machado, Grito de Guerra e Ragnarok (limpa e
## bloqueia os 5 controles). Servidor = processo do teste (peer offline).


func test_nivel_1_tem_os_atributos_base() -> void:
	var b := _spawn_berserker(1)
	assert_eq(b.hp, BERSERKER_HP)
	assert_almost_eq(b.attributes.move_speed, 6.1 * (1.0 + 20.0 * 0.004), EPS)
	assert_eq(b.ranks, Vector3i(1, 0, 0))
	assert_almost_eq(b.frenzy(), 0.0, EPS, "HP cheio: sem Frenesi")


func test_machados_gemeos_ferem_todo_o_arco_com_100_por_cento_do_atk() -> void:
	_spawn_berserker(1)
	var left := _spawn_monster(GOLEM, -1, Vector3(-1.0, 0, -1.5))
	var right := _spawn_monster(GOLEM, -2, Vector3(1.0, 0, -1.5))
	var behind := _spawn_monster(GOLEM, -3, Vector3(0, 0, 1.5))
	_berserker.input.attack = true
	_run(START, 1)
	assert_eq(GOLEM_HP - left.hp, BERSERKER_ATK)
	assert_eq(GOLEM_HP - right.hp, BERSERKER_ATK)
	assert_eq(behind.hp, GOLEM_HP, "fora do arco de 90 graus")


func test_basico_alterna_a_mao() -> void:
	var b := _spawn_berserker(1)
	_spawn_monster(GOLEM, -1, AHEAD * 1.5)
	var first := b.swing_left
	b.input.attack = true
	_run(START, 1)
	assert_ne(b.swing_left, first)
	b.basic_cooldown = 0
	b.input.attack = true
	_run(START + 1, 1)
	assert_eq(b.swing_left, first)


func test_frenesi_acelera_o_basico_conforme_o_hp() -> void:
	var b := _spawn_berserker(1)
	b.input.attack = true
	_run(START, 1)
	assert_eq(b.basic_cooldown, _interval_ticks(0.0), "100 % de HP: so a formula D")
	for case: Array in [[0.6, 0.5], [0.2, 1.0], [0.1, 1.0]]:
		b.hp = roundi(BERSERKER_HP * (case[0] as float))
		b.basic_cooldown = 0
		b.input.attack = true
		_run(START + 1, 1)
		assert_almost_eq(
			b.frenzy(), case[1] as float, 0.01, "f a %d %% de HP" % roundi(case[0] * 100)
		)
		assert_eq(
			b.basic_cooldown,
			_interval_ticks(case[1]),
			"intervalo a %d %% de HP" % roundi(case[0] * 100)
		)


func test_roubo_de_vida_cura_sobre_o_dano_depois_da_def() -> void:
	var b := _spawn_berserker(1)
	_spawn_knight(AHEAD * 1.5)
	b.hp = roundi(BERSERKER_HP * 0.2)  # f = 1
	var before := b.hp
	b.input.attack = true
	_run(START, 2)
	var dealt := CombatRules.mitigated(BERSERKER_ATK, KNIGHT_DEF)
	assert_eq(b.hp - before, BerserkerRules.lifesteal_heal(dealt, 1.0, FRENZY_LIFESTEAL))
	assert_gt(b.hp, before)


func test_roubo_de_vida_nada_com_hp_cheio() -> void:
	var b := _spawn_berserker(1)
	_spawn_knight(AHEAD * 1.5)
	b.input.attack = true
	_run(START, 2)
	assert_eq(b.hp, BERSERKER_HP)


func test_roubo_de_vida_soma_os_alvos_do_arco() -> void:
	var b := _spawn_berserker(1)
	_spawn_monster(GOLEM, -1, Vector3(-1.0, 0, -1.5))
	_spawn_monster(GOLEM, -2, Vector3(1.0, 0, -1.5))
	b.hp = roundi(BERSERKER_HP * 0.2)
	var before := b.hp
	b.input.attack = true
	_run(START, 2)
	assert_eq(
		b.hp - before, BerserkerRules.lifesteal_heal(2 * BERSERKER_ATK, 1.0, FRENZY_LIFESTEAL)
	)


func test_errar_nao_cura() -> void:
	var b := _spawn_berserker(1)
	_spawn_monster(GOLEM, -1, AHEAD * 6.0)
	b.hp = roundi(BERSERKER_HP * 0.2)
	var before := b.hp
	b.input.attack = true
	_run(START, 2)
	assert_eq(b.hp, before)


func test_arremesso_fere_e_deixa_lento_o_primeiro_alvo_sem_roubar_vida() -> void:
	var b := _spawn_berserker(1)
	var knight := _spawn_knight(AHEAD * 5.0)
	var behind := _spawn_knight(AHEAD * 6.5, 9)
	b.hp = roundi(BERSERKER_HP * 0.2)
	var before := b.hp
	b.input.skill_q = true
	var tick := START
	while knight.slow_ticks == 0 and tick < START + 20:
		_run(tick, 1)
		tick += 1
	var q := b.hero_data.skill_q
	var damage := roundi(SkillRules.amount(q, 1, b.attributes))
	assert_eq(damage, roundi(60.0 + 0.6 * BERSERKER_ATK))
	assert_eq(KNIGHT_HP - knight.hp, CombatRules.mitigated(damage, KNIGHT_DEF))
	assert_almost_eq(knight.slow_pct, 0.3, EPS)
	assert_eq(knight.slow_ticks, SLOW_TICKS)
	_run(tick, 10)
	assert_eq(behind.hp, KNIGHT_HP, "para no 1o toque")
	assert_eq(b.hp, before, "skill nao rouba vida")


func test_arremesso_tira_o_machado_da_mao_por_1_s() -> void:
	var b := _spawn_berserker(1)
	b.input.skill_q = true
	_run(START, 1)
	assert_eq(b.axe_out_ticks, 30)
	_run(START + 1, 30)
	assert_eq(b.axe_out_ticks, 0)


func test_grito_de_guerra_soma_def_e_velocidade_por_2_s() -> void:
	var b := _spawn_berserker(2)
	b.ranks = Vector3i(1, 1, 0)
	b.input.skill_e = true
	_run(START, 1)
	assert_eq(b.shout_ticks, SHOUT_TICKS, "desconta a partir do tick seguinte")
	assert_almost_eq(b._defense(), BERSERKER_DEF + 1.8 + 30.0, EPS, "DEF do nivel 2 + 30")
	assert_almost_eq(b._move_speed(), b.attributes.move_speed * 1.15, EPS)
	_run(START + 1, SHOUT_TICKS)
	assert_almost_eq(b._defense(), b.attributes.defense, EPS, "acabou")


func test_grito_reduz_o_dano_recebido() -> void:
	var b := _spawn_berserker(2)
	b.ranks = Vector3i(1, 1, 0)
	b.input.skill_e = true
	_run(START, 1)
	var hp := b.hp
	_hit_berserker(START + 1, HitLedger.Slot.BASIC, HitEffect.new(100, AHEAD))
	_run(START + 1, 1)
	assert_eq(hp - b.hp, CombatRules.mitigated(100, b.attributes.defense + 30.0))


func test_ragnarok_frenesi_no_maximo_e_velocidade_por_4_s() -> void:
	var b := _spawn_berserker(6)
	b.input.skill_r = true
	_run(START, 1)
	assert_true(b.is_raging())
	assert_almost_eq(b.frenzy(), 1.0, EPS, "f = 1 com HP cheio")
	assert_almost_eq(b._move_speed(), b.attributes.move_speed * 1.25, EPS)
	b.input.attack = true
	_run(START + 1, 1)
	assert_eq(b.basic_cooldown, _interval_ticks(1.0))
	_run(START + 2, RAGE_TICKS)
	assert_false(b.is_raging(), "4 s")


func test_ragnarok_limpa_lentidao_raiz_e_empurrao_ativos() -> void:
	var b := _spawn_berserker(6)
	b.slow_ticks = 40
	b.slow_pct = 1.0
	b.knockback_ticks = 6
	b.knockback_velocity = SIDE * 5.0
	b.input.skill_r = true
	_run(START, 1)
	assert_eq(b.slow_ticks, 0)
	assert_eq(b.knockback_ticks, 0)


func test_ragnarok_bloqueia_os_5_controles() -> void:
	var b := _spawn_berserker(6)
	b.input.skill_r = true
	_run(START, 1)
	var slow := HitEffect.new(10, AHEAD)
	slow.slow = 0.3
	slow.slow_ticks = 45
	var root := HitEffect.new(10, AHEAD)
	root.slow = 1.0
	root.slow_ticks = 45
	var stun := HitEffect.new(10, AHEAD, Vector3.ZERO, 30)
	var push := HitEffect.new(10, AHEAD, SIDE * 3.0)
	var pull := HitEffect.new(10, AHEAD, -SIDE * 3.0)
	pull.push_ticks = 9
	var hp := b.hp
	var slots: Array[HitLedger.Slot] = [
		HitLedger.Slot.BASIC,
		HitLedger.Slot.Q,
		HitLedger.Slot.E,
		HitLedger.Slot.R,
		HitLedger.Slot.REWARD
	]
	var effects: Array[HitEffect] = [slow, root, stun, push, pull]
	for i: int in effects.size():
		_hit_berserker(START + 1, slots[i], effects[i])
	_run(START + 1, 1)
	assert_lt(b.hp, hp, "o dano passa")
	assert_eq(b.slow_ticks, 0, "lentidao e raiz")
	assert_eq(b.stun_ticks, 0, "atordoamento")
	assert_eq(b.knockback_ticks, 0, "empurrao e puxao")


func test_controle_volta_a_pegar_depois_do_ragnarok() -> void:
	var b := _spawn_berserker(6)
	b.input.skill_r = true
	_run(START, RAGE_TICKS + 1)
	assert_false(b.is_raging())
	var slow := HitEffect.new(10, AHEAD)
	slow.slow = 0.3
	slow.slow_ticks = 45
	_hit_berserker(START + RAGE_TICKS + 1, HitLedger.Slot.BASIC, slow)
	_run(START + RAGE_TICKS + 1, 1)
	assert_gt(b.slow_ticks, 0)


func test_outro_heroi_nao_tem_frenesi_nem_imunidade() -> void:
	_spawn_berserker(1)
	var knight := _spawn_knight(AHEAD * 10.0)
	assert_null(knight.hero_data.passive)
	assert_eq(knight.cc_immune_ticks, 0)
	assert_almost_eq(knight._defense(), knight.attributes.defense, EPS)
	assert_almost_eq(knight._move_speed(), knight.attributes.move_speed, EPS)


func test_golpe_que_mata_o_monstro_tambem_cura() -> void:
	var b := _spawn_berserker(1)
	var golem := _spawn_monster(GOLEM, -1, AHEAD * 1.5)
	golem.hp = 30  # o golpe (42) mata; causou 30
	b.hp = roundi(BERSERKER_HP * 0.2)
	var before := b.hp
	b.input.attack = true
	_run(START, 2)
	assert_false(golem.is_alive())
	assert_eq(b.hp - before, BerserkerRules.lifesteal_heal(30, 1.0, FRENZY_LIFESTEAL))


func test_ressimular_o_golpe_no_monstro_nao_encolhe_a_cura() -> void:
	var b := _spawn_berserker(1)
	var golem := _spawn_monster(GOLEM, -1, AHEAD * 1.5)
	golem.hp = 100  # depois do 1o golpe sobram 58: recalcular daria 58, nao 42
	b.hp = roundi(BERSERKER_HP * 0.2)
	var before := b.hp
	b.input.attack = true
	b._rollback_tick(TICK, START, true)
	b.basic_cooldown = 0  # ressimula o mesmo tick: o monstro ja tomou o golpe
	b.input.attack = true
	b._rollback_tick(TICK, START, false)
	_run(START + 1, 1)
	assert_eq(b.hp - before, BerserkerRules.lifesteal_heal(BERSERKER_ATK, 1.0, FRENZY_LIFESTEAL))


func test_cura_e_dano_fatal_no_mesmo_tick_nao_dependem_da_ordem() -> void:
	for heal_first: bool in [true, false]:
		var b := _spawn_berserker(1)
		b.hp = 10
		var heal := HitEffect.new()
		heal.heal = 300  # aplicada antes, salvaria (10 + 300 > dano 169 depois da DEF)
		var lethal := HitEffect.new(200, AHEAD)
		if heal_first:
			_hit_berserker(START, HitLedger.Slot.REWARD, heal)
			_hit_berserker(START, HitLedger.Slot.BASIC, lethal)
		else:
			_hit_berserker(START, HitLedger.Slot.BASIC, lethal)
			_hit_berserker(START, HitLedger.Slot.REWARD, heal)
		_run(START, 1)
		assert_false(b.is_alive(), "golpe fatal mata (cura primeiro: %s)" % heal_first)
