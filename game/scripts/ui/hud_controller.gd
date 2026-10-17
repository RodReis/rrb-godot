class_name HudController
extends Node
## Troca a HUD pela fase (ARCHITECTURE-GAME §3.6): a da fase 1 ate a PHASE1; da TRANSITION
## (5:00) em diante, a da fase 2. As duas so consomem sinais e estado replicado; esta classe so
## liga as duas ao heroi local e ao mundo e escolhe qual aparece em phase_changed. Tambem liga o
## anel do alvo travado (F66), que vale nas duas fases.

const TARGET_RING: PackedScene = preload("res://scenes/vfx/target_ring.tscn")

var _hero: Hero
var _target_ring: TargetRing

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
	_bind_target_ring(hero)
	if not match_controller.phase_changed.is_connected(_on_match_phase_changed):
		match_controller.phase_changed.connect(_on_match_phase_changed)
	_hero = hero
	_show(match_controller.state)


## O anel e VFX: nasce so em quem desenha, na 1a ligacao (servidor headless nao tem no de VFX).
func _bind_target_ring(hero: Hero) -> void:
	if not VfxSpawner.wanted():
		return
	if _target_ring == null:
		_target_ring = TARGET_RING.instantiate() as TargetRing
		add_child(_target_ring)
	_target_ring.bind(hero)


## Na cinematica de abertura (INTRO, F69) as duas ficam escondidas.
func _show(state: int) -> void:
	var phase2 := state >= MatchState.State.TRANSITION
	var intro := state == MatchState.State.INTRO
	_phase1.set_active(not phase2 and not intro)
	_phase2.set_active(phase2)


func _on_match_phase_changed(_from: int, to: int, _tick: int) -> void:
	_show(to)
