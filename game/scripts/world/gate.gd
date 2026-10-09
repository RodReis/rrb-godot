class_name Gate
extends StaticBody3D
## Portao de base: barra o time adversario por camada de colisao (GateRules) ate fall(),
## chamado no fim da fase 1 (MatchClock.phase1_ended, 5:00).

const GROUP: StringName = &"gates"

@export var team: int = GateRules.TEAM_A

@onready var _shape: CollisionShape3D = $Shape
@onready var _door: Node3D = $Door


func _ready() -> void:
	add_to_group(GROUP)
	collision_layer = GateRules.gate_layer(team)
	collision_mask = 0


func fall() -> void:
	_shape.disabled = true
	_door.hide()


func is_fallen() -> bool:
	return _shape.disabled
