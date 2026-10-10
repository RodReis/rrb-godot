class_name SetBonusData
extends Resource
## Bonus de conjunto completo (GDB §6.1). Percentuais em fracao (0.15 = +15 %).

@export var set_id: StringName
## Nome na UI (GDB §6.1).
@export var display_name: String
@export var pieces_required: int
@export var max_hp_pct: float
@export var defense: float
@export var attack_speed_pct: float
@export var move_speed_pct: float
