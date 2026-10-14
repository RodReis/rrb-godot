class_name DynamiteCrateVfx
extends VfxOneShot
## Caixa de Dinamite do Engenheiro (F59, SPEC-059 §6), so cliente: a caixa voa em arco da mao ate o
## ponto em FLY_SECONDS (o servidor ja a posicionou), faiscas correm no pavio, a caixa pisca cada
## vez mais rapido e o anel vermelho de raio 4,5 u cresce ate a explosao, que nasce aqui (bola de
## fogo do F54, anel de choque e destrocos). O raio chega pelo play (engineer.tres) e o tempo que
## falta pelo arm; quem chega atrasado ve so o que falta.

const BURST: PackedScene = preload("res://scenes/vfx/fire_burst.tscn")
const BLAST: PackedScene = preload("res://scenes/vfx/dynamite_blast.tscn")
## Arremesso em arco: duracao (s) e altura do topo (u).
const FLY_SECONDS: float = 0.4
const ARC_HEIGHT: float = 1.6
## Frequencia do pisca (Hz) no inicio do pavio e na explosao.
const BLINK_START_HZ: float = 2.0
const BLINK_END_HZ: float = 16.0
## O anel nasce com esta fracao do raio e cresce ate o raio inteiro na explosao.
const RING_START: float = 0.15
## Folga (s) depois da explosao para o efeito nao acabar no mesmo quadro dela.
const END_PAD: float = 0.1

## Pool onde a explosao nasce; definido logo depois do play.
var pool: VfxPool

var _from: Vector3 = Vector3.ZERO
var _fuse: float = 0.0
var _fly: float = 0.0
var _radius: float = 0.0
var _blink: float = 0.0
var _exploded: bool = false

@onready var _crate: Node3D = $Crate
@onready var _glow: MeshInstance3D = $Crate/Glow
@onready var _sparks: GPUParticles3D = $Crate/Fuse
@onready var _ring: MeshInstance3D = $Ring


func _process(delta: float) -> void:
	if not visible:
		return
	if not _exploded and _age + delta >= _fuse:
		_explode()
	super(delta)
	if _exploded:
		return
	_crate.global_position = _position_at(_age)
	var progress := clampf(_age / _fuse, 0.0, 1.0)
	_blink += delta * lerpf(BLINK_START_HZ, BLINK_END_HZ, progress)
	_glow.visible = fmod(_blink, 1.0) < 0.5 and _age >= _fly
	var ring_scale := _radius * lerpf(RING_START, 1.0, progress)
	_ring.scale = Vector3(ring_scale, 1.0, ring_scale)


## A caixa sai de [param from] (mao do Engenheiro) e explode em [param seconds]; a explosao nasce
## no [param p_pool]. Chamado logo depois do play.
func arm(from: Vector3, seconds: float, p_pool: VfxPool) -> void:
	_from = from
	_fuse = maxf(seconds, 0.0)
	_fly = minf(FLY_SECONDS, _fuse)
	lifetime = _fuse + END_PAD
	pool = p_pool
	_exploded = false
	_blink = 0.0
	_crate.visible = true
	_ring.visible = true
	_sparks.restart()


func _apply_radius(radius: float) -> void:
	_radius = radius


func _explode() -> void:
	_exploded = true
	_crate.visible = false
	_ring.visible = false
	var at := Transform3D(Basis.IDENTITY, global_position)
	if pool != null:
		pool.spawn(BURST, at, _radius)
		pool.spawn(BLAST, at, _radius)


## Posicao da caixa no instante [param age]: arco da mao ao ponto, depois parada nele.
func _position_at(age: float) -> Vector3:
	var t := 1.0 if _fly <= 0.0 else clampf(age / _fly, 0.0, 1.0)
	return _from.lerp(global_position, t) + Vector3.UP * ARC_HEIGHT * 4.0 * t * (1.0 - t)
