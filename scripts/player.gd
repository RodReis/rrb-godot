extends CharacterBody2D
## Movimento de plataforma basico: andar, pular, gravidade.
## Coyote time e jump buffer deixam o pulo menos "duro".

@export var speed: float = 260.0
@export var acceleration: float = 2200.0
@export var friction: float = 2600.0
@export var jump_velocity: float = -520.0
@export var coyote_time: float = 0.1
@export var jump_buffer_time: float = 0.12

var _gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0


func _physics_process(delta: float) -> void:
	if is_on_floor():
		_coyote_timer = coyote_time
	else:
		_coyote_timer -= delta
		velocity.y += _gravity * delta

	if Input.is_action_just_pressed("jump"):
		_jump_buffer_timer = jump_buffer_time
	else:
		_jump_buffer_timer -= delta

	if _jump_buffer_timer > 0.0 and _coyote_timer > 0.0:
		velocity.y = jump_velocity
		_jump_buffer_timer = 0.0
		_coyote_timer = 0.0

	# Pulo variavel: soltar o botao corta a subida.
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= 0.5

	var direction := Input.get_axis("move_left", "move_right")
	if direction != 0.0:
		velocity.x = move_toward(velocity.x, direction * speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)

	move_and_slide()
