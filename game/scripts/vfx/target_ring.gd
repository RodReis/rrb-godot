class_name TargetRing
extends Node3D
## Anel no chao sob o alvo travado do heroi local (F66, SPEC-066 §4). So desenha: segue o node que
## Hero.target() devolve enquanto o jogador o ve, com o raio do corpo dele mais uma folga. Cena em
## scenes/vfx/ para entrar no pre-aquecimento de shaders (ShaderWarmup).

## Folga entre o corpo do alvo e o anel (u).
const MARGIN: float = 0.35
## Raio minimo do anel (u), para alvo sem capsula.
const MIN_RADIUS: float = 0.8
## Acima do chao para nao brigar com o terreno (u).
const LIFT: float = 0.06
## Raio do TorusMesh da cena (u): a escala leva ate o raio pedido.
const MESH_RADIUS: float = 1.0
## Achatamento do toro na vertical: vira uma faixa no chao.
const FLATTEN: float = 0.5

var _hero: Hero

@onready var _disc: Node3D = $Disc


func _ready() -> void:
	visible = false
	set_process(false)


## Liga ao heroi local; o anel acompanha o alvo travado dele.
func bind(hero: Hero) -> void:
	_hero = hero
	set_process(true)


func _process(_delta: float) -> void:
	if not is_instance_valid(_hero):
		visible = false
		set_process(false)
		return
	var target := _hero.target()
	visible = target != null and target.is_alive() and target.is_shown()
	if not visible:
		return
	var radius := maxf(target.body_radius() + MARGIN, MIN_RADIUS)
	var spread := radius / MESH_RADIUS
	_disc.scale = Vector3(spread, FLATTEN, spread)
	global_position = Vector3(target.global_position.x, LIFT, target.global_position.z)
