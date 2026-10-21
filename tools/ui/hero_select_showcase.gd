extends SceneTree
## Vitrine da tela de selecao de herois (F51, #228): sobe hero_select.tscn com os 10 herois e grava
## um PNG por tamanho de janela, para ver se o conteudo cabe em 16:9 e em ultrawide. Ferramenta de
## autoria (prova do #228), fora do jogo. Precisa de janela (nao roda em --headless). Uso, na raiz:
##   godot --path game -s <repo>/tools/ui/hero_select_showcase.gd -- --out <pasta>
##     [--sizes 1280x720,1920x1080,2560x1440,3440x1440]
## --ui-scale <x>: escala da interface (root.content_scale_factor, F97).
## Sai sozinha no fim. O tamanho pedido vira o tamanho da janela do jogo (root.size); o stretch do
## projeto (canvas_items, base 1920x1080, expand) faz o resto, como em tela cheia.

## Tudo carregado em tempo de execucao: script de SceneTree compila antes dos autoloads, e a
## HeroSelect depende do MatchController (NetworkTime), entao nada disso pode ser preload nem tipo.
const SCENE: String = "res://scenes/ui/hero_select.tscn"
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
]
const DEFAULT_SIZES: String = "1280x720,1920x1080,2560x1440,3440x1440"
const TICK_RATE: int = 30
const START_TICK: int = 1000
const RIVAL_PEER: int = 22
## Tempo da tela aberta na contagem (s) e espera para fontes, layout e modelos 3D assentarem.
const PICK_SECONDS: float = 24.0
const SETTLE_SECONDS: float = 1.5

var _out_dir: String = "user://"
var _sizes: PackedStringArray = DEFAULT_SIZES.split(",")
var _screen: Node


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var at := args.find("--out")
	if at >= 0 and at + 1 < args.size():
		_out_dir = args[at + 1]
	at = args.find("--sizes")
	if at >= 0 and at + 1 < args.size():
		_sizes = args[at + 1].split(",")
	at = args.find("--ui-scale")
	if at >= 0 and at + 1 < args.size():  # escala da interface do jogo (F97, ADR-0031)
		root.content_scale_factor = args[at + 1].to_float()
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
	_screen = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_screen)
	_screen.call("bind", controller, roster, available)
	_screen.call("open", PICK_SECONDS)
	for size_text: String in _sizes:
		await _shot(size_text)
	quit()


func _shot(size_text: String) -> void:
	var parts := size_text.split("x")
	root.size = Vector2i(int(parts[0]), int(parts[1]))
	await create_timer(SETTLE_SECONDS).timeout
	_report()
	var image := root.get_texture().get_image()
	var path := "%s/hero-select-%s.png" % [_out_dir.trim_suffix("/"), size_text]
	var err := image.save_png(path)
	print(
		(
			"[showcase] %s -> janela %s, imagem %s (%s)"
			% [size_text, root.size, image.get_size(), error_string(err)]
		)
	)


## Alturas em unidades da base (1920x1080): quanto cada bloco pede e quanto recebe.
func _report() -> void:
	for path: String in [
		"Root",
		"Root/Column",
		"Root/Column/Body",
		"Root/Column/Body/Columns",
		"Root/Column/Body/Columns/RosterCard",
		"Root/Column/Body/Columns/PlayerCard"
	]:
		var node := _screen.get_node_or_null(path) as Control
		if node != null:
			print(
				(
					"[medida] %s: tamanho %s, minimo %s, pos %s"
					% [path, node.size, node.get_combined_minimum_size(), node.position]
				)
			)
