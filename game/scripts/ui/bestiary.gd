class_name Bestiary
extends CanvasLayer
## Bestiario em partida (DV tela 5, PI 2026-10-09): B abre e fecha, Esc fecha. Lista + ficha +
## preview 3D dos monstros de shared/data/monsters. Nao pausa a partida; enquanto aberto o
## heroi local fica parado (PlayerInput.suspended).

@export var monsters: Array[MonsterData] = []

@onready var _list: CatalogList = %List
@onready var _detail: DetailCard = %Detail
@onready var _preview: MonsterPreview3D = %Preview


func _ready() -> void:
	visible = false
	_list.selected.connect(_on_list_selected)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(InputActions.OPEN_BESTIARY):
		toggle()
	elif visible and event.is_action_pressed(InputActions.CANCEL):
		close()
	else:
		return
	get_viewport().set_input_as_handled()


func _exit_tree() -> void:
	if visible:
		PlayerInput.suspended = false


func toggle() -> void:
	if visible:
		close()
	else:
		open()


func open() -> void:
	if _list.get_child_count() == 0:
		_build()  # so na primeira vez: o servidor dedicado nunca abre e nao carrega nada
	visible = true
	PlayerInput.suspended = true
	_list.focus_selected()


func close() -> void:
	visible = false
	PlayerInput.suspended = false


## So o visual do monstro: o no Model da cena (sem IA, rede nem grupos). Nulo sem cena.
static func model_of(monster: MonsterData) -> Node3D:
	var path := SpawnDirector.SCENE_PATH % monster.id
	if not ResourceLoader.exists(path):
		push_error("[bestiario] sem cena para o monstro %s" % monster.id)
		return null
	var instance := (load(path) as PackedScene).instantiate()
	var model := instance.get_node_or_null("Model") as Node3D
	if model != null:
		instance.remove_child(model)
	instance.free()
	return model


func _build() -> void:
	var entries: Array[CatalogEntry] = []
	for monster: MonsterData in monsters:
		entries.append(CatalogEntry.new(monster.id, monster.display_name, _tag(monster)))
	_list.bind(entries)


func _tag(monster: MonsterData) -> String:
	return DetailCard.TIER_NAMES[monster.tier]


func _on_list_selected(id: StringName) -> void:
	for monster: MonsterData in monsters:
		if monster.id == id:
			_detail.bind(monster)
			_preview.show_model(model_of(monster))
			return
