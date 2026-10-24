class_name DruidTestBase
extends GutTest
## Base dos testes do Protetor da Selva (test_druid*.gd): cena, alvos, paredes e ticks. Sem testes
## proprios (o GUT so coleta arquivos test_*).

const DRUID: String = "res://scenes/heroes/druid.tscn"
const KNIGHT: String = "res://scenes/heroes/knight.tscn"
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
const KNIGHT_HP: int = 620
const KNIGHT_DEF: float = 30.0
const GOLEM_HP: int = 680
## 1,0 s, 3,0 s e 6,0 s a 30 ticks/s.
const ROOT_TICKS: int = 30
const POTION_TICKS: int = 90
const SWAMP_TICKS: int = 180

var _druid: Druid
var _others: Array[Combatant] = []
var _zones: Array = []


func before_each() -> void:
	_others = []
	_zones = []


func _spawn_druid(level: int, at: Vector3 = Vector3.ZERO) -> Druid:
	_druid = (load(DRUID) as PackedScene).instantiate() as Druid
	_druid.name = str(CASTER)
	_druid.team = GateRules.TEAM_A
	_druid.level = level
	_druid.collision_mask = GateRules.hero_mask(GateRules.TEAM_A)
	_druid.transform = Transform3D(Basis(), at)
	add_child_autofree(_druid)
	_druid.zone_started.connect(
		func(kind: Druid.Zone, center: Vector3, _tick: int) -> void: _zones.append([kind, center])
	)
	return _druid


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


## Um tick de todos: o Protetor age e os herois alvo aplicam o ledger do proprio tick.
func _run(from: int, count: int) -> void:
	for tick: int in range(from, from + count):
		_druid._rollback_tick(TICK, tick, true)
		for other: Combatant in _others:
			if other is Hero:
				(other as Hero)._rollback_tick(TICK, tick, true)
		_druid.input.attack = false
		_druid.input.skill_q = false
		_druid.input.skill_e = false
		_druid.input.skill_r = false


func _basic_damage() -> int:
	return roundi(SkillRules.amount(_druid.hero_data.basic_attack, 1, _druid.attributes))


func _q_damage() -> int:
	return roundi(SkillRules.amount(_druid.hero_data.skill_q, _druid.ranks.x, _druid.attributes))


func _potion_total() -> int:
	return roundi(SkillRules.amount(_druid.hero_data.skill_e, _druid.ranks.y, _druid.attributes))


func _swamp_damage() -> int:
	return roundi(SkillRules.amount(_druid.hero_data.skill_r, _druid.ranks.z, _druid.attributes))


func _bot_brain(level: int = 6) -> BotInput:
	_druid = (load(DRUID) as PackedScene).instantiate() as Druid
	_druid.name = str(CASTER)
	_druid.team = GateRules.TEAM_B
	_druid.level = level
	_druid.is_bot = true
	_druid.get_node("Input").set_script(BotInput)
	add_child_autofree(_druid)
	var brain := _druid.input as BotInput
	brain._hero = _druid
	return brain
