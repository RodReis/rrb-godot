class_name NicknameRules
extends RefCounted
## Nickname da conta (F35, CONVENTION §4.8): 3 a 16 caracteres, so A-Z a-z 0-9 _. Espelha o
## SetNicknameDto do backend (que decide a unicidade, sem diferenciar maiusculas). O "#" e so de
## exibicao: nao se digita e nao se guarda. `\z` e nao `$`: no PCRE o "$" aceita um "\n" no fim.

const MIN_LENGTH: int = 3
const MAX_LENGTH: int = 16
const PATTERN: String = "^[A-Za-z0-9_]{3,16}\\z"
const PREFIX: String = "#"

static var _regex: RegEx = RegEx.create_from_string(PATTERN)


static func is_valid(text: String) -> bool:
	return _regex.search(text) != null


## "#RodReis"; vazio sem nickname.
static func display(nickname: String) -> String:
	return PREFIX + nickname if not nickname.is_empty() else ""
