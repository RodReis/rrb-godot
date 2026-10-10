class_name MatchEnd
extends CanvasLayer
## Tela de fim de partida (F18, DV tela 7, ARCHITECTURE-GAME §3.6/§3.7): resultado (VITORIA,
## DERROTA ou SEM VENCEDOR), a condicao do fim, a duracao e a tabela lado a lado dos dois
## jogadores, quem joga a esquerda, com a comparacao no meio (verde = melhor para quem joga). So
## exibe o MatchStats que chegou no match_ended. Os dois botoes pedem o fim do processo por sinal
## (o Game nao tem fila: "Jogar novamente" e o Launcher reabrindo a fila); Esc = voltar.

signal play_again_requested
signal back_requested

## Linhas da tabela, nesta ordem (_values, _numbers e BETTER seguem a mesma); as primeiras
## NUMBER_ROWS sao contagens.
const ROWS: Array[String] = [
	"Kills",
	"Mortes",
	"Nível final",
	"Dano em heróis",
	"Dano sofrido",
	"Monstros abatidos",
	"Baús abertos",
	"Rei Esqueleto",
	"Conjunto ativo",
]
const NUMBER_ROWS: int = 7
## Por linha: 1 = maior e melhor, -1 = menor e melhor, 0 = sem comparacao.
const BETTER: Array[int] = [1, -1, 1, 1, -1, 1, 1, 1, 0]
const GLYPHS: Dictionary[int, String] = {1: ">", -1: "<", 0: "="}
## Variacao do simbolo pelo efeito para quem joga: bom, neutro, ruim.
const GLYPH_TYPES: Dictionary[int, StringName] = {
	1: &"LabelCounterAlly", 0: &"LabelCounter", -1: &"LabelCounterDanger"
}
const COLLAPSE_CRITERIA: Dictionary[StringName, String] = {
	VictoryRules.COLLAPSE_HP: "MAIOR VIDA",
	VictoryRules.COLLAPSE_KILLS: "MAIS KILLS NA FASE 2",
	VictoryRules.COLLAPSE_DAMAGE: "MAIS DANO EM HERÓIS",
	VictoryRules.COLLAPSE_DRAW: "SORTEIO",
}
## Altura de cada linha e do cabecalho dos cartoes: as tres colunas alinham por elas.
const ROW_HEIGHT: int = UiTokens.SIZE_TARGET_MIN
const HEADER_HEIGHT: int = 48
## Entrada da vitoria: escala do titulo (DV tela 7 §4).
const VICTORY_SCALE: float = 1.5
## Som: o jingle do repo (DS-10), agudo na vitoria e grave na derrota.
const VICTORY_PITCH: float = 1.2
const DEFEAT_PITCH: float = 0.7

@export var item_catalog: ItemCatalog = preload("res://shared/data/items/catalog.tres")

var _rules: MatchRules
var _roster: Array[HeroData] = []
var _tween: Tween

@onready var _backdrop: ColorRect = %Backdrop
@onready var _particles: CPUParticles2D = %Particles
@onready var _title: Label = %Title
@onready var _reason: Label = %Reason
@onready var _duration: Label = %Duration
@onready var _me_card: PanelCard = %MeCard
@onready var _them_card: PanelCard = %ThemCard
@onready var _me_header: Label = %MeHeader
@onready var _them_header: Label = %ThemHeader
@onready var _me_names: VBoxContainer = %MeNames
@onready var _them_names: VBoxContainer = %ThemNames
@onready var _me_stats: VBoxContainer = %MeStats
@onready var _them_stats: VBoxContainer = %ThemStats
@onready var _compare: VBoxContainer = %Compare
@onready var _compare_header: Label = %CompareHeader
@onready var _play_again: Button = %PlayAgain
@onready var _back: Button = %Back
@onready var _sound: AudioStreamPlayer = %Sound


func _ready() -> void:
	visible = false
	for row: String in ROWS:
		for names: VBoxContainer in [_me_names, _them_names]:
			names.add_child(_row_label(tr(row), HORIZONTAL_ALIGNMENT_LEFT))
		for values: VBoxContainer in [_me_stats, _them_stats]:
			values.add_child(_row_label("", HORIZONTAL_ALIGNMENT_RIGHT))
		_compare.add_child(_row_label("", HORIZONTAL_ALIGNMENT_CENTER))
	for label: Label in [_me_header, _them_header, _compare_header]:
		label.custom_minimum_size.y = HEADER_HEIGHT
	_title.resized.connect(_on_title_resized)
	_play_again.pressed.connect(play_again_requested.emit)
	_back.pressed.connect(back_requested.emit)


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		back_requested.emit()


## Liga ao fim da partida; [param roster] da o nome de cada heroi.
func bind(match_controller: MatchController, roster: Array[HeroData]) -> void:
	_rules = match_controller.rules
	_roster = roster
	if not match_controller.match_ended.is_connected(_on_match_ended):
		match_controller.match_ended.connect(_on_match_ended)


## Mostra o resultado visto por [param local_peer].
func present(winner: int, reason: StringName, stats: MatchStats, local_peer: int) -> void:
	var me := stats.player(local_peer) if stats.has(local_peer) else MatchStats.Player.new()
	var them := stats.opponent_of(local_peer)
	if them == null:
		them = MatchStats.Player.new()
	var outcome := 0 if winner == VictoryRules.NO_WINNER else (1 if winner == local_peer else -1)
	var titles: Array[String] = [tr("DERROTA"), tr("SEM VENCEDOR"), tr("VITÓRIA")]
	_title.text = titles[outcome + 1]
	var colors: Array[Color] = [UiTokens.RED, UiTokens.TEXT_MUTED, UiTokens.GOLD]
	_title.add_theme_color_override(&"font_color", colors[outcome + 1])
	_reason.text = _reason_text(reason)
	var clock := TimerLabel.format_seconds(stats.duration, TimerLabel.Format.MM_SS)
	_duration.text = tr("Duração da partida: %s") % clock
	var accents: Array[PanelCard.Accent] = [
		PanelCard.Accent.RED, PanelCard.Accent.NONE, PanelCard.Accent.GOLD
	]
	_me_card.accent = accents[outcome + 1]
	_them_card.accent = accents[1 - outcome]
	_me_header.text = _header(tr("VOCÊ"), me.hero)
	_them_header.text = _header(tr("OPONENTE"), them.hero)
	_fill(_me_stats, _values(me))
	_fill(_them_stats, _values(them))
	_fill_compare(_numbers(me), _numbers(them))
	visible = true
	_play_again.grab_focus()
	_animate(outcome)


func _row_label(text: String, align: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.text = text
	label.custom_minimum_size.y = ROW_HEIGHT
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.horizontal_alignment = align
	return label


func _reason_text(reason: StringName) -> String:
	if reason == VictoryRules.KILL_GOAL:
		return tr("META DE %d KILLS ATINGIDA") % _rules.kill_goal
	if reason == VictoryRules.ELIMINATION:
		return tr("ELIMINAÇÃO NA MORTE SÚBITA")
	if COLLAPSE_CRITERIA.has(reason):
		var at := TimerLabel.format_seconds(_rules.max_match_duration, TimerLabel.Format.MM_SS)
		return tr("COLAPSO DA ZONA AOS %s · %s") % [at, tr(COLLAPSE_CRITERIA[reason])]
	return tr("PARTIDA ABANDONADA")


## "VOCE · CAVALEIRO"; sem heroi, so o papel.
func _header(role: String, hero: int) -> String:
	for data: HeroData in _roster:
		if data.id == Ids.to_name(hero):
			return "%s · %s" % [role, data.display_name.to_upper()]
	return role


func _values(one: MatchStats.Player) -> Array[String]:
	var texts: Array[String] = []
	for value: int in _numbers(one).slice(0, NUMBER_ROWS):
		texts.append(str(value))
	texts.append(tr("Abatido") if one.boss_killed else tr("Não abatido"))
	texts.append(HeroPlate.set_text(one.equipment, item_catalog))
	return texts


## Valores comparaveis, na ordem de ROWS (o boss vale 1/0; o conjunto nao compara).
func _numbers(one: MatchStats.Player) -> Array[int]:
	return [
		one.kills,
		one.deaths,
		one.level,
		one.hero_damage,
		one.damage_taken,
		one.monsters,
		one.chests,
		int(one.boss_killed),
		0,
	]


func _fill(column: VBoxContainer, texts: Array[String]) -> void:
	for i: int in texts.size():
		(column.get_child(i) as Label).text = texts[i]


func _fill_compare(mine: Array[int], theirs: Array[int]) -> void:
	for i: int in ROWS.size():
		var glyph := _compare.get_child(i) as Label
		var order := signi(mine[i] - theirs[i])
		glyph.text = GLYPHS[order] if BETTER[i] != 0 else ""
		glyph.theme_type_variation = GLYPH_TYPES[order * BETTER[i]]


## Vitoria: titulo cai de 1,5x com quique e particulas douradas; derrota: titulo surge devagar,
## brasas e o fundo da arena perde a cor (DV tela 7 §4). Sem vencedor: so o fundo escuro.
func _animate(outcome: int) -> void:
	if _tween != null:
		_tween.kill()
	var shader := _backdrop.material as ShaderMaterial
	shader.set_shader_parameter(&"desaturate", 0.0)
	_title.scale = Vector2.ONE
	_title.modulate.a = 1.0
	_particles.emitting = outcome != 0
	if outcome == 0:
		return
	_tween = create_tween()
	_sound.pitch_scale = VICTORY_PITCH if outcome > 0 else DEFEAT_PITCH
	_sound.play()
	if outcome > 0:
		_particles.color = UiTokens.GOLD
		_particles.gravity = Vector2.DOWN * absf(_particles.gravity.y)
		_title.scale = Vector2.ONE * VICTORY_SCALE
		(
			_tween
			. tween_property(_title, ^"scale", Vector2.ONE, UiTokens.DUR_SLOW)
			. set_trans(Tween.TRANS_BOUNCE)
			. set_ease(Tween.EASE_OUT)
		)
		return
	_particles.color = UiTokens.RED
	_particles.gravity = Vector2.UP * absf(_particles.gravity.y)
	_title.modulate.a = 0.0
	_tween.tween_property(_title, ^"modulate:a", 1.0, UiTokens.DUR_SLOW * 2.0)
	_tween.parallel().tween_method(
		func(amount: float) -> void: shader.set_shader_parameter(&"desaturate", amount),
		0.0,
		1.0,
		UiTokens.DUR_SLOW * 2.0
	)


func _on_title_resized() -> void:
	_title.pivot_offset = _title.size / 2.0


func _on_match_ended(winner: int, reason: StringName, stats: MatchStats, _tick: int) -> void:
	present(winner, reason, stats, multiplayer.get_unique_id())
