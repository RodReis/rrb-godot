class_name HeroAttributes
extends RefCounted
## Atributos finais de um heroi (nivel + itens + conjuntos), calculados por Stats.attributes.

var max_hp: int = 0
var defense: float = 0.0
var attack: float = 0.0
var intelligence: float = 0.0
var agility: float = 0.0
## u/s.
var move_speed: float = 0.0
## Segundos entre ataques basicos.
var attack_interval: float = 0.0
## 0..30.
var cdr_percent: float = 0.0
## Fracao do dano absorvida pela DEF.
var mitigation: float = 0.0
