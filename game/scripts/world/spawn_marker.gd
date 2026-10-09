class_name SpawnMarker
extends Marker3D
## Ponto de spawn da arena (SPEC-007 §4). Quem spawna (heroi, monstro, bau, boss) so le
## marcadores; nenhuma posicao em codigo.

enum Kind { HERO, MONSTER, CHEST, BOSS }
enum ChestKind { COMMON, RARE }

const GROUP: StringName = &"spawn_markers"

@export var kind: Kind
## GateRules.TEAM_NEUTRAL, TEAM_A ou TEAM_B (dono da zona).
@export var team: int
## Tier do GDB §5.1 (1, 2, 3); 0 para heroi, bau e boss.
@export var tier: int
@export var monster_id: StringName
@export var chest_kind: ChestKind


func _enter_tree() -> void:
	add_to_group(GROUP)
