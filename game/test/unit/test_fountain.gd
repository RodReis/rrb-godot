extends GutTest
## Fonte da base (PI 2026-10-10, #74): 1 % do HP max por segundo, so o time dono, raio 2,5 u, so
## com a fonte aberta (fase 1), vivo, e tomar dano pausa a cura por 3 s.

const KNIGHT: String = "res://scenes/heroes/knight.tscn"
const FOUNTAIN: String = "res://scenes/world/fountain.tscn"
const TICK: float = 1.0 / 30.0
const RATE: int = 30
## Multiplo de 30: o pulso cai no fim de cada segundo a partir daqui.
const START: int = 900
const HERE: Vector3 = Vector3(-30, 0, 15)
const NEAR: Vector3 = Vector3(2, 0, 0)
const LOW_HP: int = 300

var _hero: Hero
var _fountain: Fountain


func before_each() -> void:
	_fountain = (load(FOUNTAIN) as PackedScene).instantiate() as Fountain
	_fountain.team = GateRules.TEAM_A
	_fountain.position = HERE
	add_child_autofree(_fountain)
	_hero = (load(KNIGHT) as PackedScene).instantiate() as Hero
	_hero.name = "1"
	_hero.team = GateRules.TEAM_A
	_hero.position = HERE + NEAR
	add_child_autofree(_hero)
	_hero.fountain_open = true
	_hero.hp = LOW_HP


func _run(from: int, to: int) -> void:
	for tick: int in range(from, to + 1):
		_hero._rollback_tick(TICK, tick, true)


func test_cura_um_por_cento_do_hp_max_por_segundo() -> void:
	_run(START + 1, START + RATE - 1)
	assert_eq(_hero.hp, LOW_HP, "so no fim do segundo")
	_run(START + RATE, START + 2 * RATE)
	assert_eq(_hero.hp, LOW_HP + 2 * 6)


func test_pulso_minimo_e_arredondado() -> void:
	assert_eq(FountainRules.heal_amount(600, 0.01), 6)
	assert_eq(FountainRules.heal_amount(810, 0.01), 8)
	assert_eq(FountainRules.heal_amount(10, 0.01), 1)


func test_condicoes_da_cura() -> void:
	assert_true(FountainRules.can_heal(true, true, 0, true))
	assert_false(FountainRules.can_heal(false, true, 0, true), "fechada")
	assert_false(FountainRules.can_heal(true, false, 0, true), "morto")
	assert_false(FountainRules.can_heal(true, true, 1, true), "dano recente")
	assert_false(FountainRules.can_heal(true, true, 0, false), "fora da area")


func test_fonte_do_outro_time_nao_cura() -> void:
	_fountain.team = GateRules.TEAM_B
	_run(START + 1, START + 2 * RATE)
	assert_eq(_hero.hp, LOW_HP)


func test_fora_do_raio_nao_cura() -> void:
	_hero.position = HERE + NEAR * 2
	_run(START + 1, START + 2 * RATE)
	assert_eq(_hero.hp, LOW_HP)


func test_fechada_fora_da_fase_1_nao_cura() -> void:
	_hero.fountain_open = false
	_run(START + 1, START + 2 * RATE)
	assert_eq(_hero.hp, LOW_HP)


func test_dano_pausa_a_cura_por_3_s() -> void:
	var blow := HitEffect.new(100)
	_hero.receive_hit(START + 1, HitLedger.source_key(-3, HitLedger.Slot.BASIC), blow)
	_run(START + 1, START + 1)
	var hurt := _hero.hp
	assert_lt(hurt, LOW_HP)
	_run(START + 2, START + 3 * RATE - 1)
	assert_eq(_hero.hp, hurt, "pulsos dos segundos 1 e 2 pulados")
	_run(START + 3 * RATE, START + 3 * RATE)
	assert_eq(_hero.hp, hurt + 6)


func test_nao_passa_do_hp_max() -> void:
	_hero.hp = _hero.attributes.max_hp - 2
	_run(START + 1, START + RATE)
	assert_eq(_hero.hp, _hero.attributes.max_hp)


func test_heroi_ve_a_fonte_aberta_so_na_fase_1() -> void:
	var rules := load("res://shared/data/rules/match_pacing.tres") as MatchRules
	var clock := MatchClock.new()
	clock.rules = rules
	add_child_autofree(clock)
	var match_controller := MatchController.new()
	match_controller.rules = rules
	match_controller.clock = clock
	match_controller.available_heroes = [&"knight"]
	add_child_autofree(match_controller)
	_hero.fountain_open = false
	match_controller.open(START, RATE)
	match_controller.join(1, GateRules.TEAM_A, false, START)
	match_controller.join(2, GateRules.TEAM_B, false, START)
	match_controller.update(START + 24 * RATE)
	assert_true(_hero.fountain_open, "PHASE1")
	clock.update(START + 24 * RATE + 300 * RATE)
	assert_false(_hero.fountain_open, "TRANSITION")
