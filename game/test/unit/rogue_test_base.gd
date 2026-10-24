class_name RogueTestBase
extends GutTest
## Base dos testes da Ladina (test_rogue*.gd): cena, alvos, moita, paredes e ticks. Sem testes
## proprios (o GUT so coleta arquivos test_*).

const ROGUE: String = "res://scenes/heroes/rogue.tscn"
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

var _rogue: Rogue
var _others: Array[Combatant] = []


func before_each() -> void:
	_others = []


func _spawn_rogue(level: int, at: Vector3 = Vector3.ZERO) -> Rogue:
	_rogue = (load(ROGUE) as PackedScene).instantiate() as Rogue
	_rogue.name = str(CASTER)
	_rogue.team = GateRules.TEAM_A
	_rogue.level = level
	_rogue.collision_mask = GateRules.hero_mask(GateRules.TEAM_A)
	_rogue.transform = Transform3D(Basis(), at)
	add_child_autofree(_rogue)
	return _rogue


func _spawn_knight(at: Vector3, id: int = VICTIM) -> Knight:
	var knight := (load(KNIGHT) as PackedScene).instantiate() as Knight
	knight.name = str(id)
	knight.team = GateRules.TEAM_B
	knight.collision_mask = GateRules.hero_mask(GateRules.TEAM_B)
	knight.transform = Transform3D(Basis(), at)
	add_child_autofree(knight)
	NoRetaliation.mute(knight)
	_others.append(knight)
	return knight


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


## Um tick de todos: a Ladina age e os herois alvo aplicam o ledger do proprio tick.
func _run(from: int, count: int) -> void:
	for tick: int in range(from, from + count):
		_rogue._rollback_tick(TICK, tick, true)
		for other: Combatant in _others:
			if other is Hero:
				(other as Hero)._rollback_tick(TICK, tick, true)
		_rogue.input.attack = false
		_rogue.input.skill_q = false
		_rogue.input.skill_e = false
		_rogue.input.skill_r = false


func _active_bolts() -> int:
	var count := 0
	for node: Node in _rogue.get_node("Arrows").get_children():
		count += 1 if (node as Arrow).is_active() else 0
	return count


func _q_damage() -> int:
	return roundi(SkillRules.amount(_rogue.hero_data.skill_q, _rogue.ranks.x, _rogue.attributes))


func _r_amount() -> float:
	return SkillRules.amount(_rogue.hero_data.skill_r, _rogue.ranks.z, _rogue.attributes)


func _bot_brain(level: int = 6) -> BotInput:
	_rogue = (load(ROGUE) as PackedScene).instantiate() as Rogue
	_rogue.name = str(CASTER)
	_rogue.team = GateRules.TEAM_B
	_rogue.level = level
	_rogue.is_bot = true
	_rogue.get_node("Input").set_script(BotInput)
	add_child_autofree(_rogue)
	var brain := _rogue.input as BotInput
	brain._hero = _rogue
	return brain
