extends PaladinTestBase
## F76: quais golpes chegam ao Paladino como golpe direto (HitEffect.striker_id = combat_id de quem
## bateu), a unica coisa que a Retribuicao devolve. Diretos: basico em arco, Investida, golpe do
## monstro (nao area). Nao diretos: Terremoto (area), Bacamarte do Engenheiro (tiro, PI 2026-10-19)
## e o golpe em area do golem.

const ENGINEER: String = "res://scenes/heroes/engineer.tscn"
const SKELETON: String = "res://scenes/monsters/skeleton_t1.tscn"


## Primeiro efeito de [param source] no ledger do Paladino entre START e START + 60.
func _received(source: int) -> HitEffect:
	for tick: int in range(START, START + 60):
		var hit := _paladin._hits.get_hit(tick, source)
		if hit != null:
			return hit
	return null


func _knight_acts(level: int, button: StringName, ticks: int) -> Knight:
	_spawn_paladin(1)
	_paladin.hp = 100000  # o Paladino nao morre no meio da medicao
	var knight := (load(KNIGHT) as PackedScene).instantiate() as Knight
	knight.name = str(VICTIM)
	knight.team = GateRules.TEAM_B
	knight.level = level
	knight.collision_mask = GateRules.hero_mask(GateRules.TEAM_B)
	knight.transform = Transform3D(Basis(), AHEAD * 1.8)
	add_child_autofree(knight)
	knight.look_at(Vector3.ZERO, Vector3.UP)
	knight.input.aim = Vector3(0, 0, 1)
	knight.input.set(button, true)
	for tick: int in range(START, START + ticks):
		knight._rollback_tick(TICK, tick, true)
	return knight


func test_basico_do_cavaleiro_e_direto() -> void:
	_knight_acts(1, &"attack", 3)
	var hit := _received(HitLedger.source_key(VICTIM, HitLedger.Slot.BASIC))
	assert_not_null(hit)
	assert_eq(hit.striker_id, VICTIM)


func test_investida_e_direta() -> void:
	# Contato direto (o avanco ate ele depende da fisica, fora do teste): ja colado, avancando.
	_spawn_paladin(1)
	var knight := _spawn_enemy(KNIGHT, AHEAD * 0.7) as Knight
	knight.dash_ticks = 5
	knight.dash_direction = Vector3(0, 0, 1)
	knight._while_dashing(START)
	var hit := _received(HitLedger.source_key(VICTIM, HitLedger.Slot.Q))
	assert_not_null(hit)
	assert_eq(hit.striker_id, VICTIM)


func test_terremoto_nao_e_direto() -> void:
	_knight_acts(6, &"skill_r", 3)
	var hit := _received(HitLedger.source_key(VICTIM, HitLedger.Slot.R))
	assert_not_null(hit)
	assert_eq(hit.striker_id, TargetRules.NONE)


func test_bacamarte_nao_e_direto() -> void:
	_spawn_paladin(1)
	var engineer := _spawn_enemy(ENGINEER, AHEAD * 1.5)
	engineer.input.attack = true
	engineer.input.aim = Vector3(0, 0, 1)
	for tick: int in range(START, START + 3):
		engineer._rollback_tick(TICK, tick, true)
	var hit := _received(HitLedger.source_key(VICTIM, HitLedger.Slot.BASIC))
	assert_not_null(hit)
	assert_eq(hit.striker_id, TargetRules.NONE)


func test_golpe_do_monstro_e_direto_e_o_em_area_nao() -> void:
	_spawn_paladin(1)
	var skeleton := _spawn_monster(SKELETON, -5, AHEAD * 1.0)
	skeleton._target = _paladin
	skeleton._attack(START)
	var hit := _received(HitLedger.source_key(-5, HitLedger.Slot.BASIC))
	assert_not_null(hit)
	assert_eq(hit.striker_id, -5)
	var golem := _spawn_monster(GOLEM, -6, AHEAD * 1.0)
	golem._target = _paladin
	golem._attack(START)
	var slam := _received(HitLedger.source_key(-6, HitLedger.Slot.BASIC))
	assert_not_null(slam)
	assert_eq(slam.striker_id, TargetRules.NONE, "golpe em area")
