extends SceneTree
## Vitrine da HUD da partida (F57): sobe hud.tscn sobre a arena com um Cavaleiro (nivel 6, um
## item de conjunto) contra uma Arqueira e grava um PNG da fase 1, da engrenagem aberta e da fase
## 2. Ferramenta de autoria (comparar com docs/prd/telas/HUD Moderno/screen.png, captura do
## roadmap), fora do jogo. Precisa de janela (nao roda em --headless). Uso, na raiz:
##   godot --path game --resolution 1920x1080 -s <repo>/tools/ui/hud_showcase.gd -- --out <pasta>
## --ui-scale <x>: escala da interface (root.content_scale_factor, F97).
## Sai sozinha no fim. Relogio parado no inicio; o estado e de exemplo (nao vem de partida).

## Tudo carregado em tempo de execucao: script de SceneTree compila antes dos autoloads.
const HUD: String = "res://scenes/ui/hud.tscn"
const ARENA: String = "res://scenes/arena/ilha_arcana.tscn"
const KNIGHT: String = "res://scenes/heroes/knight.tscn"
const RANGER: String = "res://scenes/heroes/ranger.tscn"
const RULES: String = "res://shared/data/rules/match_pacing.tres"
const HELM: String = "res://shared/data/items/guard_set/guard_helm_t1.tres"
const TICKRATE: int = 30
const LEVEL: int = 6
## Camera da vitrine: alto sobre a base SO, olhando o centro.
const CAMERA_AT: Vector3 = Vector3(-14.0, 16.0, 14.0)
const SETTLE_SECONDS: float = 1.0
const SETTLE_FRAMES: int = 3

var _out_dir: String = "user://"


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var at := args.find("--out")
	if at >= 0 and at + 1 < args.size():
		_out_dir = args[at + 1]
	at = args.find("--ui-scale")
	if at >= 0 and at + 1 < args.size():  # escala da interface do jogo (F97, ADR-0031)
		root.content_scale_factor = args[at + 1].to_float()
	_run.call_deferred()


func _run() -> void:
	var rules: Resource = load(RULES)
	root.add_child((load(ARENA) as PackedScene).instantiate())
	var camera := Camera3D.new()
	root.add_child(camera)
	camera.look_at_from_position(CAMERA_AT, Vector3.ZERO)
	camera.current = true
	var players := Node3D.new()
	root.add_child(players)
	var hero := _hero(players, KNIGHT, "1", Vector3(-20, 0, 20))
	_hero(players, RANGER, "2", Vector3(20, 0, -20))
	var clock: Node = _node("res://scripts/match/match_clock.gd", rules)
	var spawns: Node = (load("res://scripts/match/spawn_director.gd") as GDScript).new()
	root.add_child(spawns)
	var controller: Node = _node("res://scripts/match/match_controller.gd", rules)
	var zone: Node = _node("res://scripts/match/zone_controller.gd", rules)
	zone.set("clock", clock)
	await process_frame
	hero.set("level", LEVEL)
	hero.set("equipment", Inventory.equip(hero.get("equipment"), load(HELM) as ItemData))
	var hud: Node = (load(HUD) as PackedScene).instantiate()
	root.add_child(hud)
	hud.call("bind", hero, clock, spawns, players, controller, zone)
	clock.call("_begin", 0, TICKRATE)
	await _shot("fase1")
	var gear := hud.get_node("HudPhase1").find_child("GearButton", true, false) as Button
	gear.pressed.emit()
	await _shot("fase1-engrenagem")
	gear.pressed.emit()
	controller.set("state", MatchState.State.PHASE2)
	controller.emit_signal("phase_changed", MatchState.State.PHASE1, MatchState.State.PHASE2, 0)
	zone.emit_signal("zone_updated", 30.0, 24.0, 0.02, 29.0, 0)
	await _shot("fase2")
	quit()


func _node(path: String, rules: Resource) -> Node:
	var node: Node = (load(path) as GDScript).new()
	node.set("rules", rules)
	root.add_child(node)
	return node


func _hero(players: Node3D, scene: String, peer: String, where: Vector3) -> Node3D:
	var hero := (load(scene) as PackedScene).instantiate() as Node3D
	hero.name = peer
	hero.position = where
	players.add_child(hero)
	return hero


func _shot(shot_name: String) -> void:
	await create_timer(SETTLE_SECONDS).timeout
	for i: int in SETTLE_FRAMES:
		await process_frame
	var path := "%s/hud-%s.png" % [_out_dir.trim_suffix("/"), shot_name]
	var err := root.get_texture().get_image().save_png(path)
	print("[showcase] %s -> %s (%s)" % [shot_name, path, error_string(err)])
