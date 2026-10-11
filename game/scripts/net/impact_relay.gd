class_name ImpactRelay
extends Node
## Impacto confirmado pelo servidor ate o VFX do cliente (F41; bloco visual regra 2). Servidor:
## cada golpe registrado no ledger do alvo (Hero.struck) e anunciado uma vez (ImpactLog: a
## ressimulacao do atacante repete o _hit) por RPC discreto, so a quem ve o alvo — quem nao ve o
## alvo (neblina F37, mato F32) nao recebe nem o impacto. No host o jogador local recebe pelo sinal.
## Cliente: impacted, que o VfxSpawner escuta. O node nasce com a main nos dois lados, antes de
## qualquer conexao, entao o RPC sempre o acha. Unreliable: perder um impacto (2 % de perda) so
## tira uma faisca, e confiavel enfileiraria atras de retransmissao.

## Cliente e host: o heroi [param attacker_id] acertou com [param slot] em [param at].
signal impacted(attacker_id: int, slot: int, at: Vector3)

const NODE_NAME: StringName = &"ImpactRelay"

## Pai dos herois (Main/Players); definido antes de entrar na arvore.
var players: Node

var _announced: ImpactLog = ImpactLog.new()  # so no servidor


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


func _on_hero_struck(target: Combatant, slot: HitLedger.Slot, tick: int, hero: Hero) -> void:
	if not multiplayer.is_server():
		return
	if not _announced.first(tick, hero.peer_id, slot, target.combat_id()):
		return
	_announced.trim_before(tick - NetworkRollback.history_limit)
	var at := target.global_position
	for peer: int in multiplayer.get_peers():
		if _sees(target, peer):
			_show.rpc_id(peer, hero.peer_id, slot, at)
	if _sees(target, multiplayer.get_unique_id()):
		impacted.emit(hero.peer_id, slot, at)


## Servidor -> cliente: um impacto que este jogador ve.
@rpc("authority", "call_remote", "unreliable")
func _show(attacker_id: int, slot: int, at: Vector3) -> void:
	impacted.emit(attacker_id, slot, at)
