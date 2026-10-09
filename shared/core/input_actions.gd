class_name InputActions
extends RefCounted
## Nomes das acoes de input (CONVENTION.md §6), usados pelo Game e pelo Launcher.
## ensure() registra todas no InputMap com teclado/mouse e gamepad (DV §3.3).
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

# Mapeamento padrao: DV §3.3; esquiva no gamepad = A/Cruz (PI 2026-10-09).
const KEYS: Dictionary = {
	MOVE_FORWARD: KEY_W,
	MOVE_BACK: KEY_S,
	MOVE_LEFT: KEY_A,
	MOVE_RIGHT: KEY_D,
	SKILL_Q: KEY_Q,
	SKILL_E: KEY_E,
	SKILL_R: KEY_R,
	INTERACT: KEY_F,
	DODGE: KEY_SPACE,
	SCOREBOARD: KEY_TAB,
	CANCEL: KEY_ESCAPE,
	OPEN_BESTIARY: KEY_B,
}
const MOUSE_BUTTONS: Dictionary = {
	PRIMARY_ATTACK: MOUSE_BUTTON_LEFT,
}
## acao -> [eixo, sentido]
const JOY_AXES: Dictionary = {
	MOVE_FORWARD: [JOY_AXIS_LEFT_Y, -1.0],
	MOVE_BACK: [JOY_AXIS_LEFT_Y, 1.0],
	MOVE_LEFT: [JOY_AXIS_LEFT_X, -1.0],
	MOVE_RIGHT: [JOY_AXIS_LEFT_X, 1.0],
	PRIMARY_ATTACK: [JOY_AXIS_TRIGGER_RIGHT, 1.0],
	SKILL_R: [JOY_AXIS_TRIGGER_LEFT, 1.0],
}
const JOY_BUTTONS: Dictionary = {
	SKILL_Q: JOY_BUTTON_LEFT_SHOULDER,
	SKILL_E: JOY_BUTTON_RIGHT_SHOULDER,
	INTERACT: JOY_BUTTON_X,
	DODGE: JOY_BUTTON_A,
	SCOREBOARD: JOY_BUTTON_BACK,
	CANCEL: JOY_BUTTON_B,
	OPEN_BESTIARY: JOY_BUTTON_DPAD_UP,
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
		if MOUSE_BUTTONS.has(action):
			var click := InputEventMouseButton.new()
			click.button_index = MOUSE_BUTTONS[action]
			InputMap.action_add_event(action, click)
		if JOY_AXES.has(action):
			var axis: Array = JOY_AXES[action]
			var motion := InputEventJoypadMotion.new()
			motion.axis = axis[0]
			motion.axis_value = axis[1]
			InputMap.action_add_event(action, motion)
		if JOY_BUTTONS.has(action):
			var button := InputEventJoypadButton.new()
			button.button_index = JOY_BUTTONS[action]
			InputMap.action_add_event(action, button)
