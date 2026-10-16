extends GutTest
## SPEC-066 §3: o auto-ataque do alvo travado respeita o alcance do basico de cada heroi (.tres):
## dentro dele o basico sai sozinho, fora dele nao sai e o heroi nao anda ate o alvo.

const HEROES: Array[String] = ["knight", "ranger", "barbarian", "fire_wizard", "rogue", "engineer"]
const DATA_PATH: String = "res://shared/data/heroes/%s.tres"
const KNIGHT: String = "res://scenes/heroes/knight.tscn"
const TICK: float = 1.0 / 30.0
## Folga em torno do alcance (u).
const MARGIN: float = 0.2
const AHEAD: Vector3 = Vector3(0.0, 0.0, -1.0)
## Cada duelo tem seus ids e o seu canto da arena: um nao enxerga nem acha o outro.
const PEER_STEP: int = 10
const LANE_STEP: float = 200.0

var _tick: int = 100
var _duels: int = 0


func _reach(id: String) -> float:
	return (load(DATA_PATH % id) as HeroData).basic_attack.attack_range


## Trava o alvo no 1o tick e roda [param ticks] ao todo; devolve o heroi.
func _fight(id: String, distance: float, ticks: int) -> Hero:
	_duels += 1
	var me := _duels * PEER_STEP
	var origin := Vector3(_duels * LANE_STEP, 0.0, 0.0)
	var hero := (load(Hero.SCENE_PATH % id) as PackedScene).instantiate() as Hero
	hero.name = str(me)
	hero.team = GateRules.TEAM_A
	hero.transform = Transform3D(Basis(), origin)
	add_child_autofree(hero)
	var foe := (load(KNIGHT) as PackedScene).instantiate() as Hero
	foe.name = str(me + 1)
	foe.team = GateRules.TEAM_B
	foe.transform = Transform3D(Basis(), origin + AHEAD * distance)
	add_child_autofree(foe)
	hero.input.target_id = me + 1
	for i: int in ticks:
		_tick += 1
		hero._rollback_tick(TICK, _tick, true)
		foe._rollback_tick(TICK, _tick, true)
		hero.input.target_id = TargetRules.NONE
	return hero


func test_dentro_do_alcance_o_basico_sai_sozinho_em_cada_heroi() -> void:
	for id: String in HEROES:
		var distance := _reach(id) - MARGIN
		var hero := _fight(id, distance, 1)
		assert_ne(hero.target_id, TargetRules.NONE, "%s travou" % id)
		assert_gt(hero.basic_cooldown, 0, "%s ataca a %.1f u" % [id, distance])


func test_fora_do_alcance_nada_sai_e_ninguem_anda_em_cada_heroi() -> void:
	for id: String in HEROES:
		var distance := _reach(id) + MARGIN
		var hero := _fight(id, distance, 4)
		var origin := Vector3(_duels * LANE_STEP, 0.0, 0.0)
		assert_ne(hero.target_id, TargetRules.NONE, "%s manteve o alvo" % id)
		assert_eq(hero.basic_cooldown, 0, "%s nao ataca a %.1f u" % [id, distance])
		assert_almost_eq(hero.global_position, origin, Vector3.ONE * 0.01, "%s ficou" % id)
