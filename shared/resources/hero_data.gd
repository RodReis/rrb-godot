class_name HeroData
extends Resource
## Heroi jogavel: atributos no nivel 1, ganho por nivel e habilidades (GDB §4).

@export var id: StringName
@export var display_name: String
@export var base_move_speed: float
@export var base_hp: float
@export var hp_per_level: float
@export var base_defense: float
@export var defense_per_level: float
@export var base_attack: float
@export var attack_per_level: float
@export var base_intelligence: float
@export var intelligence_per_level: float
@export var base_agility: float
@export var agility_per_level: float
@export var basic_attack: SkillData
@export var skill_q: SkillData
@export var skill_e: SkillData
@export var skill_r: SkillData
