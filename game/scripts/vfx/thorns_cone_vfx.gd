class_name ThornsConeVfx
extends VfxOneShot
## Espinhos do Carrasco, golpe (F98, SPEC-098 §4), so cliente: espinhos (thorn_spike.glb) rompem do
## chao em fileiras pelo cone a frente, da mais perto para a mais longe (a onda corre para fora),
## inclinados para fora, e afundam no fim. Fileiras e inclinacoes fixas por indice (sem sorteio): o
## efeito reaproveitado do pool repete. O radius do play e o alcance do golpe (a escala 1 = 1 u); a
## abertura vem de set_arc.

const SPIKE: PackedScene = preload("res://shared/assets/rrb/vfx/thorn_spike.glb")
## Fileiras: distancia (fracao do alcance) e quantos espinhos cada uma tem.
const ROWS: Array[float] = [0.3, 0.52, 0.74, 0.96]
const COUNTS: Array[int] = [3, 4, 5, 6]
## Inclinacao para fora e para a frente (graus) e variacao do tamanho, por indice.
const LEAN_DEGREES: float = 22.0
const SIZE_JITTER: Array[float] = [1.0, 0.8, 1.2, 0.9, 1.1, 0.85]
const GROW_SECONDS: float = 0.09
## Atraso da onda (s) da 1a a ultima fileira.
const WAVE_SECONDS: float = 0.14
const SINK_SECONDS: float = 0.3
## Afunda ate esta fracao do comprimento do espinho (u, a escala 1).
const SINK_DEPTH: float = 0.75
const MIN_SCALE: float = 0.001

var _spikes: Array[Node3D] = []
var _delays: PackedFloat32Array = PackedFloat32Array()
var _sizes: PackedFloat32Array = PackedFloat32Array()
var _half_arc: float = PI / 4.0


func _ready() -> void:
	_build()
	super()


func _process(delta: float) -> void:
	super(delta)
	if not visible:
		return
	var sink := clampf((lifetime - _age) / SINK_SECONDS, 0.0, 1.0)
	for i: int in _spikes.size():
		var grow := clampf((_age - _delays[i]) / GROW_SECONDS, 0.0, 1.0)
		var spike := _spikes[i]
		spike.scale = Vector3.ONE * maxf(_sizes[i] * ease(grow, 0.4), MIN_SCALE)
		spike.position.y = -(1.0 - sink) * SINK_DEPTH * _sizes[i]


## Abertura total do cone (graus); refaz as posicoes se mudou.
func set_arc(degrees: float) -> void:
	var half := deg_to_rad(degrees) / 2.0
	if is_equal_approx(half, _half_arc):
		return
	_half_arc = half
	_place()


func _apply_radius(radius: float) -> void:
	scale = Vector3(radius, radius, radius)


func _build() -> void:
	var index := 0
	for row: int in ROWS.size():
		for k: int in COUNTS[row]:
			var spike := SPIKE.instantiate() as Node3D
			add_child(spike)
			_spikes.append(spike)
			_delays.append(WAVE_SECONDS * row / (ROWS.size() - 1))
			_sizes.append(SIZE_JITTER[index % SIZE_JITTER.size()] * (0.7 + 0.15 * row))
			index += 1
	_place()


## Posicao e inclinacao de cada espinho pela fileira e pela abertura (frente = -Z).
func _place() -> void:
	var index := 0
	for row: int in ROWS.size():
		var count := COUNTS[row]
		for k: int in count:
			var t := (k + 0.5) / count * 2.0 - 1.0 + 0.12 * (row % 2) / count
			var angle := t * _half_arc
			var dir := Vector3(sin(angle), 0.0, -cos(angle))
			var spike := _spikes[index]
			spike.position = dir * ROWS[row]
			spike.basis = Basis.IDENTITY
			var out := dir.cross(Vector3.UP).normalized()
			spike.rotate(out, -deg_to_rad(LEAN_DEGREES))
			index += 1
