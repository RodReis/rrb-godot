class_name InputActions
extends RefCounted
## Nomes das acoes de input (CONVENTION.md §6), usados pelo Game e pelo Launcher.
## ensure() registra todas no InputMap; mapeamento completo (teclado/gamepad) vem em F31.
## Idempotente.

const MOVE_FORWARD: StringName = &"move_forward"
const MOVE_BACK: StringName = &"move_back"
const MOVE_LEFT: StringName = &"move_left"
const MOVE_RIGHT: StringName = &"move_right"
const PRIMARY_ATTACK: StringName = &"primary_attack"
const SKILL_Q: StringName = &"skill_q"
const SKILL_E: StringName = &"skill_e"
const SKILL_R: StringName = &"skill_r"
const INTERACT: StringName = &"interact"
const DODGE: StringName = &"dodge"
const SCOREBOARD: StringName = &"scoreboard"
const CANCEL: StringName = &"cancel"
const OPEN_BESTIARY: StringName = &"open_bestiary"

const ALL: Array[StringName] = [
	MOVE_FORWARD,
	MOVE_BACK,
	MOVE_LEFT,
	MOVE_RIGHT,
	PRIMARY_ATTACK,
	SKILL_Q,
	SKILL_E,
	SKILL_R,
	INTERACT,
	DODGE,
	SCOREBOARD,
	CANCEL,
	OPEN_BESTIARY,
]

const KEYS: Dictionary = {
	MOVE_FORWARD: KEY_W,
	MOVE_BACK: KEY_S,
	MOVE_LEFT: KEY_A,
	MOVE_RIGHT: KEY_D,
}
const MOUSE_BUTTONS: Dictionary = {
	PRIMARY_ATTACK: MOUSE_BUTTON_LEFT,
}


static func ensure() -> void:
	for action: StringName in ALL:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		if KEYS.has(action):
			var key := InputEventKey.new()
			key.physical_keycode = KEYS[action]
			InputMap.action_add_event(action, key)
		elif MOUSE_BUTTONS.has(action):
			var click := InputEventMouseButton.new()
			click.button_index = MOUSE_BUTTONS[action]
			InputMap.action_add_event(action, click)
