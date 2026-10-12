class_name FireWizardTestBase
extends GutTest
## Base dos testes do Bruxo de Fogo (test_fire_wizard*.gd): cena, alvos, paredes e ticks.
## Sem testes proprios (o GUT so coleta arquivos test_*).

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
