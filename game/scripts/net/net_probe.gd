class_name NetProbe
extends Node
## Sonda de rede (F20, --probe): mede a replicacao como o jogador a ve. Duas linhas no log, que
## tools/net-probe-report.ps1 cruza entre servidor e clientes (roteiro em game/test/net):
## - "[probe] remoto": % de quadros em que um heroi remoto ficou parado no lugar enquanto a
##   velocidade replicada dizia que ele andava (estado atrasado ou perdido). So nos clientes.
## - "[probe] throttle": menor throttle do ENet visto na janela, por peer (32 = nada descartado;
##   abaixo disso o ENet descarta no envio essa fracao dos pacotes nao confiaveis, o estado do
##   netfox).
## - "[probe] check": a cada CHECK_TICKS, monstros (no mapa, HP) e baus abertos como estavam no
##   tick X - LAG_TICKS do servidor, lidos do historico do StateSynchronizer, entao o mesmo tick
##   nos dois lados. Le um campo interno do netfox 1.35.3 (_state_history): so para medir.
##   Neblina (F37): no cliente, monstro escondido do tick X em diante sai como "-" (o servidor
##   nao manda o estado dele) e os baus sao o ultimo estado visto (subconjunto do servidor).
## - "[probe] neblina": ciclos escondido -> visivel de herois e monstros no cliente e, deles,
##   quantos receberam estado de um tick em que o servidor dizia "escondido" (deve ser 0).
## - "[probe] salto" (F29): maior salto visual dos herois, alem do que a velocidade explica, e o
##   total de teleportes contados pelo TeleportMonitor (so cliente online). Calibra o limite de
##   shared/data/rules/teleport_rules.tres (SPEC-029 §3.2): com a rede limpa (cenario A) deve ser 0.
## - "[probe] vfx" (F41): servidor = bordas do estado autoritativo por "peer:chave" (basico, R,
##   inicio e fim do avanco) e impactos anunciados; cliente = os mesmos eventos mostrados pelo
##   HeroVfx e impactos recebidos/repetidos. VFX duplicada = cliente acima do servidor ou
##   repetido > 0 (cliente pode ficar abaixo: heroi escondido, impacto perdido).

const CHECK_TICKS: int = 300
## Folga para o estado do tick chegar ao cliente mesmo com perda e 200 ms de RTT.
const LAG_TICKS: int = 30
const WINDOW_SECONDS: float = 10.0
## Velocidade replicada acima da qual o remoto deveria estar andando (u/s).
const MOVING_SPEED: float = 0.5
const STILL_DISTANCE: float = 0.0001
const UNKNOWN: String = "?"
## Monstro fora da visao do jogador deste cliente no tick do checkpoint (F37).
const FOGGED: String = "-"

## Definidos pelo main antes de entrar na arvore.
var players: Node3D
var spawns: SpawnDirector

var _last_position: Dictionary[Hero, Vector3] = {}
var _window_seconds: float = 0.0
var _window_moving: int = 0
var _window_stopped: int = 0
var _total_moving: int = 0
var _total_stopped: int = 0
var _min_throttle: Dictionary[int, int] = {}
## Servidor: ultimo (basico, R, avanco) de cada heroi e bordas contadas por "peer:chave".
var _last_timers: Dictionary[Hero, Vector3i] = {}
var _server_events: Dictionary = {}


func _ready() -> void:
	NetworkTime.after_tick.connect(_on_network_after_tick)


func _process(delta: float) -> void:
	_sample_throttle()
	_window_seconds += delta
	if _window_seconds >= WINDOW_SECONDS:
		_report_window()
	if multiplayer.is_server():
		return
	var local := str(multiplayer.get_unique_id())
	for node: Node in players.get_children():
		var hero := node as Hero
		if hero == null or hero.name == local:
			continue
		var moved := hero.global_position.distance_to(
			_last_position.get(hero, hero.global_position)
		)
		_last_position[hero] = hero.global_position
		if hero.velocity.length() > MOVING_SPEED:
			_window_moving += 1
			if moved < STILL_DISTANCE:
				_window_stopped += 1


## "Monstro:HP" na ordem dos filhos (x = fora do mapa) e baus abertos ate [param tick].
func digest(tick: int) -> String:
	var monsters: PackedStringArray = []
	var chests: PackedStringArray = []
	var alive := 0
	for node: Node in spawns.get_children():
		if node is Monster:
			var entry := _monster_at(node as Monster, tick)
			monsters.append(entry)
			if entry.is_valid_int() and entry.to_int() > 0:
				alive += 1
		elif node is Chest:
			var chest := node as Chest
			if chest.opened_tick != Chest.NOT_OPENED and chest.opened_tick <= tick:
				chests.append(chest.name)
	return "vivos=%d baus=%d %s|%s" % [alive, chests.size(), ",".join(monsters), ",".join(chests)]


func _monster_at(monster: Monster, tick: int) -> String:
	var concealment := monster.get_node(NodePath(Concealment.NODE_NAME)) as Concealment
	if not multiplayer.is_server() and concealment.last_hidden_tick >= tick:
		return FOGGED
	var sync := monster.get_node("StateSynchronizer") as StateSynchronizer
	var snapshot := sync._state_history.get_history(tick)
	var hp: Variant = snapshot.get_value(":hp")
	var present: Variant = snapshot.get_value(":present")
	if hp == null:
		return UNKNOWN
	return "x" if present == false else str(hp)


func _sample_throttle() -> void:
	var enet := multiplayer.multiplayer_peer as ENetMultiplayerPeer
	if enet == null:
		return
	# O cliente so tem conexao ENet com o servidor; get_peers() inclui o outro cliente (relay).
	var ids: PackedInt32Array = multiplayer.get_peers() if multiplayer.is_server() else [1]
	for id: int in ids:
		var peer := enet.get_peer(id)
		if peer != null:
			var value := roundi(peer.get_statistic(ENetPacketPeer.PEER_PACKET_THROTTLE))
			_min_throttle[id] = mini(_min_throttle.get(id, value), value)


func _report_window() -> void:
	if not _min_throttle.is_empty():
		print("[probe] throttle minimo %s" % _min_throttle)
		_min_throttle.clear()
	_window_seconds = 0.0
	if multiplayer.is_server():
		print("[probe] vfx servidor %s anunciados=%d" % [_server_events, ImpactRelay.announced])
		return
	print(
		(
			"[probe] vfx cliente %s recebidos=%d repetidos=%d"
			% [HeroVfx.shown_events, ImpactRelay.received, ImpactRelay.repeated]
		)
	)
	print(
		(
			"[probe] neblina: %d ciclos escondido -> visivel, %d com estado recebido escondido"
			% [Concealment.hidden_cycles, Concealment.state_leaks]
		)
	)
	var monitor := get_node_or_null("../TeleportMonitor") as TeleportMonitor
	if monitor != null:
		print(
			(
				"[probe] salto maximo %.2f u, teleportes %d"
				% [monitor.detector.max_excess(), monitor.total()]
			)
		)
	_total_moving += _window_moving
	_total_stopped += _window_stopped
	print(
		(
			"[probe] remoto parado %.1f%% (%d/%d quadros), acumulado %.1f%% (%d/%d)"
			% [
				_pct(_window_stopped, _window_moving),
				_window_stopped,
				_window_moving,
				_pct(_total_stopped, _total_moving),
				_total_stopped,
				_total_moving,
			]
		)
	)
	_window_moving = 0
	_window_stopped = 0


func _pct(part: int, whole: int) -> float:
	return 100.0 * part / whole if whole > 0 else 0.0


## Servidor: bordas do estado autoritativo, com as chaves do HeroVfx.
func _count_server_events() -> void:
	for node: Node in players.get_children():
		var hero := node as Hero
		if hero == null:
			continue
		var now := Vector3i(hero.basic_cooldown, hero.r_cooldown, int(hero.dash_ticks > 0))
		var before: Vector3i = _last_timers.get(hero, now)
		_last_timers[hero] = now
		if now.x > before.x:
			_bump(hero, "basic")
		if now.y > before.y:
			_bump(hero, "r")
		if now.z > before.z:
			_bump(hero, "dash_start")
		if now.z < before.z:
			_bump(hero, "dash_end")


func _bump(hero: Hero, key: String) -> void:
	var id := "%d:%s" % [hero.peer_id, key]
	_server_events[id] = _server_events.get(id, 0) + 1


func _on_network_after_tick(_delta: float, tick: int) -> void:
	if multiplayer.is_server():
		_count_server_events()
	if tick % CHECK_TICKS == 0 and tick > LAG_TICKS:
		print("[probe] check %d %s" % [tick - LAG_TICKS, digest(tick - LAG_TICKS)])
