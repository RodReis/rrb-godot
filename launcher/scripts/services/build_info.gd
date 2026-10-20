class_name BuildInfo
extends RefCounted
## Dados do pacote gravados por tools/build-package.ps1 no build_config.cfg (F28, F83/ADR-0023):
## [build] version (tag do Release) e update_url (manifesto latest.json). Fora do pacote (dev) nao
## ha arquivo: versao "dev" e sem URL, entao nao ha checagem de atualizacao.

const PATH: String = "res://build_config.cfg"
const DEV: String = "dev"


static func version(path: String = PATH) -> String:
	return _value(path, "version", DEV)


static func update_url(path: String = PATH) -> String:
	return _value(path, "update_url", "")


static func _value(path: String, key: String, fallback: String) -> String:
	var cfg := ConfigFile.new()
	if cfg.load(path) != OK:
		return fallback
	var value := str(cfg.get_value("build", key, fallback)).strip_edges()
	return value if not value.is_empty() else fallback
