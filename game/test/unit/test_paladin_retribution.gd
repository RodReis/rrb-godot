extends PaladinTestBase
## Retribuicao do Paladino (GDB §4.9, F76; SPEC-076 aceite): por 3 s, golpe direto (corpo a corpo)
## de origem a ate 3 u volta ao atacante — heroi, servo ou monstro — com 25..45 % do dano tomado
## (depois da DEF do Paladino) + 20 % do ATK, mitigado pela DEF do atacante. Projetil, zona e
## pulso nao voltam; o devolvido nao volta de novo (sem laco entre dois Paladinos).


func _retributing(level: int = 2) -> Paladin:
	var paladin := _spawn_paladin(level)
	paladin.ranks = Vector3i(1, 1, 0)
	paladin.retribution_ticks = 90
	return paladin


func test_golpe_da_maca_do_cavaleiro_volta_para_ele() -> void:
	_spawn_paladin(2)
	_paladin.ranks = Vector3i(1, 1, 0)
	var knight := _spawn_enemy(KNIGHT, AHEAD * 1.8)
	NoRetaliation.mute(_paladin)
	knight.input.attack = true
	knight.input.aim = Vector3(0, 0, 1)
	_paladin.input.skill_e = true
	_run(START, 3)
	var raw := roundi(SkillRules.amount(knight.hero_data.basic_attack, 1, knight.attributes))
	var taken := _paladin.attributes.max_hp - _paladin.hp
	assert_eq(taken, CombatRules.mitigated(raw, _paladin._defense()))
	assert_eq(KNIGHT_HP - knight.hp, CombatRules.mitigated(_reflected(raw), KNIGHT_DEF))


func test_dano_devolvido_bate_com_o_gdb() -> void:
	_retributing()
	# rank 1: 25 % do que o Paladino tomou + 20 % do ATK (43 no nivel 1, 46,6 no 2).
	var taken := CombatRules.mitigated(100, _paladin._defense())
	assert_eq(_reflected(100), roundi(taken * 0.25 + 0.2 * _paladin.attributes.attack))


func test_projetil_e_zona_nao_voltam() -> void:
	_retributing()
	var knight := _spawn_enemy(KNIGHT, AHEAD * 1.5)
	_strike_paladin(START + 1, VICTIM, HitEffect.new(80, AHEAD * 1.0))  # projetil: sem striker
	var zone := HitEffect.new()
	zone.true_damage = 30
	_paladin.receive_hit(START + 1, HitLedger.source_key(0, HitLedger.Slot.ZONE), zone)
	_run(START, 4)
	assert_lt(_paladin.hp, _paladin.attributes.max_hp, "o Paladino toma")
	assert_eq(knight.hp, KNIGHT_HP, "nada volta")


func test_so_golpe_de_ate_3_u_volta() -> void:
	_retributing()
	var knight := _spawn_enemy(KNIGHT, AHEAD * 4.0)
	_strike_paladin(START + 1, VICTIM, _direct_hit(100, AHEAD * 3.2, VICTIM))
	_run(START, 4)
	assert_eq(knight.hp, KNIGHT_HP, "3,2 u: longe")
	_strike_paladin(START + 5, VICTIM, _direct_hit(100, AHEAD * 3.0, VICTIM))
	_run(START + 4, 4)
	assert_eq(
		KNIGHT_HP - knight.hp, CombatRules.mitigated(_reflected(100), KNIGHT_DEF), "3 u: volta"
	)


func test_sem_retribuicao_nada_volta() -> void:
	_spawn_paladin(2)
	var knight := _spawn_enemy(KNIGHT, AHEAD * 1.5)
	_strike_paladin(START + 1, VICTIM, _direct_hit(100, AHEAD * 1.5, VICTIM))
	_run(START, 4)
	assert_eq(knight.hp, KNIGHT_HP)


func test_acaba_em_3_s() -> void:
	_spawn_paladin(2)
	_paladin.ranks = Vector3i(1, 1, 0)
	_paladin.input.skill_e = true
	_run(START, 1)
	assert_true(_paladin.is_retributing())
	_run(START + 1, 89)
	assert_true(_paladin.is_retributing(), "ultimo tick dos 90")
	_run(START + 90, 1)
	assert_false(_paladin.is_retributing())


func test_golpe_do_monstro_volta_para_o_monstro() -> void:
	_retributing()
	var golem := _spawn_monster(GOLEM, -1, AHEAD * 1.5)
	_strike_paladin(START + 1, 0, _direct_hit(50, golem.global_position, golem.uid))
	_run(START, 3)
	assert_eq(GOLEM_HP - golem.hp, _reflected(50), "monstro sem DEF")


func test_sem_laco_entre_dois_paladinos() -> void:
	_retributing()
	var other := _spawn_enemy(PALADIN, AHEAD * 1.5) as Paladin
	NoRetaliation.mute(other)
	other.ranks = Vector3i(1, 1, 0)
	other.retribution_ticks = 90
	var other_hp := other.hp
	_paladin.input.attack = true
	_run(START, 1)
	_run(START + 1, 6)
	var maca := CombatRules.mitigated(roundi(1.2 * _paladin.attributes.attack), other._defense())
	assert_eq(other_hp - other.hp, maca, "o outro toma so a maca")
	assert_lt(_paladin.hp, _paladin.attributes.max_hp, "o devolvido chegou")
	var sources := [HitLedger.source_key(CASTER, HitLedger.Slot.E)]
	for tick: int in range(START, START + 8):
		assert_null(other._hits.get_hit(tick, sources[0]), "o devolvido nao voltou de novo")


func test_ressimular_o_tick_nao_dobra_o_devolvido() -> void:
	_retributing()
	var knight := _spawn_enemy(KNIGHT, AHEAD * 1.5)
	var tick := START + 1
	_strike_paladin(tick, VICTIM, _direct_hit(100, AHEAD * 1.5, VICTIM))
	var source := HitLedger.source_key(CASTER, HitLedger.Slot.E)
	for pass_index: int in 2:
		_paladin.hp = _paladin.attributes.max_hp
		_paladin._apply_hits(tick)
		var back := knight._hits.get_hit(tick + 1, source)
		assert_not_null(back)
		assert_eq(back.damage, _reflected(100), "passada %d" % pass_index)
		assert_eq(back.striker_id, TargetRules.NONE, "o devolvido nao e direto")


func test_imune_na_bencao_devolve_so_o_atk() -> void:
	# PI 2026-10-19: volta so o que o Paladino tomou; imune, so os 20 % do ATK.
	_retributing()
	_paladin.invuln_ticks = 30
	var knight := _spawn_enemy(KNIGHT, AHEAD * 1.5)
	_strike_paladin(START + 1, VICTIM, _direct_hit(100, AHEAD * 1.5, VICTIM))
	_run(START, 4)
	assert_eq(_paladin.hp, _paladin.attributes.max_hp, "imune")
	var atk_only := roundi(0.2 * _paladin.attributes.attack)
	assert_eq(_reflected(100), atk_only)
	assert_eq(KNIGHT_HP - knight.hp, CombatRules.mitigated(atk_only, KNIGHT_DEF))
