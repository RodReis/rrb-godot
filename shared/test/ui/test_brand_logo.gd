extends GutTest
## F82 (ADR-0022): marca "Loot Start" do Launcher e do splash.


func test_horizontal_tem_icone_e_wordmark_dourado() -> void:
	var logo: BrandLogo = add_child_autofree(BrandLogo.make(36.0, 18))
	await wait_process_frames(1)
	assert_false(logo.vertical)
	var icon := logo.get_child(0) as TextureRect
	assert_not_null(icon.texture, "icone do bau carregado")
	assert_eq(logo.word().text, "LOOT START")
	var material := logo.word().material as ShaderMaterial
	assert_eq(material.get_shader_parameter(&"top_color"), UiTokens.GOLD_BRIGHT)
	assert_eq(
		material.get_shader_parameter(&"height"), logo.word().size.y, "degrade na altura real"
	)


func test_empilhada_fica_vertical() -> void:
	var logo: BrandLogo = add_child_autofree(BrandLogo.make(96.0, 48, true))
	assert_true(logo.vertical)
