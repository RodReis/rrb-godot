class_name TurretVfx
extends VfxOneShot
## Torreta do Engenheiro (F59, SPEC-059 §6), so cliente: a malha do pack nasce com um pop de escala
## (0 -> 1 em POP_SECONDS) e 4 puffs de poeira, fica no lugar do servidor pela duracao do E, gira so
## a cabeca (turret_gun) para o ponto de cada disparo e encolhe em SHRINK_SECONDS com um puff no
## fim. A Torreta nao e um node do jogo: nasce do evento do ImpactRelay (deploy_shown) e cada tiro
## vem de turret_shot_shown; quem a ve e quem tem o ponto dela no raio de visao (F37).

## Duracao do pop de instalacao e do encolher do fim (s).
const POP_SECONDS: float = 0.25
const SHRINK_SECONDS: float = 0.25
## Quanto o pop passa da escala 1 antes de assentar (ease-out-back).
const POP_OVERSHOOT: float = 1.7
## Distancia (u) do eixo da cabeca ate a boca do cano, onde o clarao nasce.
const MUZZLE_REACH: float = 0.6
## Cabeca da Torreta na malha do pack (art/vfx/build_engineer_vfx.py).
const GUN_NODE: StringName = &"turret_gun"
## Giro (graus) que leva o cano da cabeca do pack para a frente do heroi (-Z).
@export var gun_yaw_offset_degrees: float = 0.0

## Engenheiro dono desta Torreta (peer_id), para a nova substituir so a dele.
var caster: int = 0

var _total: float = 0.0
var _gun: Node3D
var _end_played: bool = false

@onready var _model: Node3D = $Model
@onready var _install_dust: GPUParticles3D = $InstallDust
@onready var _end_dust: GPUParticles3D = $EndDust
@onready var _flash: GPUParticles3D = $Flash


func _ready() -> void:
	super()
	_gun = _model.find_child(GUN_NODE, true, false) as Node3D


func _process(delta: float) -> void:
	super(delta)
	if not visible:
		return
	_model.scale = Vector3.ONE * _scale_at(_age)
	if _age >= _total and not _end_played:
		_end_played = true
		_end_dust.restart()


## Fica [param seconds] a partir de agora (logo depois do play); [param caster_id] e o dono.
func last(seconds: float, caster_id: int) -> void:
	_total = seconds
	caster = caster_id
	lifetime = seconds + SHRINK_SECONDS
	_end_played = false
	_gun.rotation = Vector3.ZERO
	_install_dust.restart()


## Esta Torreta esta no ar e e do [param caster_id].
func is_up_for(caster_id: int) -> bool:
	return visible and caster == caster_id and _age < _total


## Encerra ja (a nova Torreta do mesmo Engenheiro a substitui): encolhe e some.
func retire() -> void:
	_total = minf(_total, _age)
	lifetime = _age + SHRINK_SECONDS


## A cabeca olha o ponto [param at] e a boca solta o clarao.
func shoot(at: Vector3) -> void:
	var flat := Vector3(at.x - global_position.x, 0.0, at.z - global_position.z)
	if not flat.is_zero_approx():
		_gun.global_rotation.y = atan2(-flat.x, -flat.z) + deg_to_rad(gun_yaw_offset_degrees)
		_flash.global_position = _gun.global_position + flat.normalized() * MUZZLE_REACH
	_flash.restart()


func _scale_at(age: float) -> float:
	if age >= _total:
		return clampf(1.0 - (age - _total) / SHRINK_SECONDS, 0.0, 1.0)
	return _pop(clampf(age / POP_SECONDS, 0.0, 1.0))


## Ease-out-back: 0 -> passa de 1 -> 1.
static func _pop(t: float) -> float:
	var c := POP_OVERSHOOT
	var u := t - 1.0
	return 1.0 + (c + 1.0) * u * u * u + c * u * u
