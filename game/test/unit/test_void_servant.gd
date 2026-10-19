extends OccultistTestBase
## F78: R Servos do Vazio (GDB §4.10, SPEC-078). Invocacao, duracao e substituicao; escolha do alvo
## (prioridade, alcance, so o que o Ocultista ve); dano e abate creditados ao Ocultista; matar o
## servo nao da nada; sem o R, nada.

const LASTS: int = 300  # R1: 10 s a 30 ticks/s (PI 2026-10-18)
const FAR: Vector3 = Vector3(40, 0, 0)


## Um tick de todos: o Ocultista e os herois alvo pelo rollback, os servos pela IA do servidor.
func _tick_all(from: int, count: int) -> void:
	for tick: int in range(from, from + count):
		_run(tick, 1)
		for servant: VoidServant in _occultist.servants:
			servant._on_network_tick(TICK, tick)


func _cast_r(tick: int = START) -> void:
	_occultist.input.skill_r = true
	_run(tick, 1)


func _servant_hp(level: int = 6) -> int:
	var data := _occultist.servants[0].data
	return VoidServantRules.max_hp(data, 1 if level < 10 else 2, _occultist.attributes.intelligence)


func test_sem_o_r_aprendido_nada_acontece() -> void:
	_spawn_occultist(5)
	assert_eq(_occultist.ranks.z, 0, "R so no Nv 6")
	_cast_r()
	assert_eq(_occultist.r_cooldown, 0)
	for servant: VoidServant in _occultist.servants:
		assert_false(servant.is_alive())


func test_r_invoca_os_dois_servos_ao_lado_com_hp_do_gdb() -> void:
	_spawn_occultist(6)
	assert_eq(_occultist.ranks.z, 1, "Nv 6 ganha o R1")
	_cast_r()
	assert_gt(_occultist.r_cooldown, 0)
	var servants := _occultist.servants
	assert_eq(servants.size(), 2)
	assert_eq(servants[0].hp, _servant_hp())
	assert_eq(servants[1].hp, _servant_hp())
	assert_almost_eq(
		servants[0].global_position, Vector3(1.0, 0, -1.5), Vector3.ONE * EPS, "frente-dir."
	)
	assert_almost_eq(
		servants[1].global_position, Vector3(-1.0, 0, -1.5), Vector3.ONE * EPS, "frente-esq."
	)
	assert_eq(servants[0].team, _occultist.team)
	assert_ne(servants[0].combat_id(), servants[1].combat_id())


func test_somem_no_fim_dos_10_segundos_no_r1() -> void:
	_spawn_occultist(6)
	_cast_r()
	_tick_all(START + 1, LASTS - 2)
	assert_true(_occultist.servants[0].is_alive(), "ainda no ultimo tick da duracao")
	_tick_all(START + LASTS - 1, 2)
	assert_false(_occultist.servants[0].is_alive())
	assert_false(_occultist.servants[1].is_alive())


func test_nova_invocacao_substitui_a_anterior() -> void:
	_spawn_occultist(6)
	_cast_r()
	var servant := _occultist.servants[0]
	servant.global_position = Vector3(5, 0, 5)
	servant.receive_hit(START + 1, 99, HitEffect.new(60, Vector3.ZERO))
	assert_lt(servant.hp, _servant_hp())
	_occultist.r_cooldown = 0
	_cast_r(START + 100)
	assert_eq(servant.hp, _servant_hp(), "HP cheio de novo")
	assert_almost_eq(servant.global_position.x, 1.0, EPS, "volta para a frente do Ocultista")
	_tick_all(START + 101, LASTS - 2)
	assert_true(servant.is_alive(), "a duracao conta da invocacao nova")


func test_ressimular_o_tick_da_invocacao_nao_reinvoca() -> void:
	_spawn_occultist(6)
	_cast_r()
	var servant := _occultist.servants[0]
	servant.receive_hit(START + 1, 99, HitEffect.new(60, Vector3.ZERO))
	var hp := servant.hp
	servant.summon(START, Vector3.ZERO, Basis(), 1, 50.0, LASTS)
	assert_eq(servant.hp, hp)


func test_def_10_reduz_o_golpe_no_servo() -> void:
	_spawn_occultist(6)
	_cast_r()
	var servant := _occultist.servants[0]
	servant.receive_hit(START + 1, 99, HitEffect.new(80, Vector3.ZERO))
	assert_eq(servant.hp, _servant_hp() - CombatRules.mitigated(80, 10.0))
	servant.receive_hit(START + 1, 99, HitEffect.new(80, Vector3.ZERO))
	assert_eq(servant.hp, _servant_hp() - CombatRules.mitigated(80, 10.0), "mesmo tick + fonte")


func test_heroi_inimigo_vem_antes_do_monstro_mais_perto() -> void:
	_spawn_occultist(6)
	var knight := _spawn_knight(Vector3(0, 0, -6))
	_spawn_monster(GOLEM, -3, Vector3(3, 0, 0))
	_cast_r()
	_tick_all(START + 1, 1)
	assert_eq(_occultist.servants[0].target(), knight)
	assert_eq(_occultist.servants[1].target(), knight)


func test_alvo_travado_do_ocultista_vem_antes_do_heroi() -> void:
	_spawn_occultist(6)
	_spawn_knight(Vector3(0, 0, -4))
	var golem := _spawn_monster(GOLEM, -3, Vector3(5, 0, 0))
	_occultist.target_id = golem.uid
	_occultist.input.target_id = golem.uid
	_cast_r()
	_tick_all(START + 1, 1)
	assert_eq(_occultist.servants[0].target(), golem)


func test_monstro_no_alcance_sem_heroi() -> void:
	_spawn_occultist(6)
	var golem := _spawn_monster(GOLEM, -3, Vector3(6, 0, 0))
	_cast_r()
	_tick_all(START + 1, 1)
	assert_eq(_occultist.servants[0].target(), golem)


func test_sem_alvo_seguem_o_ocultista() -> void:
	_spawn_occultist(6)
	_spawn_knight(FAR)
	_cast_r()
	var servant := _occultist.servants[0]
	servant.global_position = Vector3(8, 0, 0)
	_tick_all(START + 1, 60)
	assert_null(servant.target())
	var gap := Vector2(servant.global_position.x, servant.global_position.z).length()
	assert_between(gap, 1.0, 2.5, "volta e para perto do Ocultista (follow_distance 2 u)")


func test_so_ataca_o_que_o_ocultista_ve() -> void:
	_spawn_occultist(6)
	var knight := _spawn_knight(Vector3(14, 0, 0))  # fora do raio de visao (12 u) do Ocultista
	_cast_r()
	var servant := _occultist.servants[0]
	servant.global_position = Vector3(12, 0, 0)  # o servo esta a 2 u dele
	_tick_all(START + 1, 1)
	assert_null(servant.target(), "o Ocultista nao ve o Cavaleiro")
	_occultist.global_position = Vector3(5, 0, 0)
	_tick_all(START + 2, 8)
	assert_eq(servant.target(), knight, "na reavaliacao, ja visto")


func test_dano_e_abate_do_servo_contam_para_o_ocultista() -> void:
	_spawn_occultist(6)
	var knight := _spawn_knight(Vector3(0, 0, -6))
	knight.respawn_seconds = 60.0  # sem isso renasce no tick seguinte
	_cast_r()
	for servant: VoidServant in _occultist.servants:
		servant.global_position = Vector3(0, 0, -5)
	_tick_all(START + 1, 3)
	assert_lt(knight.hp, KNIGHT_HP)
	assert_gt(knight.hero_damage_from(CASTER), 0, "dano de heroi creditado ao Ocultista")
	knight.hp = 1
	_tick_all(START + 4, 31)
	assert_false(knight.is_alive())
	assert_eq(knight.killer_id, CASTER, "abate do Ocultista")


func test_monstro_morto_pelo_servo_da_xp_ao_ocultista() -> void:
	_spawn_occultist(6)
	var golem := _spawn_monster(GOLEM, -3, Vector3(4, 0, 0))
	_cast_r()
	_occultist.servants[0].global_position = Vector3(3, 0, 0)
	golem.hp = 1
	var xp := _occultist.xp
	_tick_all(START + 1, 3)
	assert_false(golem.is_alive())
	assert_gt(_occultist.xp, xp)


func test_matar_o_servo_nao_da_nada_a_quem_mata() -> void:
	_spawn_occultist(6)
	var knight := _spawn_knight(Vector3(0, 0, 3))
	_cast_r()
	var servant := _occultist.servants[0]
	servant.global_position = Vector3(0, 0, 2)  # a frente do Cavaleiro (que olha para -Z)
	servant.hp = 1
	var xp := knight.xp
	knight.input.attack = true
	for tick: int in range(START + 1, START + 4):
		knight._rollback_tick(TICK, tick, true)
	assert_false(servant.is_alive(), "o Cavaleiro matou o servo")
	knight.input.attack = false
	for tick: int in range(START + 4, START + 8):
		knight._rollback_tick(TICK, tick, true)
	assert_eq(knight.xp, xp, "sem XP")
	assert_true(_occultist.is_alive())


func test_colide_como_o_heroi_do_dono_e_passa_o_proprio_portao() -> void:
	_spawn_occultist(6)
	_cast_r()
	assert_eq(_occultist.servants[0].collision_mask, GateRules.hero_mask(GateRules.TEAM_A))


func test_maldicao_reduz_a_def_do_servo() -> void:
	_spawn_occultist(6)
	_cast_r()
	var servant := _occultist.servants[0]
	var curse := HitEffect.new(0, Vector3.ZERO)
	curse.curse = 1
	curse.curse_ticks = CURSE_TICKS
	servant.receive_hit(START + 1, 98, curse)
	servant.receive_hit(START + 1, 99, HitEffect.new(80, Vector3.ZERO))
	assert_eq(servant.hp, _servant_hp() - CombatRules.mitigated(80, 4.0), "DEF 10 - 6")


func test_praga_inimiga_pulsa_no_servo_pela_def() -> void:
	_spawn_occultist(6)
	_cast_r()
	var servant := _occultist.servants[0]
	var plague := HitEffect.new(0, Vector3.ZERO)
	plague.dot_total = 120
	plague.dot_pulses = 8
	plague.dot_interval_ticks = PULSE_INTERVAL
	servant.receive_hit(START + 1, 99, plague)
	for tick: int in range(START + 1, START + 1 + 8 * PULSE_INTERVAL):
		servant._tick_curse_and_dot()
	assert_eq(servant.hp, _servant_hp() - 8 * CombatRules.mitigated(15, 10.0), "8 pulsos de 15")


## Regressao (PI 2026-10-18: "invoca longe"): o teleporte da invocacao grava o ponto novo no
## interpolador; o laco de ticks seguinte nao devolve o servo para onde ele sumiu.
func test_invocado_longe_de_onde_sumiu_fica_no_ponto_novo() -> void:
	_spawn_occultist(6)
	var servant := _occultist.servants[0]
	await wait_process_frames(2)  # o TickInterpolator se configura com call_deferred
	var interpolator := servant._interpolator
	# Um laco de ticks com o servo longe (onde sumiu), outro com a invocacao, como no NetworkTime.
	interpolator._before_tick_loop()
	servant.global_position = Vector3(30, 0, 30)
	servant._on_network_time_after_tick_loop()
	interpolator._after_tick_loop()
	interpolator._before_tick_loop()
	_cast_r()
	servant._on_network_time_after_tick_loop()
	interpolator._after_tick_loop()
	interpolator._before_tick_loop()
	assert_almost_eq(servant.global_position.x, 1.0, EPS, "no ponto da invocacao")


func test_r2_dura_12_segundos() -> void:
	_spawn_occultist(10)
	_cast_r()
	_tick_all(START + 1, 360 - 2)
	assert_true(_occultist.servants[0].is_alive())
	_tick_all(START + 359, 2)
	assert_false(_occultist.servants[0].is_alive())
