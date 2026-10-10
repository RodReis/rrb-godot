class_name MatchClock
extends Node
## Relogio da partida em ticks (ARCHITECTURE-GAME §3.3): aviso do boss, boss, fim da fase 1,
## fim da transicao, morte subita (9:00) e colapso (10:00) nos tempos de MatchRules (GDB §7.1).
## O servidor da start(); o tick de inicio vai aos clientes por RPC confiavel e os dois lados
## rodam update() no proprio tick do netfox, entao os eventos saem no mesmo tick nos dois. Base
## do MatchController.

signal boss_warning(tick: int)
signal boss_spawned(tick: int)
signal phase1_ended(tick: int)
signal transition_ended(tick: int)
signal sudden_death_started(tick: int)
signal collapsed(tick: int)

const GROUP: StringName = &"match_clock"

@export var rules: MatchRules

## Valido so com is_started() (pode ser negativo com --time adiantado).
var start_tick: int = 0

var _started: bool = false
var _tickrate: int = 0
var _event_ticks: PackedInt64Array = PackedInt64Array()
var _events: Array[Signal] = []
var _next_event: int = 0


func _ready() -> void:
	add_to_group(GROUP)
	NetworkTime.on_tick.connect(_on_network_tick)


func is_started() -> bool:
	return _started


## Servidor apenas. [param elapsed_seconds] > 0 comeca adiantado (dev, --time). Repetir e ignorado.
func start(tick: int, tickrate: int, elapsed_seconds: float = 0.0) -> void:
	if is_started():
		return
	_begin.rpc(tick - SkillRules.seconds_to_ticks(elapsed_seconds, tickrate), tickrate)


## Segundos desde o inicio; 0 antes de comecar.
func elapsed(tick: int) -> float:
	if not is_started():
		return 0.0
	return float(tick - start_tick) / _tickrate


## Segundos desde o inicio da fase 2 (5:00; negativo antes). A TRANSITION ja conta.
func phase2_elapsed(tick: int) -> float:
	return elapsed(tick) - rules.phase1_duration


## Emite, uma vez cada, os eventos cujo tick ja chegou.
func update(tick: int) -> void:
	while _next_event < _events.size() and tick >= _event_ticks[_next_event]:
		_events[_next_event].emit(tick)
		_next_event += 1


@rpc("authority", "call_local", "reliable")
func _begin(p_start_tick: int, tickrate: int) -> void:
	if is_started():
		return
	_started = true
	start_tick = p_start_tick
	_tickrate = tickrate
	_events = [
		boss_warning, boss_spawned, phase1_ended, transition_ended, sudden_death_started, collapsed
	]
	var times: Array[float] = [
		rules.boss_warning_time,
		rules.boss_spawn_time,
		rules.phase1_duration,
		rules.phase1_duration + rules.transition_duration,
		rules.phase1_duration + rules.respawn_off_at,
		rules.max_match_duration,
	]
	_event_ticks = PackedInt64Array()
	for seconds: float in times:
		_event_ticks.append(start_tick + SkillRules.seconds_to_ticks(seconds, tickrate))


func _on_network_tick(_delta: float, tick: int) -> void:
	update(tick)
