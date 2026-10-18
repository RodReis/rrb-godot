class_name CurseIndicator
extends Node3D
## Marcas de Maldicao (1 a 3 runas acima da placa) e nuvem da Praga no corpo de UM alvo (F77,
## SPEC-077 §VFX), so cliente. O CurseMarks le o estado replicado do alvo e chama apply; aqui so se
## desenha. Ocioso (sem marca, sem Praga, ou alvo fora da vista): set_process desligado e tudo
## oculto.

const MARK_COUNT: int = 3
## Distancia (u) entre runas da fileira, centrada no alvo (no eixo X do mundo).
const MARK_SPACING: float = 0.42
## Altura (u) das runas sobre a barra de HP (acima do rotulo de nivel).
const MARK_LIFT: float = 1.0
## Voltas por segundo das runas, e o balanco vertical (amplitude u, rad/s).
const MARK_SPIN: float = 0.5
const BOB_HEIGHT: float = 0.05
const BOB_SPEED: float = 3.0
## Marca nova: a runa nasce grande e assenta em POP_SECONDS (fracao a mais da escala).
const POP_SECONDS: float = 0.25
const POP_SCALE: float = 0.8
## Escala das runas (a malha tem 0,34 u de altura; a placa e lida a ~15 u).
const MARK_SCALE: float = 1.4
## A nuvem da Praga ocupa esta fracao da altura da barra de HP e esta largura (u).
const PLAGUE_HEIGHT_SHARE: float = 0.4
const PLAGUE_HALF_WIDTH: float = 0.4

var target: Combatant

var _bar_height: float = 2.4
var _stacks: int = 0
var _time: float = 0.0
var _pop: float = 0.0
var _marks: Array[Node3D] = []

@onready var _mist: GPUParticles3D = $Mist
@onready var _bubbles: GPUParticles3D = $Bubbles


func _ready() -> void:
	for i: int in MARK_COUNT:
		_marks.append(get_node("Mark%d" % i) as Node3D)
	for node: Node in find_children("*", "MeshInstance3D", true, false):
		(node as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	set_process(false)
	visible = false


func _process(delta: float) -> void:
	_time += delta
	_pop = maxf(_pop - delta, 0.0)
	var pop := 1.0 + POP_SCALE * (_pop / POP_SECONDS)
	for i: int in _stacks:
		var x := (i - (_stacks - 1) * 0.5) * MARK_SPACING
		var bob := sin(_time * BOB_SPEED + i * 1.7) * BOB_HEIGHT
		var mark := _marks[i]
		mark.position = Vector3(x, _bar_height + MARK_LIFT + bob, 0.0)
		mark.rotation.y = TAU * MARK_SPIN * _time + i * 1.3
		mark.scale = Vector3.ONE * MARK_SCALE * (pop if i == _stacks - 1 else 1.0)


## Liga ao [param p_target]; [param bar_height] = altura (u) da barra de HP dele.
func bind(p_target: Combatant, bar_height: float) -> void:
	target = p_target
	_bar_height = bar_height
	var half_height := bar_height * PLAGUE_HEIGHT_SHARE
	var extents := Vector3(PLAGUE_HALF_WIDTH, half_height, PLAGUE_HALF_WIDTH)
	for particles: GPUParticles3D in [_mist, _bubbles]:
		particles.position.y = half_height * 1.1
		(particles.process_material as ParticleProcessMaterial).emission_box_extents = extents


## [param stacks] marcas (0..3) e [param plague] (Praga ativa) do alvo; [param shown] = o jogador
## ve o alvo vivo.
func apply(stacks: int, plague: bool, shown: bool) -> void:
	var count := clampi(stacks, 0, MARK_COUNT) if shown else 0
	global_position = target.global_position
	if count > _stacks:
		_pop = POP_SECONDS
	_stacks = count
	for i: int in MARK_COUNT:
		_marks[i].visible = i < count
	var plaguing := plague and shown
	_mist.emitting = plaguing
	_bubbles.emitting = plaguing
	var active := count > 0
	visible = active or plaguing
	set_process(active)
