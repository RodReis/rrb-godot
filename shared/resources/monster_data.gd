class_name MonsterData
extends Resource
## Monstro neutro da fase 1 (GDB §5.1). Nao respawna. Chances de drop em fracao.

enum Tier { T1, T2, T3, BOSS }

@export var id: StringName
@export var display_name: String
@export var tier: Tier
## Quantidade por partida (todas as bases e o centro somados).
@export var count: int
@export var hp: float
@export var damage: float
@export var attack_interval: float
## Alcance de ataque a distancia (u); 0 = corpo a corpo.
@export var ranged_range: float
@export var area_attack: bool
@export var knockback: bool
@export var xp: int
@export var drop_common_chance: float
@export var drop_rare_chance: float
@export var drop_epic_chance: float
