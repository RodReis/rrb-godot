class_name LoadingRules
extends RefCounted
## Sorteio da tela de loading do Game (F68, SPEC-068): uma das 3 artes e uma dica da lista fixa,
## uniformes por abertura. A seed e parametro para o teste ser deterministico.

## Artes 1920x1080 geradas por tools/ui/render_loading.gd: arena de dia, de noite e os herois.
const ART_PATHS: Array[String] = [
	"res://shared/assets/ui/loading/arena_day.png",
	"res://shared/assets/ui/loading/arena_night.png",
	"res://shared/assets/ui/loading/heroes.png",
]
const TIPS_PATH: String = "res://shared/data/ui/tips.tres"


## Indice da arte (0..ART_PATHS.size()-1) para a [param rng_seed].
static func art_index(rng_seed: int) -> int:
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	return rng.randi_range(0, ART_PATHS.size() - 1)


## Indice da dica (0..count-1) para a [param rng_seed]; -1 se a lista estiver vazia. Sorteio
## independente do da arte (outra semente derivada).
static func tip_index(rng_seed: int, count: int) -> int:
	if count <= 0:
		return -1
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([rng_seed, "tip"])
	return rng.randi_range(0, count - 1)
