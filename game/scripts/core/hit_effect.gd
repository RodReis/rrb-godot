class_name HitEffect
extends RefCounted
## Efeito de um golpe sobre um heroi, aplicado pelo proprio alvo no _rollback_tick
## (ARCHITECTURE-GAME §3.2): dano bruto (antes da DEF), origem (para o escudo frontal),
## empurrao e atordoamento.

var damage: int = 0
var source: Vector3 = Vector3.ZERO
var push: Vector3 = Vector3.ZERO
var stun_ticks: int = 0


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
