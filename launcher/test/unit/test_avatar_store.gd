extends GutTest
## F35: AvatarStore guarda a escolha de avatar por conta, so local (user://): predefinido ou o
## upload ja recortado em 256x256. Nada vai ao backend.

const USER_A: String = "0b7e9f00-1111-4222-8333-444455556666"
const USER_B: String = "9c2d1a77-aaaa-4bbb-8ccc-ddddeeeeffff"

var _dir: String
var _store: AvatarStore


func before_each() -> void:
	_dir = "user://test_avatars_%d/" % Time.get_ticks_usec()
	_store = AvatarStore.new(_dir)


func after_each() -> void:
	if not DirAccess.dir_exists_absolute(_dir):
		return
	for file: String in DirAccess.get_files_at(_dir):
		DirAccess.remove_absolute(_dir + file)
	DirAccess.remove_absolute(_dir)


func _image(color: Color) -> Image:
	var image := Image.create_empty(AvatarImage.SIZE, AvatarImage.SIZE, false, Image.FORMAT_RGB8)
	image.fill(color)
	return image


func test_sem_escolha_nao_tem_textura() -> void:
	assert_eq(_store.choice(USER_A), "")
	assert_null(_store.texture(USER_A))


func test_predefinido_persiste_e_resolve_a_textura() -> void:
	assert_true(_store.use_preset(USER_A, "hero:knight"))
	assert_eq(_store.choice(USER_A), "hero:knight")
	assert_not_null(_store.texture(USER_A))
	assert_eq(AvatarStore.new(_dir).choice(USER_A), "hero:knight", "sobrevive a um novo store")


func test_predefinido_de_monstro() -> void:
	assert_true(_store.use_preset(USER_A, "monster:wolf_t2"))
	assert_not_null(_store.texture(USER_A))


func test_predefinido_inexistente_ou_fora_do_padrao_e_recusado() -> void:
	for preset: String in [
		"", "hero:nao_existe", "hero:../items/catalog", "knight", "hero:knight\n"
	]:
		assert_false(_store.use_preset(USER_A, preset), preset)
	assert_eq(_store.choice(USER_A), "")


func test_upload_salva_o_png_256_e_vira_a_escolha() -> void:
	assert_true(_store.save_upload(USER_A, _image(Color.GREEN)))
	assert_eq(_store.choice(USER_A), AvatarStore.UPLOAD)
	var texture := _store.texture(USER_A)
	assert_not_null(texture)
	assert_eq(texture.get_size(), Vector2(AvatarImage.SIZE, AvatarImage.SIZE))
	assert_eq(texture.get_image().get_pixel(10, 10), Color.GREEN)


func test_upload_de_tamanho_errado_e_recusado() -> void:
	var small := Image.create_empty(64, 64, false, Image.FORMAT_RGB8)
	assert_false(_store.save_upload(USER_A, small))
	assert_eq(_store.choice(USER_A), "")


func test_escolher_predefinido_depois_do_upload_troca_a_escolha() -> void:
	_store.save_upload(USER_A, _image(Color.GREEN))
	_store.use_preset(USER_A, "hero:ranger")
	assert_eq(_store.choice(USER_A), "hero:ranger")
	assert_ne(_store.texture(USER_A).get_size(), Vector2(0, 0))


func test_cada_conta_tem_o_seu_avatar() -> void:
	_store.use_preset(USER_A, "hero:knight")
	_store.save_upload(USER_B, _image(Color.BLUE))
	assert_eq(_store.choice(USER_A), "hero:knight")
	assert_eq(_store.choice(USER_B), AvatarStore.UPLOAD)


func test_id_de_conta_fora_do_padrao_nao_escapa_do_diretorio() -> void:
	for bad: String in ["", "../../x", "a/b", USER_A + "\n"]:
		assert_false(_store.use_preset(bad, "hero:knight"), bad)
		assert_false(_store.save_upload(bad, _image(Color.RED)), bad)
		assert_eq(_store.choice(bad), "", bad)
		assert_null(_store.texture(bad), bad)


func test_upload_sumido_do_disco_cai_sem_textura() -> void:
	_store.save_upload(USER_A, _image(Color.GREEN))
	DirAccess.remove_absolute(_dir + USER_A + ".png")
	assert_null(_store.texture(USER_A))


func test_lista_de_predefinidos_sao_os_herois_e_monstros_com_retrato() -> void:
	var catalog := CatalogService.new()
	catalog.load_all()
	var ids := AvatarStore.presets(catalog)
	assert_true(ids.has("hero:knight"))
	assert_true(ids.has("monster:wolf_t2"))
	assert_false(ids.has("monster:golem_corner"), "sem retrato nao entra")
	for id: String in ids:
		assert_not_null(AvatarStore.preset_texture(id), id)
		assert_false(AvatarStore.preset_name(id).is_empty(), id)


func test_escolha_adulterada_no_arquivo_nao_vira_textura() -> void:
	_store.use_preset(USER_A, "hero:knight")
	var cfg := ConfigFile.new()
	cfg.set_value(AvatarStore.SECTION, USER_A, "hero:../items/catalog")
	cfg.save(_dir + AvatarStore.CHOICES_FILE)
	assert_null(_store.texture(USER_A))


func test_upload_corrompido_no_disco_cai_sem_textura() -> void:
	_store.save_upload(USER_A, _image(Color.GREEN))
	var file := FileAccess.open(_dir + USER_A + ".png", FileAccess.WRITE)
	file.store_string("lixo")
	file.close()
	assert_null(_store.texture(USER_A))
	assert_engine_error_count(4, "o loader de imagem loga a falha; o chip so cai no icone padrao")


func test_upload_nao_deixa_arquivo_temporario() -> void:
	_store.save_upload(USER_A, _image(Color.GREEN))
	for file: String in DirAccess.get_files_at(_dir):
		assert_false(file.ends_with(AvatarStore.TEMP_SUFFIX), file)
