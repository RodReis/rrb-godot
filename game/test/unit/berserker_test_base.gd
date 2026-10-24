class_name BerserkerTestBase
extends GutTest
## Base dos testes do Berserker (test_berserker*.gd): cena, alvos e ticks. Sem testes proprios (o
## GUT so coleta arquivos test_*).

const BERSERKER: String = "res://scenes/heroes/berserker.tscn"
const KNIGHT: String = "res://scenes/heroes/knight.tscn"
const GOLEM: String = "res://scenes/monsters/golem_t3.tscn"
const TICK: float = 1.0 / 30.0
const START: int = 100
const CASTER: int = 7
const VICTIM: int = 8
const EPS: float = 0.0001
## Frente do heroi sem rotacao: -Z.
const AHEAD: Vector3 = Vector3(0, 0, -1)
const SIDE: Vector3 = Vector3(1, 0, 0)
## HP e DEF do Cavaleiro no nivel 1 (GDB §4.1).
const KNIGHT_HP: int = 620
const KNIGHT_DEF: float = 30.0
const GOLEM_HP: int = 680
## HP, DEF e ATK do Berserker no nivel 1 (GDB §4.8).
const BERSERKER_HP: int = 500
const BERSERKER_DEF: float = 18.0
const BERSERKER_ATK: int = 42
## Frenesi (GDB §4.8): +30% de velocidade de ataque e 10% de roubo de vida no maximo.
const FRENZY_ATTACK_SPEED: float = 0.3
const FRENZY_LIFESTEAL: float = 0.10
## 1,5 s, 2,0 s e 4,0 s a 30 ticks/s.
const SLOW_TICKS: int = 45
const SHOUT_TICKS: int = 60
const RAGE_TICKS: int = 120

var _berserker: Berserker
var _others: Array[Combatant] = []


func before_each() -> void:
	_others = []


func _spawn_berserker(level: int, at: Vector3 = Vector3.ZERO) -> Berserker:
	_berserker = (load(BERSERKER) as PackedScene).instantiate() as Berserker
	_berserker.name = str(CASTER)
	_berserker.team = GateRules.TEAM_A
	_berserker.level = level
	_berserker.collision_mask = GateRules.hero_mask(GateRules.TEAM_A)
	_berserker.transform = Transform3D(Basis(), at)
	add_child_autofree(_berserker)
	return _berserker


func _spawn_knight(at: Vector3, id: int = VICTIM) -> Knight:
	var knight := (load(KNIGHT) as PackedScene).instantiate() as Knight
	knight.name = str(id)
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


## Um tick de todos: o Berserker age e os herois alvo aplicam o ledger do proprio tick.
func _run(from: int, count: int) -> void:
	for tick: int in range(from, from + count):
		_berserker._rollback_tick(TICK, tick, true)
		for other: Combatant in _others:
			if other is Hero:
				(other as Hero)._rollback_tick(TICK, tick, true)
		_berserker.input.attack = false
		_berserker.input.skill_q = false
		_berserker.input.skill_e = false
		_berserker.input.skill_r = false


## Golpe de [param effect] no Berserker, aplicado no tick [param tick] (como o ledger faria).
func _hit_berserker(tick: int, slot: HitLedger.Slot, effect: HitEffect) -> void:
	_berserker.receive_hit(tick, HitLedger.source_key(VICTIM, slot), effect)


func _interval_ticks(f: float) -> int:
	var interval := BerserkerRules.attack_interval(
		_berserker.attributes.attack_interval, f, FRENZY_ATTACK_SPEED
	)
	return SkillRules.seconds_to_ticks(interval, 30)


func _bot_brain(level: int = 6) -> BotInput:
	_berserker = (load(BERSERKER) as PackedScene).instantiate() as Berserker
	_berserker.name = str(CASTER)
	_berserker.team = GateRules.TEAM_B
	_berserker.level = level
	_berserker.is_bot = true
	_berserker.get_node("Input").set_script(BotInput)
	add_child_autofree(_berserker)
	var brain := _berserker.input as BotInput
	brain._hero = _berserker
	return brain
