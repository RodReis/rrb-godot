extends OccultistTestBase
## Maldicao do Ocultista (GDB §2.2-F, F77; SPEC-077 aceite): o Projetil Sombrio fere 90 % do ATK e
## soma 1 marca (1 -> 2 -> 3, teto 3), a marca nova renova a duracao de todas, elas caem juntas, a
## DEF efetiva nunca fica negativa e o desconto vem depois dos bonus de DEF. Vale em heroi e
## monstro (boss incluido). Servidor = processo do teste (peer offline).


func test_nivel_1_tem_os_atributos_base() -> void:
	var occultist := _spawn_occultist(1)
	assert_eq(occultist.hp, 370)
	assert_almost_eq(occultist.attributes.move_speed, 6.0 * (1.0 + 14.0 * 0.004), EPS)
	assert_eq(occultist.ranks, Vector3i(1, 0, 0))


func test_projetil_sombrio_fere_90_por_cento_do_atk_e_marca() -> void:
	_spawn_occultist(1)
	var knight := _spawn_knight(AHEAD * 4.0)
	_occultist.input.attack = true
	_run(START, 20)
	assert_eq(_basic_damage(), roundi(0.9 * 42.0))
	assert_eq(KNIGHT_HP - knight.hp, CombatRules.mitigated(_basic_damage(), KNIGHT_DEF))
	assert_eq(knight.curse_stacks, 1)
	assert_between(knight.curse_ticks, CURSE_TICKS - 20, CURSE_TICKS)


func test_marcas_sobem_1_2_3_e_cada_golpe_ja_pega_a_defesa_menor() -> void:
	_spawn_occultist(1)
	var knight := _spawn_knight(AHEAD * 4.0)
	var drops: Array[int] = []
	var last_hp := knight.hp
	for tick: int in range(START, START + 4 * 34 + 20):
		_run_attacking(tick, 1)
		if knight.hp < last_hp:
			drops.append(last_hp - knight.hp)
			last_hp = knight.hp
	assert_gte(drops.size(), 4)
	# O golpe fere com a DEF que o alvo tinha antes dele e so entao soma a marca.
	for marks: int in 4:
		var defense := KNIGHT_DEF - 6.0 * mini(marks, 3)
		assert_eq(drops[marks], CombatRules.mitigated(_basic_damage(), defense), "golpe %d" % marks)
	assert_eq(knight.curse_stacks, 3, "teto de 3 marcas")


func test_marca_nova_renova_a_duracao_de_todas() -> void:
	_spawn_occultist(1)
	var knight := _spawn_knight(AHEAD * 4.0)
	knight.curse_stacks = 2
	knight.curse_ticks = 10
	_occultist.input.attack = true
	_run(START, 20)
	assert_eq(knight.curse_stacks, 3)
	assert_gt(knight.curse_ticks, 90, "voltou perto de 4 s")


func test_as_marcas_caem_todas_juntas_no_fim_da_duracao() -> void:
	_spawn_occultist(1)
	var knight := _spawn_knight(AHEAD * 4.0)
	knight.curse_stacks = 3
	knight.curse_ticks = 5
	assert_almost_eq(knight._defense(), KNIGHT_DEF - 18.0, EPS)
	_run(START, 4)
	assert_eq(knight.curse_stacks, 3, "ainda dura")
	_run(START + 4, 1)
	assert_eq(knight.curse_stacks, 0)
	assert_almost_eq(knight._defense(), KNIGHT_DEF, EPS, "a DEF volta inteira")


func test_defesa_efetiva_nunca_fica_negativa() -> void:
	_spawn_occultist(1)
	var knight := _spawn_knight(AHEAD * 4.0)
	knight.attributes.defense = 10.0
	knight.curse_stacks = 3
	knight.curse_ticks = 100
	assert_almost_eq(knight._defense(), 0.0, EPS, "10 - 18 vira 0")
	assert_eq(knight.effective_damage(100), 100, "sem DEF, o bruto inteiro")


func test_desconto_vem_depois_do_bonus_de_defesa() -> void:
	_spawn_occultist(1)
	var berserker := _spawn_berserker(AHEAD * 4.0)
	berserker.ranks = Vector3i(1, 1, 0)
	berserker.attributes.defense = 5.0
	berserker.shout_ticks = 100  # Grito de Guerra do rank 1: +30 DEF
	berserker.curse_stacks = 3
	berserker.curse_ticks = 100
	# (5 + 30) - 18 = 17; descontar antes do bonus daria max(0, 5 - 18) + 30 = 30.
	assert_almost_eq(berserker._defense(), 17.0, EPS)


func test_so_o_basico_marca() -> void:
	_spawn_occultist(2)
	var knight := _spawn_knight(AHEAD * 4.0)
	_occultist.input.skill_q = true
	_occultist.input.aim_distance = 4.0
	_run(START, 30)
	_occultist.input.skill_e = true
	_occultist.input.aim_distance = 4.0
	_run(START + 30, 30)
	assert_eq(knight.curse_stacks, 0, "Praga e Circulo nao marcam")


func test_maldicao_em_monstro_acumula_marcas_sem_mudar_o_dano() -> void:
	_spawn_occultist(1)
	var golem := _spawn_monster(GOLEM, -1, AHEAD * 4.0)
	var seen: Array[int] = []
	for tick: int in range(START, START + 2 * 34 + 20):
		_run_attacking(tick, 1)
		if seen.is_empty() or seen[seen.size() - 1] != golem.curse_stacks:
			seen.append(golem.curse_stacks)
	assert_eq(seen, [0, 1, 2, 3])
	assert_eq(GOLEM_HP - golem.hp, 3 * _basic_damage(), "monstro nao tem DEF: o bruto inteiro")


func test_marcas_do_monstro_caem_juntas_e_o_chefe_tambem_e_marcado() -> void:
	_spawn_occultist(1)
	var boss := _spawn_monster(BOSS, -1, AHEAD * 4.0)
	_occultist.input.attack = true
	_run(START, 20)
	assert_eq(boss.curse_stacks, 1)
	assert_gt(boss.curse_ticks, 0)
	_run(START + 20, CURSE_TICKS + 5)
	assert_eq(boss.curse_stacks, 0, "4 s depois, caem")
	assert_eq(boss.curse_ticks, 0)


func test_morrer_zera_a_maldicao_e_a_praga() -> void:
	_spawn_occultist(1)
	var knight := _spawn_knight(AHEAD * 4.0)
	knight.curse_stacks = 2
	knight.curse_ticks = 100
	knight.dot_ticks = 50
	knight.dot_left = 80
	knight.dot_interval = PULSE_INTERVAL
	knight.hp = 1
	var effect := HitEffect.new(500, Vector3.ZERO)
	effect.attacker_id = CASTER
	knight.receive_hit(START + 1, HitLedger.source_key(CASTER, HitLedger.Slot.BASIC), effect)
	_run(START, 2)
	assert_eq(knight.hp, 0)
	assert_eq([knight.curse_stacks, knight.curse_ticks, knight.dot_ticks], [0, 0, 0])


func test_ressimular_o_mesmo_tick_da_o_mesmo_estado_do_alvo() -> void:
	# Rollback: o servidor restaura o estado do alvo e reaplica o ledger do tick; pulso da Praga e
	# marca nova saem so do estado + ledger, entao a 2a passada repete a 1a.
	_spawn_occultist(1)
	var knight := _spawn_knight(AHEAD * 6.0)
	var tick := START + 50
	var mark := HitEffect.new(20, Vector3.ZERO)
	mark.attacker_id = CASTER
	mark.curse = 1
	mark.curse_ticks = CURSE_TICKS
	knight.receive_hit(tick, HitLedger.source_key(CASTER, HitLedger.Slot.BASIC), mark)
	var before := [knight.hp, 1, 30, PULSE_INTERVAL + 1, 37, PULSE_INTERVAL]
	var after: Array = []
	for pass_index: int in 2:
		knight.hp = before[0]
		knight.curse_stacks = before[1]
		knight.curse_ticks = before[2]
		knight.dot_ticks = before[3]
		knight.dot_left = before[4]
		knight.dot_interval = before[5]
		knight.dot_source = CASTER
		knight._apply_hits(tick)
		var state := [
			knight.hp, knight.curse_stacks, knight.curse_ticks, knight.dot_left, knight.dot_ticks
		]
		if pass_index == 0:
			after = state
		else:
			assert_eq(state, after, "2a passada igual a 1a")
	assert_lt(after[0], before[0], "pulso e golpe feriram")
	assert_eq(after[1], 2, "1 marca a mais")
	assert_lt(after[3], 37, "o pulso tirou do que faltava")
