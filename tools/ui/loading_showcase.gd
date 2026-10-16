extends SceneTree
## Vitrine da tela de loading do Game (F68): mostra cada uma das 3 artes com dica e barra em
## ponto de exemplo e grava um PNG de cada. Ferramenta de autoria (verificacao do PI e captura do
## roadmap), fora do jogo. Precisa de janela (nao roda em --headless). Uso, na raiz:
##   godot --path game --resolution 1920x1080 -s <repo>/tools/ui/loading_showcase.gd
##     -- --out <pasta>
## Sai sozinha no fim. A barra mostra uma etapa no meio, so para a imagem (nao vem de partida).

## Carregado em tempo de execucao: script de SceneTree compila antes dos autoloads.
const SCREEN: String = "res://scripts/ui/loading_screen.gd"
const TIPS: String = "res://shared/data/ui/tips.tres"
## Quadros esperados entre uma tela e a captura.
const SETTLE_FRAMES: int = 6
## Etapa mostrada na captura: shaders prontos, conectando pela metade.
const SAMPLE_CONNECT: float = 0.5
const ART_NAMES: Array[String] = ["arena-dia", "arena-noite", "herois"]

var _out_dir: String = "user://"


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var at := args.find("--out")
	if at >= 0 and at + 1 < args.size():
		_out_dir = args[at + 1]
	_run.call_deferred()


func _run() -> void:
	var screen: Node = (load(SCREEN) as GDScript).new()
	root.add_child(screen)
	var tips := load(TIPS) as Resource
	for art: int in ART_NAMES.size():
		screen.call("show_random", _seed_for(art), tips)
		screen.call("complete", 0)
		screen.call("report", 1, SAMPLE_CONNECT)
		for i: int in SETTLE_FRAMES:
			await process_frame
		var path := "%s/loading-%s.png" % [_out_dir.trim_suffix("/"), ART_NAMES[art]]
		var err := root.get_texture().get_image().save_png(path)
		print("[showcase] %s -> %s (%s)" % [ART_NAMES[art], path, error_string(err)])
	quit()


## Primeira semente que sorteia a arte [param art].
func _seed_for(art: int) -> int:
	var rules := load("res://scripts/core/loading_rules.gd") as GDScript
	var rng_seed := 0
	while int(rules.call("art_index", rng_seed)) != art:
		rng_seed += 1
	return rng_seed
