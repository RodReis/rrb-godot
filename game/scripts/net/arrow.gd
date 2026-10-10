class_name Arrow
extends Node3D
## Flecha do pool da Arqueira (F14). O netfox 1.35.3 nao tem spawn dentro do rollback (so o
## NetworkWeapon, por RPC e fora da ressimulacao): a flecha que nasce num tick ressimulado nao
## teria historico. Por isso o pool e fixo, filho do heroi, nasce com ele pelo MultiplayerSpawner,
## e o estado de cada flecha (STATE) entra no RollbackSynchronizer do heroi: disparar e ocupar um
## slot, ressimular o heroi reproduz a flecha. A Ranger avanca e acerta; aqui so o visual
## (top_level, extrapolado dentro do tick para nao andar aos saltos de 30 Hz).

enum Kind { NONE, BASIC, PIERCE }

## Propriedades de estado de rollback (caminho "Arrows/<nome>:<prop>" no heroi).
const STATE: Array[String] = [
	"kind", "origin", "direction", "traveled", "max_range", "damage", "pierced", "hits"
]

## Velocidade de voo (u/s), so para o visual; definida pela Ranger.
var speed: float = 0.0

# Estado de rollback.
var kind: int = Kind.NONE
## Ponta da flecha no fim do ultimo tick simulado.
var origin: Vector3 = Vector3.ZERO
var direction: Vector3 = Vector3.ZERO
var traveled: float = 0.0
var max_range: float = 0.0
## Dano bruto no disparo (antes da perfuracao e da DEF).
var damage: int = 0
## Alvos ja atravessados (perfuracao do Q).
var pierced: int = 0
## combat_id de quem ja foi atingido: o Q atravessa o alvo em varios ticks e fere uma vez so.
## Sempre reatribuido, nunca alterado no lugar (o netfox guarda a referencia no historico).
var hits: PackedInt32Array = PackedInt32Array()


func _process(_delta: float) -> void:
	visible = is_active()
	if not visible:
		return
	var ahead := minf(speed * NetworkTime.tick_factor * NetworkTime.ticktime, max_range - traveled)
	var at := origin + direction * maxf(ahead, 0.0)
	global_position = at
	if not direction.is_zero_approx():
		look_at(at + direction, Vector3.UP)


func is_active() -> bool:
	return kind != Kind.NONE


func launch(
	p_kind: Kind, from: Vector3, p_direction: Vector3, p_range: float, p_damage: int
) -> void:
	kind = p_kind
	origin = from
	direction = p_direction
	traveled = 0.0
	max_range = p_range
	damage = p_damage
	pierced = 0
	hits = PackedInt32Array()


func stop() -> void:
	kind = Kind.NONE


func has_hit(id: int) -> bool:
	return hits.has(id)


func mark_hit(id: int) -> void:
	hits = hits + PackedInt32Array([id])
