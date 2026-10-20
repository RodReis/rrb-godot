class_name UpdateService
extends RefCounted
## Atualizacao do Launcher (F83, ADR-0023): le o manifesto latest.json do site, compara com a
## versao do pacote e, se o jogador aceitar, baixa o instalador, confere o SHA-256 e o roda em
## modo silencioso (/S /UPDATE). Quem fecha o Launcher depois e o App; o instalador o reabre.

## Pasta do download (fora da instalacao, que o instalador sobrescreve).
const DOWNLOAD_DIR: String = "user://update/"
const INSTALLER_ARGS: PackedStringArray = ["/S", "/UPDATE"]

var manifest_url: String
var local_version: String
## Abre o instalador: (caminho absoluto, argumentos) -> pid (-1 = falhou). Teste troca.
var run_installer: Callable = OS.create_process

var _api: ApiClient


func _init(
	api: ApiClient,
	p_manifest_url: String = BuildInfo.update_url(),
	p_local_version: String = BuildInfo.version()
) -> void:
	_api = api
	manifest_url = p_manifest_url
	local_version = p_local_version


## Manifesto de uma versao mais nova que a local, ou vazio (sem URL, dev, rede, manifesto invalido
## ou ja atualizado). Nunca bloqueia: falha = segue sem atualizar. Apaga antes os instaladores
## que ja rodaram (~200 MB cada).
func check() -> Dictionary:
	clean()
	if manifest_url.is_empty():
		return {}
	var response: ApiClient.Response = await _api.fetch_json(manifest_url)
	if not response.ok():
		return {}
	var manifest := UpdateRules.parse_manifest(response.json)
	if manifest.is_empty() or not UpdateRules.is_newer(manifest["version"], local_version):
		return {}
	return manifest


## Apaga os instaladores baixados; o que ainda estiver rodando fica para a proxima abertura.
func clean() -> void:
	var dir := ProjectSettings.globalize_path(DOWNLOAD_DIR)
	if not DirAccess.dir_exists_absolute(dir):
		return  # nunca baixou nada (get_files_at numa pasta que nao existe da erro de engine)
	for file: String in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute(dir.path_join(file))


## Baixa, confere o SHA-256 e abre o instalador; false se algo falhou (arquivo ruim e apagado).
func install(manifest: Dictionary) -> bool:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DOWNLOAD_DIR))
	var path: String = DOWNLOAD_DIR + str(manifest["installer"])
	var url := UpdateRules.installer_url(manifest_url, manifest["installer"])
	if not await _api.download(url, path):
		return false
	if FileAccess.get_sha256(path) != manifest["sha256"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
		return false
	return int(run_installer.call(ProjectSettings.globalize_path(path), INSTALLER_ARGS)) > 0
