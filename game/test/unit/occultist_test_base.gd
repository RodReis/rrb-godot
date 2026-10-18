class_name OccultistTestBase
extends GutTest
## Base dos testes do Ocultista (test_occultist*.gd): cena, alvos, paredes e ticks. Sem testes
## proprios (o GUT so coleta arquivos test_*).

const OCCULTIST: String = "res://scenes/heroes/occultist.tscn"
const KNIGHT: String = "res://scenes/heroes/knight.tscn"
const BERSERKER: String = "res://scenes/heroes/berserker.tscn"
const GOLEM: String = "res://scenes/monsters/golem_t3.tscn"
const BOSS: String = "res://scenes/monsters/skeleton_king_boss.tscn"
const TICK: float = 1.0 / 30.0
const START: int = 100
const CASTER: int = 7
const VICTIM: int = 8
const EPS: float = 0.0001
## Frente do heroi sem rotacao: -Z.
const AHEAD: Vector3 = Vector3(0, 0, -1)
const SIDE: Vector3 = Vector3(1, 0, 0)
## HP e DEF do Cavaleiro no nivel 1 (GDB §4.1).
const KNIGHT_HP: int = 600
const KNIGHT_DEF: float = 30.0
const GOLEM_HP: int = 680
## 4,0 s da Maldicao e da Praga a 30 ticks/s; intervalo de 0,5 s entre pulsos.
const CURSE_TICKS: int = 120
const PULSE_INTERVAL: int = 15

var _occultist: Occultist
var _others: Array[Combatant] = []
var _zones: Array = []


func before_each() -> void:
	_others = []
	_zones = []


func _spawn_occultist(level: int, at: Vector3 = Vector3.ZERO) -> Occultist:
	_occultist = (load(OCCULTIST) as PackedScene).instantiate() as Occultist
	_occultist.name = str(CASTER)
	_occultist.team = GateRules.TEAM_A
	_occultist.level = level
	_occultist.collision_mask = GateRules.hero_mask(GateRules.TEAM_A)
	_occultist.transform = Transform3D(Basis(), at)
	add_child_autofree(_occultist)
	_occultist.zone_started.connect(
		func(kind: Occultist.Zone, center: Vector3, _tick: int) -> void:
			_zones.append([kind, center])
	)
	return _occultist


func _spawn_knight(at: Vector3, id: int = VICTIM) -> Knight:
	var knight := (load(KNIGHT) as PackedScene).instantiate() as Knight
	knight.name = str(id)
	knight.team = GateRules.TEAM_B
	knight.collision_mask = GateRules.hero_mask(GateRules.TEAM_B)
	knight.transform = Transform3D(Basis(), at)
	add_child_autofree(knight)
	_others.append(knight)
	return knight


func _spawn_berserker(at: Vector3, id: int = VICTIM) -> Berserker:
	var berserker := (load(BERSERKER) as PackedScene).instantiate() as Berserker
	berserker.name = str(id)
	berserker.team = GateRules.TEAM_B
	berserker.collision_mask = GateRules.hero_mask(GateRules.TEAM_B)
	berserker.transform = Transform3D(Basis(), at)
	add_child_autofree(berserker)
	_others.append(berserker)
	return berserker


func _spawn_monster(path: String, uid: int, at: Vector3) -> Monster:
	var monster := (load(path) as PackedScene).instantiate() as Monster
	monster.uid = uid
	monster.transform = Transform3D(Basis(), at)
	add_child_autofree(monster)
	_others.append(monster)
	return monster


## Um tick de todos: o Ocultista age, os herois alvo aplicam o ledger do proprio tick e o monstro
## conta a Maldicao e a Praga (so isso: sem IA, para ele nao reagir).
func _run(from: int, count: int) -> void:
	for tick: int in range(from, from + count):
		_occultist._rollback_tick(TICK, tick, true)
		for other: Combatant in _others:
			if other is Hero:
				(other as Hero)._rollback_tick(TICK, tick, true)
			elif other is Monster:
				(other as Monster)._tick_curse_and_dot(tick)
		_occultist.input.attack = false
		_occultist.input.skill_q = false
		_occultist.input.skill_e = false
		_occultist.input.skill_r = false


## Como _run, com o botao do basico segurado em todos os ticks.
func _run_attacking(from: int, count: int) -> void:
	for tick: int in range(from, from + count):
		_occultist.input.attack = true
		_run(tick, 1)


func _basic_damage() -> int:
	return roundi(SkillRules.amount(_occultist.hero_data.basic_attack, 1, _occultist.attributes))


func _q_total() -> int:
	return roundi(
		SkillRules.amount(_occultist.hero_data.skill_q, _occultist.ranks.x, _occultist.attributes)
	)


func _e_total() -> int:
	return roundi(
		SkillRules.amount(_occultist.hero_data.skill_e, _occultist.ranks.y, _occultist.attributes)
	)


func _bot_brain(level: int = 6) -> BotInput:
	_occultist = (load(OCCULTIST) as PackedScene).instantiate() as Occultist
	_occultist.name = str(CASTER)
	_occultist.team = GateRules.TEAM_B
	_occultist.level = level
	_occultist.is_bot = true
	_occultist.get_node("Input").set_script(BotInput)
	add_child_autofree(_occultist)
	var brain := _occultist.input as BotInput
	brain._hero = _occultist
	return brain
