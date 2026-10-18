extends OccultistTestBase
## Praga do Ocultista (GDB §4.10, F77; SPEC-077 aceite): projetil que para no 1o heroi ou monstro e
## o corroi por 4 s em 8 pulsos de 0,5 s; reaplicar renova sem acumular; o pulso passa pela DEF
## (com Maldicao); o abate pelo pulso conta para o Ocultista. Servidor = processo do teste.


## Roda ate [param ticks] e devolve a perda de HP de cada pulso do alvo, com o tick em que caiu.
func _pulses_of(knight: Hero, from: int, ticks: int) -> Array[Vector2i]:
	var pulses: Array[Vector2i] = []
	var last_hp := knight.hp
	for tick: int in range(from, from + ticks):
		_run(tick, 1)
		if knight.hp < last_hp:
			pulses.append(Vector2i(tick, last_hp - knight.hp))
			last_hp = knight.hp
	return pulses


func test_praga_nao_fere_de_imediato_e_nao_marca() -> void:
	_spawn_occultist(1)
	var knight := _spawn_knight(AHEAD * 5.0)
	_occultist.input.skill_q = true
	_run(START, 20)
	assert_eq(knight.hp, KNIGHT_HP, "so os pulsos ferem")
	assert_gt(knight.dot_ticks, 0)
	assert_eq(knight.dot_source, CASTER)
	assert_eq(knight.curse_stacks, 0)


func test_praga_pulsa_8_vezes_a_cada_meio_segundo_pela_def() -> void:
	_spawn_occultist(1)
	var knight := _spawn_knight(AHEAD * 5.0)
	_occultist.input.skill_q = true
	var pulses := _pulses_of(knight, START, 200)
	assert_eq(_q_total(), 80 + 42)
	var raws := _plague_raws(_q_total(), 8)
	assert_eq(raws, [15, 15, 15, 15, 16, 15, 16, 15], "122 / 8 sem perder o resto")
	assert_eq(pulses.size(), 8)
	for i: int in pulses.size():
		assert_eq(pulses[i].y, CombatRules.mitigated(raws[i], KNIGHT_DEF), "pulso %d" % i)
		if i > 0:
			assert_eq(pulses[i].x - pulses[i - 1].x, PULSE_INTERVAL, "0,5 s entre pulsos")
	assert_eq(knight.dot_ticks, 0, "acabou")
	assert_eq(pulses[7].x - pulses[0].x, 7 * PULSE_INTERVAL)


func test_pulso_usa_a_def_com_maldicao() -> void:
	_spawn_occultist(1)
	var knight := _spawn_knight(AHEAD * 5.0)
	knight.curse_stacks = 3
	knight.curse_ticks = 1000
	_occultist.input.skill_q = true
	var pulses := _pulses_of(knight, START, 200)
	assert_eq(pulses.size(), 8)
	assert_eq(pulses[0].y, CombatRules.mitigated(15, KNIGHT_DEF - 18.0))
	assert_gt(pulses[0].y, CombatRules.mitigated(15, KNIGHT_DEF))


func test_muralha_erguida_depois_nao_bloqueia_o_pulso() -> void:
	_spawn_occultist(1)
	var knight := _spawn_knight(AHEAD * 5.0)
	_occultist.input.skill_q = true
	_run(START, 20)
	assert_gt(knight.dot_ticks, 0, "a Praga pegou antes da Muralha")
	knight.shield_ticks = 1000
	knight.shield_hp = 1000
	var lost := KNIGHT_HP - knight.hp
	var pulses := _pulses_of(knight, START + 20, 200)
	for pulse: Vector2i in pulses:
		lost += pulse.y
	assert_eq(knight.shield_hp, 1000, "a Muralha so bloqueia o projetil")
	assert_gt(lost, 0)


func test_reaplicar_renova_a_duracao_sem_acumular() -> void:
	_spawn_occultist(1)
	var knight := _spawn_knight(AHEAD * 5.0)
	_occultist.input.skill_q = true
	_run(START, 70)  # no meio da Praga
	assert_gt(knight.dot_ticks, 0)
	assert_lt(knight.dot_ticks, 100)
	_occultist.q_cooldown = 0
	_occultist.input.skill_q = true
	_run(START + 70, 30)
	assert_gt(knight.dot_ticks, 80, "renovou")
	assert_lte(knight.dot_ticks, 8 * PULSE_INTERVAL, "nao somou duas duracoes")
	assert_lte(knight.dot_left, _q_total(), "nao somou dois danos")


func test_praga_para_no_primeiro_heroi_ou_monstro() -> void:
	_spawn_occultist(1)
	var front := _spawn_monster(GOLEM, -1, AHEAD * 3.0)
	var behind := _spawn_knight(AHEAD * 6.0)
	_occultist.input.skill_q = true
	_run(START, 30)
	assert_gt(front.dot_ticks, 0)
	assert_eq(behind.dot_ticks, 0)


func test_praga_alem_de_8_u_nao_alcanca() -> void:
	_spawn_occultist(1)
	var knight := _spawn_knight(AHEAD * 9.0)
	_occultist.input.skill_q = true
	_run(START, 40)
	assert_eq(knight.dot_ticks, 0)


func test_abate_pelo_pulso_conta_para_o_ocultista() -> void:
	_spawn_occultist(1)
	var knight := _spawn_knight(AHEAD * 5.0)
	knight.hp = 5
	knight.respawn_seconds = 100.0  # sem respawn imediato no teste
	_occultist.input.skill_q = true
	_run(START, 40)
	assert_eq(knight.hp, 0)
	assert_eq(knight.killer_id, CASTER)
	assert_eq(knight.hero_damage_from(CASTER), 5, "o dano conta, ate o HP restante")
	assert_eq(knight.dot_ticks, 0, "morto nao segue corroendo")


func test_praga_em_monstro_tira_o_bruto_em_8_pulsos() -> void:
	_spawn_occultist(1)
	var golem := _spawn_monster(GOLEM, -1, AHEAD * 5.0)
	_occultist.input.skill_q = true
	_run(START, 20)
	assert_between(golem.dot_left, 1, _q_total())
	assert_gt(golem.dot_ticks, 0)
	_run(START + 20, 200)
	assert_eq(GOLEM_HP - golem.hp, _q_total(), "o bruto todo, sem perder o resto")
	assert_eq(golem.dot_ticks, 0)


func test_praga_no_chefe() -> void:
	_spawn_occultist(1)
	var boss := _spawn_monster(BOSS, -1, AHEAD * 5.0)
	var hp := boss.hp
	_occultist.input.skill_q = true
	_run(START, 220)
	assert_eq(hp - boss.hp, _q_total())


func test_abate_de_monstro_pelo_pulso_credita_o_ocultista() -> void:
	_spawn_occultist(1)
	var golem := _spawn_monster(GOLEM, -1, AHEAD * 5.0)
	golem.hp = 20
	var killers: Array[int] = []
	golem.died.connect(func(killer: int, _tick: int) -> void: killers.append(killer))
	_occultist.input.skill_q = true
	_run(START, 120)
	assert_eq(golem.hp, 0)
	assert_eq(killers, [CASTER])
	assert_eq(golem.dot_ticks, 0)


func test_muralha_bloqueia_a_praga() -> void:
	_spawn_occultist(1)
	var knight := _spawn_knight(AHEAD * 4.0)
	knight.look_at(Vector3.ZERO, Vector3.UP)
	knight.shield_ticks = 90
	knight.shield_hp = 200
	_occultist.input.skill_q = true
	_run(START, 20)
	assert_eq(knight.dot_ticks, 0)
	assert_eq(knight.shield_hp, 200, "bloqueada antes de chegar")


func test_recarga_da_praga_8_s_no_rank_1() -> void:
	_spawn_occultist(1)
	_occultist.input.skill_q = true
	_run(START, 1)
	var expected := SkillRules.cooldown_ticks(
		_occultist.hero_data.skill_q, 1, _occultist.attributes.intelligence, 30
	)
	assert_eq(_occultist.q_cooldown, expected)
	assert_gt(expected, 150, "8 s menos o CDR da INT 32")

## Dano bruto de cada pulso da Praga, na ordem: o que falta dividido pelos pulsos restantes.
func _plague_raws(total: int, pulses: int) -> Array[int]:
	var raws: Array[int] = []
	var left := total
	for remaining: int in range(pulses, 0, -1):
		var raw := roundi(float(left) / remaining)
		raws.append(raw)
		left -= raw
	return raws
