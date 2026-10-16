extends GutTest
## F35: AvatarImage valida o arquivo (PNG/JPG, ate 1 MB) e entrega 256x256 recortado no centro.


func _filled_png(width: int, height: int, color: Color) -> PackedByteArray:
	var image := Image.create_empty(width, height, false, Image.FORMAT_RGB8)
	image.fill(color)
	return image.save_png_to_buffer()


func _jpg(width: int, height: int) -> PackedByteArray:
	var image := Image.create_empty(width, height, false, Image.FORMAT_RGB8)
	image.fill(Color.BLUE)
	return image.save_jpg_to_buffer(0.9)


func _write(path: String, bytes: PackedByteArray) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_buffer(bytes)
	file.close()


func test_png_quadrado_vira_256() -> void:
	var result := AvatarImage.prepare(_filled_png(512, 512, Color.RED))
	assert_true(result.ok)
	assert_eq(result.image.get_size(), Vector2i(256, 256))


func test_jpg_vira_256() -> void:
	var result := AvatarImage.prepare(_jpg(300, 300))
	assert_true(result.ok)
	assert_eq(result.image.get_size(), Vector2i(AvatarImage.SIZE, AvatarImage.SIZE))


func test_imagem_pequena_tambem_sai_256() -> void:
	var result := AvatarImage.prepare(_filled_png(40, 40, Color.GREEN))
	assert_true(result.ok)
	assert_eq(result.image.get_size(), Vector2i(256, 256))


func test_recorta_o_quadrado_central_de_imagem_larga() -> void:
	# 3 faixas verticais iguais (vermelho, verde, azul): o recorte central e so a faixa verde.
	var image := Image.create_empty(300, 100, false, Image.FORMAT_RGB8)
	image.fill_rect(Rect2i(0, 0, 100, 100), Color.RED)
	image.fill_rect(Rect2i(100, 0, 100, 100), Color.GREEN)
	image.fill_rect(Rect2i(200, 0, 100, 100), Color.BLUE)
	var result := AvatarImage.prepare(image.save_png_to_buffer())
	assert_true(result.ok)
	assert_eq(result.image.get_size(), Vector2i(256, 256))
	assert_eq(result.image.get_pixel(5, 128), Color.GREEN)
	assert_eq(result.image.get_pixel(250, 128), Color.GREEN)


func test_recorta_o_quadrado_central_de_imagem_alta() -> void:
	var image := Image.create_empty(100, 300, false, Image.FORMAT_RGB8)
	image.fill_rect(Rect2i(0, 0, 100, 100), Color.RED)
	image.fill_rect(Rect2i(0, 100, 100, 100), Color.GREEN)
	image.fill_rect(Rect2i(0, 200, 100, 100), Color.BLUE)
	var result := AvatarImage.prepare(image.save_png_to_buffer())
	assert_true(result.ok)
	assert_eq(result.image.get_pixel(128, 5), Color.GREEN)
	assert_eq(result.image.get_pixel(128, 250), Color.GREEN)


func test_acima_de_1_mb_e_recusado() -> void:
	var big := PackedByteArray()
	big.resize(AvatarImage.MAX_BYTES + 1)
	var result := AvatarImage.prepare(big)
	assert_false(result.ok)
	assert_eq(result.code, AvatarImage.TOO_LARGE)


func test_exatamente_1_mb_passa_do_limite_de_tamanho() -> void:
	var png := _filled_png(64, 64, Color.RED)
	var padded := png.duplicate()
	padded.resize(AvatarImage.MAX_BYTES)  # bytes a mais depois do IEND: o decoder ignora
	var result := AvatarImage.prepare(padded)
	assert_ne(result.code, AvatarImage.TOO_LARGE)


func test_formato_invalido_e_recusado() -> void:
	for bytes: PackedByteArray in [
		"nao sou imagem".to_utf8_buffer(),
		PackedByteArray([0x47, 0x49, 0x46, 0x38]),  # GIF
		PackedByteArray([0x42, 0x4D, 0, 0, 0, 0]),  # BMP
	]:
		var result := AvatarImage.prepare(bytes)
		assert_false(result.ok)
		assert_eq(result.code, AvatarImage.BAD_FORMAT)


func test_cabecalho_png_com_corpo_quebrado_e_recusado() -> void:
	var broken := _filled_png(64, 64, Color.RED).slice(0, 40)
	var result := AvatarImage.prepare(broken)
	assert_false(result.ok)
	assert_eq(result.code, AvatarImage.BAD_FORMAT)
	assert_engine_error_count(4, "o decoder de PNG loga a falha; o Launcher so recusa o arquivo")


func test_arquivo_vazio() -> void:
	var result := AvatarImage.prepare(PackedByteArray())
	assert_false(result.ok)
	assert_eq(result.code, AvatarImage.BAD_FORMAT)


func test_arquivo_em_disco_vira_256() -> void:
	var path := "user://test_avatar_%d.png" % Time.get_ticks_usec()
	_write(path, _filled_png(300, 200, Color.RED))
	var result := AvatarImage.prepare_file(path)
	DirAccess.remove_absolute(path)
	assert_true(result.ok)
	assert_eq(result.image.get_size(), Vector2i(AvatarImage.SIZE, AvatarImage.SIZE))


func test_arquivo_em_disco_acima_de_1_mb_nem_e_lido() -> void:
	var path := "user://test_avatar_big_%d.bin" % Time.get_ticks_usec()
	var big := PackedByteArray()
	big.resize(AvatarImage.MAX_BYTES + 1)
	_write(path, big)
	var result := AvatarImage.prepare_file(path)
	DirAccess.remove_absolute(path)
	assert_eq(result.code, AvatarImage.TOO_LARGE)


func test_arquivo_inexistente_e_recusado() -> void:
	var result := AvatarImage.prepare_file("user://nao_existe_%d.png" % Time.get_ticks_usec())
	assert_false(result.ok)
	assert_eq(result.code, AvatarImage.BAD_FORMAT)
	assert_push_error_count(0)


func test_mensagem_em_portugues_para_cada_erro() -> void:
	assert_string_contains(AvatarImage.message(AvatarImage.TOO_LARGE), "1 MB")
	assert_string_contains(AvatarImage.message(AvatarImage.BAD_FORMAT), "PNG")


func test_png_que_declara_dimensao_enorme_e_recusado_sem_decodificar() -> void:
	var bomb := _filled_png(8, 8, Color.RED)
	bomb[18] = 0x40  # largura 0x00004000 = 16384 no IHDR (a CRC nem e conferida: nada e decodificado)
	var result := AvatarImage.prepare(bomb)
	assert_false(result.ok)
	assert_eq(result.code, AvatarImage.TOO_BIG)
	assert_string_contains(AvatarImage.message(AvatarImage.TOO_BIG), "4096")


func test_png_no_limite_de_dimensao_passa() -> void:
	var result := AvatarImage.prepare(_filled_png(AvatarImage.MAX_SIDE, 8, Color.RED))
	assert_true(result.ok)


func test_jpg_que_declara_dimensao_enorme_e_recusado() -> void:
	# SOI, APP0 vazio (tamanho 4) e SOF0 com altura e largura 0x4000.
	var bomb := PackedByteArray(
		[0xFF, 0xD8, 0xFF, 0xE0, 0, 4, 0, 0, 0xFF, 0xC0, 0, 17, 8, 0x40, 0, 0x40, 0, 3, 0, 0]
	)
	var result := AvatarImage.prepare(bomb)
	assert_eq(result.code, AvatarImage.TOO_BIG)


func test_jpg_com_cabecalho_truncado_cai_no_decoder() -> void:
	var cut := PackedByteArray([0xFF, 0xD8, 0xFF, 0xE0, 0, 4, 0, 0, 0xFF, 0xC0, 0])
	var result := AvatarImage.prepare(cut)
	assert_eq(result.code, AvatarImage.BAD_FORMAT)
	assert_engine_error_count(2, "o decoder de JPG loga a falha")
