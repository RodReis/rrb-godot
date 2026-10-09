class_name Combatant
extends CharacterBody3D
## Quem pode ser golpeado (heroi ou monstro). O atacante so registra o efeito; o alvo o
## aplica (ARCHITECTURE-GAME §3.2). Monstro tem time neutro: e alvo de qualquer heroi.

const TARGETS_GROUP: StringName = &"combatants"

## GateRules.TEAM_*; definido por quem spawna.
var team: int = GateRules.TEAM_NEUTRAL


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
