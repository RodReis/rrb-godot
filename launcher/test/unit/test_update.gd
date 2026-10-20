extends GutTest
## F83 (ADR-0023): regras da atualizacao, versao do pacote e o UpdateService com ApiClient falso.

const MANIFEST_URL: String = "https://lootstart.cloud/download/latest.json"
const INSTALLER: String = "LootStart-Setup-v0.3.0.exe"
const PAYLOAD: String = "instalador de mentira"

var _api: FakeApiClient
var _runs: Array = []


func before_each() -> void:
	_api = FakeApiClient.new()
	add_child_autofree(_api)
	_runs.clear()


func _service(local: String = "v0.2.0") -> UpdateService:
	var service := UpdateService.new(_api, MANIFEST_URL, local)
	service.run_installer = func(path: String, args: PackedStringArray) -> int:
		_runs.append([path, args])
		return 4242
	return service


func _manifest(sha: String = PAYLOAD.sha256_text()) -> Dictionary:
	return {"version": "v0.3.0", "installer": INSTALLER, "sha256": sha}


func test_versao_mais_nova() -> void:
	assert_true(UpdateRules.is_newer("v0.3.0", "v0.2.0"))
	assert_true(UpdateRules.is_newer("v0.10.0", "v0.9.9"))
	assert_true(UpdateRules.is_newer("v1.0.0", "v0.99.0"))
	assert_false(UpdateRules.is_newer("v0.2.0", "v0.2.0"))
	assert_false(UpdateRules.is_newer("v0.1.9", "v0.2.0"))
	assert_false(UpdateRules.is_newer("v0.3.0", "dev"), "build de dev nunca atualiza")
	assert_false(UpdateRules.is_newer("lixo", "v0.2.0"))


func test_manifesto_rejeita_campo_fora_do_formato() -> void:
	assert_eq(UpdateRules.parse_manifest(_manifest()), _manifest())
	assert_eq(UpdateRules.parse_manifest(null), {})
	var bad: Array[Dictionary] = [
		{"version": "latest", "installer": INSTALLER, "sha256": PAYLOAD.sha256_text()},
		{"version": "v0.3.0", "installer": "../../evil.exe", "sha256": PAYLOAD.sha256_text()},
		{"version": "v0.3.0", "installer": "setup.bat", "sha256": PAYLOAD.sha256_text()},
		{"version": "v0.3.0", "installer": INSTALLER, "sha256": "abc"},
	]
	for manifest: Dictionary in bad:
		assert_eq(UpdateRules.parse_manifest(manifest), {}, str(manifest))


func test_instalador_fica_ao_lado_do_manifesto() -> void:
	assert_eq(
		UpdateRules.installer_url(MANIFEST_URL, INSTALLER),
		"https://lootstart.cloud/download/" + INSTALLER
	)


func test_versao_do_pacote_e_dev_sem_build_config() -> void:
	assert_eq(BuildInfo.version("user://nao_existe.cfg"), BuildInfo.DEV)
	assert_eq(BuildInfo.update_url("user://nao_existe.cfg"), "")
	var cfg := ConfigFile.new()
	cfg.set_value("build", "version", "v0.2.0")
	cfg.set_value("build", "update_url", MANIFEST_URL)
	cfg.save("user://test_build_config.cfg")
	assert_eq(BuildInfo.version("user://test_build_config.cfg"), "v0.2.0")
	assert_eq(BuildInfo.update_url("user://test_build_config.cfg"), MANIFEST_URL)


func test_check_acha_versao_nova() -> void:
	_api.reply("GET " + MANIFEST_URL, 200, _manifest())
	assert_eq(await _service().check(), _manifest())


func test_check_ignora_mesma_versao_rede_e_dev() -> void:
	_api.reply("GET " + MANIFEST_URL, 200, _manifest())
	assert_eq(await _service("v0.3.0").check(), {}, "ja atualizado")
	assert_eq(await _service().check(), {}, "sem resposta")
	assert_eq(await UpdateService.new(_api, "", "v0.2.0").check(), {}, "sem URL (dev)")


func test_install_confere_o_sha_e_roda_em_silencio() -> void:
	_api.download_bytes = PAYLOAD.to_utf8_buffer()
	assert_true(await _service().install(_manifest()))
	assert_eq(_api.downloads, ["https://lootstart.cloud/download/" + INSTALLER])
	assert_eq(_runs.size(), 1)
	assert_string_ends_with(_runs[0][0], INSTALLER)
	assert_eq(_runs[0][1], UpdateService.INSTALLER_ARGS)


func test_install_com_sha_errado_nao_roda_e_apaga() -> void:
	_api.download_bytes = "outro arquivo".to_utf8_buffer()
	assert_false(await _service().install(_manifest()))
	assert_eq(_runs.size(), 0, "arquivo adulterado nunca roda")
	assert_false(FileAccess.file_exists(UpdateService.DOWNLOAD_DIR + INSTALLER))


func test_install_sem_download_nao_roda() -> void:
	_api.download_ok = false
	assert_false(await _service().install(_manifest()))
	assert_eq(_runs.size(), 0)


func test_check_apaga_instalador_que_ja_rodou() -> void:
	DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(UpdateService.DOWNLOAD_DIR)
	)
	var old := UpdateService.DOWNLOAD_DIR + "LootStart-Setup-v0.1.0.exe"
	FileAccess.open(old, FileAccess.WRITE).close()
	await _service().check()
	assert_false(FileAccess.file_exists(old))


func test_check_sem_pasta_de_download_nao_da_erro() -> void:
	var dir := ProjectSettings.globalize_path(UpdateService.DOWNLOAD_DIR)
	_service().clean()
	DirAccess.remove_absolute(dir)
	assert_false(DirAccess.dir_exists_absolute(dir))
	assert_eq(await _service().check(), {})
	assert_engine_error_count(0)
