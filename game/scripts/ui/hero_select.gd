class_name HeroSelect
extends CanvasLayer
## Selecao de herois (F51, prototipo docs/prd/telas/Seleção de Heróis; CONVENTION §3): aberta
## pelo main na HERO_PICK e fechada quando ela acaba. Card esquerdo = voce (heroi mostrado),
## grade = so herois com cena, card direito = oponente quando o servidor confirma. 1-9, 0 e -
## escolhem (o 11o heroi, F98, fica no -), Espaco ou o botao confirma; o lock-in vai ao servidor por
## RPC e so vale quando volta como hero_picked (inclusive o padrao do timeout). So le sinais e
## dados; quem decide e o servidor.

const KEYS: Array[Key] = [
	KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_9, KEY_0, KEY_MINUS
]
## Atributos do HeroData com o nome do PRD §4.2.
const STAT_NAMES: Array[String] = [
	"HP (Vida)", "DEF (Defesa)", "ATK (Ataque)", "INT (Inteligência)", "AGI (Agilidade)"
]
## Giro inicial dos previews grandes: 180 = de frente para a camera nos KayKit (MonsterPreview3D).
## Sem isso o modelo entrava de costas e so depois girava (#229).
const PREVIEW_FACING: float = 180.0
const MSEC_PER_SECOND: float = 1000.0
## Barra de atributo (h-3 do prototipo).
const BAR_HEIGHT: float = 14.0
## Opacidade minima do pulso dos pontos de status (animate-pulse).
const PULSE_ALPHA: float = 0.35
## Card nao escolhido depois do lock-in.
const DIM_ALPHA: float = 0.5
## Brilho do lock-in sob o mouse e encolhida ao apertar (active:scale-98).
const HOVER_BRIGHT: Color = Color(1.12, 1.12, 1.12)
const PRESS_SCALE: float = 0.98
## Selo BLOQUEADO entra grande e assenta.
const POP_SCALE: float = 1.3

var _match: MatchController
var _roster: Array[HeroData] = []
var _available: Array[StringName] = []
## Indice do roster -> card da grade (so herois com cena).
var _cards: Dictionary[int, HeroChoice] = {}
## Maior valor de cada atributo entre os herois: as barras ficam comparaveis (PATTERNS P9).
var _stat_max: PackedFloat64Array = PackedFloat64Array()
var _stat_bars: Array[ProgressBar] = []
var _stat_values: Array[Label] = []
var _skill_names: Array[Label] = []
var _skill_cooldowns: Array[Label] = []
var _pulses: Array[Tween] = []
var _selected: int = -1
## Lock-in enviado e ainda nao confirmado, ou confirmado: a escolha nao muda mais.
var _requested: bool = false
var _ends_msec: int = 0
var _rival_icon: Texture2D

@onready var _mode: Label = %Mode
@onready var _timer: TimerLabel = %Timer
@onready var _you_status: Label = %YouStatus
@onready var _rival_status: Label = %RivalStatus
@onready var _you_dot: Panel = %YouDot
@onready var _rival_dot: Panel = %RivalDot
@onready var _player_role: Label = %PlayerRole
@onready var _player_stage: Control = %PlayerStage
@onready var _player_preview: MonsterPreview3D = %PlayerPreview
@onready var _player_locked: Control = %PlayerLocked
@onready var _player_name: Label = %PlayerName
@onready var _player_summary: Label = %PlayerSummary
@onready var _player_icon: TextureRect = %PlayerIcon
@onready var _skills: HBoxContainer = %Skills
@onready var _stats: VBoxContainer = %Stats
@onready var _choices: GridContainer = %Choices
@onready var _lock_in_frame: Control = %LockInFrame
@onready var _lock_in_gradient: Control = %LockInGradient
@onready var _lock_in: Button = %LockIn
@onready var _status: Label = %Status
@onready var _enemy_role_tag: Control = %EnemyRoleTag
@onready var _enemy_role: Label = %EnemyRole
@onready var _enemy_stage: Control = %EnemyStage
@onready var _enemy_unknown: Label = %EnemyUnknown
@onready var _enemy_preview: MonsterPreview3D = %EnemyPreview
@onready var _enemy_locked: Control = %EnemyLocked
@onready var _enemy_name: Label = %EnemyName
@onready var _enemy_summary: Label = %EnemySummary
@onready var _enemy_icon: TextureRect = %EnemyIcon
@onready var _state_dot: Panel = %StateDot
@onready var _enemy_state: Label = %EnemyState


func _ready() -> void:
	visible = false
	set_process(false)
	_rival_icon = _enemy_icon.texture
	_player_preview.facing = PREVIEW_FACING
	_enemy_preview.facing = PREVIEW_FACING
	_build_skills()
	_build_stats()
	_lock_in.pressed.connect(lock_in)
	_lock_in.mouse_entered.connect(_on_lock_in_hover.bind(true))
	_lock_in.mouse_exited.connect(_on_lock_in_hover.bind(false))
	_lock_in.button_down.connect(_on_lock_in_press.bind(true))
	_lock_in.button_up.connect(_on_lock_in_press.bind(false))
	_player_stage.resized.connect(_on_player_stage_resized)
	_mode.resized.connect(_on_mode_resized)


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


## Liga a tela a partida: [param roster] = herois do jogo, [param available] = os com cena (so
## estes entram na grade).
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
			best = maxf(best, _stat_values_of(data)[i])
		_stat_max.append(best)
	_build_choices()
	_match.hero_picked.connect(_on_match_hero_picked)


## Abre com [param seconds] de selecao pela frente.
func open(seconds: float) -> void:
	_requested = false
	_ends_msec = Time.get_ticks_msec() + roundi(seconds * MSEC_PER_SECOND)
	_status.text = tr("ESCOLHA E CONFIRME ANTES DO FIM DO TEMPO")
	_set_status(_you_status, false)
	_player_locked.hide()
	_show_enemy(-1)
	visible = true
	set_process(true)
	_timer.set_state(TimerLabel.State.WARNING)
	for index: int in _cards:
		_cards[index].show_model(model_of(_roster[index].id))
	_start_pulses()
	_selected = -1
	select(_roster.find_custom(func(d: HeroData) -> bool: return _available.has(d.id)))
	_lock_in.grab_focus()


func close() -> void:
	visible = false
	set_process(false)
	_player_preview.show_model(null)
	_enemy_preview.show_model(null)
	for index: int in _cards:
		_cards[index].show_model(null)
	for pulse: Tween in _pulses:
		pulse.kill()
	_pulses.clear()
	_timer.set_state(TimerLabel.State.NORMAL)  # mata o pisca; o open religa


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
	_status.text = tr("CONFIRMANDO...")
	_you_status.text = tr("Status: Confirmando...")
	_refresh_cards()
	_match.submit_hero_selection.rpc_id(1, Ids.to_int(_roster[_selected].id))


## So o visual do heroi: o no Model da cena, com as pecas que o heroi nao usa escondidas, o clipe de
## idle do HeroVisual em meta "idle" (o MonsterPreview3D toca esse), a altura de retrato dele em
## meta "portrait_height" (0 = a padrao do card) e a faixa do card em meta "portrait_band".
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
		model.set_meta(&"idle", visual.get(&"idle"))
		model.set_meta(&"portrait_height", visual.get(&"portrait_height"))
		model.set_meta(&"portrait_band", visual.get(&"portrait_band"))
		model.set_meta(&"portrait_turn", visual.get(&"portrait_turn"))
	instance.free()
	return model


static func _stat_values_of(data: HeroData) -> PackedFloat64Array:
	return PackedFloat64Array(
		[
			data.base_hp,
			data.base_defense,
			data.base_attack,
			data.base_intelligence,
			data.base_agility,
		]
	)


## Recarga no rank 1, sem casa decimal quando inteira.
static func _seconds_text(seconds: float) -> String:
	if is_equal_approx(seconds, roundf(seconds)):
		return "%d s" % roundi(seconds)
	return "%.1f s" % seconds


func _build_choices() -> void:
	for i: int in _roster.size():
		if not _available.has(_roster[i].id):
			continue  # so heroi com cena entra na grade (F51)
		var card := HeroChoice.new()
		card.setup(_roster[i])
		card.pressed.connect(select.bind(i))
		_choices.add_child(card)
		_cards[i] = card


## Celulas Q/E/R: tecla em badge, nome e recarga; o R em dourado (ultimate).
func _build_skills() -> void:
	var keys := InputActions.skill_labels()
	for i: int in keys.size():
		var key := keys[i]
		var ultimate := i == keys.size() - 1
		var cell := PanelContainer.new()
		cell.theme_type_variation = &"HeroGoldSkill" if ultimate else &"HeroAllySkill"
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var column := VBoxContainer.new()
		column.alignment = BoxContainer.ALIGNMENT_CENTER
		cell.add_child(column)
		var badge := PanelContainer.new()
		badge.theme_type_variation = &"HeroGoldBadge" if ultimate else &"HeroAllyBadge"
		badge.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		badge.add_child(_centered("[%s]" % key, &"LabelHeroDark"))
		column.add_child(badge)
		var skill_name := _centered("", &"LabelHeroStrong")
		skill_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		column.add_child(skill_name)
		var cooldown := _centered("", &"LabelHeroHighlight" if ultimate else &"LabelMuted")
		column.add_child(cooldown)
		_skills.add_child(cell)
		_skill_names.append(skill_name)
		_skill_cooldowns.append(cooldown)


## Linhas de atributo: nome e "valor / maior do roster" em cima, barra embaixo.
func _build_stats() -> void:
	for stat: String in STAT_NAMES:
		var row := HBoxContainer.new()
		var title := Label.new()
		title.text = stat
		title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(title)
		var value := Label.new()
		value.theme_type_variation = &"LabelHeroAccent"
		row.add_child(value)
		var bar := ProgressBar.new()
		bar.theme_type_variation = &"ProgressHero"
		bar.custom_minimum_size.y = BAR_HEIGHT
		bar.show_percentage = false
		_stats.add_child(row)
		_stats.add_child(bar)
		_stat_values.append(value)
		_stat_bars.append(bar)


func _show(index: int) -> void:
	_selected = index
	var data := _roster[index]
	_player_name.text = data.display_name.to_upper()
	_player_summary.text = data.summary
	_player_role.text = data.role.to_upper()
	_player_icon.texture = data.basic_attack.icon
	var skills: Array[SkillData] = [data.skill_q, data.skill_e, data.skill_r]
	for i: int in skills.size():
		_skill_names[i].text = skills[i].display_name
		_skill_cooldowns[i].text = tr("Recarga %s") % _seconds_text(skills[i].cooldown[0])
	var values := _stat_values_of(data)
	for i: int in _stat_bars.size():
		_stat_bars[i].max_value = _stat_max[i]
		_stat_bars[i].value = values[i]
		_stat_values[i].text = "%d / %d" % [roundi(values[i]), roundi(_stat_max[i])]
	_player_preview.show_model(model_of(data.id))
	_refresh_cards()


func _refresh_cards() -> void:
	for index: int in _cards:
		var card := _cards[index]
		card.set_active(index == _selected)
		card.disabled = _requested
		card.modulate.a = DIM_ALPHA if _requested and index != _selected else 1.0
	_lock_in.disabled = _requested
	_lock_in_gradient.self_modulate = Color.WHITE  # hover nao fica preso depois do clique
	_lock_in_frame.modulate = Color(1.0, 1.0, 1.0, UiTokens.DISABLED_ALPHA if _requested else 1.0)


## Card do oponente: [param index] = heroi confirmado, -1 = ainda escolhendo.
func _show_enemy(index: int) -> void:
	var known := index >= 0
	var data: HeroData = _roster[index] if known else null
	_enemy_name.text = data.display_name.to_upper() if known else tr("OPONENTE")
	_enemy_summary.text = data.summary if known else tr("Escolhendo o herói...")
	_enemy_role.text = data.role.to_upper() if known else ""
	_enemy_role_tag.visible = known
	_enemy_icon.texture = data.basic_attack.icon if known else _rival_icon
	_enemy_preview.show_model(model_of(data.id) if known else null)
	_enemy_unknown.visible = not known
	_enemy_locked.visible = known
	_enemy_state.text = tr("PRONTO PARA COMBATE") if known else tr("ESCOLHENDO...")
	_enemy_state.theme_type_variation = &"LabelHeroReady" if known else &"LabelHeroHighlight"
	_state_dot.theme_type_variation = &"HeroDotReady" if known else &"HeroDotWaiting"
	_set_status(_rival_status, known)
	if known:
		_pop(_enemy_locked)


func _set_status(label: Label, is_ready: bool) -> void:
	label.text = tr("Status: Pronto") if is_ready else tr("Status: Escolhendo...")
	label.theme_type_variation = &"LabelHeroReady" if is_ready else &"LabelMuted"


func _start_pulses() -> void:
	if not _pulses.is_empty():
		return
	for dot: Control in [_you_dot, _rival_dot, _state_dot]:
		var pulse := create_tween().set_loops().set_trans(Tween.TRANS_SINE)
		pulse.tween_property(dot, ^"modulate:a", PULSE_ALPHA, UiTokens.PULSE_QUEUE / 2.0)
		pulse.tween_property(dot, ^"modulate:a", 1.0, UiTokens.PULSE_QUEUE / 2.0)
		_pulses.append(pulse)


func _pop(control: Control) -> void:
	control.pivot_offset = control.size / 2.0
	control.scale = Vector2.ONE * POP_SCALE
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(control, ^"scale", Vector2.ONE, UiTokens.DUR_BASE)


func _centered(text: String, type: StringName) -> Label:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = type
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label


func _hero_index(hero_id: int) -> int:
	var id := Ids.to_name(hero_id)
	return _roster.find_custom(func(d: HeroData) -> bool: return d.id == id)


## Confirmacao do servidor: a minha (escolha ou padrao do timeout) ou a do adversario
## (espelho permitido).
func _on_match_hero_picked(peer: int, hero_id: int, _tick: int) -> void:
	var index := _hero_index(hero_id)
	if not visible or index < 0:
		return  # fechada (servidor dedicado nunca abre): nada a mostrar
	if peer != multiplayer.get_unique_id():
		_show_enemy(index)
		return
	_requested = false
	_selected = -1
	_show(index)
	_requested = true
	_refresh_cards()
	_status.text = tr("PRONTO — AGUARDANDO O ADVERSÁRIO")
	_set_status(_you_status, true)
	_player_locked.show()
	_pop(_player_locked)


func _on_player_stage_resized() -> void:
	_enemy_stage.custom_minimum_size.y = _player_stage.size.y


## Gradiente do "DUELO 1v1" vai de ponta a ponta do texto.
func _on_mode_resized() -> void:
	(_mode.material as ShaderMaterial).set_shader_parameter(&"width", _mode.size.x)


func _on_lock_in_hover(inside: bool) -> void:
	if not _lock_in.disabled:
		_lock_in_gradient.self_modulate = HOVER_BRIGHT if inside else Color.WHITE


func _on_lock_in_press(down: bool) -> void:
	_lock_in_frame.pivot_offset = _lock_in_frame.size / 2.0
	_lock_in_frame.scale = Vector2.ONE * (PRESS_SCALE if down else 1.0)
