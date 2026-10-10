class_name ScoreBanner
extends PanelCard
## Placar de kills do duelo (COMPONENTS.md, DV tela 4, PATTERNS P10): nome e kills de cada lado
## e a meta. Kills de quem joga em GREEN e do adversario em RED (contador mono 28 px bold, TOKENS
## §1); o nome diz VOCÊ/OPONENTE (cor nunca sozinha). O lider ganha a borda GOLD no proprio lado.
## Nao conta kill: recebe o placar pronto.

## Indice = is_local do lado.
const SCORE_TYPES: Array[StringName] = [&"LabelCounterDanger", &"LabelCounterAlly"]


## Um lado do placar.
class PlayerScore:
	extends RefCounted
	var name: String
	var kills: int
	var is_local: bool

	func _init(p_name: String = "", p_kills: int = 0, p_is_local: bool = false) -> void:
		name = p_name
		kills = p_kills
		is_local = p_is_local


var _sides: Array[PanelCard] = []
var _names: Array[Label] = []
var _scores: Array[Label] = []
var _target: Label = Label.new()


func _init() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(row)
	for i: int in 2:
		var side := PanelCard.new()
		side.variant = Surface.INNER
		var line := HBoxContainer.new()
		var player := Label.new()
		player.theme_type_variation = &"LabelH2"
		player.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		var score := Label.new()
		score.theme_type_variation = SCORE_TYPES[0]
		score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		# Placar espelhado: P1 "nome  3", P2 "2  nome", os numeros ficam no meio.
		for label: Label in [player, score] if i == 0 else [score, player]:
			line.add_child(label)
		side.add_child(line)
		_sides.append(side)
		_names.append(player)
		_scores.append(score)
	var versus := Label.new()
	versus.theme_type_variation = &"LabelMuted"
	versus.text = tr("VS")
	versus.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(_sides[0])
	row.add_child(versus)
	row.add_child(_sides[1])
	row.add_child(VSeparator.new())
	_target.theme_type_variation = &"LabelBadge"
	_target.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(_target)


func bind(p1: PlayerScore, p2: PlayerScore, target: int) -> void:
	var players: Array[PlayerScore] = [p1, p2]
	for i: int in players.size():
		var player := players[i]
		var who := tr("VOCÊ") if player.is_local else tr("OPONENTE")
		_names[i].text = "%s (%s)" % [player.name, who]
		_scores[i].text = str(player.kills)
		_scores[i].theme_type_variation = SCORE_TYPES[int(player.is_local)]
	var leader := leader_index(p1.kills, p2.kills)
	for i: int in _sides.size():
		_sides[i].accent = Accent.GOLD if i == leader else Accent.NONE
	_target.text = tr("META: %d KILLS") % target


## Lado com mais kills (0 ou 1); -1 empatado.
static func leader_index(p1_kills: int, p2_kills: int) -> int:
	if p1_kills == p2_kills:
		return -1
	return 0 if p1_kills > p2_kills else 1
