class_name Player
extends CharacterBody3D
## Player autoritativo no servidor. O node se chama str(peer_id).

const MAX_HP: int = 600
const SPEED: float = 5.0
const DEFENSE: int = 30
const ATTACK_DAMAGE: int = 120
const ATTACK_RANGE: float = 2.0
const ATTACK_HALF_ANGLE_DEG: float = 60.0
const ATTACK_COOLDOWN_TICKS: int = 15  # 0,5 s a 30 Hz

var hp: int = MAX_HP
var attack_cooldown: int = 0
var peer_id: int = 0

var _rollback: RollbackSynchronizer
var _hits: HitLedger = HitLedger.new()  # so no servidor; fora do estado de rollback

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

func _rollback_tick(_delta: float, tick: int, _is_fresh: bool) -> void:
	if multiplayer.is_server() and not _hits.is_empty():
		_apply_hits(tick)

	# Input vem do cliente: nunca confiar no valor recebido.
	var aim := InputRules.sanitize_direction(input.aim)
	var movement := InputRules.sanitize_direction(input.movement)
	if not aim.is_zero_approx():
		look_at(global_position + aim, Vector3.UP)
	velocity = movement.normalized() * SPEED
	velocity *= NetworkTime.physics_factor
	move_and_slide()
	velocity /= NetworkTime.physics_factor

	if attack_cooldown > 0:
		attack_cooldown -= 1
	elif input.attack:
		attack_cooldown = ATTACK_COOLDOWN_TICKS
		_melee(tick)

func _process(_delta: float) -> void:
	hp_label.text = "%d / %d" % [hp, MAX_HP]

## Registra o golpe de [param attacker_id] para [param tick]. Servidor apenas.
func receive_hit(tick: int, attacker_id: int, damage: int) -> void:
	_hits.set_hit(tick, attacker_id, damage)

## Desfaz o golpe de [param attacker_id] em [param tick] (ressimulacao sem acerto).
func cancel_hit(tick: int, attacker_id: int) -> void:
	_hits.clear_hit(tick, attacker_id)

func _melee(tick: int) -> void:
	# Dano so no servidor: o cliente nunca altera HP (card #5); o HP chega pelo estado.
	if not multiplayer.is_server():
		return
	# O alvo aplica o golpe no proprio _rollback_tick de tick+1, lendo o registro;
	# assim ressimular o alvo (input dele atrasado) nao apaga o dano.
	var hit_tick := tick + 1
	var forward := -global_transform.basis.z
	for node: Node in get_tree().get_nodes_in_group("players"):
		var other := node as Player
		if other == self:
			continue
		if CombatRules.is_in_melee_arc(global_position, forward, other.global_position, ATTACK_RANGE, ATTACK_HALF_ANGLE_DEG):
			other.receive_hit(hit_tick, peer_id, ATTACK_DAMAGE)
			# Forca ressimular o alvo a partir de hit_tick se ele ja foi simulado.
			NetworkRollback.mutate(other, hit_tick)
		else:
			other.cancel_hit(hit_tick, peer_id)

func _apply_hits(tick: int) -> void:
	for damage: int in _hits.damages_at(tick):
		hp = CombatRules.apply_damage(hp, damage, DEFENSE)
		if hp == 0:
			hp = MAX_HP  # M0: sem morte, so reinicia o HP
	_hits.trim_before(tick - NetworkRollback.history_limit)
