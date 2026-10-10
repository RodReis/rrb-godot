class_name MatchController
extends Node
## Ciclo da partida (CONVENTION §3, ARCHITECTURE-GAME §3.3): LOBBY_WAIT -> HERO_PICK -> PHASE1
## -> TRANSITION, sobre o MatchClock em ticks; PHASE2, morte subita e vitoria sao do F16. A FSM,
## as vagas e a selecao rodam so no servidor (open()); nos clientes este no so recebe os eventos
## discretos por RPC confiavel com tick e os repassa como sinais para a UI. Mortes e niveis saem
## do estado replicado dos herois, uma vez por mudanca (ressimulacao nao duplica evento); o XP do
## abate vai pelo ledger do matador (§3.2). Sem nenhum caso de modo offline: o bot e uma vaga.

signal phase_changed(from: int, to: int, tick: int)
signal hero_picked(peer: int, hero_id: int, tick: int)
signal player_died(peer: int, killer: int, tick: int)
signal player_leveled(peer: int, level: int, tick: int)
signal chest_opened(peer: int, chest_uid: int, tick: int)
signal match_ended(winner: int, reason: StringName, tick: int)

const NO_WINNER: int = 0
const REASON_ABANDONED: StringName = &"abandoned"
## Times na ordem dos slots: P1, P2.
const SLOT_TEAMS: Array[int] = [GateRules.TEAM_A, GateRules.TEAM_B]


## Vaga de um jogador (servidor).
class Seat:
	extends RefCounted
	var peer: int = 0
	var team: int = GateRules.TEAM_NEUTRAL
	var is_bot: bool = false
	var connected: bool = true
	## &"" ate o lock-in; no fim da selecao, o padrao do slot.
	var hero: StringName = &""


@export var rules: MatchRules
@export var clock: MatchClock

## Servidor: herois com cena (a Arqueira entra no F14).
var available_heroes: Array[StringName] = []
## Servidor: segundos em que o relogio da fase 1 comeca (dev, --time).
var start_seconds: float = 0.0
## Espelhado nos clientes pelo RPC de fase.
var state: MatchState.State = MatchState.State.LOBBY_WAIT
## Fim da espera ou da selecao em ticks; o cliente conta o tempo a partir do tick do evento.
var deadline_tick: int = 0

var _open: bool = false
var _tickrate: int = 0
var _seats: Array[Seat] = []
var _kills: Dictionary = {}  # peer -> kills na fase 2
var _dead: Dictionary = {}  # peer -> morto no ultimo tick visto
var _levels: Dictionary = {}  # peer -> maior nivel ja avisado
var _refusals_logged: Dictionary = {}  # peer -> true: log de lock-in recusado uma vez por peer


func _ready() -> void:
	NetworkTime.on_tick.connect(_on_network_tick)
	if clock != null:
		clock.phase1_ended.connect(_on_clock_phase1_ended)


## Servidor: comeca a esperar os jogadores.
func open(tick: int, tickrate: int) -> void:
	_open = true
	_tickrate = tickrate
	deadline_tick = tick + _ticks(rules.lobby_wait_timeout)


func seats() -> Array[Seat]:
	return _seats


func kills(peer: int) -> int:
	return _kills.get(peer, 0)


## Servidor: [param peer] ocupa a vaga do [param team]. Falso se a partida ja nao aceita ninguem.
func join(peer: int, team: int, is_bot: bool, tick: int) -> bool:
	var full := _seats.size() >= SLOT_TEAMS.size()
	if not _open or state != MatchState.State.LOBBY_WAIT or full or _seat(peer) != null:
		return false
	var seat := Seat.new()
	seat.peer = peer
	seat.team = team
	seat.is_bot = is_bot
	_seats.append(seat)
	if _seats.size() == SLOT_TEAMS.size():
		_enter(MatchState.State.HERO_PICK, tick, tick + _ticks(rules.hero_pick_duration))
	return true


## Servidor: no lobby a vaga fica livre; depois o jogador so passa a desconectado.
func leave(peer: int, _tick: int) -> void:
	var seat := _seat(peer)
	if seat == null:
		return
	if state == MatchState.State.LOBBY_WAIT:
		_seats.erase(seat)
	else:
		seat.connected = false


## Servidor: lock-in. Recusa fora da selecao, peer de fora, repetido ou heroi indisponivel;
## espelho e aceito. Com os dois confirmados, comeca a fase 1.
func submit_pick(peer: int, hero: StringName, tick: int) -> bool:
	var seat := _seat(peer)
	if state != MatchState.State.HERO_PICK or seat == null or seat.hero != &"":
		return false
	if not PickRules.can_pick(hero, available_heroes):
		return false
	seat.hero = hero
	_picked.rpc(tick, peer, Ids.to_int(hero))
	if _seats.all(func(s: Seat) -> bool: return s.hero != &""):
		_start_phase1(tick)
	return true


## Servidor: prazos de espera e de selecao.
func update(tick: int) -> void:
	if not _open:
		return
	if state == MatchState.State.LOBBY_WAIT and tick >= deadline_tick:
		_enter(MatchState.State.ENDED, tick)
		_ended.rpc(tick, NO_WINNER, REASON_ABANDONED)
	elif state == MatchState.State.HERO_PICK and tick >= deadline_tick:
		_start_phase1(tick)


## Servidor: morte e subida de nivel de cada heroi, avisadas uma vez por mudanca.
func watch_heroes(tick: int) -> void:
	for node: Node in get_tree().get_nodes_in_group(Hero.GROUP):
		var hero := node as Hero
		var dead := not hero.is_alive()
		if dead and not _dead.get(hero.peer_id, false):
			_on_hero_died(hero, tick)
		_dead[hero.peer_id] = dead
		var shown: int = _levels.get(hero.peer_id, hero.level)
		if hero.level > shown:
			_leveled.rpc(tick, hero.peer_id, hero.level)
		_levels[hero.peer_id] = maxi(hero.level, shown)


## Servidor: bau aberto por [param peer] (SpawnDirector.chest_opened).
func report_chest_opened(peer: int, chest_uid: int, tick: int) -> void:
	_chest_opened.rpc(tick, peer, chest_uid)


## Cliente -> servidor: lock-in do heroi (numero de Ids). Valor do cliente: validado aqui.
@rpc("any_peer", "call_local", "reliable")
func submit_hero_selection(hero_id: int) -> void:
	if not multiplayer.is_server():
		return
	var peer := multiplayer.get_remote_sender_id()
	if peer == 0:
		peer = multiplayer.get_unique_id()
	if not submit_pick(peer, Ids.to_name(hero_id), NetworkTime.tick):
		if not _refusals_logged.has(peer):
			_refusals_logged[peer] = true
			print("[match] lock-in recusado: peer %d, heroi %d" % [peer, hero_id])


func _seat(peer: int) -> Seat:
	for seat: Seat in _seats:
		if seat.peer == peer:
			return seat
	return null


func _ticks(seconds: float) -> int:
	return SkillRules.seconds_to_ticks(seconds, _tickrate)


## Quem nao confirmou fica com o padrao do slot; depois relogio e herois.
func _start_phase1(tick: int) -> void:
	for seat: Seat in _seats:
		if seat.hero == &"":
			var slot := SLOT_TEAMS.find(seat.team)
			seat.hero = PickRules.default_hero(rules.default_heroes, slot, available_heroes)
			_picked.rpc(tick, seat.peer, Ids.to_int(seat.hero))
	_enter(MatchState.State.PHASE1, tick)
	clock.start(tick, _tickrate, start_seconds)


## Servidor: muda o estado em todos (quem ouve phase_changed no servidor spawna os herois) e
## ajusta o respawn dos herois a fase nova.
func _enter(to: MatchState.State, tick: int, p_deadline_tick: int = 0) -> void:
	print("[match] %s -> %s, tick %d" % [_name(state), _name(to), tick])
	_changed.rpc(state, to, p_deadline_tick, tick)
	for node: Node in get_tree().get_nodes_in_group(Hero.GROUP):
		(node as Hero).respawn_seconds = KillRules.respawn_seconds(rules, state)


func _name(value: MatchState.State) -> String:
	return MatchState.State.keys()[value]


## XP ao heroi que deu o golpe final (monstro nao ganha); kill so na fase 2.
func _on_hero_died(victim: Hero, tick: int) -> void:
	var killer: Hero = null
	for node: Node in get_tree().get_nodes_in_group(Hero.GROUP):
		var hero := node as Hero
		if hero.peer_id == victim.killer_id and hero != victim:
			killer = hero
	var killer_id := 0 if killer == null else killer.peer_id
	if killer != null:
		var reward := HitEffect.new()
		reward.xp = XpTable.pvp_kill_xp(rules, MatchState.is_phase2(state), victim.level)
		var source := HitLedger.source_key(victim.peer_id, HitLedger.Slot.REWARD)
		killer.receive_hit(tick + 1, source, reward)
		NetworkRollback.mutate(killer, tick + 1)
		if KillRules.counts_kill(state):
			_kills[killer_id] = kills(killer_id) + 1
	print("[match] heroi %d morto por %d, tick %d" % [victim.peer_id, killer_id, tick])
	_died.rpc(tick, victim.peer_id, killer_id)


@rpc("authority", "call_local", "reliable")
func _changed(from: int, to: int, p_deadline_tick: int, tick: int) -> void:
	state = to as MatchState.State
	deadline_tick = p_deadline_tick
	phase_changed.emit(from, to, tick)


@rpc("authority", "call_local", "reliable")
func _picked(tick: int, peer: int, hero_id: int) -> void:
	hero_picked.emit(peer, hero_id, tick)


@rpc("authority", "call_local", "reliable")
func _died(tick: int, peer: int, killer: int) -> void:
	player_died.emit(peer, killer, tick)


@rpc("authority", "call_local", "reliable")
func _leveled(tick: int, peer: int, level: int) -> void:
	player_leveled.emit(peer, level, tick)


@rpc("authority", "call_local", "reliable")
func _chest_opened(tick: int, peer: int, chest_uid: int) -> void:
	chest_opened.emit(peer, chest_uid, tick)


@rpc("authority", "call_local", "reliable")
func _ended(tick: int, winner: int, reason: StringName) -> void:
	match_ended.emit(winner, reason, tick)


func _on_network_tick(_delta: float, tick: int) -> void:
	if not _open:
		return
	update(tick)
	watch_heroes(tick)


func _on_clock_phase1_ended(tick: int) -> void:
	if _open and state == MatchState.State.PHASE1:
		_enter(MatchState.State.TRANSITION, tick)
