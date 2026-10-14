extends SceneTree
## Vitrine da tela de fim de partida (F52): sobe match_end.tscn com estatisticas de exemplo,
## mostra a vitoria, a derrota e o abandono e grava um PNG de cada um. Ferramenta de autoria
## (comparar com o screen.png do protótipo, captura do roadmap), fora do jogo. Precisa de janela
## (nao roda em --headless). Uso, na raiz:
##   godot --path game --resolution 1920x1080 -s <repo>/tools/ui/match_end_showcase.gd
##     -- --out <pasta>
## Sai sozinha no fim. Os dados sao de exemplo (nao vem de partida).

## Tudo carregado em tempo de execucao: script de SceneTree compila antes dos autoloads, e a
## MatchEnd depende do MatchController (NetworkTime), entao nada disso pode ser preload nem tipo.
const SCENE: String = "res://scenes/ui/match_end.tscn"
const CONTROLLER: String = "res://scripts/match/match_controller.gd"
const RULES: String = "res://shared/data/rules/match_pacing.tres"
const HEROES: Array[String] = ["knight", "ranger", "barbarian", "fire_wizard", "rogue", "engineer"]
const ME: int = 11
const THEM: int = 22
## Segundos esperados depois de present(), para a animacao de entrada terminar.
const SETTLE_SECONDS: float = 1.6
## Quadros esperados entre uma tela e a captura.
const SETTLE_FRAMES: int = 3

var _out_dir: String = "user://"


func _initialize() -> void:
	# O Godot parte "--out=pasta" em dois argumentos; "--out pasta" tambem chega em dois.
	var args := OS.get_cmdline_user_args()
	var at := args.find("--out")
	if at < 0:
		at = args.find("--out=")
	if at >= 0 and at + 1 < args.size():
		_out_dir = args[at + 1]
	_run.call_deferred()


func _run() -> void:
	var controller: Node = (load(CONTROLLER) as GDScript).new()
	controller.set("rules", load(RULES))
	root.add_child(controller)
	var end: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(end)
	var roster: Array[HeroData] = []
	for hero: String in HEROES:
		roster.append(load("res://shared/data/heroes/%s.tres" % hero) as HeroData)
	end.call("bind", controller, roster)
	await _shot(end, "vitoria", ME, VictoryRules.ELIMINATION, ME)
	await _shot(end, "derrota", ME, VictoryRules.KILL_GOAL, THEM)
	await _shot(end, "sem-vencedor", VictoryRules.NO_WINNER, VictoryRules.ABANDONED, ME)
	quit()


func _shot(end: Node, shot_name: String, winner: int, reason: StringName, peer: int) -> void:
	end.call("present", winner, reason, _stats(), peer)
	await create_timer(SETTLE_SECONDS).timeout
	for i: int in SETTLE_FRAMES:
		await process_frame
	var path := "%s/match-end-%s.png" % [_out_dir.trim_suffix("/"), shot_name]
	var err := root.get_texture().get_image().save_png(path)
	print("[showcase] %s -> %s (%s)" % [shot_name, path, error_string(err)])


## Exemplo: Arqueira (nivel 10) contra Cavaleiro, com conjunto ativo e o Rei Esqueleto abatido.
func _stats() -> MatchStats:
	var stats := MatchStats.new()
	stats.duration = 594.0
	var me := stats.player(ME)
	me.hero = Ids.to_int(&"ranger")
	me.kills = 5
	me.deaths = 0
	me.level = 10
	me.hero_damage = 4820
	me.damage_taken = 1450
	me.monsters = 8
	me.chests = 4
	me.boss_killed = true
	var guard := Ids.to_int(&"guard_helm_t1")
	me.equipment = Vector4i(Ids.NONE, guard, Ids.NONE, Ids.NONE)
	var them := stats.player(THEM)
	them.hero = Ids.to_int(&"knight")
	them.kills = 3
	them.deaths = 5
	them.level = 8
	them.hero_damage = 2150
	them.damage_taken = 4820
	them.monsters = 4
	them.chests = 1
	return stats
