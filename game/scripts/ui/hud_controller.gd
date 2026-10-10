class_name HudController
extends Node
## Troca a HUD pela fase (ARCHITECTURE-GAME §3.6): a da fase 1 ate a PHASE1; da TRANSITION
## (5:00) em diante, a da fase 2. As duas so consomem sinais e estado replicado; esta classe so
## liga as duas ao heroi local e ao mundo e escolhe qual aparece em phase_changed.

var _hero: Hero

@onready var _phase1: HudPhase1 = $HudPhase1
@onready var _phase2: HudPhase2 = $HudPhase2


## Ligada a um heroi que ainda existe (se ele sair, o main liga de novo).
func is_bound() -> bool:
	return is_instance_valid(_hero)


func bind(
	hero: Hero,
	clock: MatchClock,
	spawns: SpawnDirector,
	players: Node,
	match_controller: MatchController,
	zone: ZoneController
) -> void:
	_phase1.bind(hero, clock, spawns, players)
	_phase2.bind(hero, clock, spawns, players, match_controller, zone)
	if not match_controller.phase_changed.is_connected(_on_match_phase_changed):
		match_controller.phase_changed.connect(_on_match_phase_changed)
	_hero = hero
	_show(match_controller.state)


func _show(state: int) -> void:
	var phase2 := state >= MatchState.State.TRANSITION
	_phase1.set_active(not phase2)
	_phase2.set_active(phase2)


func _on_match_phase_changed(_from: int, to: int, _tick: int) -> void:
	_show(to)
