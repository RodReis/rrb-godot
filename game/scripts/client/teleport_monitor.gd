class_name TeleportMonitor
extends Node
## Cliente online: conta os teleportes (salto visual por correcao de rede) de todos os herois que
## aparecem na tela e entrega o total ao servidor no fim da partida (F29, SPEC-029 §3.2). So o que
## o jogador ve: roda por quadro renderizado, depois da interpolacao. Nao existe no servidor
## headless, no treino offline nem no tutorial.

const RULES: String = "res://shared/data/rules/teleport_rules.tres"

var detector: TeleportDetector

## Definidos pelo main antes de entrar na arvore.
var players: Node3D
var match_controller: MatchController

var _was_alive: Dictionary[int, bool] = {}
var _was_shown: Dictionary[int, bool] = {}


func _ready() -> void:
	detector = TeleportDetector.new(load(RULES) as TeleportRules)


func _process(delta: float) -> void:
	if not MatchState.is_running(match_controller.state):
		return
	for node: Node in players.get_children():
		var hero := node as Hero
		if hero != null:
			_observe(hero, delta)


## Total de teleportes de todos os herois vistos na partida.
func total() -> int:
	return detector.total()


func _observe(hero: Hero, delta: float) -> void:
	var key := hero.peer_id
	var alive := hero.is_alive()
	var shown := hero.visible
	var exempt := TeleportDetector.is_exempt(
		alive,
		_was_alive.get(key, false),
		shown,
		_was_shown.get(key, false),
		hero.dash_ticks > 0 or hero.knockback_ticks > 0,
		PlayerInput.cinematic
	)
	detector.observe(key, hero.global_position, delta, hero.velocity.length(), exempt)
	_was_alive[key] = alive
	_was_shown[key] = shown
