class_name UpdateRules
extends RefCounted
## Regras puras da atualizacao (F83, ADR-0023): versao vX.Y.Z, manifesto latest.json
## {version, installer, sha256} e a URL do instalador ao lado do manifesto.

## Nome do instalador: arquivo simples .exe, sem caminho (vem da rede).
const INSTALLER_PATTERN: String = r"^[A-Za-z0-9._-]+\.exe$"
const SHA256_PATTERN: String = "^[0-9a-f]{64}$"
const VERSION_PATTERN: String = r"^v?(\d+)\.(\d+)\.(\d+)$"


## [major, minor, patch]; fora de vX.Y.Z (ex.: "dev") = vazio.
static func parse_version(raw: String) -> PackedInt32Array:
	var regex := RegEx.create_from_string(VERSION_PATTERN)
	var found := regex.search(raw.strip_edges())
	if found == null:
		return PackedInt32Array()
	return PackedInt32Array(
		[found.get_string(1).to_int(), found.get_string(2).to_int(), found.get_string(3).to_int()]
	)


## true se [param remote] e mais nova que [param local]; build de dev (sem versao) nunca atualiza.
static func is_newer(remote: String, local: String) -> bool:
	var have := parse_version(local)
	var offer := parse_version(remote)
	if have.is_empty() or offer.is_empty():
		return false
	for i: int in have.size():
		if offer[i] != have[i]:
			return offer[i] > have[i]
	return false


## Manifesto valido vira {version, installer, sha256}; qualquer campo fora do formato = vazio.
static func parse_manifest(json: Variant) -> Dictionary:
	if not json is Dictionary:
		return {}
	var data := json as Dictionary
	var version := str(data.get("version", ""))
	var installer := str(data.get("installer", ""))
	var sha := str(data.get("sha256", "")).to_lower()
	if parse_version(version).is_empty():
		return {}
	if RegEx.create_from_string(INSTALLER_PATTERN).search(installer) == null:
		return {}
	if RegEx.create_from_string(SHA256_PATTERN).search(sha) == null:
		return {}
	return {"version": version, "installer": installer, "sha256": sha}


## O instalador fica na mesma pasta do manifesto.
static func installer_url(manifest_url: String, installer: String) -> String:
	return manifest_url.get_base_dir() + "/" + installer
