class_name CarrascoTestBase
extends GutTest
## Base dos testes do Carrasco (test_carrasco*.gd): cena, alvos e ticks. Sem testes proprios (o GUT
## so coleta arquivos test_*).

const CARRASCO: String = "res://scenes/heroes/carrasco.tscn"
const KNIGHT: String = "res://scenes/heroes/knight.tscn"
const PALADIN: String = "res://scenes/heroes/paladin.tscn"
const BERSERKER: String = "res://scenes/heroes/berserker.tscn"
const GOLEM: String = "res://scenes/monsters/golem_t3.tscn"
const TICK: float = 1.0 / 30.0
const RATE: int = 30
const START: int = 100
const CASTER: int = 7
const VICTIM: int = 8
const EPS: float = 0.0001
## Frente do heroi sem rotacao: -Z.
const AHEAD: Vector3 = Vector3(0, 0, -1)
## Carrasco e Cavaleiro no nivel 1 (GDB §4.11 e §4.1).
const CARRASCO_HP: int = 600
const CARRASCO_DEF: float = 26.0
const CARRASCO_ATK: float = 42.0
const KNIGHT_HP: int = 600
const KNIGHT_DEF: float = 30.0
const GOLEM_HP: int = 680
const RESPAWN_SECONDS: float = 60.0

var _carrasco: Carrasco
var _others: Array[Combatant] = []


func before_each() -> void:
	_others = []
	_carrasco = null


## Carrasco do time A na origem, de frente para -Z. Com [param ranks], Q/E/R aprendidos assim.
func _spawn_carrasco(
	level: int = 1, ranks: Vector3i = Vector3i(-1, -1, -1), at: Vector3 = Vector3.ZERO
) -> Carrasco:
	var carrasco := (load(CARRASCO) as PackedScene).instantiate() as Carrasco
	carrasco.name = str(CASTER)
	carrasco.team = GateRules.TEAM_A
	carrasco.level = level
	carrasco.collision_mask = GateRules.hero_mask(GateRules.TEAM_A)
	carrasco.transform = Transform3D(Basis(), at)
	add_child_autofree(carrasco)
	if ranks.x >= 0:
		carrasco.ranks = ranks
	_carrasco = carrasco
	return carrasco


## Heroi do time B em [param at], de frente para a origem (onde fica o Carrasco).
func _spawn_enemy(path: String, at: Vector3, id: int = VICTIM, level: int = 1) -> Hero:
	var hero := (load(path) as PackedScene).instantiate() as Hero
	hero.name = str(id)
	hero.team = GateRules.TEAM_B
	hero.level = level
	hero.respawn_seconds = RESPAWN_SECONDS  # morto fica morto durante o teste
	hero.collision_mask = GateRules.hero_mask(GateRules.TEAM_B)
	hero.transform = Transform3D(Basis(), at)
	add_child_autofree(hero)
	NoRetaliation.mute(hero)
	if not at.is_zero_approx():
		hero.look_at(Vector3(0, at.y, 0), Vector3.UP)
	_others.append(hero)
	return hero


func _spawn_monster(path: String, uid: int, at: Vector3) -> Monster:
	var monster := (load(path) as PackedScene).instantiate() as Monster
	monster.uid = uid
	monster.transform = Transform3D(Basis(), at)
	add_child_autofree(monster)
	_others.append(monster)
	return monster


## Um tick de todos: o Carrasco age, depois os herois alvo aplicam o ledger do proprio tick. Os
## botoes do Carrasco soltam no fim de cada tick (o toque e um tick so).
func _run(from: int, count: int) -> void:
	for tick: int in range(from, from + count):
		_carrasco._rollback_tick(TICK, tick, true)
		for other: Combatant in _others:
			if other is Hero:
				(other as Hero)._rollback_tick(TICK, tick, true)
		_carrasco.input.attack = false
		_carrasco.input.skill_q = false
		_carrasco.input.skill_e = false
		_carrasco.input.skill_r = false


## Golpe de [param effect] no ledger do Carrasco no [param tick], vindo de [param attacker] no
## [param slot] (basico de heroi marca hero_basic, como Hero._hit).
func _strike_carrasco(
	tick: int, attacker: int, effect: HitEffect, slot: HitLedger.Slot = HitLedger.Slot.BASIC
) -> void:
	effect.attacker_id = attacker
	effect.hero_basic = slot == HitLedger.Slot.BASIC
	_carrasco.receive_hit(tick, HitLedger.source_key(attacker, slot), effect)


func _amount(skill: SkillData, rank: int) -> int:
	return roundi(SkillRules.amount(skill, rank, _carrasco.attributes))
