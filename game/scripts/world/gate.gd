class_name Gate
extends StaticBody3D
## Portao de base: barra o time adversario por camada de colisao (GateRules) ate fall(),
## chamado no fim da fase 1 (MatchClock.phase1_ended, 5:00).

const GROUP: StringName = &"gates"
## Igual a Hero.GROUP (o teste confere); nao referencia Hero para o builder e as ferramentas -s
## compilarem a cena sem os autoloads do netfox.
const HEROES_GROUP: StringName = &"heroes"

@export var team: int = GateRules.TEAM_A

var _open: float = 0.0

@onready var _shape: CollisionShape3D = $Shape
@onready var _door: Node3D = $Door
@onready var _leaf_left: Node3D = $Door/LeafL
@onready var _leaf_right: Node3D = $Door/LeafR


func _ready() -> void:
	add_to_group(GROUP)
	collision_layer = GateRules.gate_layer(team)
	collision_mask = 0
	# So visual: o servidor dedicado nao anima a porta.
	set_process(DisplayServer.get_name() != "headless")


func _process(delta: float) -> void:
	update_door(delta)


## Abre as folhas para dentro da base enquanto houver heroi do time dono perto e fecha quando sai.
## Colisao e GateRules.can_pass nao mudam (o adversario ve a porta abrir e segue barrado).
func update_door(delta: float) -> void:
	if is_fallen():
		return
	var next := GateRules.door_open_amount(_open, _hero_near(), delta)
	if next == _open:
		return
	_open = next
	var angle := deg_to_rad(GateRules.DOOR_OPEN_DEG) * smoothstep(0.0, 1.0, _open)
	_leaf_left.rotation.y = angle
	_leaf_right.rotation.y = -angle


func fall() -> void:
	_shape.disabled = true
	_door.hide()


func is_fallen() -> bool:
	return _shape.disabled


func _hero_near() -> bool:
	for node: Node in get_tree().get_nodes_in_group(HEROES_GROUP):
		var hero := node as Combatant
		var offset := hero.global_position - global_position
		if GateRules.door_wants_open(team, hero.team, Vector2(offset.x, offset.z).length()):
			return true
	return false
