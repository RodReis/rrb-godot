class_name DialogAction
extends RefCounted
## Botao do ModalDialog: rotulo e tipo (o destrutivo usa LnButtonDanger, PATTERNS P12).

enum Kind { NORMAL, PRIMARY, DANGER }

## Indice = Kind.
const TYPES: Array[StringName] = [&"LnButton", &"LnButtonPrimary", &"LnButtonDanger"]

var label: String = ""
var kind: Kind = Kind.NORMAL


static func make(p_label: String, p_kind: Kind = Kind.NORMAL) -> DialogAction:
	var action := DialogAction.new()
	action.label = p_label
	action.kind = p_kind
	return action
