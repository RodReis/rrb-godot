class_name DayNight
extends Node
## Ciclo dia/noite (F49, SPEC-049): so cliente, so visual. Le o MatchClock (mesmo relogio nos dois
## clientes, sem RPC por quadro) e o sentido sorteado pela seed (MatchController.day_to_night),
## amostra a curva do DayNightProfile e aplica no Sun, no Environment, no ceu e na emissao de
## magma, cristais e rio. Selecao de herois: progresso 0. Partida que acaba antes dos 10:00
## congela; depois dela fica na ponta. Servidor headless nao cria este node (main).

const PROFILE_PATH: String = "res://shared/data/visual/day_night.tres"
const MATERIALS_DIR: String = "res://shared/resources/materials/"
## Materiais cuja emissao escala com a luz (uniform day_night_emission nos shaders).
const EMISSIVE_MATERIALS: Array[String] = [
	"volcanic_lava.tres",
	"arcane_river.tres",
	"arcane_crystal_magenta.tres",
	"arcane_crystal_cyan.tres",
	"arcane_crystal_green.tres",
]
const EMISSION_PARAM: StringName = &"day_night_emission"
const SKY_AMOUNT_PARAM: StringName = &"day_amount"
const SKY_SUN_PARAM: StringName = &"sun_direction"
## Mudou menos que isso, nada a reaplicar (uns 0,01 s de partida; invisivel).
const MIN_STEP: float = 0.00002
## A ReflectionProbe (UPDATE_ONCE) guarda o ceu do 1o quadro: refaz-se em tantos degraus da
## partida, cada um por poucos quadros em UPDATE_ALWAYS.
const PROBE_STEPS: int = 8
const PROBE_REFRESH_FRAMES: int = 2

@export var profile: DayNightProfile

var _clock: MatchClock
var _match: MatchController
var _sun: DirectionalLight3D
var _env: Environment
var _sky: ShaderMaterial
var _probe: ReflectionProbe
var _emissive: Array[ShaderMaterial] = []
var _key: DayNightKey = DayNightKey.new()
var _last_night: float = -1.0
var _probe_step: int = 0
var _probe_frames_left: int = 0


## So quem desenha tem luz para animar (nunca o servidor headless).
static func wanted() -> bool:
	return DisplayServer.get_name() != "headless"


func _ready() -> void:
	set_process(false)


## Liga o ciclo aos nodes da arena e ja aplica o estado atual (a selecao mostra o inicio).
## [param probe] e opcional.
func bind(
	clock: MatchClock,
	controller: MatchController,
	sun: DirectionalLight3D,
	world: WorldEnvironment,
	probe: ReflectionProbe = null
) -> void:
	if profile == null:
		profile = load(PROFILE_PATH) as DayNightProfile
	_clock = clock
	_match = controller
	_sun = sun
	_env = world.environment
	_sky = _own_sky_material(_env)
	_probe = probe
	_emissive.clear()
	for file: String in EMISSIVE_MATERIALS:
		_emissive.append(load(MATERIALS_DIR + file) as ShaderMaterial)
	apply(NetworkTime.tick)
	set_process(true)


## Aplica a luz do tick [param tick] (testavel sem NetworkTime).
func apply(tick: int) -> void:
	var progress := DayNightRules.progress(_clock.elapsed(tick), _clock.rules.max_match_duration)
	var night := DayNightRules.night_amount(progress, _match.day_to_night)
	if absf(night - _last_night) < MIN_STEP:
		return
	_last_night = night
	profile.sample(night, _key)
	_apply_sun(_key)
	_apply_environment(_key)
	_apply_sky(_key)
	for material: ShaderMaterial in _emissive:
		material.set_shader_parameter(EMISSION_PARAM, _key.emission_scale)
	_refresh_probe(night)


func _process(_delta: float) -> void:
	apply(NetworkTime.tick)
	if _probe_frames_left > 0:
		_probe_frames_left -= 1
		if _probe_frames_left == 0:
			_probe.update_mode = ReflectionProbe.UPDATE_ONCE


## Copia propria do material do ceu: o .tres compartilhado nao carrega o estado da partida.
func _own_sky_material(env: Environment) -> ShaderMaterial:
	if env.sky == null or not env.sky.sky_material is ShaderMaterial:
		push_warning("[daynight] ambiente sem ceu de shader: o ceu nao acompanha o ciclo")
		return null
	var sky := env.sky.duplicate() as Sky
	var material := (sky.sky_material as ShaderMaterial).duplicate() as ShaderMaterial
	sky.sky_material = material
	env.sky = sky
	return material


func _apply_sun(key: DayNightKey) -> void:
	_sun.rotation_degrees = Vector3(key.sun_pitch_deg, key.sun_yaw_deg, 0.0)
	_sun.light_color = key.sun_color
	_sun.light_energy = key.sun_energy
	_sun.shadow_blur = key.sun_shadow_blur


func _apply_environment(key: DayNightKey) -> void:
	_env.ambient_light_color = key.ambient_color
	_env.ambient_light_energy = key.ambient_energy
	_env.tonemap_exposure = key.exposure
	_env.volumetric_fog_density = key.fog_density
	_env.volumetric_fog_albedo = key.fog_albedo
	_env.fog_light_color = key.fog_albedo


func _apply_sky(key: DayNightKey) -> void:
	if _sky == null:
		return
	_sky.set_shader_parameter(SKY_AMOUNT_PARAM, key.sky_day)
	_sky.set_shader_parameter(SKY_SUN_PARAM, _sun.basis.z)


## O degrau sai de `night` (nao do progresso): se o sentido chegar depois do bind, a sonda tambem
## troca de estado.
func _refresh_probe(night: float) -> void:
	if _probe == null:
		return
	var step := int(night * PROBE_STEPS)
	if step == _probe_step:
		return
	_probe_step = step
	_probe.update_mode = ReflectionProbe.UPDATE_ALWAYS
	_probe_frames_left = PROBE_REFRESH_FRAMES
