class_name ShacklesVfx
extends VfxOneShot
## Correntes do Julgamento no alvo preso (F98, SPEC-098 §4), so cliente: dois aneis de elos
## (chain_link.glb) em volta do alvo, um nos tornozelos e outro na cintura, apertam ao chegar e
## giram devagar pela duracao da raiz; somem encolhendo. Anel e elos fixos por indice (sem
## sorteio).

const LINK: PackedScene = preload("res://shared/assets/rrb/vfx/chain_link.glb")
## Elos por anel, alturas (u) e raios (u) dos aneis.
const PER_RING: int = 12
const HEIGHTS: Array[float] = [0.25, 1.05]
const RADII: Array[float] = [0.48, 0.55]
const SPIN: float = 0.15
const GRIP_SECONDS: float = 0.15
const SHRINK_SECONDS: float = 0.2
## O anel chega de mais longe e aperta ate o raio dele.
const GRIP_FROM: float = 2.2
const MIN_SCALE: float = 0.001

var _rings: Array[Node3D] = []

## Elo da cena: so molde do warm-up de shaders, fica escondido.
@onready var _template: Node3D = $Link


func _ready() -> void:
	_template.visible = false
	for r: int in HEIGHTS.size():
		var ring := Node3D.new()
		ring.position.y = HEIGHTS[r]
		add_child(ring)
		for i: int in PER_RING:
			var link := LINK.instantiate() as Node3D
			var angle := TAU * i / PER_RING
			# Elo deitado na tangente do anel, alternando o giro como numa corrente de verdade.
			link.position = Vector3(cos(angle), 0.0, sin(angle)) * RADII[r]
			link.rotation = Vector3(0.0, -angle, PI / 2.0 * (i % 2))
			ring.add_child(link)
		_rings.append(ring)
	super()


func _process(delta: float) -> void:
	super(delta)
	if not visible:
		return
	var grip := clampf(_age / GRIP_SECONDS, 0.0, 1.0)
	var shrink := clampf((lifetime - _age) / SHRINK_SECONDS, 0.0, 1.0)
	var spread := lerpf(GRIP_FROM, 1.0, ease(grip, 0.3))
	for r: int in _rings.size():
		var ring := _rings[r]
		var size := maxf(spread * shrink, MIN_SCALE)
		ring.scale = Vector3(size, maxf(shrink, MIN_SCALE), size)
		ring.rotation.y += TAU * SPIN * delta * (1.0 if r == 0 else -1.0)


## Fica [param seconds] preso (depois do play); o tempo de soltar soma por fora.
func last(seconds: float) -> void:
	lifetime = seconds + SHRINK_SECONDS
