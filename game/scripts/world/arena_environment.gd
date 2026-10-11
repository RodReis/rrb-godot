class_name ArenaEnvironment
extends WorldEnvironment
## Ambiente da arena (F38): aplica os toggles de [graphics] do settings.cfg (GraphicsSettings)
## sobre uma copia do Environment gerado pelo builder. So cliente; no servidor headless nada muda.


func _ready() -> void:
	if DisplayServer.get_name() == "headless" or environment == null:
		return
	var env := environment.duplicate() as Environment
	GraphicsSettings.apply(env, GraphicsSettings.load_file())
	environment = env
