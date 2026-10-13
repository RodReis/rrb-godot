class_name Bestiary
extends CanvasLayer
## Bestiario em partida (DV tela 5, PI 2026-10-09): B abre e fecha, Esc fecha. Duas abas (F62,
## ADR-0014): Heroi (ficha do heroi local, HeroSheet; abre primeiro quando ha heroi) e Monstros
## (lista + ficha + preview 3D dos monstros de shared/data/monsters). Nao pausa a partida;
## enquanto aberto o heroi local fica parado (PlayerInput.suspended).

const TITLE_HERO: String = "FICHA DO HERÓI"
const TITLE_MONSTERS: String = "BESTIÁRIO DA ARENA"

@export var monsters: Array[MonsterData] = []

@onready var _list: CatalogList = %List
@onready var _detail: DetailCard = %Detail
@onready var _preview: MonsterPreview3D = %Preview
@onready var _title: Label = %Title
@onready var _hero_tab: Button = %HeroTab
@onready var _monster_tab: Button = %MonsterTab
@onready var _hero_sheet: HeroSheet = %HeroSheet
@onready var _monster_body: Control = %Body


func _ready() -> void:
	visible = false
	_list.selected.connect(_on_list_selected)
	_hero_tab.pressed.connect(show_hero)
	_monster_tab.pressed.connect(show_monsters)


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


## Liga a aba Heroi ao heroi do jogador deste processo.
func bind_hero(hero: Hero) -> void:
	_hero_sheet.bind(hero)


func open() -> void:
	if _list.get_child_count() == 0:
		_build()  # so na primeira vez: o servidor dedicado nunca abre e nao carrega nada
	visible = true
	PlayerInput.suspended = true
	_hero_tab.disabled = not _hero_sheet.has_hero()  # selecao: heroi ainda nao nasceu
	if _hero_tab.disabled:
		show_monsters()
	else:
		show_hero()


func show_hero() -> void:
	if not _hero_sheet.has_hero():
		show_monsters()
		return
	_hero_sheet.refresh()
	_set_tab(true)


func show_monsters() -> void:
	_set_tab(false)
	_list.focus_selected()


func is_hero_tab() -> bool:
	return _hero_sheet.visible


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


func _set_tab(hero: bool) -> void:
	_hero_sheet.visible = hero
	_monster_body.visible = not hero
	_hero_tab.set_pressed_no_signal(hero)
	_monster_tab.set_pressed_no_signal(not hero)
	_title.text = tr(TITLE_HERO if hero else TITLE_MONSTERS)


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
