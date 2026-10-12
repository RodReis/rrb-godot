class_name MatchEndCard
extends PanelContainer
## Cartão de um jogador na tela de fim (F52, protótipo "Destaques da Tela de Fim de Partida"):
## moldura do herói com o nível, lado e selo de resultado, nome e a coluna de linhas da tabela.
## Só mostra; quem decide texto e tom é a MatchEnd. O tom (Win, Lose, Draw) escolhe os tipos do
## Theme: EndCard, EndIcon, LabelEndLevel, LabelEndTag e LabelEndReason + tom.

## Altura do cabeçalho até a linha divisória: a coluna do comparador alinha por ela.
const HEADER_HEIGHT: int = 88

## Linhas da tabela, na ordem em que foram montadas por [method setup_rows].
var rows: Array[MatchEndRow] = []

@onready var icon_box: PanelContainer = %IconBox
@onready var icon_rect: TextureRect = %Icon
@onready var level_label: Label = %Level
@onready var side_label: Label = %Side
@onready var tag_label: Label = %Tag
@onready var name_label: Label = %Name
@onready var hero_label: Label = %Hero
@onready var _header: Control = %Header
@onready var _rows_box: VBoxContainer = %Rows


func _ready() -> void:
	_header.custom_minimum_size.y = HEADER_HEIGHT


## Monta uma linha por estatística; chame uma vez, com a cena na árvore.
func setup_rows(names: Array[String], icons: Array[Texture2D]) -> void:
	for i: int in names.size():
		var row := MatchEndRow.new()
		row.setup(names[i], icons[i])
		_rows_box.add_child(row)
		rows.append(row)


## Cabeçalho do jogador. [param tone]: Win, Lose ou Draw. [param tag] vazio esconde o selo e
## [param level] 0 esconde a pílula de nível (sem herói, sem nível).
func show_player(
	tone: StringName,
	side: String,
	who: String,
	hero_text: String,
	icon: Texture2D,
	level: int,
	tag: String
) -> void:
	theme_type_variation = StringName("EndCard" + tone)
	icon_box.theme_type_variation = StringName("EndIcon" + tone)
	icon_rect.texture = icon
	level_label.theme_type_variation = StringName("LabelEndLevel" + tone)
	level_label.text = tr("NV.%d") % level
	level_label.visible = level > 0
	side_label.theme_type_variation = StringName("LabelEndReason" + tone)
	side_label.text = side
	tag_label.theme_type_variation = StringName("LabelEndTag" + tone)
	tag_label.text = tag
	tag_label.visible = tag != ""
	name_label.text = who
	hero_label.text = hero_text
	hero_label.visible = hero_text != ""
