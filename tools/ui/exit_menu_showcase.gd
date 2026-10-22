extends SceneTree
## Vitrine do menu do Esc (F80): sobe a selecao de herois (fundo), abre o ExitMenu e grava um PNG do
## menu e outro da confirmacao online. Ferramenta de autoria (evidencia, captura do roadmap), fora
## do jogo. Precisa de janela (nao roda em --headless). Uso, na raiz:
##   godot --path game --resolution 1920x1080 -s <repo>/tools/ui/exit_menu_showcase.gd
##     -- --out <pasta>
## Sai sozinha no fim.

## Tudo carregado em tempo de execucao: script de SceneTree compila antes dos autoloads.
const HERO_SELECT: String = "res://scenes/ui/hero_select.tscn"
const EXIT_MENU: String = "res://scripts/ui/exit_menu.gd"
const CONTROLLER: String = "res://scripts/match/match_controller.gd"
const CLOCK: String = "res://scripts/match/match_clock.gd"
const RULES: String = "res://shared/data/rules/match_pacing.tres"
const HEROES: Array[String] = [
	"knight",
	"ranger",
	"barbarian",
	"fire_wizard",
	"rogue",
	"engineer",
	"druid",
	"berserker",
	"occultist",
	"paladin",
	"carrasco",
]
const TICK_RATE: int = 30
const START_TICK: int = 1000
const RIVAL_PEER: int = 22
const PICK_SECONDS: float = 24.0
const SETTLE_SECONDS: float = 1.5

var _out_dir: String = "user://"


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var at := args.find("--out")
	if at >= 0 and at + 1 < args.size():
		_out_dir = args[at + 1]
	_run.call_deferred()


func _run() -> void:
	var rules: Resource = load(RULES)
	var clock: Node = (load(CLOCK) as GDScript).new()
	clock.set("rules", rules)
	root.add_child(clock)
	var controller: Node = (load(CONTROLLER) as GDScript).new()
	controller.set("rules", rules)
	controller.set("clock", clock)
	var available: Array[StringName] = []
	var roster: Array[HeroData] = []
	for hero: String in HEROES:
		available.append(StringName(hero))
		roster.append(load("res://shared/data/heroes/%s.tres" % hero) as HeroData)
	controller.set("available_heroes", available.duplicate())
	root.add_child(controller)
	controller.call("open", START_TICK, TICK_RATE)
	controller.call("join", root.multiplayer.get_unique_id(), 0, false, START_TICK)
	controller.call("join", RIVAL_PEER, 1, false, START_TICK)
	var screen: Node = (load(HERO_SELECT) as PackedScene).instantiate()
	root.add_child(screen)
	screen.call("bind", controller, roster, available)
	screen.call("open", PICK_SECONDS)
	var menu: Node = (load(EXIT_MENU) as GDScript).new()
	root.add_child(menu)
	menu.call("open", true)
	await _shot("menu")
	menu.call("_ask_confirmation")
	await _shot("confirmacao-online")
	quit()


func _shot(shot_name: String) -> void:
	await create_timer(SETTLE_SECONDS).timeout
	var path := "%s/exit-menu-%s.png" % [_out_dir.trim_suffix("/"), shot_name]
	var err := root.get_texture().get_image().save_png(path)
	print("[showcase] %s -> %s (%s)" % [shot_name, path, error_string(err)])
