class_name ServantData
extends Resource
## Servo do Vazio (R do Ocultista, GDB §4.10, F78): numeros do servo invocado. A duracao e a
## recarga da invocacao ficam no skill_r do occultist.tres. Campos "por rank" como no SkillData
## (indice rank - 1; o ultimo vale para os ranks seguintes).

@export var display_name: String
## HP por rank do R, mais hp_intelligence_ratio * INT do Ocultista na invocacao.
@export var base_hp: PackedFloat64Array
@export var hp_intelligence_ratio: float
@export var defense: float
## u/s.
@export var move_speed: float
## Golpe corpo a corpo: alcance (u, centro a centro no plano) e intervalo (s).
@export var attack_reach: float
@export var attack_interval: float
## Dano por rank do R, mais damage_intelligence_ratio * INT do Ocultista na invocacao.
@export var base_damage: PackedFloat64Array
@export var damage_intelligence_ratio: float
## Escolha do alvo: alcance (u, a partir do servo) e intervalo da reavaliacao (s).
@export var target_reach: float
@export var retarget_interval: float
## Onde cada servo nasce: ahead_offset a frente do Ocultista e side_offset para cada lado (u); e ate
## onde chega perto dele quando o segue sem alvo (u).
@export var ahead_offset: float
@export var side_offset: float
@export var follow_distance: float
