class_name EngineerTestBase
extends GutTest
## Base dos testes do Engenheiro (test_engineer*.gd): cena, alvos, moita, paredes e ticks. Sem
## testes proprios (o GUT so coleta arquivos test_*).

const ENGINEER: String = "res://scenes/heroes/engineer.tscn"
const KNIGHT: String = "res://scenes/heroes/knight.tscn"
const ROGUE: String = "res://scenes/heroes/rogue.tscn"
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
const KNIGHT_HP: int = 600
const KNIGHT_DEF: float = 30.0
const GOLEM_HP: int = 680
## 6,0 s, 1,5 s e 0,3 s a 30 ticks/s.
const TURRET_TICKS: int = 180
const FUSE_TICKS: int = 45
const PULL_TICKS: int = 9

var _eng: Engineer
var _others: Array[Combatant] = []
var _shots: int = 0


func before_each() -> void:
	_others = []
	_shots = 0


func _spawn_engineer(level: int, at: Vector3 = Vector3.ZERO) -> Engineer:
	_eng = (load(ENGINEER) as PackedScene).instantiate() as Engineer
	_eng.name = str(CASTER)
	_eng.team = GateRules.TEAM_A
	_eng.level = level
	_eng.collision_mask = GateRules.hero_mask(GateRules.TEAM_A)
	_eng.transform = Transform3D(Basis(), at)
	add_child_autofree(_eng)
	_eng.turret_fired.connect(func(_from: Vector3, _at: Vector3, _tick: int) -> void: _shots += 1)
	return _eng


func _spawn_knight(at: Vector3, id: int = VICTIM) -> Knight:
	var knight := (load(KNIGHT) as PackedScene).instantiate() as Knight
	knight.name = str(id)
	knight.team = GateRules.TEAM_B
	knight.collision_mask = GateRules.hero_mask(GateRules.TEAM_B)
	knight.transform = Transform3D(Basis(), at)
	add_child_autofree(knight)
	_others.append(knight)
	return knight


func _spawn_rogue(at: Vector3, id: int = VICTIM) -> Rogue:
	var rogue := (load(ROGUE) as PackedScene).instantiate() as Rogue
	rogue.name = str(id)
	rogue.team = GateRules.TEAM_B
	rogue.level = 2
	rogue.collision_mask = GateRules.hero_mask(GateRules.TEAM_B)
	rogue.transform = Transform3D(Basis(), at)
	add_child_autofree(rogue)
	_others.append(rogue)
	return rogue


func _spawn_monster(path: String, uid: int, at: Vector3) -> Monster:
	var monster := (load(path) as PackedScene).instantiate() as Monster
	monster.uid = uid
	monster.transform = Transform3D(Basis(), at)
	add_child_autofree(monster)
	_others.append(monster)
	return monster


## Moita de [param size] em [param at] (grupo tall_grass); antes dos herois, que a leem no _ready.
func _grass_at(at: Vector3, size: Vector3) -> void:
	var area := Area3D.new()
	area.add_to_group(VisibilityRules.GROUP)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	area.add_child(shape)
	area.position = at
	add_child_autofree(area)


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


## Um tick de todos: o Engenheiro age e os herois alvo aplicam o ledger do proprio tick.
func _run(from: int, count: int) -> void:
	for tick: int in range(from, from + count):
		_eng._rollback_tick(TICK, tick, true)
		for other: Combatant in _others:
			if other is Hero:
				(other as Hero)._rollback_tick(TICK, tick, true)
		_eng.input.attack = false
		_eng.input.skill_q = false
		_eng.input.skill_e = false
		_eng.input.skill_r = false


func _q_damage() -> int:
	return roundi(SkillRules.amount(_eng.hero_data.skill_q, _eng.ranks.x, _eng.attributes))


func _turret_damage() -> int:
	return roundi(SkillRules.amount(_eng.hero_data.skill_e, _eng.ranks.y, _eng.attributes))


func _dynamite_damage() -> int:
	return roundi(SkillRules.amount(_eng.hero_data.skill_r, _eng.ranks.z, _eng.attributes))


func _bot_brain(level: int = 6) -> BotInput:
	_eng = (load(ENGINEER) as PackedScene).instantiate() as Engineer
	_eng.name = str(CASTER)
	_eng.team = GateRules.TEAM_B
	_eng.level = level
	_eng.is_bot = true
	_eng.get_node("Input").set_script(BotInput)
	add_child_autofree(_eng)
	var brain := _eng.input as BotInput
	brain._hero = _eng
	return brain
