class_name TeleportDetector
extends RefCounted
## Conta teleportes de heroi por correcao de rede (F29, SPEC-029 §3.2): em cada quadro renderizado
## compara a posicao com a do quadro anterior e descarta o que a velocidade e o tempo do quadro
## explicam. O que sobra e somado numa janela curta, para que o mesmo salto conte igual a 60 ou a
## 144 quadros por segundo. Regra pura; quem alimenta as posicoes e o TeleportMonitor.

## Janela deslizante (s) em que o deslocamento alem do esperado se soma: cerca de 1 tick.
const WINDOW_S: float = 0.05
## Depois de um quadro isento (respawn, reaparecer da neblina, avanco) o interpolador ainda desliza
## o heroi por uns quadros sem teleport(): esse tempo (s) tambem nao conta.
const SETTLE_S: float = 0.1
## Quadro mais longo que isto (s) e travada do cliente, nao da rede: so remarca a posicao.
const MAX_FRAME_S: float = 0.1

var _rules: TeleportRules
## Relogio de cada heroi, somado dos delta dos quadros dele: o cooldown nao depende de Time nem de
## quantos herois sao observados por quadro.
var _elapsed: Dictionary[int, float] = {}
var _last_position: Dictionary[int, Vector3] = {}
var _last_event: Dictionary[int, float] = {}
var _settle_until: Dictionary[int, float] = {}
## Heroi -> Vector2(instante, excesso) dos quadros dentro da janela.
var _recent: Dictionary[int, Array] = {}
var _counts: Dictionary[int, int] = {}
var _max_excess: float = 0.0


func _init(rules: TeleportRules) -> void:
	_rules = rules


## Quadro em que o deslocamento nao e salto de rede (SPEC-029 §3.2 item 2): avanco ou empurrao de
## habilidade, respawn (morto agora ou no quadro anterior), heroi escondido (a posicao que ele
## mostra e a de antes de sumir) e a cinematica de abertura, em que os herois sao postos no lugar.
static func is_exempt(
	alive: bool,
	was_alive: bool,
	shown: bool,
	was_shown: bool,
	displaced_by_skill: bool,
	cinematic: bool
) -> bool:
	return not (alive and was_alive and shown and was_shown) or displaced_by_skill or cinematic


## Um quadro de [param key]. [param expected_speed] (u/s) e a velocidade que explica o
## deslocamento; [param exempt] = avanco, empurrao, respawn ou heroi escondido: so atualiza a
## posicao. Devolve true se contou um teleporte neste quadro.
func observe(
	key: int, position: Vector3, delta: float, expected_speed: float, exempt: bool
) -> bool:
	var now: float = _elapsed.get(key, 0.0) + delta
	_elapsed[key] = now
	var before: Variant = _last_position.get(key)
	_last_position[key] = position
	if exempt or delta > MAX_FRAME_S:
		_settle_until[key] = now + SETTLE_S
		_recent.erase(key)
		return false
	if before == null or now < _settle_until.get(key, 0.0):
		return false
	var excess := position.distance_to(before as Vector3) - expected_speed * delta
	var window := _sum_window(key, now, maxf(excess, 0.0))
	_max_excess = maxf(_max_excess, window)
	if window <= _rules.teleport_threshold_u:
		return false
	if now - _last_event.get(key, -INF) < _rules.teleport_cooldown_s:
		return false
	_last_event[key] = now
	_recent.erase(key)
	_counts[key] = count(key) + 1
	return true


## Maior excesso somado numa janela, visto em quadro nao isento (u): a metrica de maior salto da
## calibracao (NetProbe).
func max_excess() -> float:
	return _max_excess


func count(key: int) -> int:
	return _counts.get(key, 0)


## Soma de todos os herois vistos.
func total() -> int:
	var sum := 0
	for value: int in _counts.values():
		sum += value
	return sum


## O heroi saiu de cena: o proximo quadro dele so marca a posicao.
func forget(key: int) -> void:
	_last_position.erase(key)
	_settle_until.erase(key)
	_recent.erase(key)


## Soma o excesso do quadro com o dos que ainda estao na janela, descartando os mais velhos.
func _sum_window(key: int, now: float, excess: float) -> float:
	var recent: Array = _recent.get(key, [])
	while not recent.is_empty() and now - (recent[0] as Vector2).x > WINDOW_S:
		recent.pop_front()
	recent.append(Vector2(now, excess))
	_recent[key] = recent
	var sum := 0.0
	for entry: Vector2 in recent:
		sum += entry.y
	return sum
