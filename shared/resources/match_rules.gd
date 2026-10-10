class_name MatchRules
extends Resource
## Ritmo da partida 1v1: espera, selecao, tempos, respawn, XP de abate, zona e baus (GDB §3.3,
## §5, §6.2, §7; CONVENTION §3). Tempos em segundos; percentuais em fracao.

## Espera do 2o jogador (LOBBY_WAIT); expirou = partida abandoned (ARCHITECTURE-GAME §3.7).
@export var lobby_wait_timeout: float
## Duracao da selecao de herois (HERO_PICK).
@export var hero_pick_duration: float
## Heroi de quem nao confirma a tempo, por slot (P1, P2) — R-PEND-04.
@export var default_heroes: Array[StringName]

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
## Fonte da base (PI 2026-10-10, #74): cura por segundo (fracao do HP max), so na fase 1, so o
## time dono, dentro do raio (u); tomar dano pausa a cura por fountain_damage_pause (s).
@export var fountain_heal_pct: float
@export var fountain_radius: float
@export var fountain_damage_pause: float
