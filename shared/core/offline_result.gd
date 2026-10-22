class_name OfflineResult
extends RefCounted
## Contrato user://offline_result.cfg (ADR-0029, ARCHITECTURE-LAUNCHER §5.4): o Game grava ao fim de
## todo treino contra o bot e do tutorial; o Launcher le, apaga e, se for tutorial/completed ou
## bot/win (qualquer nivel), avisa o backend para liberar a fila online. O arquivo e aditivo: os
## codigos de saida (§5.2) nao mudam. Funcoes puras sobre ConfigFile; o caminho entra por parametro
## para o teste.

const PATH: String = "user://offline_result.cfg"
const SECTION: String = "result"
const KIND: String = "kind"
const OUTCOME: String = "outcome"
## Nivel do bot do ADR-0027; so em kind=bot.
const BOT_DIFFICULTY: String = "bot_difficulty"
const FINISHED_AT: String = "finished_at"

const KIND_TUTORIAL: String = "tutorial"
const KIND_BOT: String = "bot"
const COMPLETED: String = "completed"
const WIN: String = "win"
const LOSS: String = "loss"
const QUIT: String = "quit"

## Motivo da fila liberada na conta (SPEC-085 §5); o mesmo texto vai ao backend.
const REASON_TUTORIAL: String = "tutorial"
const REASON_BOT_WIN: String = "bot_win"

const OUTCOMES_BY_KIND: Dictionary[String, Array] = {
	KIND_TUTORIAL: [COMPLETED, QUIT],
	KIND_BOT: [WIN, LOSS, QUIT],
}


## Grava o resultado. Combinacao fora do contrato (tutorial/win, bot/completed...) nao e gravada.
## [param bot_difficulty] so entra em kind=bot.
static func write(
	kind: String, outcome: String, bot_difficulty: int = 0, path: String = PATH
) -> Error:
	if not _valid(kind, outcome):
		return ERR_INVALID_PARAMETER
	var config := ConfigFile.new()
	config.set_value(SECTION, KIND, kind)
	config.set_value(SECTION, OUTCOME, outcome)
	if kind == KIND_BOT:
		config.set_value(SECTION, BOT_DIFFICULTY, bot_difficulty)
	config.set_value(SECTION, FINISHED_AT, Time.get_datetime_string_from_system(true) + "Z")
	return config.save(path)


## O resultado gravado, ou vazio se o arquivo nao existe, nao le ou foge do contrato.
static func read(path: String = PATH) -> Dictionary:
	var config := ConfigFile.new()
	if config.load(path) != OK:
		return {}
	var kind: Variant = config.get_value(SECTION, KIND, "")
	var outcome: Variant = config.get_value(SECTION, OUTCOME, "")
	if not (kind is String and outcome is String and _valid(kind, outcome)):
		return {}
	var result := {KIND: kind, OUTCOME: outcome}
	if kind == KIND_BOT:
		var level: Variant = config.get_value(SECTION, BOT_DIFFICULTY, 0)
		result[BOT_DIFFICULTY] = level if level is int else 0
	result[FINISHED_AT] = str(config.get_value(SECTION, FINISHED_AT, ""))
	return result


## Le e apaga (o Launcher processa cada resultado uma unica vez). Arquivo invalido tambem some.
static func consume(path: String = PATH) -> Dictionary:
	var result := read(path)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	return result


## REASON_* que libera a fila para esse resultado, ou "" (derrota, saida no meio, vazio).
static func unlock_reason(result: Dictionary) -> String:
	if result.is_empty():
		return ""
	if result[KIND] == KIND_TUTORIAL and result[OUTCOME] == COMPLETED:
		return REASON_TUTORIAL
	if result[KIND] == KIND_BOT and result[OUTCOME] == WIN:
		return REASON_BOT_WIN
	return ""


static func _valid(kind: String, outcome: String) -> bool:
	return OUTCOMES_BY_KIND.has(kind) and outcome in OUTCOMES_BY_KIND[kind]
