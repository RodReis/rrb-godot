class_name CurseMarks
extends Node
## Marcas de Maldicao e Praga do Ocultista sobre qualquer alvo (F77, SPEC-077 §VFX) e a animacao
## do controle (atordoado, preso, lento: StatusMark, PI 2026-10-22), so cliente (filho do
## VfxSpawner). Vale para os dois lados: le o estado replicado do alvo (Hero e Monster:
## curse_stacks, dot_ticks, controle), nao um evento. Um unico _process percorre os alvos (sem
## alocacao); cada indicador nasce so na 1a vez que o alvo precisa dele e dorme ocioso.

const INDICATOR: PackedScene = preload("res://scenes/vfx/curse_indicator.tscn")

var _tracked: Array[Combatant] = []
var _indicators: Dictionary[Combatant, CurseIndicator] = {}
var _statuses: Dictionary[Combatant, StatusMark] = {}


func _ready() -> void:
	get_tree().node_added.connect(_on_tree_node_added)
	for node: Node in get_tree().get_nodes_in_group(Combatant.TARGETS_GROUP):
		_track(node)


func _process(_delta: float) -> void:
	for combatant: Combatant in _tracked:
		_update(combatant)


func _track(node: Node) -> void:
	if not (node is Hero or node is Monster):
		return
	var combatant := node as Combatant
	if _tracked.has(combatant):
		return
	_tracked.append(combatant)
	combatant.tree_exiting.connect(_on_combatant_tree_exiting.bind(combatant), CONNECT_ONE_SHOT)


func _update(combatant: Combatant) -> void:
	_update_status(combatant)
	var stacks := 0
	var plague := false
	if combatant is Hero:
		var hero := combatant as Hero
		stacks = hero.curse_stacks
		plague = hero.dot_ticks > 0
	else:
		var monster := combatant as Monster
		stacks = monster.curse_stacks
		plague = monster.dot_ticks > 0
	var indicator: CurseIndicator = _indicators.get(combatant)
	if indicator == null:
		if stacks == 0 and not plague:
			return
		indicator = INDICATOR.instantiate() as CurseIndicator
		add_child(indicator)
		indicator.bind(combatant, _bar_of(combatant).position.y)
		_indicators[combatant] = indicator
	var shown := combatant.is_alive() and combatant.is_shown() and not PlayerInput.cinematic
	indicator.apply(stacks, plague, shown)


## Atordoado, preso ou lento: o indicador e filho do alvo (segue o corpo, sem interpolar aqui).
func _update_status(combatant: Combatant) -> void:
	var status := _status_of(combatant)
	var indicator: StatusMark = _statuses.get(combatant)
	if indicator == null:
		if status == StatusRules.Status.NONE:
			return
		indicator = StatusMark.new()
		indicator.name = "StatusMark"
		combatant.add_child(indicator)
		indicator.bind(_bar_of(combatant).position.y)
		_statuses[combatant] = indicator
	var shown := combatant.is_alive() and combatant.is_shown() and not PlayerInput.cinematic
	indicator.apply(status, shown)


## Controle do alvo, do estado replicado (o Hero ja esta no teto de metodos publicos do lint).
static func _status_of(combatant: Combatant) -> StatusRules.Status:
	if combatant is Hero:
		var hero := combatant as Hero
		return StatusRules.shown(hero.stun_ticks, hero.slow_ticks, hero.slow_pct)
	return (combatant as Monster).status()


static func _bar_of(combatant: Combatant) -> WorldHealthBar:
	return (combatant as Hero).hp_bar if combatant is Hero else (combatant as Monster).hp_bar


## Alvo que saiu da arvore (monstro liberado, heroi que desconectou): solta o indicador dele.
func _on_combatant_tree_exiting(combatant: Combatant) -> void:
	_tracked.erase(combatant)
	_statuses.erase(combatant)  # filho do alvo: sai junto
	var indicator: CurseIndicator = _indicators.get(combatant)
	if indicator != null:
		indicator.queue_free()
		_indicators.erase(combatant)


func _on_tree_node_added(node: Node) -> void:
	_track(node)
