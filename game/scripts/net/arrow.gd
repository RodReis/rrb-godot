class_name Arrow
extends Node3D
## Projetil do pool de um ProjectileHero: flecha da Arqueira (F14), bola de fogo do Bruxo (F54;
## EXPLODE = Explosao de Chamas, explode onde o voo acaba), virote da Ladina (F58; FAN = virote da
## Rajada em Leque), garra do Engenheiro (F59; CLAW = Garra Mecanica), projetil sombrio e praga do
## Ocultista (F77; SHADOW = basico, PLAGUE = Q), espinhos e correntes do Carrasco (F98; THORNS =
## recast do Q, CHAINS = R). O netfox 1.35.3 nao tem spawn dentro do rollback
## (so o NetworkWeapon, por RPC e fora da ressimulacao): a flecha que nasce num tick ressimulado nao
## teria historico. Por isso o pool e fixo, filho do heroi, nasce com ele pelo MultiplayerSpawner, e
## o estado de cada flecha (STATE) entra no RollbackSynchronizer do heroi: disparar e ocupar um
## slot, ressimular o heroi reproduz a flecha. O ProjectileHero avanca e acerta; aqui so o visual
## (top_level). Visual desacoplado do estado (F41): a flecha mostrada anda sozinha na velocidade do
## disparo e so acompanha a posicao da rede (extrapolada dentro do tick), sem recuar
## (VfxRules.arrow_progress) — a flecha ressimulada nao ziguezagueia nem anda aos saltos de 30 Hz.

## Visual: disparo novo neste slot (o rastro do VFX recomeca daqui).
signal shown_launched

enum Kind { NONE, BASIC, PIERCE, EXPLODE, FAN, CLAW, ROOT, AXE, SHADOW, PLAGUE, THORNS, CHAINS }

## Propriedades de estado de rollback (caminho "Arrows/<nome>:<prop>" no heroi).
const STATE: Array[String] = [
	"kind", "origin", "direction", "traveled", "max_range", "damage", "pierced", "hits"
]
## Ponto de disparo (origin - direction * traveled) que mudou mais que isto (u^2) = disparo novo.
const RELAUNCH_EPSILON_SQ: float = 0.0001

## Velocidade de voo (u/s), so para o visual; definida pelo ProjectileHero.
var speed: float = 0.0
## Velocidade de voo (u/s) por Kind quando o heroi tem projeteis de velocidades diferentes (F74); o
## tipo que nao esta aqui voa em [member speed].
var kind_speeds: Dictionary[int, float] = {}

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

## Visual: avanco mostrado desde o disparo e o ponto de disparo que ele segue.
var _shown_progress: float = 0.0
var _shown_launch: Vector3 = Vector3.INF


func _process(delta: float) -> void:
	visible = is_active()
	if not visible:
		_shown_launch = Vector3.INF
		return
	var flight := kind_speeds.get(kind, speed) as float
	var ahead := minf(flight * NetworkTime.tick_factor * NetworkTime.ticktime, max_range - traveled)
	var network := traveled + maxf(ahead, 0.0)
	var launch := origin - direction * traveled
	if launch.distance_squared_to(_shown_launch) > RELAUNCH_EPSILON_SQ:
		_shown_launch = launch
		_shown_progress = network
		shown_launched.emit()
	else:
		_shown_progress = VfxRules.arrow_progress(
			_shown_progress, network, flight, delta, max_range
		)
	var at := _shown_launch + direction * _shown_progress
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
