extends Node
## Visual do heroi: esconde as pecas do pack que o heroi nao usa e escolhe a animacao pelo
## estado do Hero (replicado/previsto). So le estado; nunca o altera. Morto: cai uma vez e fica.

@export var model: Node3D
@export var hidden_parts: Array[StringName] = []
@export var idle: StringName = &"Idle"
@export var run: StringName = &"Running_A"
@export var dash: StringName = &"Running_B"
@export var block: StringName = &"Blocking"
@export var stunned: StringName = &"Hit_B"
@export var basic_attack: StringName = &"1H_Melee_Attack_Slice_Horizontal"
## Vazio = o Q nao tem animacao propria (Investida usa a de avanco).
@export var skill_q: StringName = &""
@export var skill_r: StringName = &"1H_Melee_Attack_Chop"
@export var death: StringName = &"Death_A"
## Velocidade abaixo da qual o heroi esta parado (u/s).
@export var moving_speed: float = 0.1

var _hero: Hero
var _player: AnimationPlayer
var _one_shot: bool = false
var _last_basic: int = 0
var _last_q: int = 0
var _last_r: int = 0
var _fallen: bool = false


func _ready() -> void:
	_hero = get_parent() as Hero
	for part: StringName in hidden_parts:
		var node := model.find_child(part) as Node3D
		if node:
			node.hide()
	_player = model.find_child("AnimationPlayer") as AnimationPlayer
	for looping: StringName in [idle, run, dash, block]:
		if _player.has_animation(looping):
			_player.get_animation(looping).loop_mode = Animation.LOOP_LINEAR
	_player.animation_finished.connect(_on_player_animation_finished)


func _process(_delta: float) -> void:
	if not _hero.is_alive():
		if not _fallen:
			_fallen = true
			_once(death)
		return
	_fallen = false
	var started_basic := _hero.basic_cooldown > _last_basic
	var started_r := _hero.r_cooldown > _last_r
	var started_q := _hero.q_cooldown > _last_q and skill_q != &""
	_last_basic = _hero.basic_cooldown
	_last_q = _hero.q_cooldown
	_last_r = _hero.r_cooldown
	if _hero.stun_ticks > 0:
		_loop(stunned)
	elif _hero.dash_ticks > 0:
		_loop(dash)
	elif started_r:
		_once(skill_r)
	elif started_q:
		_once(skill_q)
	elif started_basic:
		_once(basic_attack)
	elif _one_shot:
		return
	elif _hero.shield_ticks > 0:
		_loop(block)
	elif _hero.velocity.length() > moving_speed:
		_loop(run)
	else:
		_loop(idle)


func _loop(animation: StringName) -> void:
	_one_shot = false
	if _player.current_animation != animation:
		_player.play(animation)


func _once(animation: StringName) -> void:
	_one_shot = true
	_player.play(animation)


func _on_player_animation_finished(_animation: StringName) -> void:
	_one_shot = false
