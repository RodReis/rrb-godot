class_name HistoryFormat
extends RefCounted
## Textos do Historico (FRONTEND-LAUNCHER §8.3 regra 2): nome e papel do heroi e nome do conjunto
## vem de shared/data (nunca do prototipo); motivo de fim, duracao, data local e id curto sao
## formatados aqui. Funcoes puras, testaveis sem cena.

const HEROES_DIR: String = "res://shared/data/heroes/"
const SET_BONUS_PATH: String = "res://shared/data/items/{set}_set/{set}_bonus.tres"
const PORTRAITS_DIR: String = "res://shared/assets/ui/heroes/"
## Id vindo do backend vira nome de arquivo: so letras minusculas, digitos e "_" (\z: o "$" do
## PCRE aceita um "\n" no fim).
const ID_PATTERN: String = "^[a-z0-9_]+\\z"
const NO_HERO: String = "Sem herói"
const UNKNOWN_REASON: String = "Partida encerrada"
const SECONDS_PER_MINUTE: int = 60
const MINUTES_PER_DAY: int = 1440
## "2026-10-15T12:10:00" (o backend manda ISO 8601 UTC com milissegundos e "Z").
const ISO_LENGTH: int = 19
## Motivo de fim (end_reason do backend) -> texto. Os do Game: VictoryRules; os de aborto: backend.
const END_REASONS: Dictionary[String, String] = {
	"kill_goal": "Meta de abates",
	"elimination": "Adversário eliminado",
	"collapse_hp": "Colapso: mais vida",
	"collapse_kills": "Colapso: mais abates",
	"collapse_damage": "Colapso: mais dano",
	"collapse_draw": "Colapso: sorteio",
	"abandoned": "Ninguém conectado",
	"heartbeat_lost": "Servidor sem sinal",
	"token_expired": "Ninguém entrou a tempo",
	"pairing_failed": "Falha ao montar a partida",
	"backend_restart": "Servidor reiniciado",
}

static var _id_regex: RegEx = RegEx.create_from_string(ID_PATTERN)


## HeroData do id, ou null (vazio, fora do padrao ou sem arquivo).
static func hero(hero_id: String) -> HeroData:
	if not _id_regex.search(hero_id):
		return null
	var path := "%s%s.tres" % [HEROES_DIR, hero_id]
	return load(path) as HeroData if ResourceLoader.exists(path) else null


static func hero_name(hero_id: String) -> String:
	var data := hero(hero_id)
	return data.display_name if data != null else NO_HERO


static func hero_role(hero_id: String) -> String:
	var data := hero(hero_id)
	return data.role if data != null else ""


## Retrato 1:1 do heroi (render dos assets reais, §8.3 regra 3); null se nao existir.
static func portrait(hero_id: String) -> Texture2D:
	if not _id_regex.search(hero_id):
		return null
	var path := "%s%s.png" % [PORTRAITS_DIR, hero_id]
	return load(path) as Texture2D if ResourceLoader.exists(path) else null


## Nome do conjunto ativo ("Caçador"); "" se nao ha conjunto ou o id nao existe. Nao se chama
## set_name: static func com esse nome colide com Resource.set_name do proprio GDScript.
static func active_set_name(set_id: String) -> String:
	if not _id_regex.search(set_id):
		return ""
	var path := SET_BONUS_PATH.replace("{set}", set_id)
	if not ResourceLoader.exists(path):
		return ""
	var bonus := load(path) as SetBonusData
	return bonus.display_name if bonus != null else ""


static func end_reason(reason: String) -> String:
	if reason.is_empty():
		return ""
	return END_REASONS.get(reason, UNKNOWN_REASON)


## "08:42 min"; "" para duracao desconhecida (partida interrompida).
static func duration(seconds: int) -> String:
	if seconds < 0:
		return ""
	return (
		"%02d:%02d min"
		% [floori(float(seconds) / SECONDS_PER_MINUTE), seconds % SECONDS_PER_MINUTE]
	)


## Data e hora no fuso local ("15/10/2026 09:10"). `bias_minutes`: deslocamento do fuso em
## relacao ao UTC (padrao: o do sistema); "" se o texto nao for uma data ISO.
static func played_at(iso: String, bias_minutes: int = _system_bias()) -> String:
	if iso.length() < ISO_LENGTH:
		return ""
	var utc := Time.get_unix_time_from_datetime_string(iso.substr(0, ISO_LENGTH))
	if utc <= 0:
		return ""
	var local := Time.get_datetime_dict_from_unix_time(utc + bias_minutes * SECONDS_PER_MINUTE)
	return (
		"%02d/%02d/%d %02d:%02d"
		% [local["day"], local["month"], local["year"], local["hour"], local["minute"]]
	)


## "#0B7E9F00": primeiros 8 caracteres do match_id (o id inteiro e um UUID).
static func short_id(match_id: String) -> String:
	if match_id.is_empty():
		return ""
	return "#" + match_id.left(8).to_upper()


static func _system_bias() -> int:
	return int(Time.get_time_zone_from_system()["bias"])
