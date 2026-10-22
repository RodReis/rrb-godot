extends GutTest
## F85 (ADR-0029): contrato user://offline_result.cfg. O Game grava ao fim do treino ou do
## tutorial; o Launcher le, apaga e, se for tutorial/completed ou bot/win, avisa o backend.

const TMP_PATH: String = "user://test_f85_offline_result.cfg"


func after_each() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TMP_PATH))


func test_round_trip_do_treino_guarda_o_nivel_do_bot() -> void:
	assert_eq(OfflineResult.write(OfflineResult.KIND_BOT, OfflineResult.WIN, 3, TMP_PATH), OK)
	var result := OfflineResult.read(TMP_PATH)
	assert_eq(result[OfflineResult.KIND], OfflineResult.KIND_BOT)
	assert_eq(result[OfflineResult.OUTCOME], OfflineResult.WIN)
	assert_eq(result[OfflineResult.BOT_DIFFICULTY], 3)


func test_round_trip_do_tutorial_nao_tem_nivel_de_bot() -> void:
	OfflineResult.write(OfflineResult.KIND_TUTORIAL, OfflineResult.COMPLETED, 0, TMP_PATH)
	var result := OfflineResult.read(TMP_PATH)
	assert_eq(result[OfflineResult.KIND], OfflineResult.KIND_TUTORIAL)
	assert_eq(result[OfflineResult.OUTCOME], OfflineResult.COMPLETED)
	assert_false(result.has(OfflineResult.BOT_DIFFICULTY))


func test_finished_at_e_iso_8601_em_utc() -> void:
	OfflineResult.write(OfflineResult.KIND_BOT, OfflineResult.LOSS, 1, TMP_PATH)
	var finished: String = OfflineResult.read(TMP_PATH)[OfflineResult.FINISHED_AT]
	assert_true(finished.ends_with("Z"), finished)
	assert_eq(finished.length(), "2026-10-22T12:00:00Z".length())
	assert_eq(finished[10], "T")


func test_arquivo_ausente_le_vazio() -> void:
	assert_true(OfflineResult.read(TMP_PATH).is_empty())


func test_combinacao_invalida_nao_e_gravada() -> void:
	# tutorial nao tem vitoria nem derrota; bot nao tem "completed".
	assert_ne(OfflineResult.write(OfflineResult.KIND_TUTORIAL, OfflineResult.WIN, 0, TMP_PATH), OK)
	assert_ne(OfflineResult.write(OfflineResult.KIND_BOT, OfflineResult.COMPLETED, 1, TMP_PATH), OK)
	assert_ne(OfflineResult.write("outro", OfflineResult.QUIT, 0, TMP_PATH), OK)
	assert_false(FileAccess.file_exists(TMP_PATH))


func test_arquivo_adulterado_le_vazio() -> void:
	var config := ConfigFile.new()
	config.set_value(OfflineResult.SECTION, OfflineResult.KIND, OfflineResult.KIND_TUTORIAL)
	config.set_value(OfflineResult.SECTION, OfflineResult.OUTCOME, OfflineResult.WIN)
	config.save(TMP_PATH)
	assert_true(OfflineResult.read(TMP_PATH).is_empty())


func test_consume_le_e_apaga() -> void:
	OfflineResult.write(OfflineResult.KIND_TUTORIAL, OfflineResult.QUIT, 0, TMP_PATH)
	var result := OfflineResult.consume(TMP_PATH)
	assert_eq(result[OfflineResult.OUTCOME], OfflineResult.QUIT)
	assert_false(FileAccess.file_exists(TMP_PATH))
	assert_true(OfflineResult.consume(TMP_PATH).is_empty())


func test_consume_apaga_tambem_o_arquivo_invalido() -> void:
	var config := ConfigFile.new()
	config.set_value(OfflineResult.SECTION, OfflineResult.KIND, "lixo")
	config.save(TMP_PATH)
	assert_true(OfflineResult.consume(TMP_PATH).is_empty())
	assert_false(FileAccess.file_exists(TMP_PATH))


func test_unlock_reason_so_para_tutorial_concluido_e_vitoria_sobre_o_bot() -> void:
	var cases: Array[Array] = [
		[OfflineResult.KIND_TUTORIAL, OfflineResult.COMPLETED, 0, OfflineResult.REASON_TUTORIAL],
		[OfflineResult.KIND_TUTORIAL, OfflineResult.QUIT, 0, ""],
		[OfflineResult.KIND_BOT, OfflineResult.WIN, 1, OfflineResult.REASON_BOT_WIN],
		[OfflineResult.KIND_BOT, OfflineResult.WIN, 3, OfflineResult.REASON_BOT_WIN],
		[OfflineResult.KIND_BOT, OfflineResult.LOSS, 3, ""],
		[OfflineResult.KIND_BOT, OfflineResult.QUIT, 1, ""],
	]
	for row: Array in cases:
		OfflineResult.write(row[0], row[1], row[2], TMP_PATH)
		assert_eq(OfflineResult.unlock_reason(OfflineResult.read(TMP_PATH)), row[3], str(row))
	assert_eq(OfflineResult.unlock_reason({}), "")
