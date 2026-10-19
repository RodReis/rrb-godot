extends PaladinTestBase
## Paladino Radiante (GDB §4.9, F76; SPEC-076 aceite): Maca em arco de 60° / 2 u com 120 % do ATK e
## Golpe Consagrado que fere e atordoa so o 1o heroi, servo ou monstro da faixa de 2,5 u x 1 u (o
## chefe so toma o dano; o Ragnarok ignora o atordoamento). Servidor = processo do teste.


func test_nivel_1_tem_os_atributos_base() -> void:
	var paladin := _spawn_paladin(1)
	assert_eq(paladin.hp, PALADIN_HP)
	assert_almost_eq(paladin.attributes.defense, PALADIN_DEF, EPS)
	assert_eq(paladin.ranks, Vector3i(1, 0, 0))


func test_maca_fere_120_por_cento_do_atk() -> void:
	_spawn_paladin(1)
	var knight := _spawn_enemy(KNIGHT, AHEAD * 1.8)
	_paladin.input.attack = true
	_run(START, 3)
	var raw := roundi(1.2 * PALADIN_ATK)
	assert_eq(KNIGHT_HP - knight.hp, CombatRules.mitigated(raw, KNIGHT_DEF))


func test_maca_nao_alcanca_alem_de_2_u() -> void:
	_spawn_paladin(1)
	var knight := _spawn_enemy(KNIGHT, AHEAD * 2.2)
	_paladin.input.attack = true
	_run(START, 3)
	assert_eq(knight.hp, KNIGHT_HP)


func test_golpe_consagrado_fere_e_atordoa_so_o_primeiro_da_faixa() -> void:
	_spawn_paladin(1)
	var far := _spawn_enemy(KNIGHT, AHEAD * 2.2, VICTIM)
	var near := _spawn_enemy(KNIGHT, AHEAD * 1.0 + Vector3(0.3, 0, 0), VICTIM + 1)
	_paladin.input.skill_q = true
	_run(START, 2)
	assert_eq(_q_damage(), roundi(50 + 0.7 * PALADIN_ATK))
	assert_eq(KNIGHT_HP - near.hp, CombatRules.mitigated(_q_damage(), KNIGHT_DEF))
	assert_gt(near.stun_ticks, 0)
	assert_eq(far.hp, KNIGHT_HP, "so o 1o da faixa")
	assert_eq(far.stun_ticks, 0)


func test_atordoamento_dura_0_8_s_no_rank_1() -> void:
	_spawn_paladin(1)
	var knight := _spawn_enemy(KNIGHT, AHEAD * 1.5)
	_paladin.input.skill_q = true
	# Tick do golpe + 24 ticks (0,8 s a 30/s) parado: no fim do 24o ainda falta 1 tick.
	_run(START, 25)
	assert_eq(knight.stun_ticks, 1)
	_run(START + 25, 1)
	assert_eq(knight.stun_ticks, 0)


func test_faixa_nao_pega_quem_esta_de_lado() -> void:
	_spawn_paladin(1)
	var knight := _spawn_enemy(KNIGHT, Vector3(1.2, 0, -1.0))
	_paladin.input.skill_q = true
	_run(START, 2)
	assert_eq(knight.hp, KNIGHT_HP)


func test_golem_e_atordoado() -> void:
	_spawn_paladin(1)
	var golem := _spawn_monster(GOLEM, -1, AHEAD * 1.5)
	_paladin.input.skill_q = true
	_run(START, 1)
	assert_eq(GOLEM_HP - golem.hp, _q_damage(), "monstro sem DEF")
	assert_gt(golem._stun_ticks, 0)


func test_chefe_so_toma_o_dano() -> void:
	_spawn_paladin(1)
	var boss := _spawn_monster(BOSS, -2, AHEAD * 1.5)
	var boss_hp := boss.hp
	_paladin.input.skill_q = true
	_run(START, 1)
	assert_eq(boss_hp - boss.hp, _q_damage())
	assert_eq(boss._stun_ticks, 0, "chefe: so o dano")


func test_ragnarok_ignora_o_atordoamento() -> void:
	_spawn_paladin(1)
	var berserker := _spawn_enemy(BERSERKER, AHEAD * 1.5)
	berserker.cc_immune_ticks = 100
	var before := berserker.hp
	_paladin.input.skill_q = true
	_run(START, 2)
	assert_lt(berserker.hp, before, "toma o dano")
	assert_eq(berserker.stun_ticks, 0)
