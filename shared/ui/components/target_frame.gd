class_name TargetFrame
extends PanelCard
## Moldura do alvo travado (F66, COMPONENTS.md): nome, etiqueta (nivel do heroi ou tier do
## monstro) e barra de HP inimiga com ghost. Some ao destravar. So mostra: quem alimenta e a HUD.
## Cena: chame bind()/set_hp() depois de entrar na arvore (os nos internos sao @onready).

var _hp_max: int = -1

@onready var _name: Label = %TargetName
@onready var _tag: Label = %TargetTag
@onready var _hp: StatBar = %TargetHp


func _ready() -> void:
	visible = false


## Mostra a moldura de um alvo novo.
func bind(target_name: String, tag: String, hp: int, hp_max: int) -> void:
	_name.text = target_name
	_tag.text = tag
	_hp_max = hp_max
	_hp.bind("", hp, hp_max, StatBar.Kind.HP_ENEMY)
	visible = true


## Segue o HP do mesmo alvo: queda desce a barra na hora e a ghost depois.
func set_hp(hp: int, hp_max: int) -> void:
	if hp_max != _hp_max:
		_hp_max = hp_max
		_hp.bind("", hp, hp_max, StatBar.Kind.HP_ENEMY)
	else:
		_hp.animate_to(hp)


func clear() -> void:
	visible = false
