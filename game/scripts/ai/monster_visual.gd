extends Node
## Visual do monstro: animacao pelo estado replicado (velocidade, golpe, HP). So le estado.
## Modelo sem AnimationPlayer (Golem): pisao no golpe e some ao morrer. HP de volta (respawn da
## fase 1, F36) reaparece parado.

@export var model: Node3D
@export var idle: StringName = &"Idle"
@export var run: StringName = &"Running_A"
@export var attack: StringName = &"Unarmed_Melee_Attack_Punch_A"
@export var death: StringName = &"Death_A"
## Velocidade abaixo da qual o monstro esta parado (u/s).
@export var moving_speed: float = 0.1
## Pisao do modelo sem animacao (u, s).
@export var stomp_height: float = 0.3
@export var stomp_time: float = 0.25

var _monster: Monster
var _player: AnimationPlayer
var _one_shot: bool = false
var _dead: bool = false
var _last_cooldown: int = 0


func _ready() -> void:
	_monster = get_parent() as Monster
	_player = model.find_child("AnimationPlayer") as AnimationPlayer
	if _player == null:
		return
	for looping: StringName in [idle, run]:
		if _player.has_animation(looping):
			_player.get_animation(looping).loop_mode = Animation.LOOP_LINEAR
	_player.animation_finished.connect(_on_player_animation_finished)


func _process(_delta: float) -> void:
	if _dead:
		if _monster.is_alive():
			_revive()
		return
	if not _monster.is_alive():
		_die()
		return
	var started_attack := _monster.attack_cooldown > _last_cooldown
	_last_cooldown = _monster.attack_cooldown
	if _player == null:
		if started_attack:
			_stomp()
		return
	if started_attack:
		_one_shot = true
		_player.play(attack)
	elif _one_shot:
		return
	elif _monster.velocity.length() > moving_speed:
		_loop(run)
	else:
		_loop(idle)


func _die() -> void:
	_dead = true
	if _player == null or not _player.has_animation(death):
		model.hide()
		return
	_player.play(death)


func _revive() -> void:
	_dead = false
	_one_shot = false
	_last_cooldown = _monster.attack_cooldown
	model.show()
	if _player != null:
		_player.play(idle)


## Golpe de modelo sem animacao (Golem): sobe e bate no chao.
func _stomp() -> void:
	var tween := create_tween()
	tween.tween_property(model, "position:y", stomp_height, stomp_time / 2.0)
	tween.tween_property(model, "position:y", 0.0, stomp_time / 2.0)


func _loop(animation: StringName) -> void:
	if _player.current_animation != animation:
		_player.play(animation)


func _on_player_animation_finished(_animation: StringName) -> void:
	_one_shot = false
	if _dead:
		model.hide()
