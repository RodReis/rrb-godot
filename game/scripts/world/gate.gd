class_name Gate
extends StaticBody3D
## Portao de base: barra o time adversario por camada de colisao (GateRules) ate fall(),
## chamado no gates_fallen (5:00).

@export var team: int = GateRules.TEAM_A

@onready var _shape: CollisionShape3D = $Shape
@onready var _door: Node3D = $Door


func _ready() -> void:
	collision_layer = GateRules.gate_layer(team)
	collision_mask = 0


func fall() -> void:
	_shape.disabled = true
	_door.hide()


func is_fallen() -> bool:
	return _shape.disabled
