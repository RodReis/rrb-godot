class_name MatchRules
extends Resource
## Ritmo da partida 1v1: tempos, respawn, XP de abate, zona e baus (GDB §3.3, §5, §6.2, §7).
## Tempos em segundos; percentuais em fracao.

@export var phase1_duration: float
@export var max_match_duration: float
@export var boss_warning_time: float
@export var boss_spawn_time: float
@export var respawn_phase1: float
@export var respawn_phase2: float
@export var phase1_kill_xp: int
@export var phase2_kill_xp_base: int
@export var phase2_kill_xp_per_level: int
@export var kill_goal: int
## Tempo na fase 2 em que o respawn desliga (morte subita).
@export var respawn_off_at: float
## Degraus da zona, alinhados: tempo na fase 2, raio (u) e dano fora (fracao do HP max/s).
@export var zone_times: PackedFloat64Array
@export var zone_radius: PackedFloat64Array
@export var zone_damage_pct: PackedFloat64Array
## No colapso final o dano dobra a cada este intervalo.
@export var zone_collapse_doubling: float
@export var common_chests_per_base: int
@export var rare_chests: int
@export var common_chest_item_chance: float
@export var common_chest_heal_chance: float
@export var rare_chest_rare_chance: float
@export var rare_chest_common_chance: float
@export var rare_chest_epic_chance: float
@export var heal_amount: float
## Tempo segurando F para confirmar troca de item.
@export var swap_hold_time: float
## Distancia maxima (u) do heroi ao bau para abrir com F ou trocar o item.
@export var chest_interact_range: float
