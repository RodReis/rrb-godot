class_name MatchController
extends Node
## Ciclo da partida (CONVENTION §3, ARCHITECTURE-GAME §3.3): LOBBY_WAIT -> HERO_PICK -> PHASE1
## -> TRANSITION -> PHASE2 -> SUDDEN_DEATH -> ENDED, sobre o MatchClock em ticks. Fase 2 (F16):
## zona ligada (ZoneController), kills e dano no KillTracker, respawn desligado na morte subita e
## fim por VictoryRules a cada morte, na morte subita e no colapso (10:00). A FSM,
## as vagas e a selecao rodam so no servidor (open()); nos clientes este no so recebe os eventos
## discretos por RPC confiavel com tick e os repassa como sinais para a UI. Mortes e niveis saem
## do estado replicado dos herois, uma vez por mudanca (ressimulacao nao duplica evento); o XP do
## abate vai pelo ledger do matador (§3.2). Sem nenhum caso de modo offline: o bot e uma vaga.

signal phase_changed(from: int, to: int, tick: int)
signal hero_picked(peer: int, hero_id: int, tick: int)
signal player_died(peer: int, killer: int, tick: int)
signal player_leveled(peer: int, level: int, tick: int)
signal chest_opened(peer: int, chest_uid: int, tick: int)
## Kill da fase 2: [param total] = kills de [param peer] na partida (HUD da fase 2, F17).
signal kill_scored(peer: int, total: int, tick: int)
## stats: peer -> {"kills": kills na fase 2, "hero_damage": dano causado em herois}.
signal match_ended(winner: int, reason: StringName, stats: Dictionary, tick: int)

const NO_WINNER: int = VictoryRules.NO_WINNER
const REASON_ABANDONED: StringName = VictoryRules.ABANDONED
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
## Opcional (testes sem zona).
@export var zone: ZoneController

## Servidor: herois com cena (a Arqueira entra no F14).
var available_heroes: Array[StringName] = []
## Servidor: segundos em que o relogio da fase 1 comeca (dev, --time).
var start_seconds: float = 0.0
## Servidor: seed da partida (a dos baus) para o sorteio do colapso.
var match_seed: int = 0
## Espelhado nos clientes pelo RPC de fase.
var state: MatchState.State = MatchState.State.LOBBY_WAIT
## Fim da espera ou da selecao em ticks; o cliente conta o tempo a partir do tick do evento.
var deadline_tick: int = 0

var _open: bool = false
var _tickrate: int = 0
var _seats: Array[Seat] = []
var _tracker: KillTracker = KillTracker.new()
var _dead: Dictionary = {}  # peer -> morto no ultimo tick visto
var _levels: Dictionary = {}  # peer -> maior nivel ja avisado
var _refusals_logged: Dictionary = {}  # peer -> true: log de lock-in recusado uma vez por peer


func _ready() -> void:
	NetworkTime.on_tick.connect(_on_network_tick)
	if clock != null:
		clock.phase1_ended.connect(_on_clock_phase1_ended)
		clock.transition_ended.connect(_on_clock_transition_ended)
		clock.sudden_death_started.connect(_on_clock_sudden_death_started)
		clock.collapsed.connect(_on_clock_collapsed)


## Servidor: comeca a esperar os jogadores.
func open(tick: int, tickrate: int) -> void:
	_open = true
	_tickrate = tickrate
	deadline_tick = tick + _ticks(rules.lobby_wait_timeout)


func seats() -> Array[Seat]:
	return _seats


func kills(peer: int) -> int:
	return _tracker.kills(peer)


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


## Servidor: no lobby a vaga fica livre; depois o jogador so passa a desconectado. Quem cai na
## selecao sem confirmar fica com o padrao do slot na hora (o outro nao espera o prazo todo).
func leave(peer: int, tick: int) -> void:
	var seat := _seat(peer)
	if seat == null:
		return
	if state == MatchState.State.LOBBY_WAIT:
		_seats.erase(seat)
		return
	seat.connected = false
	if state == MatchState.State.HERO_PICK and seat.hero == &"":
		_pick_default(seat, tick)
		_start_if_all_picked(tick)


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
	_start_if_all_picked(tick)
	return true


## Servidor: prazos de espera e de selecao.
func update(tick: int) -> void:
	if not _open:
		return
	if state == MatchState.State.LOBBY_WAIT and tick >= deadline_tick:
		_finish(tick, NO_WINNER, REASON_ABANDONED)
	elif state == MatchState.State.HERO_PICK and tick >= deadline_tick:
		_start_phase1(tick)


## Servidor: morte e subida de nivel de cada heroi, avisadas uma vez por mudanca.
# ponytail: a morte vista aqui e definitiva (evento, XP, kill); se uma ressimulacao posterior
# desfizer o golpe (input atrasado), o efeito fica. Raro e servidor segue autoritativo, como no
# Chest e no Monster; esperar o history_limit antes de anunciar se isso aparecer em jogo.
func watch_heroes(tick: int) -> void:
	if state == MatchState.State.ENDED:
		return
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


func _pick_default(seat: Seat, tick: int) -> void:
	var slot := SLOT_TEAMS.find(seat.team)
	seat.hero = PickRules.default_hero(rules.default_heroes, slot, available_heroes)
	_picked.rpc(tick, seat.peer, Ids.to_int(seat.hero))


func _start_if_all_picked(tick: int) -> void:
	if _seats.all(func(s: Seat) -> bool: return s.hero != &""):
		_start_phase1(tick)


## Quem nao confirmou fica com o padrao do slot; depois relogio e herois.
func _start_phase1(tick: int) -> void:
	for seat: Seat in _seats:
		if seat.hero == &"":
			_pick_default(seat, tick)
	_enter(MatchState.State.PHASE1, tick)
	clock.start(tick, _tickrate, start_seconds)


## Servidor: muda o estado em todos (quem ouve phase_changed no servidor spawna os herois) e
## ajusta a fase nova: respawn (tempo; desligado na morte subita), fonte da base (so na fase 1)
## e zona (fase 2).
func _enter(to: MatchState.State, tick: int, p_deadline_tick: int = 0) -> void:
	print("[match] %s -> %s, tick %d" % [_name(state), _name(to), tick])
	_changed.rpc(state, to, p_deadline_tick, tick)
	for node: Node in get_tree().get_nodes_in_group(Hero.GROUP):
		var hero := node as Hero
		hero.respawn_seconds = KillRules.respawn_seconds(rules, state)
		if not KillRules.respawns(state):
			hero.respawn_off_tick = mini(hero.respawn_off_tick, tick)
		hero.fountain_open = state == MatchState.State.PHASE1
	if zone != null:
		zone.active = MatchState.is_phase2(state)


func _name(value: MatchState.State) -> String:
	return MatchState.State.keys()[value]


## Fim: avisa todos com o placar; o processo do servidor dedicado encerra (main).
func _finish(tick: int, winner: int, reason: StringName) -> void:
	_enter(MatchState.State.ENDED, tick)
	_ended.rpc(tick, winner, reason, _stats())


## Fase 2: VictoryRules na ordem do GDB §7.2; acabou, encerra.
func _judge(tick: int, collapsed: bool) -> void:
	var sudden_death := state == MatchState.State.SUDDEN_DEATH
	var verdict := VictoryRules.evaluate(
		_contenders(), rules.kill_goal, sudden_death, collapsed, match_seed
	)
	if verdict.is_over():
		_finish(tick, verdict.winner, verdict.reason)


func _heroes() -> Array[Hero]:
	var result: Array[Hero] = []
	for node: Node in get_tree().get_nodes_in_group(Hero.GROUP):
		result.append(node as Hero)
	return result


## Uma vaga, um jogador; vaga sem heroi conta como morta.
func _contenders() -> Array[VictoryRules.Contender]:
	var heroes := _heroes()
	var result: Array[VictoryRules.Contender] = []
	for seat: Seat in _seats:
		var contender := VictoryRules.Contender.new()
		contender.peer = seat.peer
		contender.connected = seat.connected
		contender.alive = false
		contender.kills = kills(seat.peer)
		contender.damage = _tracker.damage_dealt(seat.peer, heroes)
		for hero: Hero in heroes:
			if hero.peer_id == seat.peer:
				contender.alive = hero.is_alive()
				contender.hp_pct = float(hero.hp) / hero.attributes.max_hp
		result.append(contender)
	return result


func _stats() -> Dictionary:
	var heroes := _heroes()
	var result := {}
	for seat: Seat in _seats:
		result[seat.peer] = {
			"kills": kills(seat.peer),
			"hero_damage": _tracker.damage_dealt(seat.peer, heroes),
		}
	return result


## XP ao heroi que deu o golpe final (monstro e zona nao ganham); kill so na fase 2. Na fase 2
## toda morte pode encerrar a partida (meta de kills, eliminacao na morte subita).
func _on_hero_died(victim: Hero, tick: int) -> void:
	var killer: Hero = null
	for node: Node in get_tree().get_nodes_in_group(Hero.GROUP):
		var hero := node as Hero
		if hero.peer_id == victim.killer_id and hero != victim:
			killer = hero
	var killer_id := 0 if killer == null else killer.peer_id
	if killer != null:
		var reward := HitEffect.new()
		reward.xp = KillTracker.reward_xp(rules, state, victim.level)
		var source := HitLedger.source_key(victim.peer_id, HitLedger.Slot.REWARD)
		killer.receive_hit(tick + 1, source, reward)
		NetworkRollback.mutate(killer, tick + 1)
	var scored := _tracker.score(killer_id, state)
	print("[match] heroi %d morto por %d, tick %d" % [victim.peer_id, killer_id, tick])
	_died.rpc(tick, victim.peer_id, killer_id)
	if scored:
		_scored.rpc(tick, killer_id, kills(killer_id))
	if MatchState.is_phase2(state):
		_judge(tick, false)


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
func _scored(tick: int, peer: int, total: int) -> void:
	kill_scored.emit(peer, total, tick)


@rpc("authority", "call_local", "reliable")
func _leveled(tick: int, peer: int, level: int) -> void:
	player_leveled.emit(peer, level, tick)


@rpc("authority", "call_local", "reliable")
func _chest_opened(tick: int, peer: int, chest_uid: int) -> void:
	chest_opened.emit(peer, chest_uid, tick)


@rpc("authority", "call_local", "reliable")
func _ended(tick: int, winner: int, reason: StringName, stats: Dictionary) -> void:
	match_ended.emit(winner, reason, stats, tick)


func _on_network_tick(_delta: float, tick: int) -> void:
	if not _open:
		return
	update(tick)
	watch_heroes(tick)


func _on_clock_phase1_ended(tick: int) -> void:
	if _open and state == MatchState.State.PHASE1:
		_enter(MatchState.State.TRANSITION, tick)


func _on_clock_transition_ended(tick: int) -> void:
	if _open and state == MatchState.State.TRANSITION:
		_enter(MatchState.State.PHASE2, tick)


## 9:00: respawn desliga; quem ja esta morto fica morto e pode encerrar na hora. O relogio roda
## antes deste no no tick: as mortes do tick entram antes do julgamento.
func _on_clock_sudden_death_started(tick: int) -> void:
	if _open and state == MatchState.State.PHASE2:
		watch_heroes(tick)
		if state == MatchState.State.PHASE2:
			_enter(MatchState.State.SUDDEN_DEATH, tick)
			_judge(tick, false)


## 10:00: resolucao imediata (I1).
func _on_clock_collapsed(tick: int) -> void:
	if _open and state == MatchState.State.SUDDEN_DEATH:
		watch_heroes(tick)
		if state == MatchState.State.SUDDEN_DEATH:
			_judge(tick, true)
