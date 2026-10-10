class_name Fountain
extends Node3D
## Fonte de agua da base (PI 2026-10-10, #74): marca a area onde o heroi do time dono recupera
## vida na fase 1. Quem cura e o proprio Hero no _rollback_tick (FountainRules); aqui so o lugar,
## o time e o raio. Uma por base, no canto esquerdo (arena simetrica por rotacao de 180 graus).

const GROUP: StringName = &"fountains"

@export var rules: MatchRules
## GateRules.TEAM_* da base.
@export var team: int = GateRules.TEAM_NEUTRAL


func _ready() -> void:
	add_to_group(GROUP)


## [param point] dentro da area de cura e [param hero_team] e o dono.
func heals(point: Vector3, hero_team: int) -> bool:
	var area := CombatRules.in_radius(global_position, point, rules.fountain_radius)
	return hero_team == team and area
