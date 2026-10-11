class_name HeroVfx
extends Node3D
## Efeitos de um heroi (F41), so no cliente (VfxSpawner): segue o heroi e dispara pela borda do
## estado replicado/previsto (VfxRules.started), como o HeroVisual. Nada nasce no _rollback_tick:
## ressimular restaura o mesmo estado e nao cria borda nova, e o heroi remoto, que o cliente nao
## simula, entra pelo mesmo caminho. Impacto confirmado vem do servidor (impact, ImpactRelay).
## Heroi escondido (mato, neblina) ou morto nao mostra nada; ao reaparecer as bordas recomecam do
## estado atual, para nao mostrar um disparo que aconteceu escondido.

## Medicao (NetProbe, --probe): disparos mostrados por "peer:chave" (chaves = as do servidor).
static var shown_events: Dictionary = {}

var hero: Hero
var pool: VfxPool

## Ultimo valor visto de cada timer/flag (borda).
var _previous: Dictionary = {}  # StringName -> int
var _was_shown: bool = false


func _process(delta: float) -> void:
	if not is_instance_valid(hero):
		queue_free()
		return
	global_transform = hero.global_transform
	var shown := hero.is_shown() and hero.is_alive()
	if shown != _was_shown:
		_was_shown = shown
		visible = shown
		_previous.clear()
	_refresh(shown, delta)


## Liga ao [param p_hero]; efeitos de uma vez saem de [param p_pool].
func bind(p_hero: Hero, p_pool: VfxPool) -> void:
	hero = p_hero
	pool = p_pool
	visible = false  # aparece no 1o quadro em que o jogador ve o heroi
	_was_shown = false
	_bound()


## Golpe de [param _slot] confirmado pelo servidor em [param _at] (alvo visto por este jogador).
func impact(_slot: HitLedger.Slot, _at: Vector3) -> void:
	pass


## Subclasse: le numeros do HeroData e da cena do heroi.
func _bound() -> void:
	pass


## Subclasse, a cada quadro: [param _shown] = o jogador ve o heroi vivo.
func _refresh(_shown: bool, _delta: float) -> void:
	pass


## O timer [param key] subiu (disparo novo) com o heroi visivel. O 1o valor visto nao e borda.
func _started(key: StringName, value: int) -> bool:
	var before: int = _previous.get(key, value)
	_previous[key] = value
	return VfxRules.started(before, value) and _shown_event(key)


## A flag [param key] acabou de desligar (fim do avanco) com o heroi visivel.
func _ended(key: StringName, active: bool) -> bool:
	var before: int = _previous.get(key, int(active))
	_previous[key] = int(active)
	return before == 1 and not active and _shown_event(key)


func _shown_event(key: StringName) -> bool:
	if not _was_shown:
		return false
	var id := "%d:%s" % [hero.peer_id, key]
	shown_events[id] = shown_events.get(id, 0) + 1
	return true
