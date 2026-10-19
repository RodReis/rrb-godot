extends PaladinTestBase
## Bencao Inviolavel do Paladino (GDB §4.9, F76; ADR-0016 item 5): cura [120, 200] + 1,2 INT com
## teto no HP maximo e imunidade a todo dano por [1,5, 2,0] s — heroi, monstro e zona da fase 2 —
## enquanto controle (atordoamento, lentidao, empurrao) continua valendo.


func _blessed(hp: int) -> void:
	_spawn_paladin(6)
	_paladin.ranks = Vector3i(1, 0, 1)
	_paladin.hp = hp
	_paladin.input.skill_r = true
	_run(START, 1)


func _heal() -> int:
	return roundi(
		SkillRules.amount(_paladin.hero_data.skill_r, _paladin.ranks.z, _paladin.attributes)
	)


func test_cura_base_mais_1_2_int() -> void:
	_blessed(300)
	assert_eq(_heal(), roundi(120 + 1.2 * _paladin.attributes.intelligence))
	assert_eq(_paladin.hp, 300 + _heal())
	assert_true(_paladin.is_blessed())


func test_cura_tem_teto_no_hp_maximo() -> void:
	_blessed(10)
	_paladin.hp = _paladin.attributes.max_hp - 10
	_paladin.r_cooldown = 0
	_paladin.input.skill_r = true
	_run(START + 1, 1)
	assert_eq(_paladin.hp, _paladin.attributes.max_hp)


func test_imune_a_golpe_de_heroi_e_de_monstro() -> void:
	_blessed(300)
	var hp := _paladin.hp
	_strike_paladin(START + 2, VICTIM, _direct_hit(200, AHEAD, VICTIM))
	var monster := HitEffect.new(150, AHEAD)
	_paladin.receive_hit(START + 3, HitLedger.source_key(-1, HitLedger.Slot.BASIC), monster)
	_run(START + 1, 4)
	assert_eq(_paladin.hp, hp)


func test_imune_a_zona_da_fase_2() -> void:
	_blessed(300)
	var hp := _paladin.hp
	var zone := HitEffect.new()
	zone.true_damage = 60
	_paladin.receive_hit(START + 2, HitLedger.source_key(0, HitLedger.Slot.ZONE), zone)
	_run(START + 1, 3)
	assert_eq(_paladin.hp, hp)


func test_controle_continua_valendo() -> void:
	_blessed(300)
	var stun := HitEffect.new(100, AHEAD, Vector3(0, 0, 1.5), 20)
	stun.slow = 0.3
	stun.slow_ticks = 30
	_strike_paladin(START + 2, VICTIM, stun)
	var hp := _paladin.hp
	_run(START + 1, 2)
	assert_eq(_paladin.hp, hp, "sem dano")
	assert_gt(_paladin.stun_ticks, 0, "atordoado")
	assert_gt(_paladin.slow_ticks, 0, "lento")
	assert_gt(_paladin.knockback_ticks, 0, "empurrado")


func test_imunidade_dura_1_5_s_no_rank_1() -> void:
	_blessed(300)
	var hp := _paladin.hp
	# Uso no START: ticks START+1 .. START+45 imunes (45 = 1,5 s); no START+46 o golpe pega.
	_strike_paladin(START + 45, VICTIM, _direct_hit(200, AHEAD, VICTIM))
	_run(START + 1, 45)
	assert_eq(_paladin.hp, hp, "ainda imune no 45o tick")
	_strike_paladin(START + 46, VICTIM + 1, _direct_hit(200, AHEAD, VICTIM + 1))
	_run(START + 46, 1)
	assert_lt(_paladin.hp, hp)


func test_rank_2_dura_2_s_e_cura_200_mais_int() -> void:
	_spawn_paladin(10)
	_paladin.ranks = Vector3i(1, 0, 2)
	_paladin.hp = 200
	_paladin.input.skill_r = true
	_run(START, 1)
	assert_eq(_paladin.invuln_ticks, 60)
	assert_eq(_paladin.hp, 200 + roundi(200 + 1.2 * _paladin.attributes.intelligence))
