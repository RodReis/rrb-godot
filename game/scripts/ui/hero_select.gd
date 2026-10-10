class_name HeroSelect
extends CanvasLayer
## Selecao de herois (DV tela 2, CONVENTION §3, PATTERNS P9/P11): aberta pelo main na HERO_PICK
## e fechada quando ela acaba. 1/2 escolhem, Espaco ou o botao confirma; o lock-in vai ao
## servidor por RPC e so vale quando volta como hero_picked (inclusive o padrao do timeout).
## Heroi sem cena aparece indisponivel. So le sinais e dados; quem decide e o servidor.

const KEYS: Array[Key] = [KEY_1, KEY_2]
const STAT_NAMES: Array[String] = ["HP", "DEF", "ATK", "INT", "AGI"]
const MSEC_PER_SECOND: float = 1000.0

var _match: MatchController
var _roster: Array[HeroData] = []
var _available: Array[StringName] = []
var _buttons: Array[Button] = []
## Maior valor de cada atributo entre os herois: as barras ficam comparaveis (PATTERNS P9).
var _stat_max: PackedFloat64Array = PackedFloat64Array()
var _selected: int = -1
## Lock-in enviado e ainda nao confirmado, ou confirmado: a escolha nao muda mais.
var _requested: bool = false
var _ends_msec: int = 0

@onready var _timer: TimerLabel = %Timer
@onready var _choices: HBoxContainer = %Choices
@onready var _player_preview: MonsterPreview3D = %PlayerPreview
@onready var _player_name: Label = %PlayerName
@onready var _stats: Array[StatBar] = [%Hp, %Def, %Atk, %Int, %Agi]
@onready var _skills: Label = %Skills
@onready var _lock_in: Button = %LockIn
@onready var _status: Label = %Status
@onready var _enemy_preview: MonsterPreview3D = %EnemyPreview
@onready var _enemy_name: Label = %EnemyName
@onready var _enemy_status: Label = %EnemyStatus


func _ready() -> void:
	visible = false
	set_process(false)
	_lock_in.pressed.connect(lock_in)


func _process(_delta: float) -> void:
	_timer.set_seconds(maxf((_ends_msec - Time.get_ticks_msec()) / MSEC_PER_SECOND, 0.0))


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	var key := event as InputEventKey
	if key != null and key.pressed and not key.echo and KEYS.has(key.keycode):
		select(KEYS.find(key.keycode))
	elif event.is_action_pressed(&"ui_accept"):
		lock_in()
	else:
		return
	get_viewport().set_input_as_handled()


## Liga a tela a partida: [param roster] = herois mostrados, [param available] = os com cena.
func bind(
	match_controller: MatchController, roster: Array[HeroData], available: Array[StringName]
) -> void:
	_match = match_controller
	_roster = roster
	_available = available
	_stat_max = PackedFloat64Array()
	for i: int in STAT_NAMES.size():
		var best := 0.0
		for data: HeroData in roster:
			best = maxf(best, _stat_values(data)[i])
		_stat_max.append(best)
	_build_choices()
	_match.hero_picked.connect(_on_match_hero_picked)


## Abre com [param seconds] de selecao pela frente.
func open(seconds: float) -> void:
	_requested = false
	_ends_msec = Time.get_ticks_msec() + roundi(seconds * MSEC_PER_SECOND)
	_status.text = tr("Escolha e confirme antes do fim do tempo")
	_enemy_name.text = tr("ADVERSÁRIO")
	_enemy_status.text = tr("Escolhendo...")
	_enemy_preview.show_model(null)
	visible = true
	set_process(true)
	_selected = -1
	select(_roster.find_custom(func(d: HeroData) -> bool: return _available.has(d.id)))
	_lock_in.grab_focus()


func close() -> void:
	visible = false
	set_process(false)
	_player_preview.show_model(null)
	_enemy_preview.show_model(null)


## Mostra o heroi [param index] do roster; ignorado se indisponivel ou ja confirmado.
func select(index: int) -> void:
	if _requested or index < 0 or index >= _roster.size() or index == _selected:
		return
	if not _available.has(_roster[index].id):
		return
	_show(index)


## Envia o lock-in do heroi mostrado ao servidor (uma vez).
func lock_in() -> void:
	if _requested or _selected < 0:
		return
	_requested = true
	_status.text = tr("Confirmando...")
	_refresh_buttons()
	_match.submit_hero_selection.rpc_id(1, Ids.to_int(_roster[_selected].id))


## So o visual do heroi: o no Model da cena, com as pecas que o heroi nao usa escondidas.
static func model_of(hero_id: StringName) -> Node3D:
	var path := Hero.SCENE_PATH % hero_id
	if not ResourceLoader.exists(path):
		return null
	var instance := (load(path) as PackedScene).instantiate()
	var model := instance.get_node_or_null("Model") as Node3D
	var visual := instance.get_node_or_null("Visual")
	if model != null:
		instance.remove_child(model)
	if model != null and visual != null:
		for part: StringName in visual.get(&"hidden_parts"):
			var node := model.find_child(part) as Node3D
			if node != null:
				node.hide()
	instance.free()
	return model


static func _stat_values(data: HeroData) -> PackedFloat64Array:
	return PackedFloat64Array(
		[
			data.base_hp,
			data.base_defense,
			data.base_attack,
			data.base_intelligence,
			data.base_agility,
		]
	)


func _build_choices() -> void:
	for i: int in _roster.size():
		var data := _roster[i]
		var badge := HotkeyBadge.new()
		badge.key = OS.get_keycode_string(KEYS[i]) if i < KEYS.size() else ""
		var button := Button.new()
		button.custom_minimum_size.y = UiTokens.SIZE_TARGET_MIN
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.text = data.display_name.to_upper()
		if not _available.has(data.id):
			button.text += " · " + tr("INDISPONÍVEL")
			button.disabled = true
		button.pressed.connect(select.bind(i))
		_choices.add_child(badge)
		_choices.add_child(button)
		_buttons.append(button)


func _show(index: int) -> void:
	_selected = index
	var data := _roster[index]
	_player_name.text = data.display_name.to_upper()
	var values := _stat_values(data)
	for i: int in _stats.size():
		_stats[i].bind(STAT_NAMES[i], values[i], _stat_max[i], StatBar.Kind.STAT)
	_skills.text = (
		"\n"
		. join(
			PackedStringArray(
				[
					"[Q] %s" % data.skill_q.display_name,
					"[E] %s" % data.skill_e.display_name,
					"[R] %s" % data.skill_r.display_name,
				]
			)
		)
	)
	_player_preview.show_model(model_of(data.id))
	_refresh_buttons()


func _refresh_buttons() -> void:
	for i: int in _buttons.size():
		_buttons[i].disabled = _requested or not _available.has(_roster[i].id)
		_buttons[i].theme_type_variation = &"ButtonPrimary" if i == _selected else &""
	_lock_in.disabled = _requested


func _hero_index(hero_id: int) -> int:
	var id := Ids.to_name(hero_id)
	return _roster.find_custom(func(d: HeroData) -> bool: return d.id == id)


## Confirmacao do servidor: a minha (escolha ou padrao do timeout) ou a do adversario
## (espelho permitido).
func _on_match_hero_picked(peer: int, hero_id: int, _tick: int) -> void:
	var index := _hero_index(hero_id)
	if not visible or index < 0:
		return  # fechada (servidor dedicado nunca abre): nada a mostrar
	if peer == multiplayer.get_unique_id():
		_requested = false
		_selected = -1
		_show(index)
		_requested = true
		_refresh_buttons()
		_status.text = tr("PRONTO — aguardando o adversário")
		return
	_enemy_name.text = _roster[index].display_name.to_upper()
	_enemy_status.text = tr("PRONTO")
	_enemy_preview.show_model(model_of(_roster[index].id))
