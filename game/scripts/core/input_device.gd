class_name InputDevice
extends RefCounted
## Qual dispositivo o jogador esta usando agora, para trocar teclado <-> gamepad em tempo
## real (mira pelo mouse ou pelo analogico direito).

## Abaixo disto o analogico e ruido e nao troca o dispositivo.
const STICK_DEADZONE: float = 0.2


static func uses_gamepad(event: InputEvent, current: bool) -> bool:
	if event is InputEventJoypadButton:
		return true
	if event is InputEventJoypadMotion:
		return absf((event as InputEventJoypadMotion).axis_value) > STICK_DEADZONE or current
	if event is InputEventKey or event is InputEventMouse:
		return false
	return current
