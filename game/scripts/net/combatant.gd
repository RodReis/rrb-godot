class_name Combatant
extends CharacterBody3D
## Quem pode ser golpeado (heroi ou monstro). O atacante so registra o efeito; o alvo o
## aplica (ARCHITECTURE-GAME §3.2). Monstro tem time neutro: e alvo de qualquer heroi.

const TARGETS_GROUP: StringName = &"combatants"

## GateRules.TEAM_*; definido por quem spawna.
var team: int = GateRules.TEAM_NEUTRAL

var _body_radius: float = -1.0


func _enter_tree() -> void:
	add_to_group(TARGETS_GROUP)


## Registra o efeito da [param source] para [param tick]. Servidor apenas.
func receive_hit(_tick: int, _source: int, _effect: HitEffect) -> void:
	pass


## Desfaz o efeito da [param source] em [param tick] (ressimulacao sem acerto).
func cancel_hit(_tick: int, _source: int) -> void:
	pass


func is_alive() -> bool:
	return true


## Id unico de quem e golpeado (peer_id do heroi, uid negativo do monstro).
func combat_id() -> int:
	return 0


## Raio da capsula do corpo (CollisionShape3D), para o acerto de projetil (F14).
func body_radius() -> float:
	if _body_radius < 0.0:
		var body := get_node_or_null("CollisionShape3D") as CollisionShape3D
		var capsule := body.shape as CapsuleShape3D if body != null else null
		_body_radius = capsule.radius if capsule != null else 0.0
	return _body_radius
