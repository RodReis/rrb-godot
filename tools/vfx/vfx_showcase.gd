extends SceneTree
## Vitrine dos VFX de combate (F41): sobe a partida de main.tscn offline vs bot, escolhe o heroi,
## poe o jogador perto do monstro vivo mais proximo e aperta as teclas reais (Input.action_press,
## mira pelo mouse em cima do monstro) numa sequencia que mostra basico, Q, E e R. Ferramenta de
## autoria (verificacao visual, captura do roadmap com o Movie Maker), fora do jogo. Uso, na raiz:
##   godot --path game --resolution 1280x720 -s <repo>/tools/vfx/vfx_showcase.gd
##     [--write-movie <saida>.avi --fixed-fps 30] -- --offline --bot --level=10 --hero=ranger
## Sai sozinha no fim da sequencia. Como o frametime_probe: script de SceneTree compila antes dos
## autoloads, entao heroi, monstro, MatchController e NetworkTime sao lidos sem tipo de classe.

const MAIN: String = "res://scenes/main.tscn"
## Distancia (u) ate o monstro ao comecar: a Investida (6 u) e a flecha alcancam.
const START_DISTANCE: Dictionary = {"knight": 4.0, "ranger": 6.0, "rogue": 3.5, "engineer": 5.0, "druid": 5.0}
## Sequencia por heroi: [segundos desde o inicio, acao, segundos apertada]. Acao "end" encerra.
const SCRIPTS: Dictionary = {
	"knight":
	[
		[0.6, &"skill_q", 0.1],
		[1.6, &"primary_attack", 0.1],
		[2.7, &"primary_attack", 0.1],
		[3.3, &"skill_e", 0.1],
		[4.3, &"primary_attack", 0.1],
		[5.2, &"skill_r", 0.1],
		[9.5, &"end", 0.0],
	],
	"ranger":
	[
		[0.6, &"primary_attack", 0.1],
		[1.5, &"primary_attack", 0.1],
		[2.4, &"skill_q", 0.1],
		[3.4, &"move_left", 0.35],
		[3.45, &"skill_e", 0.1],
		[4.6, &"skill_r", 0.1],
		[5.6, &"primary_attack", 0.1],
		[6.5, &"primary_attack", 0.1],
		[9.0, &"end", 0.0],
	],
	# Ladina (F58): basico, Rajada a 3,5 u, fumaca (E) e Emboscada de dentro da nuvem (R, x1,3).
	"rogue":
	[
		[0.6, &"primary_attack", 0.1],
		[1.6, &"skill_q", 0.1],
		[3.0, &"skill_e", 0.1],
		[5.0, &"skill_r", 0.1],
		[7.0, &"primary_attack", 0.1],
		[11.0, &"end", 0.0],
	],
	# Engenheiro (F59): Garra a 5 u, Torreta (E, atira no monstro), Dinamite no monstro (R) e o
	# bacamarte de perto no fim.
	"engineer":
	[
		[0.6, &"skill_q", 0.1],
		[1.8, &"skill_e", 0.1],
		[4.0, &"skill_r", 0.1],
		[8.2, &"primary_attack", 0.1],
		[9.2, &"primary_attack", 0.1],
		[11.0, &"end", 0.0],
	],
	# Protetor da Selva (F74): Seiva, Raizes a 5 u, Pocao Verde nos pes (E), Pantano no monstro (R).
	"druid":
	[
		[0.6, &"primary_attack", 0.1],
		[1.6, &"skill_q", 0.1],
		[3.4, &"skill_e", 0.1],
		[5.2, &"skill_r", 0.1],
		[12.0, &"primary_attack", 0.1],
		[13.0, &"end", 0.0],
	],
}

var _main: Node
var _hero_id: String = "knight"
var _hero: Node3D
var _target: Node3D
var _elapsed: float = -1.0
var _step: int = 0
var _releases: Dictionary = {}  # acao -> segundos em que solta


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--hero="):
			_hero_id = arg.trim_prefix("--hero=")
	_main = (load(MAIN) as PackedScene).instantiate()
	root.add_child(_main)
	current_scene = _main


func _process(delta: float) -> bool:
	var controller := _main.get_node("MatchController")
	if controller.get("state") == MatchState.State.HERO_PICK:
		var tick: int = root.get_node("NetworkTime").get("tick")
		controller.call("submit_pick", 1, StringName(_hero_id), tick)
	if _hero == null:
		if controller.get("state") <= MatchState.State.INTRO:
			return false  # o heroi ja existe na INTRO, mas sem input (F69)
		_hero = _main.get_node_or_null("Players/1") as Node3D
		if _hero != null:
			_place()
		return false
	if _target != null:
		var camera := _main.get_viewport().get_camera_3d()
		if camera != null:
			var on_viewport := camera.unproject_position(_target.global_position)
			Input.warp_mouse(_main.get_viewport().get_screen_transform() * on_viewport)
	_elapsed += delta
	if _elapsed < 0.0:
		return false
	for action: StringName in _releases.keys():
		if _elapsed >= _releases[action]:
			Input.action_release(action)
			_releases.erase(action)
	var steps: Array = SCRIPTS[_hero_id]
	while _step < steps.size() and _elapsed >= steps[_step][0]:
		var action: StringName = steps[_step][1]
		if action == &"end":
			print("[showcase] fim")
			return true
		Input.action_press(action)
		_releases[action] = _elapsed + float(steps[_step][2])
		print("[showcase] %.2f s %s" % [_elapsed, action])
		_step += 1
	return false


## Jogador a START_DISTANCE do monstro vivo mais perto, de frente para ele.
func _place() -> void:
	var best := INF
	for node: Node in _main.get_node("Spawns").get_children():
		var monster := node as Node3D
		var script := node.get_script() as Script
		if script == null or script.get_global_name() != &"Monster" or not node.call("is_alive"):
			continue
		var d := monster.global_position.distance_to(_hero.global_position)
		if d < best:
			best = d
			_target = monster
	if _target == null:
		push_error("[showcase] sem monstro vivo")
		return
	var away := _hero.global_position - _target.global_position
	away.y = 0.0
	var distance: float = START_DISTANCE[_hero_id]
	var spot := _target.global_position + away.normalized() * distance
	_hero.global_position = Vector3(spot.x, _hero.global_position.y, spot.z)
	_hero.look_at(
		Vector3(_target.global_position.x, _hero.global_position.y, _target.global_position.z)
	)
	_elapsed = -1.0  # 1 s para a camera chegar
	print("[showcase] %s perto de %s" % [_hero_id, _target.name])
