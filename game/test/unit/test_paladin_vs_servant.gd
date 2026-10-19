extends OccultistTestBase
## F76 x F78: o golpe do Servo do Vazio no Paladino com Retribuicao volta para o servo (mitigado
## pela DEF 10 dele), e o Golpe Consagrado atordoa o servo (SPEC-076: heroi, servo ou monstro).

const PALADIN: String = "res://scenes/heroes/paladin.tscn"


func _paladin_near(servant: VoidServant) -> Paladin:
	var paladin := (load(PALADIN) as PackedScene).instantiate() as Paladin
	paladin.name = str(VICTIM)
	paladin.team = GateRules.TEAM_B
	paladin.level = 2
	paladin.collision_mask = GateRules.hero_mask(GateRules.TEAM_B)
	paladin.transform = Transform3D(Basis(), servant.global_position + Vector3(0, 0, 1.5))
	add_child_autofree(paladin)
	paladin.ranks = Vector3i(1, 1, 0)
	return paladin


func test_golpe_do_servo_volta_para_o_servo() -> void:
	_spawn_occultist(6)
	_occultist.input.skill_r = true
	_run(START, 1)
	var servant := _occultist.servants[0]
	var paladin := _paladin_near(servant)
	paladin.retribution_ticks = 90
	var servant_hp := servant.hp
	var hit := HitEffect.new(60, servant.global_position)
	hit.attacker_id = CASTER
	hit.striker_id = servant.uid
	paladin.receive_hit(START + 2, HitLedger.source_key(servant.uid, HitLedger.Slot.BASIC), hit)
	paladin._rollback_tick(TICK, START + 2, true)
	var e := paladin.hero_data.skill_e
	var back := PaladinRules.reflected_damage(
		CombatRules.mitigated(60, paladin._defense()),
		SkillData.at_rank(e.reflect_ratio, 1),
		paladin.attributes.attack,
		e.attack_ratio
	)
	assert_eq(servant_hp - servant.hp, CombatRules.mitigated(back, 10.0))


func test_golpe_consagrado_atordoa_o_servo() -> void:
	_spawn_occultist(6)
	_occultist.input.skill_r = true
	_run(START, 1)
	var servant := _occultist.servants[0]
	var paladin := _paladin_near(servant)
	paladin.look_at(servant.global_position, Vector3.UP)
	paladin.input.skill_q = true
	paladin._rollback_tick(TICK, START + 2, true)
	assert_gt(servant._stun_ticks, 0)
