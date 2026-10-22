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
## Torreta e Caixa de Dinamite do Engenheiro (F59, SPEC-059 §3.1): mesmo caminho, porque o
## Engenheiro some de quem o ve oculto e a Torreta nao. A instalacao chega confiavel
## (deploy_shown); cada disparo da Torreta, nao (turret_shot_shown: perder um tracante so tira um
## efeito).
## Pocao Verde e Pantano do Protetor da Selva (F74, SPEC-074): mesmo caminho da fumaca e da Torreta
## (zone_shown, confiavel: a zona vale por 3 e 6 s e o Protetor some de quem esta fora do mato ou da
## visao). Circulo Profano do Ocultista (F77): o mesmo caminho.

## Cliente e host: o heroi [param attacker_id] acertou com [param slot] em [param at].
signal impacted(attacker_id: int, slot: int, at: Vector3)
## Cliente e host: a Ladina [param caster_id] lancou a fumaca em [param center] no [param tick].
signal smoke_shown(caster_id: int, center: Vector3, tick: int)
## Cliente e host: o Engenheiro [param caster_id] posicionou [param kind] (Engineer.Deploy) em
## [param center].
signal deploy_shown(caster_id: int, kind: int, center: Vector3, tick: int)
## Cliente e host: o Protetor da Selva [param caster_id] abriu a zona [param kind] (Druid.Zone) em
## [param center] no [param tick].
signal zone_shown(caster_id: int, kind: int, center: Vector3, tick: int)
## Cliente e host: a Torreta do Engenheiro [param caster_id], em [param from], atirou em
## [param at]; [param ticks_left] = o que falta da Torreta (quem entra na visao depois da instalacao
## a monta pelo primeiro tiro que ve).
signal turret_shot_shown(caster_id: int, from: Vector3, at: Vector3, ticks_left: int)

const NODE_NAME: StringName = &"ImpactRelay"
## Chave de "slot" do disparo da Torreta no ImpactLog (fora do HitLedger.Slot): um por tick.
const TURRET_SHOT_KEY: int = 100
## Cliente: impactos recentes lembrados para contar repetidos (medicao).
const RECENT_LIMIT: int = 256

## Medicao (NetProbe, --probe): anunciados (servidor), recebidos e recebidos repetidos (cliente).
static var announced: int = 0
static var received: int = 0
static var repeated: int = 0
## Medicao: nuvens anunciadas (servidor) e recebidas (cliente).
static var smokes_announced: int = 0
static var smokes_received: int = 0
## Medicao: instalacoes e disparos da Torreta/caixa, anunciados (servidor) e recebidos (cliente).
static var deploys_announced: int = 0
static var deploys_received: int = 0
static var turret_shots_announced: int = 0
static var turret_shots_received: int = 0
## Medicao: zonas do Protetor da Selva, anunciadas (servidor) e recebidas (cliente).
static var zones_announced: int = 0
static var zones_received: int = 0

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
	var engineer := node as Engineer
	if engineer != null:
		engineer.deployed.connect(_on_engineer_deployed.bind(engineer))
		engineer.turret_fired.connect(_on_engineer_turret_fired.bind(engineer))
	var druid := node as Druid
	if druid != null:
		druid.zone_started.connect(_on_druid_zone_started.bind(druid))
	var occultist := node as Occultist
	if occultist != null:
		occultist.zone_started.connect(_on_occultist_zone_started.bind(occultist))
	var carrasco := node as Carrasco
	if carrasco != null:
		carrasco.zone_started.connect(_on_carrasco_zone_started.bind(carrasco))


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


func _on_engineer_deployed(
	kind: Engineer.Deploy, center: Vector3, tick: int, engineer: Engineer
) -> void:
	if not multiplayer.is_server():
		return
	var slot := HitLedger.Slot.E if kind == Engineer.Deploy.TURRET else HitLedger.Slot.R
	if not _announced.first(tick, engineer.peer_id, slot, 0):
		return
	deploys_announced += 1
	for peer: int in multiplayer.get_peers():
		if _sees_point(peer, center, engineer):
			_show_deploy.rpc_id(peer, engineer.peer_id, kind, center, tick)
	if _sees_point(multiplayer.get_unique_id(), center, engineer):
		deploy_shown.emit(engineer.peer_id, kind, center, tick)


func _on_engineer_turret_fired(from: Vector3, at: Vector3, tick: int, engineer: Engineer) -> void:
	if not multiplayer.is_server():
		return
	if not _announced.first(tick, engineer.peer_id, TURRET_SHOT_KEY, 0):
		return
	turret_shots_announced += 1
	for peer: int in multiplayer.get_peers():
		if _sees_point(peer, from, engineer):
			_show_turret_shot.rpc_id(peer, engineer.peer_id, from, at, engineer.turret_ticks)
	if _sees_point(multiplayer.get_unique_id(), from, engineer):
		turret_shot_shown.emit(engineer.peer_id, from, at, engineer.turret_ticks)


func _on_druid_zone_started(kind: Druid.Zone, center: Vector3, tick: int, druid: Druid) -> void:
	if not multiplayer.is_server():
		return
	var slot := HitLedger.Slot.E if kind == Druid.Zone.POTION else HitLedger.Slot.R
	if not _announced.first(tick, druid.peer_id, slot, 0):
		return
	zones_announced += 1
	for peer: int in multiplayer.get_peers():
		if _sees_point(peer, center, druid):
			_show_zone.rpc_id(peer, druid.peer_id, kind, center, tick)
	if _sees_point(multiplayer.get_unique_id(), center, druid):
		zone_shown.emit(druid.peer_id, kind, center, tick)


## Circulo Profano do Ocultista (F77, SPEC-077): mesmo caminho do Pantano (zone_shown), slot E.
func _on_occultist_zone_started(
	_kind: Occultist.Zone, center: Vector3, tick: int, occultist: Occultist
) -> void:
	if not multiplayer.is_server():
		return
	if not _announced.first(tick, occultist.peer_id, HitLedger.Slot.E, 0):
		return
	zones_announced += 1
	for peer: int in multiplayer.get_peers():
		if _sees_point(peer, center, occultist):
			_show_zone.rpc_id(peer, occultist.peer_id, Occultist.Zone.CIRCLE, center, tick)
	if _sees_point(multiplayer.get_unique_id(), center, occultist):
		zone_shown.emit(occultist.peer_id, Occultist.Zone.CIRCLE, center, tick)


## Raio de luz das Correntes do Carrasco (F98, SPEC-098): mesmo caminho do Circulo (zone_shown),
## slot R.
func _on_carrasco_zone_started(kind: int, center: Vector3, tick: int, carrasco: Carrasco) -> void:
	if not multiplayer.is_server():
		return
	if not _announced.first(tick, carrasco.peer_id, HitLedger.Slot.R, 0):
		return
	zones_announced += 1
	for peer: int in multiplayer.get_peers():
		if _sees_point(peer, center, carrasco):
			_show_zone.rpc_id(peer, carrasco.peer_id, kind, center, tick)
	if _sees_point(multiplayer.get_unique_id(), center, carrasco):
		zone_shown.emit(carrasco.peer_id, kind, center, tick)


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


## Servidor -> cliente: uma Torreta ou caixa que este jogador ve.
@rpc("authority", "call_remote", "reliable")
func _show_deploy(caster_id: int, kind: int, center: Vector3, tick: int) -> void:
	deploys_received += 1
	deploy_shown.emit(caster_id, kind, center, tick)


## Servidor -> cliente: uma zona do Protetor da Selva que este jogador ve.
@rpc("authority", "call_remote", "reliable")
func _show_zone(caster_id: int, kind: int, center: Vector3, tick: int) -> void:
	zones_received += 1
	zone_shown.emit(caster_id, kind, center, tick)


## Servidor -> cliente: um disparo de Torreta que este jogador ve.
@rpc("authority", "call_remote", "unreliable")
func _show_turret_shot(caster_id: int, from: Vector3, at: Vector3, ticks_left: int) -> void:
	turret_shots_received += 1
	turret_shot_shown.emit(caster_id, from, at, ticks_left)


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
