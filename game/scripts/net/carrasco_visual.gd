class_name CarrascoVisual
extends HeroVisual
## Visual do Carrasco (F98, SPEC-098 §4): o golpe dos Espinhos, o arremesso do recast e a explosao da
## Penitencia saem dos contadores do estado (Carrasco.q_casts, recasts, blasts), porque a recarga do Q
## so sobe no recast. A canalizacao usa o laco `channel`; o resto e o HeroVisual. So le estado.

## Golpe em arco dos Espinhos, o arremesso do recast e a explosao da Penitencia, com as velocidades.
@export var thorns: StringName = &""
@export var thorns_speed: float = 1.0
@export var recast: StringName = &""
@export var recast_speed: float = 1.0
@export var blast: StringName = &""
@export var blast_speed: float = 1.0

var _last_casts: int = 0
var _last_recasts: int = 0
var _last_blasts: int = 0


func _process(delta: float) -> void:
	var carrasco := _hero as Carrasco
	var cast := carrasco.q_casts != _last_casts
	var threw := carrasco.recasts != _last_recasts
	var blew := carrasco.blasts != _last_blasts
	_last_casts = carrasco.q_casts
	_last_recasts = carrasco.recasts
	_last_blasts = carrasco.blasts
	if carrasco.is_alive() and carrasco.stun_ticks == 0 and carrasco.knockback_ticks == 0:
		if blew and blast != &"":
			_once(blast, blast_speed)
		elif threw and recast != &"":
			_once(recast, recast_speed)
		elif cast and thorns != &"":
			_once(thorns, thorns_speed)
	super(delta)
