extends SceneTree
## Sonda de frame time (F38, bloco visual regra 5): sobe a partida de main.tscn com os argumentos
## de usuario, espera os dois herois nascerem, aquece e mede o tempo de quadro com vsync
## desligado. Imprime e grava em <saida>.json: media e p99 do intervalo entre quadros (CPU) e do
## tempo de render da GPU no viewport raiz, alem da resolucao. Ferramenta de autoria, fora do
## jogo. Uso (na raiz do repo, janela aberta, nao headless):
##   godot --path game --resolution 1920x1080 -s <repo>/tools/perf/frametime_probe.gd --
##     --offline --bot --autopilot=bot --seed=38 --out=<saida>
## --equip: os dois herois ficam com as 4 pecas epicas a medicao inteira (SPEC-048 §6 item 4).
## Sai com 1 se os herois nao nascerem em SPAWN_TIMEOUT segundos.

const MAIN: String = "res://scenes/main.tscn"
const HEROES: int = 2
## Pick do humano cai no default em 24 s (match_pacing.tres); folga para a espera e a selecao.
const SPAWN_TIMEOUT: float = 60.0
## Depois do spawn: compila o que faltar e deixa a camera chegar no heroi.
const WARMUP_SECONDS: float = 5.0
const MEASURE_SECONDS: float = 30.0
const P99: float = 0.99
## Itens do --equip, por HeroData.id (um conjunto por heroi, arma epica).
const EPIC_SETS: Dictionary[StringName, Array] = {
	&"knight": [&"sword_t3_epic", &"guard_helm_t3", &"guard_chest_t3", &"guard_boots_t3"],
	&"ranger": [&"sword_t3_epic", &"hunter_helm_t3", &"hunter_chest_t3", &"hunter_boots_t3"],
	&"barbarian": [&"sword_t3_epic", &"guard_helm_t3", &"guard_chest_t3", &"guard_boots_t3"],
	&"fire_wizard": [&"sword_t3_epic", &"hunter_helm_t3", &"hunter_chest_t3", &"hunter_boots_t3"],
}

var _out: String = "frametime"
var _players: Node
var _elapsed: float = 0.0
var _phase: int = 0
var _cpu_ms: PackedFloat64Array = []
var _gpu_ms: PackedFloat64Array = []
var _equip: bool = false


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
		elif arg == "--equip":
			_equip = true
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
