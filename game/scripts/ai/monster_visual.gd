extends Node
## Visual do monstro: animacao pelo estado replicado (velocidade, golpe, HP). So le estado.
## HP caindo fora de um golpe toca [member hit] (Lobo e Golem, F55), se o modelo tiver. Sem a
## animacao de morte, some ao morrer. HP de volta (respawn da fase 1, F36) reaparece parado. Fora
## do mapa (Monster.present falso, F20) some na hora, sem animacao de morte.

@export var model: Node3D
@export var idle: StringName = &"Idle"
@export var run: StringName = &"Running_A"
@export var attack: StringName = &"Unarmed_Melee_Attack_Punch_A"
@export var death: StringName = &"Death_A"
## Reacao ao dano; vazio = nenhuma.
@export var hit: StringName = &""
## Velocidade abaixo da qual o monstro esta parado (u/s).
@export var moving_speed: float = 0.1

var _monster: Monster
var _player: AnimationPlayer
var _one_shot: bool = false
var _dead: bool = false
var _last_cooldown: int = 0
var _last_hp: int = 0


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
	if not _monster.present:
		_dead = true
		model.hide()
		return
	if _dead:
		if _monster.is_alive():
			_revive()
		return
	if not _monster.is_alive():
		_die()
		return
	var started_attack := _monster.attack_cooldown > _last_cooldown
	_last_cooldown = _monster.attack_cooldown
	var took_hit := _monster.hp < _last_hp
	_last_hp = _monster.hp
	if _player == null:
		return
	if started_attack:
		_one_shot = true
		_player.play(attack)
	elif took_hit and not _one_shot and _player.has_animation(hit):
		_one_shot = true
		_player.play(hit)
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
	_last_hp = _monster.hp
	model.show()
	if _player != null:
		_player.play(idle)


func _loop(animation: StringName) -> void:
	if _player.current_animation != animation:
		_player.play(animation)


func _on_player_animation_finished(_animation: StringName) -> void:
	_one_shot = false
	if _dead:
		model.hide()
