class_name Player
extends CharacterBody3D
## Player autoritativo no servidor. O node se chama str(peer_id).

const MAX_HP: int = 600
const SPEED: float = 5.0

var hp: int = MAX_HP
var attack_cooldown: int = 0
var peer_id: int = 0

var _rollback: RollbackSynchronizer

@onready var input: PlayerInput = $Input
@onready var hp_label: Label3D = $HpLabel

func _ready() -> void:
	peer_id = name.to_int()
	add_to_group("players")
	set_multiplayer_authority(1)
	input.set_multiplayer_authority(peer_id)

	_rollback = RollbackSynchronizer.new()
	_rollback.name = "RollbackSynchronizer"
	_rollback.root = self
	_rollback.state_properties = [":transform", ":velocity", ":hp", ":attack_cooldown"]
	_rollback.input_properties = ["Input:movement", "Input:aim", "Input:attack"]
	_rollback.enable_input_broadcast = false
	add_child(_rollback)

	var interpolator := TickInterpolator.new()
	interpolator.name = "TickInterpolator"
	interpolator.root = self
	interpolator.properties = [":transform"]
	add_child(interpolator)

	_rollback.process_settings()

func _rollback_tick(_delta: float, _tick: int, _is_fresh: bool) -> void:
	# Input vem do cliente: nunca confiar no valor recebido.
	var aim := InputRules.sanitize_direction(input.aim)
	var movement := InputRules.sanitize_direction(input.movement)
	if not aim.is_zero_approx():
		look_at(global_position + aim, Vector3.UP)
	velocity = movement.normalized() * SPEED
	velocity *= NetworkTime.physics_factor
	move_and_slide()
	velocity /= NetworkTime.physics_factor

func _process(_delta: float) -> void:
	hp_label.text = "%d / %d" % [hp, MAX_HP]
