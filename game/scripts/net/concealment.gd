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

## Servidor: [param peer] passou a ver ([param shown]) ou deixou de ver o alvo no [param tick].
signal sight_changed(peer: int, shown: bool, tick: int)

const NODE_NAME: StringName = &"Concealment"

## Cliente (soma de todos os alvos, lida pelo NetProbe): ciclos escondido -> visivel e, deles,
## quantos receberam estado de um tick em que o servidor dizia "escondido" (deve ser 0).
static var hidden_cycles: int = 0
static var state_leaks: int = 0
## Alvos na arvore (o VisionDirector percorre sem alocar).
static var _all: Array[Concealment] = []

var _target: Node3D
## (observer: Hero) -> bool: o heroi [param observer] ve o alvo agora.
var _seen_by: Callable
## Filtro do sincronizador do alvo; null = sem sincronizador (bau).
var _filter: PeerVisibilityFilter
## Heroi: o peer so recebe aviso depois de confirmar o spawn; null = node existe desde o load.
var _ack: SpawnAck
## Cliente: tick do ultimo estado recebido do alvo.
var _last_state: Callable
## Cliente: esconde o node e a colisao quando o servidor manda (heroi e monstro; o bau nao some).
var _hide_on_client: bool = true
## Peer dono do alvo (heroi): comeca visivel para ele nos dois lados. 0 = nenhum.
var _owner_peer: int = 0
## Servidor: peer -> ve o alvo (o que o peer ja sabe). Ausente = o padrao de shown_to.
var _shown: Dictionary = {}
## Servidor: peers que mudaram no ultimo refresh (reusado a cada tick).
var _changed: PackedInt32Array = PackedInt32Array()
## Cliente: o servidor escondeu o alvo deste peer.
var _hidden_here: bool = true
## Cliente: tick a partir do qual o estado recebido e de depois da revelacao (-1 = nunca sumiu).
var _shown_tick: int = -1
## Cliente: tick do aviso "escondido" e o 1o estado recebido daquele tick em diante (-1 = nenhum).
var _hide_tick: int = -1
var _first_after_hide: int = -1
## Cliente: ultimo valor de is_shown (log so na troca).
var _was_shown: bool = true
## Cliente: ultimo tick (NetworkTime) em que o alvo estava escondido; -1 = nunca (NetProbe).
var last_hidden_tick: int = -1


## Cria o no filho de [param target]. [param seen_by] = regra do alvo; [param filter], [param ack]
## e [param last_state] podem faltar (bau). [param owner_peer] = dono (heroi) ou 0.
static func guard(
	target: Node3D,
	seen_by: Callable,
	filter: PeerVisibilityFilter,
	ack: SpawnAck,
	last_state: Callable,
	hide_on_client: bool,
	owner_peer: int
) -> Concealment:
	var concealment := Concealment.new()
	concealment.name = NODE_NAME
	concealment._target = target
	concealment._seen_by = seen_by
	concealment._filter = filter
	concealment._ack = ack
	concealment._last_state = last_state
	concealment._hide_on_client = hide_on_client
	concealment._owner_peer = owner_peer
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
		_filter.add_visibility_filter(shown_to)
	# Heroi nasce depois da conexao (id ja certo); monstro e bau nascem no load, sem dono (0).
	_hidden_here = _owner_peer != multiplayer.get_unique_id()
	_was_shown = not _hidden_here
	set_process(_hide_on_client)


func _process(_delta: float) -> void:
	if multiplayer.is_server():
		return
	if _hidden_here and _first_after_hide < 0 and _hide_tick >= 0:
		var last: int = _last_state.call()
		if last >= _hide_tick:
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
				% [_target.name, "reapareceu" if shown else "sumiu", _last_state.call()]
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
	if not _hide_on_client:
		return true
	return VisibilityRules.shown_on_client(_hidden_here, _shown_tick, _last_state.call())


## Servidor: recalcula, para cada heroi de [param observers], se o peer dele ve o alvo; os peers
## de [param remote] (conectados) so contam depois de confirmar o spawn do alvo. Atualiza o
## filtro e devolve os peers que mudaram (array reusado; announce avisa).
func refresh(observers: Array[Hero], remote: PackedInt32Array) -> PackedInt32Array:
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
## [param remote] — e emite sight_changed para todos (bot e jogador do host inclusive).
func announce(changed: PackedInt32Array, remote: PackedInt32Array, tick: int) -> void:
	for peer: int in changed:
		var shown := shown_to(peer)
		if _hide_on_client and remote.has(peer):
			_set_hidden.rpc_id(peer, not shown, tick)
		sight_changed.emit(peer, shown, tick)


## Servidor -> cliente: o alvo sumiu ([param hidden]) ou voltou a partir de [param tick].
@rpc("authority", "call_remote", "reliable")
func _set_hidden(hidden: bool, tick: int) -> void:
	if hidden:
		_hide_tick = tick
		_first_after_hide = -1
	elif _hidden_here and _hide_tick >= 0:
		# Medida, nao afirmacao: estado de um tick em [hide, show) = o servidor vazou.
		hidden_cycles += 1
		if _first_after_hide >= 0 and _first_after_hide < tick:
			state_leaks += 1
			print("[visao] %s recebeu estado do tick %d escondido" % [_target.name, _first_after_hide])
	_hidden_here = hidden
	_shown_tick = tick
