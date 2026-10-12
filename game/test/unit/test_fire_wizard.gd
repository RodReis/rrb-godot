extends GutTest
## fire_wizard.tscn (GDB §4.4, F54; SPEC-054 §6 item 2): Bola de Fogo para no 1o alvo e na
## Muralha; Explosao de Chamas explode no 1o alvo, na Muralha, no muro ou no fim do alcance e fere
## em area quem esta no raio 2,0 u; Anel de Fogo fere e empurra 2,0 u para fora e para no muro e no
## rio; Meteoro cai exatamente 1,0 s depois da marcacao e acerta so quem esta no raio 3,5 u naquele
## tick. Servidor = processo do teste (peer offline).

const WIZARD: String = "res://scenes/heroes/fire_wizard.tscn"
const KNIGHT: String = "res://scenes/heroes/knight.tscn"
const SKELETON: String = "res://scenes/monsters/skeleton_t1.tscn"
const GOLEM: String = "res://scenes/monsters/golem_t3.tscn"
const TICK: float = 1.0 / 30.0
const START: int = 100
const CASTER: int = 7
const VICTIM: int = 8
const EPS: float = 0.0001
## Frente do heroi sem rotacao: -Z.
const AHEAD: Vector3 = Vector3(0, 0, -1)
const SIDE: Vector3 = Vector3(1, 0, 0)
## 1,0 s a 30 ticks/s.
const METEOR_TICKS: int = 30

var _wizard: FireWizard
var _others: Array[Combatant] = []


func before_each() -> void:
	_others = []


func _spawn_wizard(level: int) -> FireWizard:
	_wizard = (load(WIZARD) as PackedScene).instantiate() as FireWizard
	_wizard.name = str(CASTER)
	_wizard.team = GateRules.TEAM_A
	_wizard.level = level
	_wizard.collision_mask = GateRules.hero_mask(GateRules.TEAM_A)
	add_child_autofree(_wizard)
	return _wizard


func _spawn_knight(at: Vector3) -> Knight:
	var knight := (load(KNIGHT) as PackedScene).instantiate() as Knight
	knight.name = str(VICTIM)
	knight.team = GateRules.TEAM_B
	knight.collision_mask = GateRules.hero_mask(GateRules.TEAM_B)
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


## Parede fina de [param size] em [param at] na camada [param layer].
func _block_at(at: Vector3, size: Vector3, layer: int) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = layer
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	body.position = at + Vector3.UP
	add_child_autofree(body)


## Um tick de todos: o Bruxo age e os herois alvo aplicam o ledger do proprio tick.
func _run(from: int, count: int) -> void:
	for tick: int in range(from, from + count):
		_wizard._rollback_tick(TICK, tick, true)
		for other: Combatant in _others:
			if other is Hero:
				(other as Hero)._rollback_tick(TICK, tick, true)
		_wizard.input.attack = false
		_wizard.input.skill_q = false
		_wizard.input.skill_e = false
		_wizard.input.skill_r = false


func _active_balls() -> int:
	var count := 0
	for node: Node in _wizard.get_node("Arrows").get_children():
		count += 1 if (node as Arrow).is_active() else 0
	return count


func _q_damage() -> int:
	return roundi(SkillRules.amount(_wizard.hero_data.skill_q, 1, _wizard.attributes))


func test_nivel_1_tem_os_atributos_base() -> void:
	var wizard := _spawn_wizard(1)
	assert_eq(wizard.hp, 360)
	assert_almost_eq(wizard.attributes.move_speed, 6.0 * (1.0 + 15.0 * 0.004), EPS)
	assert_eq(wizard.ranks, Vector3i(1, 0, 0))


func test_bola_de_fogo_acerta_o_primeiro_e_para() -> void:
	_spawn_wizard(1)
	var near := _spawn_monster(SKELETON, -1, AHEAD * 4.0)
	var far := _spawn_monster(SKELETON, -2, AHEAD * 6.0)
	_wizard.input.attack = true
	_run(START, 20)
	assert_eq(near.hp, 160 - 45)
	assert_eq(far.hp, 160)
	assert_eq(_active_balls(), 0)


func test_bola_de_fogo_some_aos_8_u() -> void:
	_spawn_wizard(1)
	var beyond := _spawn_monster(SKELETON, -1, AHEAD * 9.5)
	_wizard.input.attack = true
	_run(START, 20)
	assert_eq(beyond.hp, 160)
	assert_almost_eq((_wizard.get_node("Arrows/Arrow0") as Arrow).traveled, 8.0, EPS)


func test_bola_de_fogo_no_heroi_passa_pela_def() -> void:
	_spawn_wizard(1)
	var knight := _spawn_knight(AHEAD * 5.0)
	_wizard.input.attack = true
	_run(START, 20)
	assert_eq(knight.hp, 600 - CombatRules.mitigated(45, 30.0))


func test_muralha_bloqueia_a_bola_de_fogo() -> void:
	_spawn_wizard(1)
	var knight := _spawn_knight(AHEAD * 5.0)
	knight.look_at(Vector3.ZERO, Vector3.UP)  # Muralha virada para o Bruxo
	knight.shield_ticks = 90
	knight.shield_hp = 200
	_wizard.input.attack = true
	_run(START, 20)
	assert_eq(knight.hp, 600)
	assert_eq(knight.shield_hp, 200, "bloqueada antes de chegar: nem o escudo absorve")
	assert_eq(_active_balls(), 0)


func test_explosao_no_primeiro_alvo_fere_quem_esta_no_raio_2_u() -> void:
	_spawn_wizard(1)
	# Bola (raio 0,4) toca o Golem (raio 0,7) a 5 - 1,1 = 3,9 u: a explosao nasce ali.
	var first := _spawn_monster(GOLEM, -1, AHEAD * 5.0)
	var beside := _spawn_monster(GOLEM, -2, AHEAD * 5.0 + SIDE * 1.5)
	var behind := _spawn_monster(GOLEM, -3, AHEAD * 7.0)
	var wide := _spawn_monster(GOLEM, -4, AHEAD * 3.9 - SIDE * 2.1)
	_wizard.input.skill_q = true
	_run(START, 20)
	var damage := _q_damage()
	assert_eq(damage, roundi(70.0 + 0.9 * 45.0))
	assert_eq(680 - first.hp, damage)
	assert_eq(680 - beside.hp, damage, "1,86 u da explosao")
	assert_eq(behind.hp, 680, "3,1 u: fora do raio")
	assert_eq(wide.hp, 680, "2,1 u: fora do raio")
	assert_eq(_active_balls(), 0)
	_run(START + 20, 30)
	assert_eq(680 - first.hp, damage, "uma vez por alvo")


func test_explosao_no_fim_do_alcance() -> void:
	_spawn_wizard(1)
	var past := _spawn_monster(GOLEM, -1, AHEAD * 10.5)
	_wizard.input.skill_q = true
	_run(START, 25)
	assert_eq(680 - past.hp, _q_damage(), "explode a 9 u e pega quem esta a 1,5 u")


func test_explosao_no_muro() -> void:
	_spawn_wizard(1)
	_block_at(AHEAD * 3.0, Vector3(4, 4, 0.5), PhysicsLayers.WORLD)
	var front := _spawn_monster(GOLEM, -1, AHEAD * 2.0 + SIDE * 1.5)
	var behind := _spawn_monster(GOLEM, -2, AHEAD * 5.0)
	await wait_physics_frames(2)
	_wizard.input.skill_q = true
	_run(START, 20)
	assert_eq(680 - front.hp, _q_damage(), "explode na face do muro (2,75 u)")
	assert_eq(behind.hp, 680)


func test_explosao_na_muralha() -> void:
	_spawn_wizard(1)
	var knight := _spawn_knight(AHEAD * 5.0)
	knight.look_at(Vector3.ZERO, Vector3.UP)
	knight.shield_ticks = 90
	knight.shield_hp = 200
	var behind := _spawn_monster(GOLEM, -1, AHEAD * 7.0)
	_wizard.input.skill_q = true
	_run(START, 20)
	assert_eq(knight.hp, 600, "a Muralha absorve a explosao que vem da frente")
	assert_eq(knight.shield_hp, 200 - CombatRules.mitigated(_q_damage(), 30.0))
	assert_eq(behind.hp, 680)
	assert_eq(_active_balls(), 0)


func test_anel_fere_e_empurra_2_u_para_fora() -> void:
	_spawn_wizard(2)
	assert_eq(_wizard.ranks.y, 1, "E aprendido no nivel 2")
	var knight := _spawn_knight(SIDE * 2.0)
	var golem := _spawn_monster(GOLEM, -1, AHEAD * 2.9)
	var outside := _spawn_monster(GOLEM, -2, -AHEAD * 3.2)
	await wait_physics_frames(2)  # corpos do teste anterior saem do espaco fisico
	_wizard.input.skill_e = true
	_run(START, 15)
	var damage := roundi(40.0 + 0.5 * _wizard.attributes.attack)
	assert_eq(600 - knight.hp, CombatRules.mitigated(damage, 30.0))
	assert_eq(680 - golem.hp, damage)
	assert_eq(outside.hp, 680)
	assert_almost_eq(knight.global_position, SIDE * 4.0, Vector3.ONE * 0.05)
	assert_almost_eq(golem.global_position, AHEAD * 4.9, Vector3.ONE * 0.05)
	assert_almost_eq(outside.global_position, -AHEAD * 3.2, Vector3.ONE * EPS)


func test_anel_para_no_muro() -> void:
	_spawn_wizard(2)
	_block_at(SIDE * 3.0, Vector3(0.5, 4, 6), PhysicsLayers.WORLD)
	var knight := _spawn_knight(SIDE * 2.0)
	await wait_physics_frames(2)
	_wizard.input.skill_e = true
	_run(START, 15)
	assert_lt(knight.global_position.x, 2.75, "nao atravessa o muro")
	assert_gt(knight.global_position.x, 2.0)


func test_anel_para_no_rio() -> void:
	_spawn_wizard(2)
	_block_at(SIDE * 3.0, Vector3(0.5, 4, 6), PhysicsLayers.RIVER)
	var knight := _spawn_knight(SIDE * 2.0)
	await wait_physics_frames(2)
	_wizard.input.skill_e = true
	_run(START, 15)
	assert_lt(knight.global_position.x, 2.75, "o empurrao nao joga ninguem no rio")


func test_meteoro_cai_exatamente_1_s_depois_da_marcacao() -> void:
	_spawn_wizard(6)
	assert_eq(_wizard.ranks.z, 1, "R aprendido no nivel 6")
	var center := _spawn_monster(GOLEM, -1, AHEAD * 6.0)
	var edge := _spawn_monster(GOLEM, -2, AHEAD * 6.0 + SIDE * 3.4)
	var out := _spawn_monster(GOLEM, -3, AHEAD * 6.0 - SIDE * 3.7)
	_wizard.input.skill_r = true
	_wizard.input.aim_distance = 6.0
	_run(START, 1)
	assert_almost_eq(_wizard.meteor_center, AHEAD * 6.0, Vector3.ONE * EPS)
	assert_eq(_wizard.meteor_ticks, METEOR_TICKS)
	_run(START + 1, METEOR_TICKS - 1)
	assert_eq(center.hp, 680, "ainda no ar")
	_run(START + METEOR_TICKS, 1)
	var attrs := _wizard.attributes
	var damage := roundi(260.0 + 1.4 * attrs.intelligence + 0.6 * attrs.attack)
	assert_eq(680 - center.hp, damage)
	assert_eq(680 - edge.hp, damage, "3,4 u")
	assert_eq(out.hp, 680, "3,7 u")
	assert_eq(_wizard.meteor_ticks, 0)
	_run(START + METEOR_TICKS + 1, 30)
	assert_eq(680 - center.hp, damage, "dano unico")


func test_meteoro_acerta_quem_esta_na_area_na_queda() -> void:
	_spawn_wizard(6)
	var leaves := _spawn_monster(GOLEM, -1, AHEAD * 6.0)
	var arrives := _spawn_monster(GOLEM, -2, AHEAD * 6.0 + SIDE * 6.0)
	_wizard.input.skill_r = true
	_wizard.input.aim_distance = 6.0
	_run(START, 15)
	leaves.global_position = AHEAD * 6.0 + SIDE * 6.0
	arrives.global_position = AHEAD * 6.0
	_run(START + 15, METEOR_TICKS)
	assert_eq(leaves.hp, 680)
	assert_lt(arrives.hp, 680)


func test_meteoro_no_heroi_passa_pelo_ledger() -> void:
	_spawn_wizard(6)
	var knight := _spawn_knight(AHEAD * 6.0)
	_wizard.input.skill_r = true
	_wizard.input.aim_distance = 6.0
	_run(START, METEOR_TICKS + 2)
	var attrs := _wizard.attributes
	var damage := roundi(260.0 + 1.4 * attrs.intelligence + 0.6 * attrs.attack)
	assert_eq(600 - knight.hp, CombatRules.mitigated(damage, 30.0))


func test_meteoro_alem_do_alcance_cai_a_9_u() -> void:
	_spawn_wizard(6)
	_wizard.input.skill_r = true
	_wizard.input.aim_distance = 40.0
	_run(START, 1)
	assert_almost_eq(_wizard.meteor_center, AHEAD * 9.0, Vector3.ONE * EPS)


func test_meteoro_segue_com_o_bruxo_morto() -> void:
	_spawn_wizard(6)
	var golem := _spawn_monster(GOLEM, -1, AHEAD * 6.0)
	_wizard.input.skill_r = true
	_wizard.input.aim_distance = 6.0
	_run(START, 1)
	_wizard.hp = 0
	_wizard.respawn_ticks = 300
	_run(START + 1, METEOR_TICKS)
	assert_lt(golem.hp, 680)


func _bot_brain() -> BotInput:
	_wizard = (load(WIZARD) as PackedScene).instantiate() as FireWizard
	_wizard.name = str(CASTER)
	_wizard.team = GateRules.TEAM_B
	_wizard.is_bot = true
	_wizard.get_node("Input").set_script(BotInput)
	add_child_autofree(_wizard)
	var brain := _wizard.input as BotInput
	brain._hero = _wizard
	return brain


func test_bot_de_bruxo_lanca_q_e_meteoro_ate_9_u() -> void:
	var brain := _bot_brain()
	var monster := _spawn_monster(SKELETON, -1, AHEAD * 8.5)
	await wait_physics_frames(2)
	brain._attack(START, monster, true)
	assert_true(brain.skill_q)
	assert_true(brain.skill_r)
	assert_false(brain.skill_e)
	assert_false(brain.attack, "fora do alcance do basico: anda")
	assert_almost_eq(brain.aim_distance, 8.5, EPS, "Meteoro mira a posicao do alvo")


func test_bot_de_bruxo_usa_o_anel_com_inimigo_perto() -> void:
	var brain := _bot_brain()
	var monster := _spawn_monster(SKELETON, -1, AHEAD * 2.5)
	await wait_physics_frames(2)
	brain._attack(START, monster, true)
	assert_true(brain.skill_e)
	assert_true(brain.attack)


func test_bot_de_bruxo_farmando_nao_usa_habilidade() -> void:
	var brain := _bot_brain()
	var monster := _spawn_monster(SKELETON, -1, AHEAD * 2.5)
	await wait_physics_frames(2)
	brain._attack(START, monster, false)
	assert_false(brain.skill_q)
	assert_false(brain.skill_e)
	assert_false(brain.skill_r)
	assert_true(brain.attack)
