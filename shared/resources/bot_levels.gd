class_name BotLevels
extends Resource
## Escada de niveis do bot (F81, ADR-0027): `--bot-difficulty=<n>` e o indice 1-based. Nivel novo =
## linha nova em bot_levels.tres, sem ADR.

## Nivel usado com argumento ausente ou fora de 1..N (o bot de antes do F81).
const DEFAULT_NUMBER: int = 2

@export var levels: Array[BotLevel]


func count() -> int:
	return levels.size()


## O nivel [param number] (1..N); fora da faixa, o padrao.
func pick(number: int) -> BotLevel:
	return levels[normalize(number) - 1]


func normalize(number: int) -> int:
	return number if number >= 1 and number <= levels.size() else DEFAULT_NUMBER
