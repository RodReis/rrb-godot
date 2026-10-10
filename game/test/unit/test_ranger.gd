extends GutTest
## ranger.tscn (GDB §4.2, F14): numeros de ranger.tres; flecha do pool voa, acerta pelo ledger e
## some no alcance, no muro e na Muralha; Q atravessa perdendo dano; E rola invulneravel e reseta
## o basico; R pulsa 6 vezes com lentidao. Servidor = processo do teste (peer offline).

const RANGER: String = "res://scenes/heroes/ranger.tscn"
const KNIGHT: String = "res://scenes/heroes/knight.tscn"
const SKELETON: String = "res://scenes/monsters/skeleton_t1.tscn"
const GOLEM: String = "res://scenes/monsters/golem_t3.tscn"
const TICK: float = 1.0 / 30.0
const RATE: int = 30
const START: int = 100
const SHOOTER: int = 7
const VICTIM: int = 8
const EPS: float = 0.0001
## Frente do heroi sem rotacao: -Z.
const AHEAD: Vector3 = Vector3(0, 0, -1)

var _ranger: Ranger
var _others: Array[Combatant] = []


func before_each() -> void:
	_others = []


func _spawn_ranger(level: int) -> Ranger:
	_ranger = (load(RANGER) as PackedScene).instantiate() as Ranger
	_ranger.name = str(SHOOTER)
	_ranger.team = GateRules.TEAM_A
	_ranger.level = level
	add_child_autofree(_ranger)
	return _ranger


func _spawn_knight(at: Vector3) -> Knight:
	var knight := (load(KNIGHT) as PackedScene).instantiate() as Knight
	knight.name = str(VICTIM)
	knight.team = GateRules.TEAM_B
	knight.transform = Transform3D(Basis(), at)
	add_child_autofree(knight)
	_others.append(knight)
	return knight


func _spawn_monster(path: String, uid: int, at: Vector3) -> Monster:
	var monster := (load(path) as PackedScene).instantiate() as Monster
	monster.uid = uid
	monster.transform = Transform3D(Basis(), at)
	add_child_autofree(monster)
	_others.append(monster)
	return monster


## Um tick de todos: a Arqueira atira/avanca e os herois alvo aplicam o ledger do proprio tick.
func _run(from: int, count: int) -> void:
	for tick: int in range(from, from + count):
		_ranger._rollback_tick(TICK, tick, true)
		for other: Combatant in _others:
			if other is Hero:
				(other as Hero)._rollback_tick(TICK, tick, true)
		_ranger.input.attack = false
		_ranger.input.skill_q = false
		_ranger.input.skill_e = false
		_ranger.input.skill_r = false


func _active_arrows() -> int:
	var count := 0
	for node: Node in _ranger.get_node("Arrows").get_children():
		count += 1 if (node as Arrow).is_active() else 0
	return count


func _first_arrow() -> Arrow:
	return _ranger.get_node("Arrows/Arrow0") as Arrow


func test_nivel_1_tem_os_atributos_base() -> void:
	var ranger := _spawn_ranger(1)
	assert_eq(ranger.hp, 380)
	assert_almost_eq(ranger.attributes.move_speed, 6.2 * (1.0 + 25.0 * 0.004), EPS)
	assert_eq(ranger.ranks, Vector3i(1, 0, 0))


func test_basico_voa_e_some_ao_atingir_9_u() -> void:
	_spawn_ranger(1)
	_ranger.input.attack = true
	_run(START, 1)
	var arrow := _first_arrow()
	assert_eq(arrow.kind, Arrow.Kind.BASIC)
	assert_eq(arrow.damage, 55)
	_run(START + 1, 13)
	assert_true(arrow.is_active(), "13 ticks = 8,67 u: ainda voando")
	_run(START + 14, 1)
	assert_false(arrow.is_active())
	assert_almost_eq(arrow.traveled, 9.0, EPS)


func test_basico_acerta_o_primeiro_e_para() -> void:
	_spawn_ranger(1)
	var near := _spawn_monster(SKELETON, -1, AHEAD * 4.0)
	var far := _spawn_monster(SKELETON, -2, AHEAD * 7.0)
	_ranger.input.attack = true
	_run(START, 15)
	assert_eq(near.hp, 160 - 55)
	assert_eq(far.hp, 160)
	assert_eq(_active_arrows(), 0)


func test_basico_no_heroi_passa_pelo_ledger_e_pela_def() -> void:
	_spawn_ranger(1)
	var knight := _spawn_knight(AHEAD * 5.0)
	_ranger.input.attack = true
	_run(START, 15)
	assert_eq(knight.hp, 600 - CombatRules.mitigated(55, 30.0))


func test_q_atravessa_perdendo_15_por_cento_por_alvo() -> void:
	_spawn_ranger(1)
	var first := _spawn_monster(GOLEM, -1, AHEAD * 3.0)
	var second := _spawn_monster(GOLEM, -2, AHEAD * 6.0)
	var third := _spawn_monster(GOLEM, -3, AHEAD * 10.5)
	_ranger.input.skill_q = true
	_run(START, 20)
	var damage := roundi(65.0 + 0.95 * 55.0)
	assert_eq(680 - first.hp, damage)
	assert_eq(680 - second.hp, roundi(damage * 0.85))
	assert_eq(680 - third.hp, roundi(damage * 0.70), "alcance do Q: 11 u")
	assert_eq(
		_ranger.q_cooldown, SkillRules.cooldown_ticks(_ranger.hero_data.skill_q, 1, 15.0, RATE) - 19
	)


func test_flecha_para_no_muro() -> void:
	_spawn_ranger(1)
	var wall := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(4, 4, 0.5)
	shape.shape = box
	wall.add_child(shape)
	wall.position = AHEAD * 4.0 + Vector3.UP
	add_child_autofree(wall)
	var behind := _spawn_monster(SKELETON, -1, AHEAD * 6.0)
	await wait_physics_frames(2)
	_ranger.input.attack = true
	_run(START, 15)
	assert_eq(behind.hp, 160)
	assert_eq(_active_arrows(), 0)
	assert_almost_eq(_first_arrow().traveled, 3.75, 0.01)


func test_muralha_ativa_bloqueia_a_flecha() -> void:
	_spawn_ranger(1)
	var knight := _spawn_knight(AHEAD * 5.0)
	knight.look_at(Vector3.ZERO, Vector3.UP)  # Muralha virada para a Arqueira
	knight.shield_ticks = 60
	knight.shield_hp = 200
	_ranger.input.attack = true
	_run(START, 15)
	assert_eq(knight.hp, 600)
	assert_eq(knight.shield_hp, 200, "bloqueada antes de chegar: nem o escudo absorve")
	assert_eq(_active_arrows(), 0)


func test_rolamento_avanca_fica_invulneravel_e_reseta_o_basico() -> void:
	_spawn_ranger(2)
	assert_eq(_ranger.ranks.y, 1, "E aprendido no nivel 2")
	_ranger.basic_cooldown = 20
	_ranger.input.movement = Vector3(1, 0, 0)
	_ranger.input.skill_e = true
	_run(START, 1)
	assert_eq(_ranger.basic_cooldown, 0)
	assert_eq(_ranger.dash_ticks, 11)
	assert_almost_eq(_ranger.dash_speed * 11 / RATE, 4.2, EPS)
	assert_eq(_ranger.dash_direction, Vector3(1, 0, 0))
	assert_eq(_ranger.invuln_ticks, 9)
	assert_eq(
		_ranger.e_cooldown, SkillRules.cooldown_ticks(_ranger.hero_data.skill_e, 1, 16.5, RATE)
	)


func test_invulnerabilidade_do_rolamento_dura_9_ticks() -> void:
	_spawn_ranger(2)
	_ranger.input.skill_e = true
	_run(START, 1)
	var blow := HitEffect.new(100, Vector3.ZERO)
	for tick: int in range(START + 1, START + 11):
		_ranger.receive_hit(tick, VICTIM, blow)
	_run(START + 1, 9)
	assert_eq(_ranger.hp, _ranger.attributes.max_hp, "9 ticks sem dano")
	_run(START + 10, 1)
	assert_eq(_ranger.hp, _ranger.attributes.max_hp - CombatRules.mitigated(100, 11.2))


func test_rolamento_parado_vai_para_a_frente() -> void:
	_spawn_ranger(2)
	_ranger.input.skill_e = true
	_run(START, 1)
	assert_almost_eq(_ranger.dash_direction, AHEAD, Vector3.ONE * EPS)


func test_chuva_cai_no_cursor_pulsa_6_vezes_e_deixa_lento() -> void:
	_spawn_ranger(6)
	var golem := _spawn_monster(GOLEM, -1, AHEAD * 5.0)
	var knight := _spawn_knight(AHEAD * 5.0 + Vector3(1, 0, 0))
	_ranger.input.skill_r = true
	_ranger.input.aim_distance = 5.0
	_run(START, 1)
	assert_almost_eq(_ranger.rain_center, AHEAD * 5.0, Vector3.ONE * EPS)
	assert_eq(_ranger.rain_ticks, 90)
	_run(START + 1, 2)
	assert_gt(golem._slow_ticks, 0)
	assert_eq(knight.slow_ticks, 15, "16 ticks de lentidao, um ja descontado")
	assert_almost_eq(knight.slow_pct, 0.25, EPS)
	_run(START + 3, 95)
	assert_eq(_ranger.rain_ticks, 0)
	var attrs := _ranger.attributes
	var pulse := roundi(30.0 + 0.25 * attrs.intelligence + 0.15 * attrs.attack)
	assert_eq(680 - golem.hp, 6 * pulse)
	assert_eq(knight.slow_ticks, 0, "lentidao acaba depois do ultimo pulso")


func test_chuva_alem_do_alcance_cai_a_8_u() -> void:
	_spawn_ranger(6)
	_ranger.input.skill_r = true
	_ranger.input.aim_distance = 40.0
	_run(START, 1)
	assert_almost_eq(_ranger.rain_center, AHEAD * 8.0, Vector3.ONE * EPS)


func test_pool_cheio_reaproveita_a_flecha_mais_antiga() -> void:
	_spawn_ranger(1)
	for i: int in 5:
		_ranger.basic_cooldown = 0
		_ranger.input.attack = true
		_run(START + i, 1)
	assert_eq(_active_arrows(), 4)
	assert_almost_eq(_first_arrow().traveled, 0.0, EPS, "a 1a flecha foi reaproveitada")


func _wall_at(at: Vector3) -> void:
	var wall := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(4, 4, 0.5)
	shape.shape = box
	wall.add_child(shape)
	wall.position = at + Vector3.UP
	add_child_autofree(wall)


func _bot_brain() -> BotInput:
	_ranger = (load(RANGER) as PackedScene).instantiate() as Ranger
	_ranger.name = str(SHOOTER)
	_ranger.team = GateRules.TEAM_B
	_ranger.is_bot = true
	_ranger.get_node("Input").set_script(BotInput)
	add_child_autofree(_ranger)
	var brain := _ranger.input as BotInput
	brain._hero = _ranger
	return brain


func test_bot_de_arqueira_atira_com_linha_livre() -> void:
	var brain := _bot_brain()
	var monster := _spawn_monster(SKELETON, -1, AHEAD * 6.0)
	await wait_physics_frames(2)
	brain._attack(START, monster, true)
	assert_true(brain.attack)
	assert_true(brain.skill_q)
	assert_almost_eq(brain.aim_distance, 6.0, EPS)


func test_bot_de_arqueira_nao_atira_no_muro() -> void:
	var brain := _bot_brain()
	_wall_at(AHEAD * 3.0)
	var monster := _spawn_monster(SKELETON, -1, AHEAD * 6.0)
	await wait_physics_frames(2)
	brain._attack(START, monster, true)
	assert_false(brain.attack)
	assert_false(brain.skill_q)
	assert_false(brain.movement.is_zero_approx(), "segue andando ate ter linha de tiro")
