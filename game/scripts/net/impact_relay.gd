class_name ImpactRelay
extends Node
## Impacto confirmado pelo servidor ate o VFX do cliente (F41; bloco visual regra 2). Servidor:
## cada golpe registrado no ledger do alvo (Hero.struck) e anunciado uma vez (ImpactLog: a
## ressimulacao do atacante repete o _hit) por RPC discreto, so a quem ve o alvo — quem nao ve o
## alvo (neblina F37, mato F32) nao recebe nem o impacto. No host o jogador local recebe pelo sinal.
## Cliente: impacted, que o VfxSpawner escuta. O node nasce com a main nos dois lados, antes de
## qualquer conexao, entao o RPC sempre o acha. Unreliable: perder um impacto (2 % de perda) so
## tira uma faisca, e confiavel enfileiraria atras de retransmissao.
## Fumaca da Ladina (F58, SPEC-058 §6): a nuvem chega por aqui, nao pelo estado da Ladina (ela some
## de quem esta fora da nuvem). Uma vez por lancamento, a quem tem o centro dela no raio de visao
## (F37) ou e do time dela; confiavel, porque perder a nuvem esconderia por 3 s a regra que vale.

## Cliente e host: o heroi [param attacker_id] acertou com [param slot] em [param at].
signal impacted(attacker_id: int, slot: int, at: Vector3)
## Cliente e host: a Ladina [param caster_id] lancou a fumaca em [param center] no [param tick].
signal smoke_shown(caster_id: int, center: Vector3, tick: int)

const NODE_NAME: StringName = &"ImpactRelay"
## Cliente: impactos recentes lembrados para contar repetidos (medicao).
const RECENT_LIMIT: int = 256

## Medicao (NetProbe, --probe): anunciados (servidor), recebidos e recebidos repetidos (cliente).
static var announced: int = 0
static var received: int = 0
static var repeated: int = 0
## Medicao: nuvens anunciadas (servidor) e recebidas (cliente).
static var smokes_announced: int = 0
static var smokes_received: int = 0

## Pai dos herois (Main/Players); definido antes de entrar na arvore.
var players: Node

var _announced: ImpactLog = ImpactLog.new()  # so no servidor
var _recent: Dictionary = {}  # cliente: [atacante, slot, tick, posicao] -> true


func _ready() -> void:
	players.child_entered_tree.connect(_on_players_child_entered_tree)


## O jogador de [param peer] ve [param target] (o que o servidor ja decidiu e avisou).
static func _sees(target: Node, peer: int) -> bool:
	var concealment := target.get_node_or_null(NodePath(Concealment.NODE_NAME)) as Concealment
	return concealment == null or concealment.shown_to(peer)


func _on_players_child_entered_tree(node: Node) -> void:
	var hero := node as Hero
	if hero != null:
		hero.struck.connect(_on_hero_struck.bind(hero))
	var rogue := node as Rogue
	if rogue != null:
		rogue.smoked.connect(_on_rogue_smoked.bind(rogue))


## O heroi do jogador [param peer] ve o ponto [param at] (time de [param caster] sempre ve).
func _sees_point(peer: int, at: Vector3, caster: Hero) -> bool:
	var observer := players.get_node_or_null(NodePath(str(peer))) as Hero
	if observer == null:
		return false
	if observer.team == caster.team:
		return true
	return VisionRules.in_sight(observer.global_position, at, observer.match_rules.vision_radius)


func _on_rogue_smoked(center: Vector3, tick: int, rogue: Rogue) -> void:
	if not multiplayer.is_server():
		return
	if not _announced.first(tick, rogue.peer_id, HitLedger.Slot.E, 0):
		return
	smokes_announced += 1
	for peer: int in multiplayer.get_peers():
		if _sees_point(peer, center, rogue):
			_show_smoke.rpc_id(peer, rogue.peer_id, center, tick)
	if _sees_point(multiplayer.get_unique_id(), center, rogue):
		smoke_shown.emit(rogue.peer_id, center, tick)


func _on_hero_struck(target: Combatant, slot: HitLedger.Slot, tick: int, hero: Hero) -> void:
	if not multiplayer.is_server():
		return
	if not _announced.first(tick, hero.peer_id, slot, target.combat_id()):
		return
	_announced.trim_before(tick - NetworkRollback.history_limit)
	announced += 1
	var at := target.global_position
	for peer: int in multiplayer.get_peers():
		if _sees(target, peer):
			_show.rpc_id(peer, hero.peer_id, slot, at, tick)
	if _sees(target, multiplayer.get_unique_id()):
		impacted.emit(hero.peer_id, slot, at)


## Servidor -> cliente: uma nuvem de fumaca que este jogador ve.
@rpc("authority", "call_remote", "reliable")
func _show_smoke(caster_id: int, center: Vector3, tick: int) -> void:
	smokes_received += 1
	smoke_shown.emit(caster_id, center, tick)


## Servidor -> cliente: um impacto que este jogador ve ([param tick] do golpe, para a medicao).
@rpc("authority", "call_remote", "unreliable")
func _show(attacker_id: int, slot: int, at: Vector3, tick: int) -> void:
	received += 1
	if _recent.size() >= RECENT_LIMIT:
		_recent.clear()
	var key := [attacker_id, slot, tick, at]
	if _recent.has(key):
		repeated += 1
	_recent[key] = true
	impacted.emit(attacker_id, slot, at)
