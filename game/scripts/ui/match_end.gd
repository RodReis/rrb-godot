class_name MatchEnd
extends CanvasLayer
## Tela de fim de partida (F18, refeita no F52 fiel ao protótipo "Destaques da Tela de Fim de
## Partida"; DV tela 7, ARCHITECTURE-GAME §3.6/§3.7): resultado (VITORIA, DERROTA ou SEM VENCEDOR),
## a condicao do fim, a duracao e a tabela lado a lado dos dois jogadores, quem joga a esquerda,
## com a comparacao no meio. So exibe o MatchStats que chegou no match_ended; nada e calculado
## aqui alem de quem esta melhor em cada linha. Os dois botoes pedem o fim do processo por sinal
## (o Game nao tem fila: "Jogar novamente" e o Launcher reabrindo a fila); Esc = voltar. Sem
## clique, fecha sozinha apos AUTO_CLOSE_SECONDS (contagem visivel, F70) pelo mesmo sinal do Voltar.

signal play_again_requested
signal back_requested

## Linhas da tabela, nesta ordem (ICONS, BETTER, ICON_TOKENS e VALUE_TOKENS seguem a mesma); as
## primeiras NUMBER_ROWS sao contagens, depois o Rei Esqueleto e o conjunto ativo.
const ROWS: Array[String] = [
	"Abates (Kills)",
	"Mortes",
	"Nível Final Atingido",
	"Dano Total em Heróis",
	"Dano Sofrido",
	"Monstros da Selva Abatidos",
	"Baús Abertos",
	"Rei Esqueleto",
	"Conjunto de Itens Ativo",
]
const ICONS: Array[Texture2D] = [
	preload("res://shared/ui/icons/ui_crosshair.svg"),
	preload("res://shared/ui/icons/ui_skull.svg"),
	preload("res://shared/ui/icons/ui_trend.svg"),
	preload("res://shared/ui/icons/ui_swords.svg"),
	preload("res://shared/ui/icons/ui_shield.svg"),
	preload("res://shared/ui/icons/ui_paw.svg"),
	preload("res://shared/ui/icons/ui_chest.svg"),
	preload("res://shared/ui/icons/ui_crown.svg"),
	preload("res://shared/ui/icons/ui_sparkle.svg"),
]
const NUMBER_ROWS: int = 7
const LEVEL_ROW: int = 2
const BOSS_ROW: int = 7
const SET_ROW: int = 8
## Por linha: 1 = maior e melhor, -1 = menor e melhor, 0 = sem comparacao.
const BETTER: Array[int] = [1, -1, 1, 1, -1, 1, 1, 1, 0]
## Cor (token) do icone e do valor de quem esta melhor ou empatado na linha (protótipo).
const ICON_TOKENS: Array[StringName] = [
	&"GOLD", &"TEXT_MUTED", &"CYAN", &"GOLD_BRIGHT", &"TEXT_MUTED", &"GREEN", &"GOLD"
]
const VALUE_TOKENS: Array[StringName] = [
	&"TEXT", &"GREEN", &"CYAN", &"GOLD_BRIGHT", &"GREEN", &"TEXT", &"GOLD_BRIGHT"
]
const GLYPHS: Dictionary[int, String] = {1: ">", -1: "<", 0: "="}
const COLLAPSE_CRITERIA: Dictionary[StringName, String] = {
	VictoryRules.COLLAPSE_HP: "MAIOR VIDA",
	VictoryRules.COLLAPSE_KILLS: "MAIS KILLS NA FASE 2",
	VictoryRules.COLLAPSE_DAMAGE: "MAIS DANO EM HERÓIS",
	VictoryRules.COLLAPSE_DRAW: "SORTEIO",
}
## Tom por resultado, de DERROTA (-1) a VITORIA (+1), indexado por resultado + 1.
const TONES: Array[StringName] = [&"Lose", &"Draw", &"Win"]
## Brilhos do fundo por tom: topo, esquerda, direita (radial-gradient do protótipo).
const GLOWS: Dictionary[StringName, Array] = {
	&"Win": [Color(UiTokens.GOLD, 0.15), Color(UiTokens.BLUE, 0.1), Color(UiTokens.RED, 0.1)],
	&"Lose":
	[
		Color(UiTokens.RED, 0.22),
		Color(UiTokens.RED, 0.12),
		Color(UiTokens.RED, 0.18),
	],
	&"Draw": [Color(UiTokens.TEXT_MUTED, 0.08), Color.TRANSPARENT, Color.TRANSPARENT],
}
## Cor de acento por tom (icone do motivo e brilho atras do titulo) e alfa do brilho no centro
## (text-shadow do protótipo).
const TONE_COLORS: Dictionary[StringName, Color] = {
	&"Win": UiTokens.GOLD, &"Lose": UiTokens.RED, &"Draw": UiTokens.TEXT_MUTED
}
const HALO_ALPHA: float = 0.55
## Diametro do circulo do comparador (w-6 h-6 do protótipo, 1,2x).
const GLYPH_SIZE: int = 28
## Entrada da vitoria: escala do titulo (DV tela 7 §4).
const VICTORY_SCALE: float = 1.5
## Pulso do botao principal na vitoria (pulse-subtle do protótipo: 3 s, opacidade a 50 %).
const PULSE_SECONDS: float = 3.0
const PULSE_ALPHA: float = 0.5
## "Jogar novamente" encolhe ao pressionar (active:scale-95).
const PRESS_SCALE: float = 0.95
## Som: o jingle do repo (DS-10), agudo na vitoria e grave na derrota.
const VICTORY_PITCH: float = 1.2
const DEFEAT_PITCH: float = 0.7
## Sem clique, a tela fecha sozinha (F70, ADR-0015 item 8): o Launcher volta ao lobby com o card.
const AUTO_CLOSE_SECONDS: float = 15.0

@export var item_catalog: ItemCatalog = preload("res://shared/data/items/catalog.tres")

var _rules: MatchRules
var _roster: Array[HeroData] = []
var _tween: Tween
## Tween em laço do botão principal; null fora da vitória.
var _pulse_tween: Tween
var _seconds_left: float = 0.0

@onready var _root: Control = $Root
@onready var _countdown: Label = %Countdown
@onready var _backdrop: RunicBackdrop = %Backdrop
@onready var _particles: CPUParticles2D = %Particles
@onready var _title: Label = %Title
@onready var _halo: TextureRect = %Halo
@onready var _reason_pill: PanelContainer = %ReasonPill
@onready var _reason_icon: TextureRect = %ReasonIcon
@onready var _clock_icon: TextureRect = %ClockIcon
@onready var _shield_icon: TextureRect = %ShieldIcon
@onready var _back_icon: TextureRect = %BackIcon
@onready var _compare_column: MarginContainer = %CompareColumn
@onready var _reason: Label = %Reason
@onready var _duration: Label = %DurationValue
@onready var _me_card: MatchEndCard = %MeCard
@onready var _them_card: MatchEndCard = %ThemCard
@onready var _compare: VBoxContainer = %Compare
@onready var _compare_top: Control = %CompareTop
@onready var _play_again: Button = %PlayAgain
@onready var _play_icon: TextureRect = %PlayIcon
@onready var _play_label: Label = %PlayLabel
@onready var _back: Button = %Back
@onready var _sound: AudioStreamPlayer = %Sound


func _ready() -> void:
	visible = false
	set_process(false)
	var names: Array[String] = []
	for row: String in ROWS:
		names.append(tr(row))
		_compare.add_child(_glyph_holder())
	_me_card.setup_rows(names, ICONS)
	_them_card.setup_rows(names, ICONS)
	_compare_top.custom_minimum_size.y = MatchEndCard.HEADER_HEIGHT
	# A coluna do comparador começa à altura do primeiro conteúdo dos cartões (SPACE_LG).
	_compare_column.add_theme_constant_override(&"margin_top", UiTokens.SPACE_LG)
	_compare_column.add_theme_constant_override(&"margin_bottom", UiTokens.SPACE_LG)
	_clock_icon.modulate = UiTokens.GOLD_BRIGHT
	_shield_icon.modulate = UiTokens.BLUE
	_back_icon.modulate = UiTokens.TEXT_MUTED
	_title.resized.connect(_on_title_resized)
	_root.resized.connect(_on_root_resized)
	_on_root_resized()
	_play_again.pressed.connect(play_again_requested.emit)
	_back.pressed.connect(back_requested.emit)
	for button: Button in [_play_again, _back]:
		button.button_down.connect(_on_button_down.bind(button))
		button.button_up.connect(_on_button_up.bind(button))
		button.resized.connect(_on_button_resized.bind(button))


func _process(delta: float) -> void:
	_seconds_left = maxf(_seconds_left - delta, 0.0)
	_show_countdown()
	if _seconds_left <= 0.0:
		set_process(false)
		back_requested.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		back_requested.emit()


## Segundos que faltam para a tela fechar sozinha; 0 antes de apresentar e depois de fechar.
func seconds_left() -> float:
	return _seconds_left


## Se o botão principal está pulsando (só na vitória).
func is_pulsing() -> bool:
	return _pulse_tween != null


## Liga ao fim da partida; [param roster] da o nome e o icone de cada heroi.
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
	var tone := TONES[outcome + 1]
	var titles: Array[String] = [tr("DERROTA"), tr("SEM VENCEDOR"), tr("VITÓRIA")]
	_title.text = titles[outcome + 1]
	_title.theme_type_variation = StringName("LabelEndTitle" + tone)
	_reason.text = _reason_text(reason)
	_reason.theme_type_variation = StringName("LabelEndReason" + tone)
	_reason_pill.theme_type_variation = StringName("EndReason" + tone)
	_reason_icon.modulate = TONE_COLORS[tone]
	_duration.text = TimerLabel.format_seconds(stats.duration, TimerLabel.Format.MM_SS)
	_set_tone(tone, outcome)
	var tags: Array[String] = [tr("DERROTADO"), "", tr("VENCEDOR")]
	var other_tone := TONES[1 - outcome]
	_show_player(_me_card, tone, tr("ALIADO"), tr("VOCÊ"), me, tags[outcome + 1])
	_show_player(_them_card, other_tone, tr("INIMIGO"), tr("OPONENTE"), them, tags[1 - outcome])
	_fill_rows(_me_card, me, them)
	_fill_rows(_them_card, them, me)
	_fill_compare(_numbers(me), _numbers(them))
	visible = true
	_play_again.grab_focus()
	_animate(outcome)
	_seconds_left = AUTO_CLOSE_SECONDS
	_show_countdown()
	set_process(true)


## Milhar com ponto, como em pt-BR ("4.820").
static func format_number(value: int) -> String:
	var digits := str(absi(value))
	var grouped := ""
	for i: int in digits.length():
		if i > 0 and (digits.length() - i) % 3 == 0:
			grouped += "."
		grouped += digits[i]
	return "-" + grouped if value < 0 else grouped


func _show_countdown() -> void:
	_countdown.text = tr("Fechando em %d s") % ceili(_seconds_left)


func _glyph_holder() -> CenterContainer:
	var holder := CenterContainer.new()
	holder.custom_minimum_size.y = MatchEndRow.HEIGHT
	var circle := PanelContainer.new()
	circle.theme_type_variation = &"EndGlyph"
	circle.custom_minimum_size = Vector2.ONE * GLYPH_SIZE
	var label := Label.new()
	label.theme_type_variation = &"LabelEndGlyph"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	circle.add_child(label)
	holder.add_child(circle)
	return holder


func _reason_text(reason: StringName) -> String:
	if reason == VictoryRules.KILL_GOAL:
		return tr("META DE %d KILLS ATINGIDA") % _rules.kill_goal
	if reason == VictoryRules.ELIMINATION:
		return tr("ELIMINAÇÃO NA MORTE SÚBITA")
	if COLLAPSE_CRITERIA.has(reason):
		var at := TimerLabel.format_seconds(_rules.max_match_duration, TimerLabel.Format.MM_SS)
		return tr("COLAPSO DA ZONA AOS %s · %s") % [at, tr(COLLAPSE_CRITERIA[reason])]
	if reason != VictoryRules.ABANDONED:
		push_warning("[match_end] motivo de fim sem texto: %s" % reason)
	return tr("PARTIDA ABANDONADA")


## Fundo, brilho do titulo e botao principal na cor do tom.
func _set_tone(tone: StringName, outcome: int) -> void:
	var glows: Array = GLOWS[tone]
	var material := _backdrop.material as ShaderMaterial
	for i: int in glows.size():
		material.set_shader_parameter(StringName("glow_color_%d" % (i + 1)), glows[i])
	_halo.modulate = Color(TONE_COLORS[tone], HALO_ALPHA if outcome != 0 else 0.0)
	var primary_dark := outcome >= 0
	_play_again.theme_type_variation = &"ButtonEndPrimary" if primary_dark else &"ButtonEndDanger"
	_play_label.theme_type_variation = &"LabelEndButtonDark" if primary_dark else &"LabelEndButton"
	_play_icon.modulate = UiTokens.BG_SURFACE if primary_dark else UiTokens.TEXT


func _show_player(
	card: MatchEndCard,
	tone: StringName,
	side: String,
	who: String,
	one: MatchStats.Player,
	tag: String
) -> void:
	var data := _hero_data(one.hero)
	var hero_text := ""
	var icon: Texture2D = null
	if data != null:
		hero_text = "— %s" % data.display_name.to_upper()
		icon = data.basic_attack.icon if data.basic_attack != null else null
	card.show_player(tone, side, who, hero_text, icon, one.level, tag)


func _hero_data(hero: int) -> HeroData:
	for data: HeroData in _roster:
		if data.id == Ids.to_name(hero):
			return data
	return null


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


## Preenche as linhas do cartao de [param one]; "melhor" e "pior" sao em relacao a [param other].
func _fill_rows(card: MatchEndCard, one: MatchStats.Player, other: MatchStats.Player) -> void:
	var mine := _numbers(one)
	var theirs := _numbers(other)
	for i: int in NUMBER_ROWS:
		var order := signi(mine[i] - theirs[i]) * BETTER[i]
		var text := tr("Nv. %d") % mine[i] if i == LEVEL_ROW else format_number(mine[i])
		var icon_color: Color = UiTokens.COLORS[ICON_TOKENS[i]]
		var value_token := VALUE_TOKENS[i]
		if order < 0:
			icon_color = UiTokens.RED if BETTER[i] < 0 else UiTokens.TEXT_MUTED
			value_token = &"TEXT_MUTED"
		var value_type := StringName("LabelEndValue" + String(value_token).to_pascal_case())
		card.rows[i].show_value(&"EndRow", text, value_type, icon_color)
	if one.boss_killed:
		card.rows[BOSS_ROW].show_value(
			&"EndRowBoss", tr("Abatido"), &"LabelEndPillGold", UiTokens.GOLD
		)
	else:
		card.rows[BOSS_ROW].show_value(
			&"EndRowMuted", tr("Não abatido"), &"LabelEndPillMuted", UiTokens.TEXT_MUTED
		)
	var pieces := HeroPlate.set_pieces(one.equipment, item_catalog)
	if pieces.is_empty():
		var none := tr("Sem conjunto")
		card.rows[SET_ROW].show_value(&"EndRowMuted", none, &"LabelMuted", UiTokens.TEXT_MUTED)
	else:
		var text := " · ".join(pieces)
		card.rows[SET_ROW].show_value(&"EndRowSet", text, &"LabelHeroAccent", UiTokens.CYAN)


func _fill_compare(mine: Array[int], theirs: Array[int]) -> void:
	for i: int in ROWS.size():
		var circle := _compare.get_child(i).get_child(0) as Control
		circle.visible = BETTER[i] != 0
		(circle.get_child(0) as Label).text = GLYPHS[signi(mine[i] - theirs[i])]


## Vitoria: titulo cai de 1,5x com quique, particulas douradas e o botao principal pulsa;
## derrota: titulo surge devagar e brasas vermelhas sobem (DV tela 7 §4). Sem vencedor: so o fundo.
func _animate(outcome: int) -> void:
	if _tween != null:
		_tween.kill()
	_pulse(outcome > 0)
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


func _pulse(enabled: bool) -> void:
	if _pulse_tween != null:
		_pulse_tween.kill()
		_pulse_tween = null
	_play_again.modulate.a = 1.0
	if not enabled:
		return
	_pulse_tween = create_tween().set_loops()
	var half := PULSE_SECONDS / 2.0
	for alpha: float in [PULSE_ALPHA, 1.0]:
		(
			_pulse_tween
			. tween_property(_play_again, ^"modulate:a", alpha, half)
			. set_trans(Tween.TRANS_SINE)
			. set_ease(Tween.EASE_IN_OUT)
		)


## Particulas na tela inteira, tambem em janela mais larga (stretch expand).
func _on_root_resized() -> void:
	_particles.position = _root.size / 2.0
	_particles.emission_rect_extents = _root.size / 2.0


func _on_title_resized() -> void:
	_title.pivot_offset = _title.size / 2.0


func _on_button_resized(button: Button) -> void:
	button.pivot_offset = button.size / 2.0


func _on_button_down(button: Button) -> void:
	button.scale = Vector2.ONE * PRESS_SCALE


func _on_button_up(button: Button) -> void:
	button.scale = Vector2.ONE


func _on_match_ended(winner: int, reason: StringName, stats: MatchStats, _tick: int) -> void:
	present(winner, reason, stats, multiplayer.get_unique_id())
