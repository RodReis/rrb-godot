class_name LauncherScreen
extends Control
## Base das telas do Launcher (FRONTEND-LAUNCHER §2-§3): a tela emite, o App decide. O ScreenStack
## liga back_requested ao pop e diz se ha tela abaixo (can_go_back) para a tela mostrar o voltar.

signal back_requested

## Ha tela abaixo na pilha? Sem ela, o botao de voltar nao aparece (nada de botao morto, §8.3).
var can_go_back: bool = false:
	set(value):
		can_go_back = value
		_can_go_back_changed()


## Virtual: a tela mostra ou esconde o proprio botao de voltar.
func _can_go_back_changed() -> void:
	pass
