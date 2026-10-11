@tool
extends Node
## Bake do LightmapGI da arena dentro do editor (F38). No Godot 4.7.2 o bake nao e exposto a
## script (LightmapGI nao tem bake() na API; so o plugin do editor chama): esta ferramenta abre a
## cena, seleciona o LightmapGI, aperta o botao "Bake Lightmaps" do plugin e confere o dado.
## No 1o bake (sem LightmapGIData) o plugin abre um dialogo de arquivo: a ferramenta confirma
## <cena>.lmbake. Depois o caminho sai do proprio dado; a textura fica ao lado.
## A cena NAO e salva aqui: o tools/bake-lightmap.ps1 roda o builder em seguida, que liga o
## .lmbake (edite o builder, nao a cena). So roda com -- --bake-lightmap; o .ps1 copia este
## script para uma pasta temporaria do projeto e abre a cena dele no editor.
## Imprime "[bake] OK" ou "[bake] FALHA: ..." e fecha o editor.

const DEFAULT_SCENE: String = "res://scenes/arena/ilha_arcana.tscn"
const LIGHTMAP_NODE: String = "LightmapGI"
## Quadros para o editor terminar de abrir a janela/cena antes de cada passo.
const SETTLE_FRAMES: int = 30
const STEP_FRAMES: int = 10

## Ao abrir a arena o editor troca de aba e tira este node da arvore: o SceneTree fica guardado.
var _tree: SceneTree


func _ready() -> void:
	if Engine.is_editor_hint() and "--bake-lightmap" in OS.get_cmdline_user_args():
		_tree = get_tree()
		_bake.call_deferred()


func _bake() -> void:
	var scene := DEFAULT_SCENE
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--scene="):
			scene = arg.trim_prefix("--scene=")
	await _frames(SETTLE_FRAMES)
	while EditorInterface.get_resource_filesystem().is_scanning():
		await _frames(STEP_FRAMES)
	EditorInterface.set_main_screen_editor("3D")
	EditorInterface.open_scene_from_path(scene)
	await _frames(STEP_FRAMES)
	var root := EditorInterface.get_edited_scene_root()
	if root == null or root.scene_file_path != scene:
		_finish("cena %s nao abriu" % scene)
		return
	var lightmap := root.get_node_or_null(LIGHTMAP_NODE) as LightmapGI
	if lightmap == null:
		_finish("%s sem o node %s (rode o builder)" % [scene, LIGHTMAP_NODE])
		return
	EditorInterface.edit_node(lightmap)
	await _frames(STEP_FRAMES)
	var button := _bake_button(EditorInterface.get_base_control())
	if button == null:
		_finish("botao de bake do LightmapGI nao encontrado")
		return
	var data_path := scene.get_basename() + ".lmbake"
	var before := (
		FileAccess.get_modified_time(data_path) if FileAccess.file_exists(data_path) else 0
	)
	var started := Time.get_ticks_msec()
	button.pressed.emit()  # bake sincrono, com a barra de progresso do editor
	await _frames(STEP_FRAMES)
	if lightmap.light_data == null:
		# 1o bake: sem LightmapGIData o plugin abre o dialogo de arquivo ja com <cena>.lmbake.
		var dialog := _visible_file_dialog()
		if dialog == null:
			_finish("bake sem dado e sem dialogo de arquivo (%s)" % _editor_warning())
			return
		print("[bake] 1o bake: dialogo sugere %s; usando %s" % [dialog.current_path, data_path])
		dialog.hide()
		dialog.file_selected.emit(data_path)
		await _frames(STEP_FRAMES)
	var data := lightmap.light_data
	if data == null or data.resource_path.is_empty():
		_finish("bake nao gerou LightmapGIData (%s)" % _editor_warning())
		return
	# Rebake: o builder ja liga o .lmbake antigo; se o plugin falhar, o dado velho continua la.
	if FileAccess.get_modified_time(data.resource_path) <= before:
		_finish("%s nao foi regravado (%s)" % [data.resource_path, _editor_warning()])
		return
	print(
		(
			"[bake] OK %s: %d malhas, %d s"
			% [data.resource_path, data.get_user_count(), (Time.get_ticks_msec() - started) / 1000]
		)
	)
	_finish("")


## O botao do plugin tem o icone "Bake" do tema do editor e so aparece na barra do editor 3D com
## um LightmapGI selecionado (os do VoxelGI e do NavigationRegion3D usam o mesmo icone e ficam em
## containers escondidos). Busca inclui nodes internos.
func _bake_button(from: Node) -> Button:
	var icon := EditorInterface.get_editor_theme().get_icon("Bake", "EditorIcons")
	var found: Button = null
	var pending: Array[Node] = [from]
	while not pending.is_empty():
		var node: Node = pending.pop_back()
		var button := node as Button
		if button != null and button.icon == icon:
			var shown := button.is_visible_in_tree()
			print("[bake] botao com icone Bake: '%s' na tela=%s" % [button.text, shown])
			if shown:
				found = button
		pending.append_array(node.get_children(true))
	return found


func _visible_file_dialog() -> EditorFileDialog:
	var pending: Array[Node] = [EditorInterface.get_base_control().get_tree().root]
	while not pending.is_empty():
		var node: Node = pending.pop_back()
		var dialog := node as EditorFileDialog
		if dialog != null and dialog.visible:
			return dialog
		pending.append_array(node.get_children(true))
	return null


## Texto do aviso que o plugin mostra em dialogo quando o bake falha (nao vai para o log).
func _editor_warning() -> String:
	var texts: PackedStringArray = []
	var pending: Array[Node] = [EditorInterface.get_base_control().get_tree().root]
	while not pending.is_empty():
		var node: Node = pending.pop_back()
		var dialog := node as AcceptDialog
		if dialog != null and dialog.visible and not dialog.dialog_text.is_empty():
			texts.append(dialog.dialog_text)
		pending.append_array(node.get_children(true))
	return " | ".join(texts) if not texts.is_empty() else "sem aviso na tela"


## Fecha sem salvar a cena da arena e sai do editor. A cena temporaria desta ferramenta fica
## aberta (fecha-la libera este node no meio da funcao); o .ps1 apaga a pasta depois.
func _finish(error: String) -> void:
	if not error.is_empty():
		push_error("[bake] FALHA: " + error)
	EditorInterface.close_scene()
	_tree.quit(0 if error.is_empty() else 1)


func _frames(count: int) -> void:
	for i: int in range(count):
		await _tree.process_frame
