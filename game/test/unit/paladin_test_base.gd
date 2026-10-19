class_name PaladinTestBase
extends GutTest
## Base dos testes do Paladino (test_paladin*.gd): cena, alvos e ticks. Sem testes proprios (o GUT
## so coleta arquivos test_*).

const PALADIN: String = "res://scenes/heroes/paladin.tscn"
const KNIGHT: String = "res://scenes/heroes/knight.tscn"
const BERSERKER: String = "res://scenes/heroes/berserker.tscn"
const RANGER: String = "res://scenes/heroes/ranger.tscn"
const GOLEM: String = "res://scenes/monsters/golem_t3.tscn"
const BOSS: String = "res://scenes/monsters/skeleton_king_boss.tscn"
const TICK: float = 1.0 / 30.0
const START: int = 100
const CASTER: int = 7
const VICTIM: int = 8
const EPS: float = 0.0001
## Frente do heroi sem rotacao: -Z.
const AHEAD: Vector3 = Vector3(0, 0, -1)
## Paladino e Cavaleiro no nivel 1 (GDB §4.9 e §4.1).
const PALADIN_HP: int = 620
const PALADIN_DEF: float = 28.0
const PALADIN_ATK: float = 38.0
const KNIGHT_HP: int = 600
const KNIGHT_DEF: float = 30.0
const GOLEM_HP: int = 680

var _paladin: Paladin
var _others: Array[Combatant] = []


func before_each() -> void:
	_others = []


func _spawn_paladin(level: int, at: Vector3 = Vector3.ZERO, id: int = CASTER) -> Paladin:
	var paladin := (load(PALADIN) as PackedScene).instantiate() as Paladin
	paladin.name = str(id)
	paladin.team = GateRules.TEAM_A
	paladin.level = level
	paladin.collision_mask = GateRules.hero_mask(GateRules.TEAM_A)
	paladin.transform = Transform3D(Basis(), at)
	add_child_autofree(paladin)
	if _paladin == null or id == CASTER:
		_paladin = paladin
	return paladin


## Heroi do time B em [param at], de frente para a origem (onde fica o Paladino).
func _spawn_enemy(path: String, at: Vector3, id: int = VICTIM) -> Hero:
	var hero := (load(path) as PackedScene).instantiate() as Hero
	hero.name = str(id)
	hero.team = GateRules.TEAM_B
	hero.collision_mask = GateRules.hero_mask(GateRules.TEAM_B)
	hero.transform = Transform3D(Basis(), at)
	add_child_autofree(hero)
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


## Um tick de todos: o Paladino age, depois os herois alvo aplicam o ledger do proprio tick.
func _run(from: int, count: int) -> void:
	for tick: int in range(from, from + count):
		_paladin._rollback_tick(TICK, tick, true)
		for other: Combatant in _others:
			if other is Hero:
				(other as Hero)._rollback_tick(TICK, tick, true)
		_paladin.input.attack = false
		_paladin.input.skill_q = false
		_paladin.input.skill_e = false
		_paladin.input.skill_r = false


## Golpe de [param effect] no ledger do Paladino no [param tick] (fonte = atacante + slot).
func _strike_paladin(tick: int, attacker: int, effect: HitEffect) -> void:
	effect.attacker_id = attacker
	_paladin.receive_hit(tick, HitLedger.source_key(attacker, HitLedger.Slot.BASIC), effect)


## Golpe direto bruto [param damage] de [param striker] (combat_id) vindo de [param from].
func _direct_hit(damage: int, from: Vector3, striker: int) -> HitEffect:
	var effect := HitEffect.new(damage, from)
	effect.striker_id = striker
	return effect


func _q_damage() -> int:
	return roundi(
		SkillRules.amount(_paladin.hero_data.skill_q, _paladin.ranks.x, _paladin.attributes)
	)


## Dano bruto que a Retribuicao devolve de um golpe bruto [param raw] no Paladino.
func _reflected(raw: int) -> int:
	var e := _paladin.hero_data.skill_e
	var taken := CombatRules.mitigated(raw, _paladin._defense())
	return PaladinRules.reflected_damage(
		taken,
		SkillData.at_rank(e.reflect_ratio, _paladin.ranks.y),
		_paladin.attributes.attack,
		e.attack_ratio
	)
