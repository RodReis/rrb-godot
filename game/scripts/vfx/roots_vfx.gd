class_name RootsVfx
extends VfxOneShot
## Raizes Vivas do Protetor da Selva (F74, SPEC-074 §VFX), so cliente: raizes (root_tendril.glb)
## brotam em anel em volta do alvo atingido (crescem em GROW_SECONDS com um pequeno excesso),
## ficam pelo tempo do enraizamento e encolhem em SHRINK_SECONDS. O anel e as inclinacoes sao
## fixos por indice (sem sorteio): o mesmo efeito reaproveitado do pool repete. O radius do play
## escala o efeito inteiro (anel e raizes).

const TENDRIL: PackedScene = preload("res://shared/assets/rrb/vfx/root_tendril.glb")
const COUNT: int = 8
## Distancia das raizes ao alvo (u, a escala 1) e inclinacao para fora (graus).
const RING_RADIUS: float = 0.55
const LEAN_DEGREES: float = 18.0
const GROW_SECONDS: float = 0.2
const SHRINK_SECONDS: float = 0.25
## Quanto o brotar passa da escala 1 antes de assentar (ease-out-back).
const GROW_OVERSHOOT: float = 1.7
## Escala minima: escala 0 deixa a base singular e as posicoes dos filhos viram NaN.
const MIN_SCALE: float = 0.001
## Variacao do tamanho de cada raiz (fracao), fixa por indice.
const SIZE_JITTER: Array[float] = [1.0, 0.8, 1.15, 0.9, 1.1, 0.85, 1.05, 0.95]

## Peca que brota (padrao: a raiz do Druida; o Carrasco usa espinhos, F98).
@export var tendril_scene: PackedScene = TENDRIL

var _tendrils: Array[Node3D] = []


func _ready() -> void:
	for i: int in COUNT:
		var tendril := tendril_scene.instantiate() as Node3D
		var angle := TAU * i / COUNT + 0.3 * (i % 2)
		tendril.position = Vector3(cos(angle), 0.0, sin(angle)) * RING_RADIUS
		tendril.rotation = Vector3(0.0, -angle, 0.0)
		tendril.rotate_object_local(Vector3.FORWARD, deg_to_rad(LEAN_DEGREES))
		add_child(tendril)
		_tendrils.append(tendril)
	super()


func _process(delta: float) -> void:
	super(delta)
	if not visible:
		return
	var grow := _grow_at(_age)
	var shrink := clampf((lifetime - _age) / SHRINK_SECONDS, 0.0, 1.0)
	for i: int in _tendrils.size():
		var size := maxf(grow * shrink * SIZE_JITTER[i], MIN_SCALE)
		_tendrils[i].scale = Vector3.ONE * size


## Fica [param seconds] em pe (depois do play); o tempo de encolher soma por fora.
func last(seconds: float) -> void:
	lifetime = seconds + SHRINK_SECONDS


func _apply_radius(radius: float) -> void:
	scale = Vector3.ONE * radius


## 0 -> 1 em GROW_SECONDS, com excesso (ease-out-back).
func _grow_at(age: float) -> float:
	var t := clampf(age / GROW_SECONDS, 0.0, 1.0)
	var c := GROW_OVERSHOOT
	return 1.0 + (c + 1.0) * pow(t - 1.0, 3.0) + c * pow(t - 1.0, 2.0)
