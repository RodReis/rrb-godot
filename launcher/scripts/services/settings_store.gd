class_name SettingsStore
extends RefCounted
## Configuracoes do jogador (ARCHITECTURE-LAUNCHER §3.3): le e grava user://settings.cfg pelo
## contrato UserSettings (§5.3). Nao toca em no: quem aplica na janela e no audio e o App, ao ouvir
## saved.

signal saved(values: Dictionary)

var path: String = UserSettings.PATH
## Ultimos valores lidos ou gravados com sucesso.
var values: Dictionary = UserSettings.defaults()


func _init(p_path: String = UserSettings.PATH) -> void:
	path = p_path


func load_values() -> Dictionary:
	values = UserSettings.load_file(path)
	return values.duplicate(true)


## Grava e, se deu certo, guarda e avisa. Falha: valores anteriores mantidos, sem aviso.
func save(new_values: Dictionary) -> Error:
	var err := UserSettings.save_file(new_values, path)
	if err != OK:
		push_warning("[settings] falha ao gravar %s: %s" % [path, error_string(err)])
		return err
	values = new_values.duplicate(true)
	saved.emit(values.duplicate(true))
	return OK


func reset() -> Error:
	return save(UserSettings.defaults())
