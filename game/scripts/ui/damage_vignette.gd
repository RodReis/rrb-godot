class_name DamageVignette
extends CanvasLayer
## Alerta de dano nas laterais da tela (PI 2026-10-22): vermelho suave nas bordas quando o heroi
## local perde HP, apagando em FLASH_SECONDS; com HP baixo fica um pulso leve continuo
## (HudMath.damage_vignette). Mesmo shader da vinheta da zona (PATTERNS P8). So le o HP replicado;
## escondida na cinematica (INTRO), com o heroi morto e com o alerta desligado ([ui] damage_alert,
## no Launcher ou na engrenagem da partida).

const SHADER: Shader = preload("res://scenes/ui/zone_vignette.gdshader")
const FLASH_SECONDS: float = 0.5
## Abaixo da HUD (as fases ficam na camada 1).
const LAYER: int = 0

## [ui] damage_alert do settings.cfg: o Main aplica no boot, a engrenagem troca na partida.
static var enabled: bool = true

var _hero: Hero
var _shown_hp: int = -1
var _flash: float = 0.0
var _rect: ColorRect = ColorRect.new()
var _material: ShaderMaterial = ShaderMaterial.new()


func _ready() -> void:
	layer = LAYER
	_material.shader = SHADER
	_material.set_shader_parameter(&"color", UiTokens.RED)
	_material.set_shader_parameter(&"pulse_period", UiTokens.PULSE_ZONE)
	_rect.material = _material
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.visible = false
	add_child(_rect)
	set_process(false)


func bind(hero: Hero) -> void:
	_hero = hero
	_shown_hp = hero.hp
	_flash = 0.0
	set_process(true)


## Intensidade mostrada agora (0 = escondida).
func intensity() -> float:
	if not _rect.visible:
		return 0.0
	var value: float = _material.get_shader_parameter(&"intensity")
	return value


func _process(delta: float) -> void:
	if not is_instance_valid(_hero):
		_rect.visible = false
		set_process(false)
		return
	var hp := _hero.hp
	_flash = HudMath.damage_flash(_flash, hp < _shown_hp, delta, FLASH_SECONDS)
	_shown_hp = hp
	var ratio := float(hp) / maxi(_hero.attributes.max_hp, 1)
	var value := HudMath.damage_vignette(_flash, ratio, _hero.is_alive())
	_rect.visible = enabled and value > 0.0 and not PlayerInput.cinematic
	if _rect.visible:
		_material.set_shader_parameter(&"intensity", value)
