class_name CurseMarks
extends Node
## Marcas de Maldicao e Praga do Ocultista sobre qualquer alvo (F77, SPEC-077 §VFX), so cliente
## (filho do VfxSpawner). Vale para os dois lados: le o estado replicado do alvo (Hero e Monster:
## curse_stacks, dot_ticks), nao um evento. Um unico _process percorre os alvos (sem alocacao);
## o CurseIndicator de cada um nasce so na 1a vez que ele tem marca ou Praga e dorme ocioso.

const INDICATOR: PackedScene = preload("res://scenes/vfx/curse_indicator.tscn")

var _tracked: Array[Combatant] = []
var _indicators: Dictionary[Combatant, CurseIndicator] = {}


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
		var bar: WorldHealthBar = (
			(combatant as Hero).hp_bar if combatant is Hero else (combatant as Monster).hp_bar
		)
		indicator = INDICATOR.instantiate() as CurseIndicator
		add_child(indicator)
		indicator.bind(combatant, bar.position.y)
		_indicators[combatant] = indicator
	var shown := combatant.is_alive() and combatant.is_shown() and not PlayerInput.cinematic
	indicator.apply(stacks, plague, shown)


## Alvo que saiu da arvore (monstro liberado, heroi que desconectou): solta o indicador dele.
func _on_combatant_tree_exiting(combatant: Combatant) -> void:
	_tracked.erase(combatant)
	var indicator: CurseIndicator = _indicators.get(combatant)
	if indicator != null:
		indicator.queue_free()
		_indicators.erase(combatant)


func _on_tree_node_added(node: Node) -> void:
	_track(node)
