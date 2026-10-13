class_name SkillButton
extends TextureProgressBar
## Habilidade na HUD (COMPONENTS.md): icone, tecla, rank e recarga radial com os segundos.
## Icone vem do SkillData (placeholder geometrico, DEBITO DS-06); sem icone, quadrado com a
## inicial. Tecla em badge metalica no canto inferior direito (TOKENS v2). Estados: LOCKED
## (sem rank ainda, ex.: R antes do nivel 6), COOLING, READY; upgradable (ponto livre) poe
## moldura dourada pulsando e, se ainda travada, troca o "Nv2" pelo atalho de aprender (F57).
## Cena: chame bind()/set_*() depois de entrar na arvore (os nos internos sao @onready).

enum State { LOCKED, READY, COOLING }

const FRAME_READY: StringName = &"SkillFrame"
const FRAME_UPGRADABLE: StringName = &"SkillFrameUpgradable"
## Opacidade do veu da recarga sobre o icone.
const COOLDOWN_VEIL_ALPHA: float = 0.75
## Pulso da moldura dourada: opacidade minima.
const PULSE_MIN_ALPHA: float = 0.35

static var _blank: ImageTexture

@export var hotkey: String = "":
	set(value):
		hotkey = value
		if is_node_ready():
			_hotkey.key = value

var state: State = State.READY
var upgradable: bool = false
## Atalho de aprender ("Ctrl+E"), mostrado no lugar do nivel minimo quando ha ponto livre.
var learn_key: String = ""

var _required_level: int = 0
var _locked: bool = false
var _remaining: float = 0.0
var _has_icon: bool = false
var _pulse: Tween

@onready var _letter: Label = %Letter
@onready var _cooldown: Label = %Cooldown
@onready var _rank: Label = %Rank
@onready var _hotkey: HotkeyBadge = %Hotkey
@onready var _frame: Panel = %Frame


func _ready() -> void:
	if _blank == null:
		var image := Image.create_empty(
			UiTokens.SIZE_SKILL, UiTokens.SIZE_SKILL, false, Image.FORMAT_RGBA8
		)
		image.fill(Color.WHITE)
		_blank = ImageTexture.create_from_image(image)
	texture_under = _blank
	texture_progress = _blank
	tint_under = UiTokens.BG_CARD
	tint_progress = Color(UiTokens.BG_SURFACE, COOLDOWN_VEIL_ALPHA)
	_hotkey.key = hotkey
	_refresh()


## Segundos de recarga: inteiro arredondado para cima; abaixo de 1 s, com decimo.
static func cooldown_text(remaining: float) -> String:
	if remaining >= 1.0:
		return str(ceili(remaining))
	return "%.1f" % remaining


func bind(skill: SkillData, rank: int) -> void:
	tooltip_text = skill.display_name
	_letter.text = skill.display_name.left(1).to_upper()
	_has_icon = skill.icon != null
	texture_under = skill.icon if _has_icon else _blank
	tint_under = Color.WHITE if _has_icon else UiTokens.BG_CARD
	_rank.text = str(rank) if rank > 0 else ""
	_required_level = (
		skill.required_hero_level[0] if not skill.required_hero_level.is_empty() else 0
	)
	_refresh()


func set_cooldown(remaining: float, total: float) -> void:
	_remaining = maxf(remaining, 0.0)
	value = _remaining / total if total > 0.0 else 0.0
	_refresh()


func set_locked(locked: bool) -> void:
	_locked = locked
	_refresh()


## Chamada a cada quadro pela HUD: so age quando muda.
func set_upgradable(on: bool) -> void:
	if on == upgradable:
		return
	upgradable = on
	_frame.theme_type_variation = FRAME_UPGRADABLE if on else FRAME_READY
	if _pulse != null:
		_pulse.kill()
		_pulse = null
	_frame.self_modulate.a = 1.0
	if on:
		_pulse = create_tween().set_loops()
		var half := UiTokens.PULSE_QUEUE / 2.0
		_pulse.tween_property(_frame, ^"self_modulate:a", PULSE_MIN_ALPHA, half)
		_pulse.tween_property(_frame, ^"self_modulate:a", 1.0, half)
	_refresh()


func _refresh() -> void:
	if _locked:
		state = State.LOCKED
	elif _remaining > 0.0:
		state = State.COOLING
	else:
		state = State.READY
	var dim := state == State.LOCKED and not upgradable
	modulate.a = UiTokens.DISABLED_ALPHA if dim else 1.0
	_letter.visible = state == State.READY and not _has_icon
	_cooldown.visible = state != State.READY
	if state == State.LOCKED:
		var learnable := upgradable and not learn_key.is_empty()
		_cooldown.text = learn_key if learnable else tr("Nv%d") % _required_level
		value = 0.0
	elif state == State.COOLING:
		_cooldown.text = cooldown_text(_remaining)
