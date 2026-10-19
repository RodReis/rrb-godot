extends Node
## Visual do Servo do Vazio (F78): animacao procedural pelo estado replicado, sem esqueleto. Parado
## flutua devagar; andando, balanca e inclina para a frente; no golpe (attack_cooldown sobe) as duas
## garras descem juntas; morto (HP 0) encolhe e some; invocado (HP de volta) reaparece inteiro.
## Pecas do modelo (art/heroes/build_void_servant.py): Body, ArmL, ArmR, Eyes.

@export var model: Node3D
## Velocidade abaixo da qual o servo esta parado (u/s).
@export var moving_speed: float = 0.1
## Amplitude (u) e frequencia (Hz) do flutuar; o andar balanca mais rapido.
@export var bob_height: float = 0.06
@export var idle_hz: float = 0.8
@export var walk_hz: float = 2.6
## Inclinacao andando e giro das garras no golpe (graus); duracao do golpe e da morte (s).
@export var lean_degrees: float = 12.0
@export var strike_degrees: float = 75.0
@export var strike_time: float = 0.3
@export var death_time: float = 0.4

var _servant: VoidServant
var _parts: Array[Node3D] = []
var _rests: Array[Transform3D] = []
var _arms: Array[Node3D] = []
## Transform da cena do Model (giro de 180 graus): a morte escala por cima dele.
var _model_rest: Transform3D = Transform3D.IDENTITY
var _time: float = 0.0
var _strike_left: float = 0.0
var _death_left: float = 0.0
var _last_cooldown: int = 0
var _was_alive: bool = false


func _ready() -> void:
	_servant = get_parent() as VoidServant
	_model_rest = model.transform
	for part: StringName in [&"Body", &"Eyes", &"ArmL", &"ArmR"]:
		var node := model.find_child(part) as Node3D
		if node != null:
			_parts.append(node)
			_rests.append(node.transform)
			if part.begins_with("Arm"):
				_arms.append(node)
	model.hide()


func _process(delta: float) -> void:
	var alive := _servant.is_alive()
	if alive != _was_alive:
		_was_alive = alive
		_death_left = 0.0 if alive else death_time
		_strike_left = 0.0
		_last_cooldown = _servant.attack_cooldown
		model.transform = _model_rest
		if alive:
			model.show()  # morrendo segue a mostra ate encolher
	if not alive:
		_dying(delta)
		return
	if _servant.attack_cooldown > _last_cooldown:
		_strike_left = strike_time
	_last_cooldown = _servant.attack_cooldown
	_strike_left = maxf(_strike_left - delta, 0.0)
	_time += delta
	var moving := _servant.velocity.length() > moving_speed
	var hz := walk_hz if moving else idle_hz
	var bob := Vector3.UP * bob_height * sin(_time * TAU * hz)
	var lean := Basis(Vector3.RIGHT, deg_to_rad(-lean_degrees if moving else 0.0))
	var strike := sin(PI * (1.0 - _strike_left / strike_time)) if _strike_left > 0.0 else 0.0
	var claw := Basis(Vector3.RIGHT, deg_to_rad(-strike_degrees * strike))
	for i: int in _parts.size():
		var rest := _rests[i]
		var part := _parts[i]
		var turn := lean * (claw if _arms.has(part) else Basis.IDENTITY)
		part.transform = Transform3D(turn * rest.basis, turn * rest.origin + bob)


func _dying(delta: float) -> void:
	if _death_left <= 0.0:
		model.hide()
		return
	_death_left = maxf(_death_left - delta, 0.0)
	var shrink := maxf(_death_left / death_time, 0.01)
	model.transform = Transform3D(
		_model_rest.basis.scaled(Vector3.ONE * shrink), _model_rest.origin
	)
