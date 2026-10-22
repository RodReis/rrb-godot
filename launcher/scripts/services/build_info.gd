class_name BuildInfo
extends RefCounted
## Dados do pacote gravados por tools/build-package.ps1 no build_config.cfg (F28, F83/ADR-0023):
## [build] version (tag do Release), update_url (manifesto latest.json) e channel (F86). Fora do
## pacote (dev) nao ha arquivo: versao "dev" e sem URL, entao nao ha checagem de atualizacao.

const PATH: String = "res://build_config.cfg"
const DEV: String = "dev"
## Canal de distribuicao (F86): "site" (instalador e atualizador proprio) ou "itch" (ZIP; o app do
## itch.io atualiza).
const CHANNEL_SITE: String = "site"
const CHANNEL_ITCH: String = "itch"


static func channel(path: String = PATH) -> String:
	return _value(path, "channel", CHANNEL_SITE)


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
