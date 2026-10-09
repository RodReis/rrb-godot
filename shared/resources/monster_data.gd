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
## Raio do golpe em area em volta do monstro (u), quando area_attack.
@export var area_radius: float
## Alcance do golpe corpo a corpo (u).
@export var melee_range: float
## Distancia em que o monstro parado percebe o heroi (u).
@export var aggro_range: float
## Distancia maxima do ponto de spawn; passou, volta e regenera o HP (u).
@export var leash_range: float
@export var move_speed: float
@export var knockback: bool
@export var xp: int
@export var drop_common_chance: float
@export var drop_rare_chance: float
@export var drop_epic_chance: float
