class_name HotkeyHint
extends RefCounted
## Atalho mostrado no ScreenFooter: tecla e o que ela faz.

var key: String = ""
var label: String = ""


static func make(p_key: String, p_label: String) -> HotkeyHint:
	var hint := HotkeyHint.new()
	hint.key = p_key
	hint.label = p_label
	return hint
