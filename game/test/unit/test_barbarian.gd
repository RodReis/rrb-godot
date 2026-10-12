extends GutTest
## barbarian.tscn (GDB §4.3, F53; SPEC-053 §6 itens 3 e 2): basico em arco de 90 graus; Salto ate o
## ponto mirado que para no muro e no rio e fere em area uma vez na aterrissagem; Rodopio com 3
## pulsos por alvo e sem basico durante o giro; Execucao soma 25 % do HP faltante do alvo, antes
## da DEF. Servidor = processo do teste (peer offline).

const BARBARIAN: String = "res://scenes/heroes/barbarian.tscn"
const KNIGHT: String = "res://scenes/heroes/knight.tscn"
const SKELETON: String = "res://scenes/monsters/skeleton_t1.tscn"
const GOLEM: String = "res://scenes/monsters/golem_t3.tscn"
const TICK: float = 1.0 / 30.0
const START: int = 100
const ATTACKER: int = 7
const VICTIM: int = 8
const EPS: float = 0.0001
## Frente do heroi sem rotacao: -Z.
const AHEAD: Vector3 = Vector3(0, 0, -1)
## 0,45 s a 30 ticks/s.
const LEAP_TICKS: int = 14

var _barbarian: Barbarian
var _others: Array[Combatant] = []


func before_each() -> void:
	_others = []


func _spawn_barbarian(level: int) -> Barbarian:
	_barbarian = (load(BARBARIAN) as PackedScene).instantiate() as Barbarian
	_barbarian.name = str(ATTACKER)
	_barbarian.team = GateRules.TEAM_A
	_barbarian.level = level
	_barbarian.collision_mask = GateRules.hero_mask(GateRules.TEAM_A)
	add_child_autofree(_barbarian)
	return _barbarian


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


func _block_at(at: Vector3, layer: int) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = layer
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(6, 4, 0.5)
	shape.shape = box
	body.add_child(shape)
	body.position = at + Vector3.UP
	add_child_autofree(body)


## Um tick de todos: o Barbaro age e os herois alvo aplicam o ledger do proprio tick.
func _run(from: int, count: int) -> void:
	for tick: int in range(from, from + count):
		_barbarian._rollback_tick(TICK, tick, true)
		for other: Combatant in _others:
			if other is Hero:
				(other as Hero)._rollback_tick(TICK, tick, true)
		_barbarian.input.attack = false
		_barbarian.input.skill_q = false
		_barbarian.input.skill_e = false
		_barbarian.input.skill_r = false


func _at_angle(degrees: float, distance: float) -> Vector3:
	var rad := deg_to_rad(degrees)
	return Vector3(sin(rad), 0.0, -cos(rad)) * distance


func test_nivel_1_tem_os_atributos_base() -> void:
	var barbarian := _spawn_barbarian(1)
	assert_eq(barbarian.hp, 480)
	assert_almost_eq(barbarian.attributes.move_speed, 6.0 * (1.0 + 20.0 * 0.004), EPS)
	assert_eq(barbarian.ranks, Vector3i(1, 0, 0))


func test_basico_acerta_no_arco_de_90_graus_e_2_4_u() -> void:
	_spawn_barbarian(1)
	var inside := _spawn_monster(SKELETON, -1, _at_angle(40.0, 2.2))
	var wide := _spawn_monster(SKELETON, -2, _at_angle(-50.0, 2.2))
	var far := _spawn_monster(SKELETON, -3, AHEAD * 2.7)
	_barbarian.input.attack = true
	_run(START, 1)
	assert_eq(inside.hp, 160 - 52)
	assert_eq(wide.hp, 160)
	assert_eq(far.hp, 160)


func test_salto_vai_ao_ponto_mirado_e_fere_uma_vez_na_aterrissagem() -> void:
	_spawn_barbarian(1)
	var near := _spawn_monster(SKELETON, -1, AHEAD * 5.0 + Vector3(1.5, 0, 0))
	var away := _spawn_monster(SKELETON, -2, AHEAD * 9.0)
	await wait_physics_frames(2)
	_barbarian.input.skill_q = true
	_barbarian.input.aim_distance = 5.0
	_run(START, 1)
	assert_eq(_barbarian.dash_ticks, LEAP_TICKS)
	_run(START + 1, LEAP_TICKS - 1)
	assert_eq(near.hp, 160, "no ar ainda nao fere")
	_run(START + LEAP_TICKS, 1)
	assert_almost_eq(_barbarian.global_position, AHEAD * 5.0, Vector3.ONE * 0.01)
	var damage := roundi(60.0 + 0.8 * 52.0)
	assert_eq(near.hp, 160 - damage)
	assert_eq(away.hp, 160)
	_run(START + LEAP_TICKS + 1, 30)
	assert_eq(near.hp, 160 - damage, "uma vez por alvo")


func test_salto_alem_do_alcance_para_em_7_u() -> void:
	_spawn_barbarian(1)
	await wait_physics_frames(2)  # corpos do teste anterior saem do espaco fisico
	_barbarian.input.skill_q = true
	_barbarian.input.aim_distance = 40.0
	_run(START, LEAP_TICKS + 1)
	assert_almost_eq(_barbarian.global_position, AHEAD * 7.0, Vector3.ONE * 0.01)


func test_salto_para_no_muro_e_aterrissa_ali() -> void:
	_spawn_barbarian(1)
	_block_at(AHEAD * 3.0, PhysicsLayers.WORLD)
	var behind := _spawn_monster(SKELETON, -1, AHEAD * 6.0)
	await wait_physics_frames(2)
	_barbarian.input.skill_q = true
	_barbarian.input.aim_distance = 7.0
	_run(START, LEAP_TICKS + 1)
	assert_gt(_barbarian.global_position.z, -3.0, "nao atravessa o muro")
	assert_eq(_barbarian.dash_ticks, 0)
	assert_false(_barbarian.leaping)
	assert_eq(behind.hp, 160, "aterrissou antes do muro: 6 u fica fora do raio")


func test_salto_para_no_rio() -> void:
	_spawn_barbarian(1)
	_block_at(AHEAD * 3.0, PhysicsLayers.RIVER)
	await wait_physics_frames(2)
	_barbarian.input.skill_q = true
	_barbarian.input.aim_distance = 7.0
	_run(START, LEAP_TICKS + 1)
	assert_gt(_barbarian.global_position.z, -3.0, "o rio so se cruza pelas pontes")
	assert_eq(_barbarian.dash_ticks, 0)


func test_rodopio_aplica_exatamente_3_pulsos_por_alvo() -> void:
	_spawn_barbarian(2)
	assert_eq(_barbarian.ranks.y, 1, "E aprendido no nivel 2")
	var golem := _spawn_monster(GOLEM, -1, AHEAD * 2.0)
	var knight := _spawn_knight(Vector3(2.0, 0, 0))
	_barbarian.input.skill_e = true
	_run(START, 1)
	assert_true(_barbarian.is_channeling())
	_run(START + 1, 60)
	assert_false(_barbarian.is_channeling())
	var pulse := roundi(30.0 + 0.35 * _barbarian.attributes.attack)
	assert_eq(680 - golem.hp, 3 * pulse)
	assert_eq(600 - knight.hp, 3 * CombatRules.mitigated(pulse, 30.0))


func test_rodopio_bloqueia_o_basico_enquanto_gira() -> void:
	_spawn_barbarian(2)
	_barbarian.input.skill_e = true
	_run(START, 1)
	var tick := START + 1
	while _barbarian.is_channeling():
		_barbarian.input.attack = true
		_run(tick, 1)
		tick += 1
		if _barbarian.is_channeling():
			assert_eq(_barbarian.basic_cooldown, 0, "sem basico no tick %d" % tick)
	_barbarian.input.attack = true
	_run(tick, 1)
	assert_gt(_barbarian.basic_cooldown, 0, "terminado o giro, golpeia")


func test_execucao_soma_25_por_cento_do_hp_faltante_antes_da_def() -> void:
	_spawn_barbarian(6)
	assert_eq(_barbarian.ranks.z, 1, "R aprendido no nivel 6")
	var knight := _spawn_knight(AHEAD * 2.0)
	knight.hp = 300
	_barbarian.input.skill_r = true
	_run(START, 2)
	var attrs := _barbarian.attributes
	var raw := roundi(200.0 + attrs.intelligence + 0.5 * attrs.attack + 0.25 * 300)
	assert_eq(knight.hp, 300 - CombatRules.mitigated(raw, 30.0))


func test_execucao_no_monstro_usa_o_hp_faltante_dele() -> void:
	_spawn_barbarian(6)
	var golem := _spawn_monster(GOLEM, -1, AHEAD * 2.0)
	golem.hp = 340
	_barbarian.input.skill_r = true
	_run(START, 1)
	var attrs := _barbarian.attributes
	var raw := roundi(200.0 + attrs.intelligence + 0.5 * attrs.attack + 0.25 * 340)
	assert_eq(golem.hp, maxi(340 - raw, 0))


func test_execucao_so_acerta_no_cone_de_60_graus() -> void:
	_spawn_barbarian(6)
	var side := _spawn_monster(SKELETON, -1, _at_angle(40.0, 2.0))
	_barbarian.input.skill_r = true
	_run(START, 1)
	assert_eq(side.hp, 160)
	assert_gt(_barbarian.r_cooldown, 0, "golpe sai mesmo sem alvo")


func _bot_brain() -> BotInput:
	_barbarian = (load(BARBARIAN) as PackedScene).instantiate() as Barbarian
	_barbarian.name = str(ATTACKER)
	_barbarian.team = GateRules.TEAM_B
	_barbarian.is_bot = true
	_barbarian.get_node("Input").set_script(BotInput)
	add_child_autofree(_barbarian)
	var brain := _barbarian.input as BotInput
	brain._hero = _barbarian
	return brain


func test_bot_salta_no_alvo_fora_do_alcance_do_basico() -> void:
	var brain := _bot_brain()
	var monster := _spawn_monster(SKELETON, -1, AHEAD * 5.0)
	brain._attack(START, monster, true)
	assert_true(brain.skill_q)
	assert_false(brain.skill_e)
	assert_false(brain.attack)
	assert_almost_eq(brain.aim_distance, 5.0, EPS)


func test_bot_perto_gira_executa_e_golpeia() -> void:
	var brain := _bot_brain()
	var monster := _spawn_monster(SKELETON, -1, AHEAD * 1.5)
	brain._attack(START, monster, true)
	assert_false(brain.skill_q)
	assert_true(brain.skill_e)
	assert_true(brain.skill_r)
	assert_true(brain.attack)


func test_bot_farmando_nao_usa_habilidade() -> void:
	var brain := _bot_brain()
	var monster := _spawn_monster(SKELETON, -1, AHEAD * 5.0)
	brain._attack(START, monster, false)
	assert_false(brain.skill_q)
