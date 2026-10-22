class_name ScoreBanner
extends PanelCard
## Placar de kills do duelo (COMPONENTS.md, DV tela 4, PATTERNS P10; enxuto em 2026-10-22 pelo PI:
## so numeros e avatares). Avatar do heroi de cada lado com borda GREEN (voce) ou RED (oponente),
## kills no meio (contador mono 28 px bold, GREEN de quem joga e RED do adversario) e a meta com o
## icone de trofeu. O lider troca a borda para GOLD. Cor nunca sozinha: o lado de quem joga vem
## primeiro e o nome com VOCÊ/OPONENTE fica no tooltip do avatar. Nao conta kill: recebe o placar.

## Indice = is_local do lado.
const SCORE_TYPES: Array[StringName] = [&"LabelCounterDanger", &"LabelCounterAlly"]
const TEAM_ACCENTS: Array[Accent] = [Accent.RED, Accent.GREEN]
const PORTRAITS_DIR: String = "res://shared/assets/ui/heroes/"
const AVATAR_SIZE: Vector2 = Vector2(44, 44)


## Um lado do placar.
class PlayerScore:
	extends RefCounted
	var name: String
	var kills: int
	var is_local: bool
	## HeroData.id (retrato em PORTRAITS_DIR); vazio = sem retrato.
	var hero_id: StringName

	func _init(
		p_name: String = "", p_kills: int = 0, p_is_local: bool = false, p_hero_id: StringName = &""
	) -> void:
		name = p_name
		kills = p_kills
		is_local = p_is_local
		hero_id = p_hero_id


var _sides: Array[PanelCard] = []
var _avatars: Array[TextureRect] = []
var _scores: Array[Label] = []
var _target: Label = Label.new()


func _init() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override(&"separation", UiTokens.SPACE_MD)
	add_child(row)
	for i: int in 2:
		var side := PanelCard.new()
		side.variant = Surface.INNER
		side.mouse_filter = MOUSE_FILTER_PASS  # tooltip com o nome
		var avatar := TextureRect.new()
		avatar.custom_minimum_size = AVATAR_SIZE
		avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		avatar.mouse_filter = MOUSE_FILTER_IGNORE
		side.add_child(avatar)
		var score := Label.new()
		score.theme_type_variation = SCORE_TYPES[0]
		score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		score.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_sides.append(side)
		_avatars.append(avatar)
		_scores.append(score)
	var dash := Label.new()
	dash.theme_type_variation = &"LabelMuted"
	dash.text = "–"
	dash.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	# Espelhado: [avatar] 3 – 2 [avatar]; os numeros ficam no meio.
	for node: Control in [_sides[0], _scores[0], dash, _scores[1], _sides[1], VSeparator.new()]:
		row.add_child(node)
	_target.theme_type_variation = &"LabelH2"
	_target.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_target.tooltip_text = tr("Meta de kills")
	_target.mouse_filter = MOUSE_FILTER_PASS
	row.add_child(_target)


func _ready() -> void:
	IconFont.apply(_target)


func bind(p1: PlayerScore, p2: PlayerScore, target: int) -> void:
	var players: Array[PlayerScore] = [p1, p2]
	var leader := leader_index(p1.kills, p2.kills)
	for i: int in players.size():
		var player := players[i]
		var who := tr("VOCÊ") if player.is_local else tr("OPONENTE")
		_sides[i].tooltip_text = "%s (%s)" % [player.name, who]
		_sides[i].accent = Accent.GOLD if i == leader else TEAM_ACCENTS[int(player.is_local)]
		_avatars[i].texture = portrait(player.hero_id)
		_scores[i].text = str(player.kills)
		_scores[i].theme_type_variation = SCORE_TYPES[int(player.is_local)]
	_target.text = "%s %d" % [UiIcons.EMOJI_EVENTS, target]


## Lado com mais kills (0 ou 1); -1 empatado.
static func leader_index(p1_kills: int, p2_kills: int) -> int:
	if p1_kills == p2_kills:
		return -1
	return 0 if p1_kills > p2_kills else 1


## Retrato do heroi [param hero_id]; null se vazio ou sem arquivo.
static func portrait(hero_id: StringName) -> Texture2D:
	if hero_id.is_empty():
		return null
	var path := "%s%s.png" % [PORTRAITS_DIR, hero_id]
	return load(path) as Texture2D if ResourceLoader.exists(path) else null
