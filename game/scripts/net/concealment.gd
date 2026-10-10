class_name Concealment
extends Node
## Quem ve o alvo (F32 mato alto, F37 neblina de guerra; CONVENTION §4.7, §4.9). O alvo e um
## heroi, um monstro ou um bau; a regra e dele (seen_by). No servidor, o VisionDirector chama
## refresh/announce a cada tick: quem nao ve deixa de receber o estado do sincronizador do alvo
## (filtro ao lado do SpawnAck) — neblina so no cliente e proibida — e o peer e avisado por RPC
## confiavel (evento discreto, fora da simulacao). Sem estado, o node ficaria parado onde sumiu;
## por isso o cliente esconde o heroi/monstro e tira a colisao dele ate chegar estado de depois
## da revelacao. Bau nao some: so deixa de receber o estado e o dono reage a sight_changed. No
## host (--offline) o jogador local e o servidor: ali o esconder e so visual, pela mesma regra.
## Heroi: o servidor ressimula ticks passados quando chega input atrasado e retransmite cada um
## com o filtro da hora; por isso o filtro do heroi e refeito a cada tick do rollback e so deixa
## passar estado de depois da revelacao (_shown_since). Na revelacao o peer recebe estado
## completo (sem diff contra referencia de antes de sumir). Premissa: monstro e bau existem no
## cliente desde o load da cena, antes de ele conectar, entao o RPC sempre acha o node.

## Servidor: [param peer] passou a ver ([param shown]) ou deixou de ver o alvo no [param tick].
signal sight_changed(peer: int, shown: bool, tick: int)

const NODE_NAME: StringName = &"Concealment"

## Cliente (soma de todos os alvos, lida pelo NetProbe): ciclos escondido -> visivel e, deles,
## quantos receberam estado de um tick em que o servidor dizia "escondido" (deve ser 0).
static var hidden_cycles: int = 0
static var state_leaks: int = 0
## Alvos na arvore (o VisionDirector percorre sem alocar).
static var _all: Array[Concealment] = []

## Cliente: ultimo tick (NetworkTime) em que o alvo estava escondido; -1 = nunca (NetProbe).
var last_hidden_tick: int = -1

var _target: Node3D
## (observer: Hero) -> bool: o heroi [param observer] ve o alvo agora.
var _seen_by: Callable
## Sincronizador do alvo (RollbackSynchronizer ou StateSynchronizer); null = bau.
var _sync: Node
var _filter: PeerVisibilityFilter
## Heroi: o peer so recebe aviso depois de confirmar o spawn; null = node existe desde o load.
var _ack: SpawnAck
## Peer dono do alvo (heroi): comeca visivel para ele nos dois lados. 0 = nenhum.
var _owner_peer: int = 0
## Servidor: peer -> ve o alvo (o que o peer ja sabe). Ausente = o padrao de shown_to.
var _shown: Dictionary = {}
## Servidor: peer -> primeiro tick de estado que ele pode receber (desde a ultima revelacao).
var _shown_since: Dictionary = {}
## Servidor: peers conectados do ultimo refresh (filtro refeito no rollback).
var _remote: PackedInt32Array = PackedInt32Array()
## Servidor: peers que mudaram no ultimo refresh (reusado a cada tick).
var _changed: PackedInt32Array = PackedInt32Array()
## Cliente: o servidor escondeu o alvo deste peer.
var _hidden_here: bool = true
## Cliente: tick a partir do qual o estado recebido e de depois da revelacao (-1 = nunca sumiu).
var _shown_tick: int = -1
## Cliente: tick do aviso "escondido" e o 1o estado recebido de depois dele (-1 = nenhum).
var _hide_tick: int = -1
var _first_after_hide: int = -1
## Cliente: ultimo valor de is_shown (log so na troca).
var _was_shown: bool = true


## Cria o no filho de [param target] com a regra [param seen_by]. [param sync] = sincronizador do
## alvo (heroi, monstro; null = bau, que nao some); [param ack] = SpawnAck (heroi); [param
## owner_peer] = dono (heroi) ou 0.
static func guard(
	target: Node3D,
	seen_by: Callable,
	sync: Node = null,
	ack: SpawnAck = null,
	owner_peer: int = 0
) -> Concealment:
	var concealment := Concealment.new()
	concealment.name = NODE_NAME
	concealment._target = target
	concealment._seen_by = seen_by
	concealment._sync = sync
	concealment._ack = ack
	concealment._owner_peer = owner_peer
	if sync is RollbackSynchronizer:
		concealment._filter = (sync as RollbackSynchronizer).visibility_filter
	elif sync is StateSynchronizer:
		concealment._filter = (sync as StateSynchronizer).visibility_filter
	target.add_child(concealment)
	return concealment


static func all() -> Array[Concealment]:
	return _all


func _enter_tree() -> void:
	_all.append(self)


func _exit_tree() -> void:
	_all.erase(self)


func _ready() -> void:
	if _filter != null:
		_filter.add_visibility_filter(_visible_to)
	if _sync is RollbackSynchronizer:
		NetworkRollback.after_process_tick.connect(_on_network_rollback_after_process_tick)
	# Heroi nasce depois da conexao (id ja certo); monstro e bau nascem no load, sem dono (0).
	_hidden_here = _owner_peer != multiplayer.get_unique_id()
	_was_shown = not _hidden_here
	set_process(_sync != null)


func _process(_delta: float) -> void:
	# No _ready o peer ainda e offline e is_server() mente; aqui ja vale.
	if multiplayer.is_server():
		set_process(false)
		return
	var last := _last_state()
	if _hidden_here and _first_after_hide < 0 and _hide_tick >= 0 and last > _hide_tick:
		_first_after_hide = last
	var shown := is_shown()
	if not shown:
		last_hidden_tick = NetworkTime.tick
	if shown == _was_shown:
		return
	_was_shown = shown
	if _target is Hero:
		print(
			(
				"[visao] heroi %s %s (ultimo estado recebido: tick %d)"
				% [_target.name, "reapareceu" if shown else "sumiu", last]
			)
		)


func target() -> Node3D:
	return _target


## Servidor: [param peer] ve o alvo (o que ja foi decidido e avisado). O dono comeca vendo.
func shown_to(peer: int) -> bool:
	return _shown.get(peer, peer == _owner_peer)


## O jogador deste processo ve o alvo? No servidor (host), pela regra; no cliente, pelo aviso do
## servidor e pela chegada de estado novo. Bau no cliente: sempre (mostra o ultimo estado visto).
func is_shown() -> bool:
	if multiplayer.is_server():
		return shown_to(multiplayer.get_unique_id())
	if _sync == null:
		return true
	return VisibilityRules.shown_on_client(_hidden_here, _shown_tick, _last_state())


## Servidor: recalcula, para cada heroi de [param observers], se o peer dele ve o alvo; os peers
## de [param remote] (conectados) so contam depois de confirmar o spawn do alvo. Atualiza o
## filtro e devolve os peers que mudaram (array reusado; announce avisa).
func refresh(observers: Array[Hero], remote: PackedInt32Array) -> PackedInt32Array:
	_remote = remote
	_changed.clear()
	for observer: Hero in observers:
		var peer := observer.peer_id
		if _ack != null and remote.has(peer) and not _ack.has_confirmed(peer):
			continue
		var shown: bool = _seen_by.call(observer)
		if shown != shown_to(peer):
			_shown[peer] = shown
			_changed.append(peer)
	if not _changed.is_empty() and _filter != null:
		_filter.update_visibility(remote)
	return _changed


## Servidor: avisa os peers de [param changed] (do refresh) — RPC so a quem esta em
## [param remote] — e emite sight_changed para todos (bot e jogador do host inclusive). Quem passa
## a ver no [param tick] so recebe estado de tick + 1 em diante, e completo.
func announce(changed: PackedInt32Array, remote: PackedInt32Array, tick: int) -> void:
	for peer: int in changed:
		var shown := shown_to(peer)
		if shown:
			_shown_since[peer] = tick + 1
		if _sync != null and remote.has(peer):
			if shown:
				_forget_ack(peer)
			_set_hidden.rpc_id(peer, not shown, tick)
		sight_changed.emit(peer, shown, tick)


## Filtro do sincronizador: [param peer] recebe o estado. No rollback do heroi, so o estado de
## ticks de depois da revelacao (o tick gravado e NetworkRollback.tick + 1).
func _visible_to(peer: int) -> bool:
	if not shown_to(peer):
		return false
	if not NetworkRollback.is_rollback():
		return true
	return NetworkRollback.tick + 1 >= _shown_since.get(peer, 0)


# ponytail: le campos internos do netfox 1.35.3 (o ultimo tick de estado do StateSynchronizer e o
# ultimo ack de cada peer nao sao expostos; o NetProbe ja le _state_history); trocar se o addon
# expuser.
## Cliente: tick do ultimo estado recebido do alvo (-1 = nenhum na janela do historico).
func _last_state() -> int:
	var rollback := _sync as RollbackSynchronizer
	if rollback != null:
		return rollback.get_last_known_state()
	var state := _sync as StateSynchronizer
	if state == null or state._state_history.is_empty():
		return -1
	return state._state_history.get_latest_tick()


## Servidor: esquece o ultimo ack de [param peer]: o proximo estado vai completo, sem diff contra
## uma referencia de antes de sumir que o cliente ja pode ter descartado.
func _forget_ack(peer: int) -> void:
	var rollback := _sync as RollbackSynchronizer
	if rollback != null:
		rollback._history_transmitter._ackd_state.erase(peer)
	else:
		(_sync as StateSynchronizer)._ackd_state.erase(peer)


## Servidor -> cliente: o alvo sumiu ([param hidden]) ou voltou a partir de [param tick].
@rpc("authority", "call_remote", "reliable")
func _set_hidden(hidden: bool, tick: int) -> void:
	if hidden:
		_hide_tick = tick
		_first_after_hide = -1
	elif _hidden_here and _hide_tick >= 0:
		# Medida, nao afirmacao: estado de um tick em (hide, show) = o servidor vazou. O do
		# proprio tick da revelacao pode chegar antes do aviso (canais diferentes) e e legitimo.
		hidden_cycles += 1
		if _first_after_hide >= 0 and _first_after_hide < tick:
			state_leaks += 1
			print("[visao] %s recebeu estado do tick %d escondido" % [_target.name, _first_after_hide])
	_hidden_here = hidden
	_shown_tick = tick


# ponytail: update_visibility aloca as listas do filtro a cada tick ressimulado de cada heroi
# (1x1: 2 herois); trocar por um filtro que guarde a lista se o profiler apontar.
## Servidor: refaz o filtro do heroi antes de gravar e transmitir o tick seguinte do rollback.
func _on_network_rollback_after_process_tick(_tick: int) -> void:
	if multiplayer.is_server() and _filter != null:
		_filter.update_visibility(_remote)
