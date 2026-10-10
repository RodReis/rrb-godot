class_name HitEffect
extends RefCounted
## Efeito de um golpe sobre um heroi, aplicado pelo proprio alvo no _rollback_tick
## (ARCHITECTURE-GAME §3.2): dano bruto (antes da DEF), origem (para o escudo frontal),
## empurrao, atordoamento e XP (recompensa de abate, GDB §3.3/§5.1). attacker_id = peer_id do
## heroi que golpeou (o monstro morto da o XP a ele). Saque de bau (GDB §6.2): cura e item a
## equipar (numero de Ids). Lentidao (R da Arqueira, F14): fracao e ticks. Zona (F16):
## true_damage ignora DEF e Muralha.

var damage: int = 0
var source: Vector3 = Vector3.ZERO
var push: Vector3 = Vector3.ZERO
var stun_ticks: int = 0
var xp: int = 0
var attacker_id: int = 0
var heal: int = 0
var item: int = Ids.NONE
var slow: float = 0.0
var slow_ticks: int = 0
var true_damage: int = 0


func _init(
	p_damage: int = 0,
	p_source: Vector3 = Vector3.ZERO,
	p_push: Vector3 = Vector3.ZERO,
	p_stun_ticks: int = 0
) -> void:
	damage = p_damage
	source = p_source
	push = p_push
	stun_ticks = p_stun_ticks
