extends SceneTree
## Sonda de frame time (F38, bloco visual regra 5): sobe a partida de main.tscn com os argumentos
## de usuario, espera os dois herois nascerem, aquece e mede o tempo de quadro com vsync
## desligado. Imprime e grava em <saida>.json: media e p99 do intervalo entre quadros (CPU) e do
## tempo de render da GPU no viewport raiz, alem da resolucao. Ferramenta de autoria, fora do
## jogo. Uso (na raiz do repo, janela aberta, nao headless):
##   godot --path game --resolution 1920x1080 -s <repo>/tools/perf/frametime_probe.gd --
##     --offline --bot --autopilot=bot --seed=38 --out=<saida>
## --equip: os dois herois ficam com as 4 pecas epicas a medicao inteira (SPEC-048 §6 item 4).
## --smoke: cada Ladina tem uma nuvem de fumaca ativa a medicao inteira (SPEC-058 §8 item 8): a
## sonda reemite o evento da nuvem (ImpactRelay.smoke_shown) no lugar dela a cada SMOKE_SECONDS.
## --engineer: cada Engenheiro tem Torreta atirando e Dinamite explodindo a medicao inteira
## (SPEC-059 §8 item 8): a sonda reemite os eventos do ImpactRelay (deploy_shown, turret_shot_shown)
## na posicao do heroi e do outro, nos compassos ENGINEER_*_SECONDS.
## --druid: cada Protetor da Selva tem Pocao Verde e Pantano ativos a medicao inteira (SPEC-074 §8):
## a sonda reemite o evento do ImpactRelay (zone_shown) nos compassos DRUID_*_SECONDS.
## --berserker: cada Berserker fica no Ragnarok a medicao inteira (SPEC-075 aceite: corpo em chamas,
## aura, fumaca e brasas do Frenesi com f = 1); a sonda segura Hero.cc_immune_ticks.
## --occultist: cada Ocultista tem Circulo Profano ativo no outro heroi a medicao inteira, e o outro
## fica com 3 marcas de Maldicao e a Praga visiveis (SPEC-077 aceite): a sonda reemite o evento do
## ImpactRelay (zone_shown) a cada OCCULTIST_CIRCLE_SECONDS e segura curse_* e dot_ticks no alvo
## (dot_left 0: a Praga aparece sem ferir). Cada Ocultista tambem reinvoca os 2 Servos do Vazio a
## cada OCCULTIST_SERVANT_SECONDS (SPEC-078 aceite: 4 servos ativos com dois Ocultistas).
## --grass: o heroi controlado fica no centro da primeira moita a medicao inteira (SPEC-072 §4: a
## silhueta e a abertura da moita ligam enquanto ele esta la).
## --shot=<arquivo.png>: grava o viewport do jogo (so ele, nunca a tela) no meio da medicao.
## Sai com 1 se os herois nao nascerem em SPAWN_TIMEOUT segundos.

const MAIN: String = "res://scenes/main.tscn"
const HEROES: int = 2
## Pick do humano cai no default em 24 s (match_pacing.tres); folga para a espera e a selecao.
const SPAWN_TIMEOUT: float = 60.0
## Depois do spawn: compila o que faltar e deixa a camera chegar no heroi.
const WARMUP_SECONDS: float = 5.0
const MEASURE_SECONDS: float = 30.0
const P99: float = 0.99
## Nova nuvem antes de a anterior (3 s) acabar.
const SMOKE_SECONDS: float = 2.5
## Compassos do --engineer (s): Torreta nova antes de a anterior (6 s) acabar, disparo a cada 0,75 s
## e caixa de Dinamite a cada 3 s (pavio de 1,5 s, entao sempre ha uma no ar ou explodindo).
const ENGINEER_TURRET_SECONDS: float = 5.5
const ENGINEER_SHOT_SECONDS: float = 0.75
const ENGINEER_CRATE_SECONDS: float = 3.0
## Compassos do --druid (s): Pocao nova antes de a anterior (3 s) acabar e Pantano novo antes de o
## anterior (6 s) acabar.
const DRUID_POTION_SECONDS: float = 2.5
const DRUID_SWAMP_SECONDS: float = 5.5
## Circulo novo antes de o anterior (3 s) acabar.
const OCCULTIST_CIRCLE_SECONDS: float = 2.5
## Servos novos antes de os anteriores (10 s no R1) acabarem.
const OCCULTIST_SERVANT_SECONDS: float = 9.5
## Ticks que o --occultist segura nas marcas e na Praga do alvo (qualquer valor > 0 as mantem).
const CURSE_HOLD_TICKS: int = 120
## Timer de imunidade que o --berserker segura (ticks; qualquer valor > 0 mantem o Ragnarok).
const RAGE_HOLD_TICKS: int = 120
## Itens do --equip, por HeroData.id (um conjunto por heroi, arma epica).
const EPIC_SETS: Dictionary[StringName, Array] = {
	&"knight": [&"sword_t3_epic", &"guard_helm_t3", &"guard_chest_t3", &"guard_boots_t3"],
	&"ranger": [&"sword_t3_epic", &"hunter_helm_t3", &"hunter_chest_t3", &"hunter_boots_t3"],
	&"barbarian": [&"sword_t3_epic", &"guard_helm_t3", &"guard_chest_t3", &"guard_boots_t3"],
	&"fire_wizard": [&"sword_t3_epic", &"hunter_helm_t3", &"hunter_chest_t3", &"hunter_boots_t3"],
	&"rogue": [&"sword_t3_epic", &"hunter_helm_t3", &"hunter_chest_t3", &"hunter_boots_t3"],
	&"engineer": [&"sword_t3_epic", &"hunter_helm_t3", &"hunter_chest_t3", &"hunter_boots_t3"],
	&"druid": [&"sword_t3_epic", &"hunter_helm_t3", &"hunter_chest_t3", &"hunter_boots_t3"],
	&"berserker": [&"sword_t3_epic", &"guard_helm_t3", &"guard_chest_t3", &"guard_boots_t3"],
	&"occultist": [&"sword_t3_epic", &"hunter_helm_t3", &"hunter_chest_t3", &"hunter_boots_t3"],
}

var _out: String = "frametime"
var _players: Node
var _elapsed: float = 0.0
var _phase: int = 0
var _cpu_ms: PackedFloat64Array = []
var _gpu_ms: PackedFloat64Array = []
var _equip: bool = false
var _smoke: bool = false
var _smoke_wait: float = 0.0
var _engineer: bool = false
var _druid: bool = false
var _berserker: bool = false
var _occultist: bool = false
var _circle_wait: float = 0.0
var _servant_wait: float = 0.0
var _potion_wait: float = 0.0
var _swamp_wait: float = 0.0
var _grass: bool = false
var _grass_linked: bool = false
var _patch: Node3D
var _shot: String = ""
var _turret_wait: float = 0.0
var _shot_wait: float = 0.0
var _crate_wait: float = 0.0


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
		elif arg == "--equip":
			_equip = true
		elif arg == "--smoke":
			_smoke = true
		elif arg == "--engineer":
			_engineer = true
		elif arg == "--druid":
			_druid = true
		elif arg == "--berserker":
			_berserker = true
		elif arg == "--occultist":
			_occultist = true
		elif arg == "--grass":
			_grass = true
		elif arg.begins_with("--shot="):
			_shot = arg.trim_prefix("--shot=")
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	var main := (load(MAIN) as PackedScene).instantiate()
	root.add_child(main)
	current_scene = main
	_players = main.get_node("Players")
	RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(), true)


func _process(delta: float) -> bool:
	_elapsed += delta
	if _equip and _phase > 0:
		_equip_heroes()  # todo quadro: o bot pode trocar item no bau
	if _smoke and _phase > 0:
		_smoke_wait -= delta
		if _smoke_wait <= 0.0:
			_smoke_wait = SMOKE_SECONDS
			_smoke_rogues()
	if _engineer and _phase > 0:
		_engineer_effects(delta)
	if _druid and _phase > 0:
		_druid_effects(delta)
	if _berserker and _phase > 0:
		_rage_berserkers()
	if _occultist and _phase > 0:
		_occultist_effects(delta)
	if _grass and _phase > 0 and not _grass_linked:
		_grass_linked = true
		root.get_node("NetworkRollback").connect(&"after_process_tick", _hold_in_grass)
	match _phase:
		0:
			if _players.get_child_count() >= HEROES:
				print("[frametime] herois nasceram em %.1f s" % _elapsed)
				_next_phase()
			elif _elapsed > SPAWN_TIMEOUT:
				push_error("[frametime] herois nao nasceram em %.0f s" % SPAWN_TIMEOUT)
				quit(1)
		1:
			if _elapsed >= WARMUP_SECONDS:
				_next_phase()
		2:
			_cpu_ms.append(delta * 1000.0)
			var gpu := RenderingServer.viewport_get_measured_render_time_gpu(
				root.get_viewport_rid()
			)
			if gpu > 0.0:  # 0 = sem medicao neste quadro
				_gpu_ms.append(gpu)
			if _shot != "" and _elapsed >= MEASURE_SECONDS / 2.0:
				root.get_viewport().get_texture().get_image().save_png(_shot)
				_shot = ""
			if _elapsed >= MEASURE_SECONDS:
				_report()
				quit(0)
	return false


## Sem tipos do jogo (Hero, Inventory): compilar hero.gd aqui, antes dos autoloads do netfox,
## falha (NetworkTime ainda nao existe). Slot do Vector4i = ItemData.slot, valor = numero do Ids.
func _equip_heroes() -> void:
	for hero: Node in _players.get_children():
		var data: Resource = hero.get(&"hero_data")
		if data == null or not EPIC_SETS.has(data.get(&"id")):
			continue
		var catalog: ItemCatalog = hero.get(&"item_catalog")
		var equipment := Vector4i.ZERO
		for id: StringName in EPIC_SETS[data.get(&"id")]:
			var number := Ids.to_int(id)
			equipment[catalog.find(number).slot] = number
		hero.set(&"equipment", equipment)


## Sem tipos do jogo (como _equip_heroes): o sinal e o tick saem pelo nome.
func _smoke_rogues() -> void:
	var relay := current_scene.get_node("ImpactRelay")
	var tick: int = root.get_node("NetworkTime").get(&"tick")
	for hero: Node in _players.get_children():
		var data: Resource = hero.get(&"hero_data")
		if data != null and data.get(&"id") == &"rogue":
			relay.emit_signal(
				&"smoke_shown", hero.name.to_int(), hero.get(&"global_position"), tick
			)


## Sem tipos do jogo (como _equip_heroes): leva o heroi controlado para o centro da moita mais
## perto dele (a da propria metade: na fase 1 o time nao sai dela) depois de simular e antes de
## gravar o tick (after_process_tick): mover so no quadro seria desfeito no tick seguinte, e o
## piloto automatico o tiraria de la.
func _hold_in_grass(_tick: int) -> void:
	var hero := _players.get_node_or_null(str(get_multiplayer().get_unique_id())) as Node3D
	if hero == null:
		return
	if _patch == null:
		var best := INF
		for node: Node in get_nodes_in_group(&"tall_grass"):
			var distance := hero.global_position.distance_to((node as Node3D).global_position)
			if distance < best:
				best = distance
				_patch = node as Node3D
	if _patch != null:
		hero.global_position = _patch.global_position * Vector3(1, 0, 1)


func _next_phase() -> void:
	_phase += 1
	_elapsed = 0.0


func _report() -> void:
	var size := root.get_viewport().get_visible_rect().size
	var result := {
		"frames": _cpu_ms.size(),
		"window": "%dx%d" % [DisplayServer.window_get_size().x, DisplayServer.window_get_size().y],
		"viewport": "%dx%d" % [size.x, size.y],
		"driver": RenderingServer.get_current_rendering_driver_name(),
		"gpu": RenderingServer.get_video_adapter_name(),
		"cpu_mean_ms": _mean(_cpu_ms),
		"cpu_p99_ms": _percentile(_cpu_ms, P99),
		"gpu_mean_ms": _mean(_gpu_ms),
		"gpu_p99_ms": _percentile(_gpu_ms, P99),
		"equip": _equip,
		"smoke": _smoke,
		"grass": _grass,
		"berserker": _berserker,
		"occultist": _occultist,
	}
	var text := JSON.stringify(result, "  ")
	print("[frametime] ", text)
	var file := FileAccess.open(_out + ".json", FileAccess.WRITE)
	if file == null:
		var reason := error_string(FileAccess.get_open_error())
		push_error("[frametime] nao gravou %s.json: %s" % [_out, reason])
		return
	file.store_string(text)


static func _mean(values: PackedFloat64Array) -> float:
	var total := 0.0
	for v: float in values:
		total += v
	return total / maxf(values.size(), 1.0)


static func _percentile(values: PackedFloat64Array, q: float) -> float:
	if values.is_empty():
		return 0.0
	var sorted := values.duplicate()
	sorted.sort()
	return sorted[mini(int(q * sorted.size()), sorted.size() - 1)]


## Sem tipos do jogo (como _smoke_rogues): Torreta, disparos e caixa pelos sinais do relay. A
## Torreta fica 2 u a frente do Engenheiro e atira no outro heroi; a caixa cai no outro heroi.
func _engineer_effects(delta: float) -> void:
	_turret_wait -= delta
	_shot_wait -= delta
	_crate_wait -= delta
	var relay := current_scene.get_node("ImpactRelay")
	var tick: int = root.get_node("NetworkTime").get(&"tick")
	for hero: Node in _players.get_children():
		var data: Resource = hero.get(&"hero_data")
		if data == null or data.get(&"id") != &"engineer":
			continue
		var position: Vector3 = hero.get(&"global_position")
		var other := _other_than(hero)
		var target: Vector3 = other.get(&"global_position") if other != null else position
		var turret := position + (target - position).normalized() * 2.0
		var caster := hero.name.to_int()
		if _turret_wait <= 0.0:
			relay.emit_signal(&"deploy_shown", caster, 0, turret, tick)
		if _shot_wait <= 0.0:
			relay.emit_signal(&"turret_shot_shown", caster, turret, target, 100)
		if _crate_wait <= 0.0:
			relay.emit_signal(&"deploy_shown", caster, 1, target, tick)
	if _turret_wait <= 0.0:
		_turret_wait = ENGINEER_TURRET_SECONDS
	if _shot_wait <= 0.0:
		_shot_wait = ENGINEER_SHOT_SECONDS
	if _crate_wait <= 0.0:
		_crate_wait = ENGINEER_CRATE_SECONDS


func _other_than(hero: Node) -> Node:
	for other: Node in _players.get_children():
		if other != hero:
			return other
	return null


## Sem tipos do jogo: Pocao nos pes do Protetor e Pantano no outro heroi, pelo sinal do relay.
func _druid_effects(delta: float) -> void:
	_potion_wait -= delta
	_swamp_wait -= delta
	var relay := current_scene.get_node("ImpactRelay")
	var tick: int = root.get_node("NetworkTime").get(&"tick")
	for hero: Node in _players.get_children():
		var data: Resource = hero.get(&"hero_data")
		if data == null or data.get(&"id") != &"druid":
			continue
		var position: Vector3 = hero.get(&"global_position")
		var other := _other_than(hero)
		var target: Vector3 = other.get(&"global_position") if other != null else position
		var caster := hero.name.to_int()
		if _potion_wait <= 0.0:
			relay.emit_signal(&"zone_shown", caster, 0, position, tick)
		if _swamp_wait <= 0.0:
			relay.emit_signal(&"zone_shown", caster, 1, target, tick)
	if _potion_wait <= 0.0:
		_potion_wait = DRUID_POTION_SECONDS
	if _swamp_wait <= 0.0:
		_swamp_wait = DRUID_SWAMP_SECONDS


## Sem tipos do jogo: o Ragnarok dura enquanto a sonda segura o timer de imunidade.
func _rage_berserkers() -> void:
	for hero: Node in _players.get_children():
		var data: Resource = hero.get(&"hero_data")
		if data != null and data.get(&"id") == &"berserker":
			hero.set(&"cc_immune_ticks", RAGE_HOLD_TICKS)


## Sem tipos do jogo: Circulo no outro heroi pelo sinal do relay; marcas e Praga seguradas nele.
func _occultist_effects(delta: float) -> void:
	_circle_wait -= delta
	_servant_wait -= delta
	var relay := current_scene.get_node("ImpactRelay")
	var tick: int = root.get_node("NetworkTime").get(&"tick")
	for hero: Node in _players.get_children():
		var data: Resource = hero.get(&"hero_data")
		if data == null or data.get(&"id") != &"occultist":
			continue
		var other := _other_than(hero)
		if other == null:
			continue
		other.set(&"curse_stacks", 3)
		other.set(&"curse_ticks", CURSE_HOLD_TICKS)
		other.set(&"dot_ticks", CURSE_HOLD_TICKS)
		other.set(&"dot_left", 0)
		if _circle_wait <= 0.0:
			var center: Vector3 = other.get(&"global_position")
			relay.emit_signal(&"zone_shown", hero.name.to_int(), 0, center, tick)
		if _servant_wait <= 0.0:
			hero.call(&"_summon", tick)
	if _circle_wait <= 0.0:
		_circle_wait = OCCULTIST_CIRCLE_SECONDS
	if _servant_wait <= 0.0:
		_servant_wait = OCCULTIST_SERVANT_SECONDS
