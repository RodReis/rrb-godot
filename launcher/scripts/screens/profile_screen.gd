class_name ProfileScreen
extends LauncherScreen
## Perfil da conta (F35; FRONTEND-LAUNCHER §8: sem pasta de prototipo propria, usa a linguagem do
## formulario do Login e o chip do cabecalho do Menu Principal). Dois modos: SETUP, o 1o login
## (nickname obrigatorio antes do lobby, avatar opcional) e EDIT (so o avatar; o nickname ja
## definido aparece travado). O avatar e predefinido (retratos dos herois e monstros reais) ou
## upload PNG/JPG de ate 1 MB, recortado em 256x256 e guardado so em user://: nunca vai ao backend.
## Chama o ProfileService (nickname) e o AvatarStore (avatar); a tela so emite e o App decide.

## Nickname definido no 1o login: o App leva ao lobby.
signal completed
## Avatar trocado: o App atualiza o chip do cabecalho.
signal avatar_changed

enum Mode { SETUP, EDIT }

const CARD_WIDTH: float = 640.0
## Colunas da grade (16 retratos: 10 herois + 6 monstros) e o lado de cada ficha.
const TILE_COLUMNS: int = 6
const TILE_SIZE: Vector2 = Vector2(64, 64)
## Borda da ficha (LnAvatarTile): o retrato fica por dentro dela.
const TILE_BORDER: float = 2.0
## Moldura do avatar grande.
const PREVIEW_SIZE: Vector2 = Vector2(96, 96)
## Fundo: dois brilhos como no Login (cor, centro UV, raio px).
const GLOW_GOLD: Color = Color(UiTokens.GOLD, 0.10)
const GLOW_BLUE: Color = Color(UiTokens.BLUE, 0.15)

var _profile: ProfileService
var _avatars: AvatarStore
var _catalog: CatalogService
var _mode: Mode = Mode.SETUP
var _title: Label = Label.new()
var _subtitle: Label = Label.new()
var _banner: PanelContainer = PanelContainer.new()
var _banner_text: Label = Label.new()
var _nick_row: FormRow = FormRow.new()
var _nick: IconField = IconField.new()
var _rule: Label = Label.new()
var _avatar_row: FormRow = FormRow.new()
var _preview: PanelContainer = PanelContainer.new()
var _preview_image: TextureRect = TextureRect.new()
var _preview_glyph: Label = Label.new()
var _tiles_box: GridContainer = GridContainer.new()
var _tiles: Dictionary[String, Button] = {}
var _group: ButtonGroup = ButtonGroup.new()
var _upload: Button = Button.new()
var _dialog: FileDialog = FileDialog.new()
var _submit: Button = Button.new()


func _ready() -> void:
	var backdrop := Backdrop.new()
	backdrop.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	backdrop.glow(0, GLOW_GOLD, Vector2(0.03, 0.06), 256.0)
	backdrop.glow(1, GLOW_BLUE, Vector2(0.85, 0.95), 304.0)
	add_child(backdrop)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(center)
	center.add_child(_card())
	_dialog.use_native_dialog = true
	_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_dialog.filters = PackedStringArray(["*.png, *.jpg, *.jpeg ; Imagens PNG ou JPG"])
	_dialog.title = tr("Escolher imagem")
	_dialog.file_selected.connect(load_avatar_file)
	add_child(_dialog)
	_refresh()


## Liga a tela aos servicos e ao modo (o App decide: conta sem nickname = SETUP).
func bind(
	profile: ProfileService, avatars: AvatarStore, catalog: CatalogService, mode: Mode
) -> void:
	_profile = profile
	_avatars = avatars
	_catalog = catalog
	_mode = mode
	if is_node_ready():
		_refresh()


func mode() -> Mode:
	return _mode


## Envia (botao ou Enter). SETUP: valida e define o nickname; EDIT: so conclui (volta).
func submit() -> void:
	if _profile == null or _submit.disabled:
		return
	if _mode == Mode.EDIT:
		back_requested.emit()
		return
	_clear_errors()
	_set_busy(true)
	var result: ProfileService.Result = await _profile.set_nickname(_nick.line_edit.text)
	if not is_inside_tree():
		return  # sessao expirou no meio: o App ja trocou a tela
	_set_busy(false)
	if result.ok:
		completed.emit()
	elif result.on_field:
		_nick_row.set_error(result.message)
		_nick.line_edit.grab_focus()
	else:
		_show_banner(result.message)


## Escolhe um retrato predefinido ("hero:knight", "monster:wolf_t2").
func select_preset(preset: String) -> void:
	if _avatars == null or _profile.profile == null:
		return
	_banner.visible = false
	if not _avatars.use_preset(_profile.profile.id, preset):
		_show_banner(tr("Não foi possível guardar o avatar neste computador."))
		return
	_after_avatar_change()


## Upload: PNG/JPG ate 1 MB, recortado e redimensionado para 256x256; erro vira a faixa da tela.
func load_avatar_file(path: String) -> void:
	if _avatars == null or _profile.profile == null:
		return
	_banner.visible = false
	var result := AvatarImage.prepare_file(path)
	if not result.ok:
		_show_banner(AvatarImage.message(result.code))
		return
	if not _avatars.save_upload(_profile.profile.id, result.image):
		_show_banner(tr("Não foi possível guardar o avatar neste computador."))
		return
	_after_avatar_change()


func nickname_field() -> LineEdit:
	return _nick.line_edit


func submit_button() -> Button:
	return _submit


func upload_button() -> Button:
	return _upload


func preset_tile(preset: String) -> Button:
	return _tiles.get(preset)


func preset_ids() -> Array[String]:
	return _tiles.keys()


func title_text() -> String:
	return _title.text


func nickname_error() -> String:
	return _nick_row.error_text()


func banner_text() -> String:
	return _banner_text.text if _banner.visible else ""


## O avatar grande mostra uma imagem (escolhida) ou o icone padrao?
func preview_has_image() -> bool:
	return _preview_image.visible


func _card() -> GlassPanel:
	var card := GlassPanel.new(GlassPanel.BLUR_XL)
	card.theme_type_variation = &"LnCardGlass"
	card.custom_minimum_size.x = CARD_WIDTH
	var form := VBoxContainer.new()
	form.theme_type_variation = &"LnVGapMd"
	card.add_child(form)
	form.add_child(_header())
	_banner.theme_type_variation = &"LnBannerError"
	_banner.visible = false
	_banner_text.theme_type_variation = &"LnBodySmError"
	_banner_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_banner.add_child(_banner_text)
	form.add_child(_banner)
	_nick_row.bind(tr("Nickname"))
	_nick.bind_prefix(NicknameRules.PREFIX, tr("seu_nickname"))
	_nick.line_edit.max_length = NicknameRules.MAX_LENGTH
	_nick.line_edit.text_submitted.connect(submit.unbind(1))
	_nick.line_edit.text_changed.connect(_on_nickname_changed)
	_nick_row.add_child(_nick)
	_rule.theme_type_variation = &"LnBodySmMuted"
	_rule.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_rule.text = (
		"%s  %s"
		% [
			UiIcons.INFO,
			tr(
				"De 3 a 16 caracteres: letras, números e _. Maiúsculas e minúsculas contam como iguais."
			)
		]
	)
	_nick_row.add_child(_rule)
	form.add_child(_nick_row)
	_avatar_row.bind(tr("Avatar"))
	_avatar_row.add_child(_avatar_picker())
	form.add_child(_avatar_row)
	_submit.theme_type_variation = &"LnButtonSubmit"
	_submit.pressed.connect(submit)
	form.add_child(_submit)
	return card


func _header() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.theme_type_variation = &"LnHGapMd"
	var glyph := Label.new()
	glyph.theme_type_variation = &"LnIconTitle"
	glyph.text = UiIcons.PERSON
	glyph.size_flags_vertical = SIZE_SHRINK_BEGIN
	row.add_child(glyph)
	var text := VBoxContainer.new()
	text.theme_type_variation = &"LnVGapXs"
	text.size_flags_horizontal = SIZE_EXPAND_FILL
	_title.theme_type_variation = &"LnHeadlineMd"
	text.add_child(_title)
	_subtitle.theme_type_variation = &"LnBodyMuted"
	_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_child(_subtitle)
	row.add_child(text)
	return row


## Avatar grande a esquerda; a direita a grade de retratos e o envio de imagem.
func _avatar_picker() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.theme_type_variation = &"LnHGapMd"
	_preview.theme_type_variation = &"LnAvatarPreview"
	_preview.custom_minimum_size = PREVIEW_SIZE
	_preview.size_flags_vertical = SIZE_SHRINK_BEGIN
	_preview.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	_preview_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_preview_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_preview.add_child(_preview_image)
	_preview_glyph.theme_type_variation = &"LnIconMuted"
	_preview_glyph.text = UiIcons.PERSON
	_preview_glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_preview_glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_preview.add_child(_preview_glyph)
	row.add_child(_preview)
	var side := VBoxContainer.new()
	side.theme_type_variation = &"LnVGapSm"
	side.size_flags_horizontal = SIZE_EXPAND_FILL
	_tiles_box.columns = TILE_COLUMNS
	_tiles_box.add_theme_constant_override(&"h_separation", UiTokens.SPACE_XS)
	_tiles_box.add_theme_constant_override(&"v_separation", UiTokens.SPACE_XS)
	side.add_child(_tiles_box)
	_upload.theme_type_variation = &"LnButtonCyan"
	_upload.text = "%s  %s" % [UiIcons.LANDSCAPE, tr("ENVIAR IMAGEM")]
	_upload.pressed.connect(_dialog_popup)
	side.add_child(_upload)
	var note := Label.new()
	note.theme_type_variation = &"LnBodySmMuted"
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.text = tr("PNG ou JPG, até 1 MB. Fica só neste computador: os outros jogadores não veem.")
	side.add_child(note)
	row.add_child(side)
	return row


## Textos e controles do modo, a grade de retratos e o avatar atual.
func _refresh() -> void:
	var setup := _mode == Mode.SETUP
	_title.text = tr("ESCOLHA SEU NICKNAME") if setup else tr("SEU PERFIL")
	_subtitle.text = (
		tr("É como seu adversário vê você no histórico. Depois de confirmado, não dá para trocar.")
		if setup
		else tr("Troque o avatar quando quiser. O nickname já foi definido.")
	)
	_nick.line_edit.editable = setup
	_nick.line_edit.focus_mode = Control.FOCUS_ALL if setup else Control.FOCUS_NONE
	_rule.visible = setup
	if _profile != null and _profile.profile != null:
		_nick.line_edit.text = _profile.profile.nickname
	_refresh_submit_text()
	_clear_errors()
	_build_tiles()
	_update_preview()
	_focus_first.call_deferred()


func _build_tiles() -> void:
	for child: Node in _tiles_box.get_children():
		_tiles_box.remove_child(child)
		child.queue_free()
	_tiles.clear()
	if _catalog == null:
		return
	var current := _current_choice()
	for preset: String in AvatarStore.presets(_catalog):
		var tile := Button.new()
		tile.theme_type_variation = &"LnAvatarTile"
		tile.toggle_mode = true
		tile.button_group = _group
		tile.add_child(_tile_art(AvatarStore.preset_texture(preset)))
		tile.custom_minimum_size = TILE_SIZE
		tile.tooltip_text = AvatarStore.preset_name(preset)
		tile.set_pressed_no_signal(preset == current)
		tile.pressed.connect(select_preset.bind(preset))
		_tiles_box.add_child(tile)
		_tiles[preset] = tile


## Retrato da ficha em recorte quadrado central (os retratos de monstro sao cartoes largos com o
## monstro no meio), dentro da borda da ficha.
func _tile_art(texture: Texture2D) -> TextureRect:
	var art := TextureRect.new()
	art.texture = texture
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.offset_left = TILE_BORDER
	art.offset_top = TILE_BORDER
	art.offset_right = -TILE_BORDER
	art.offset_bottom = -TILE_BORDER
	return art


func _after_avatar_change() -> void:
	_update_preview()
	var current := _current_choice()
	for preset: String in _tiles:
		_tiles[preset].set_pressed_no_signal(preset == current)
	avatar_changed.emit()


func _update_preview() -> void:
	var texture: Texture2D = null
	if _avatars != null and _profile != null and _profile.profile != null:
		texture = _avatars.texture(_profile.profile.id)
	_preview_image.texture = texture
	_preview_image.visible = texture != null
	_preview_glyph.visible = texture == null


func _current_choice() -> String:
	if _avatars == null or _profile == null or _profile.profile == null:
		return ""
	return _avatars.choice(_profile.profile.id)


func _focus_first() -> void:
	if _mode == Mode.SETUP:
		_nick.line_edit.grab_focus()
	elif not _tiles.is_empty():
		var first: Button = _tiles.values()[0]
		first.grab_focus()
	else:
		_submit.grab_focus()


func _dialog_popup() -> void:
	_dialog.popup_centered_ratio(0.6)


func _set_busy(busy: bool) -> void:
	_submit.disabled = busy
	_upload.disabled = busy
	_nick.line_edit.editable = not busy and _mode == Mode.SETUP
	for tile: Button in _tiles.values():
		tile.disabled = busy
	if busy:
		_submit.text = "%s  %s" % [UiIcons.PROGRESS_ACTIVITY, tr("SALVANDO…")]
	else:
		_refresh_submit_text()


func _refresh_submit_text() -> void:
	var setup := _mode == Mode.SETUP
	_submit.text = (
		"%s  %s" % [UiIcons.CHECK, tr("CONFIRMAR NICKNAME")]
		if setup
		else "%s  %s" % [UiIcons.ARROW_BACK, tr("CONCLUIR")]
	)


func _show_banner(message: String) -> void:
	_banner_text.text = "%s  %s" % [UiIcons.ERROR, message]
	_banner.visible = true


func _clear_errors() -> void:
	_banner.visible = false
	_nick_row.clear_error()


func _on_nickname_changed(_text: String) -> void:
	_nick_row.clear_error()
