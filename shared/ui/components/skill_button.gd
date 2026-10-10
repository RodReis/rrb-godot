class_name SkillButton
extends TextureProgressBar
## Habilidade na HUD (COMPONENTS.md): icone, tecla, rank e recarga radial com os segundos.
## Icone e placeholder (quadrado com a inicial, DEBITO DS-06). Estados: LOCKED (sem rank
## ainda, ex.: R antes do nivel 6), COOLING, READY; upgradable (ponto livre) poe moldura GOLD.
## Cena: chame bind()/set_*() depois de entrar na arvore (os nos internos sao @onready).

enum State { LOCKED, READY, COOLING }

const FRAME_READY: StringName = &"SkillFrame"
const FRAME_UPGRADABLE: StringName = &"SkillFrameUpgradable"
## Opacidade do veu da recarga sobre o icone.
const COOLDOWN_VEIL_ALPHA: float = 0.75

static var _blank: ImageTexture

@export var hotkey: String = "":
	set(value):
		hotkey = value
		if is_node_ready():
			_hotkey.key = value

var state: State = State.READY
var upgradable: bool = false

var _required_level: int = 0
var _locked: bool = false
var _remaining: float = 0.0

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


func set_upgradable(on: bool) -> void:
	upgradable = on
	_frame.theme_type_variation = FRAME_UPGRADABLE if on else FRAME_READY


func _refresh() -> void:
	if _locked:
		state = State.LOCKED
	elif _remaining > 0.0:
		state = State.COOLING
	else:
		state = State.READY
	modulate.a = UiTokens.DISABLED_ALPHA if state == State.LOCKED else 1.0
	_letter.visible = state == State.READY
	_cooldown.visible = state != State.READY
	if state == State.LOCKED:
		_cooldown.text = tr("Nv%d") % _required_level
		value = 0.0
	elif state == State.COOLING:
		_cooldown.text = cooldown_text(_remaining)
