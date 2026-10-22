class_name TutorialDirector
extends Node
## Roteiro do tutorial (F85, SPEC-085 §2). Observa o heroi local, a camera e o mundo, preenche o
## TutorialRules.Progress e avanca o passo quando o jogador faz a acao (regra em TutorialRules).
## So ordena eventos: marca o monstro e o bau do passo, completa o XP para o abate fechar o nivel
## (passo 4), adianta o relogio ao fim da fase 1 e solta o bot (passo 6). Nao muda numero de
## heroi, item nem regra da partida. Existe so no `--tutorial`, que roda offline: este processo e o
## servidor, entao ler o estado do heroi aqui e ler o estado autoritativo. So observa o passo
## atual: o que o jogador fez antes de chegar nele nao conta.

signal step_changed(step: TutorialRules.Step)

## Fonte do XP de ajuste no ledger do heroi (fora dos ids de peer e de bau).
const XP_SOURCE_ID: int = -9999
## Deslocamento por quadro (u) acima do qual foi teleporte (respawn), nao andar.
const MAX_STEP_DISTANCE: float = 3.0
## Marcador de cone sobre o alvo do passo.
const MARKER_HEIGHT: float = 3.4
const MARKER_BOB: float = 0.25
const MARKER_BOB_SPEED: float = 4.0
const MARKER_RADIUS: float = 0.35
const MARKER_SIZE: float = 0.7
const MARKER_COLOR: Color = UiTokens.GOLD_BRIGHT
## Entre buscas do alvo quando o atual segue valido.
const REFRESH_SECONDS: float = 1.0

var step: TutorialRules.Step = TutorialRules.Step.MOVE_CAMERA
var progress: TutorialRules.Progress = TutorialRules.Progress.new()

var _hero: Hero
var _camera: FollowCamera
var _spawns: SpawnDirector
var _clock: MatchClock
var _match: MatchController
var _bestiary: Bestiary
var _overlay: TutorialOverlay
var _bot: BotInput
var _marker: MeshInstance3D
var _focus: Node3D
var _refresh_left: float = 0.0
var _last_position: Vector3 = Vector3.ZERO
var _last_yaw: float = 0.0
var _last_cooldowns: Vector3i = Vector3i.ZERO
var _level_at_entry: int = 1
var _points_at_entry: int = 0


## Ligado a um heroi que ainda existe.
func is_bound() -> bool:
	return is_instance_valid(_hero)


func bind(
	hero: Hero,
	camera: FollowCamera,
	spawns: SpawnDirector,
	clock: MatchClock,
	match_controller: MatchController,
	bestiary: Bestiary,
	overlay: TutorialOverlay,
	players: Node
) -> void:
	_hero = hero
	_camera = camera
	_spawns = spawns
	_clock = clock
	_match = match_controller
	_bestiary = bestiary
	_overlay = overlay
	for node: Node in players.get_children():
		var other := node as Hero
		if other != null and other.is_bot:
			_bot = other.get_node("Input") as BotInput
	_last_position = hero.global_position
	_last_yaw = camera.global_rotation.y
	hero.struck.connect(_on_hero_struck)
	camera.distance_changed.connect(_on_camera_distance_changed)
	spawns.monster_killed.connect(_on_spawns_monster_killed)
	match_controller.phase_changed.connect(_on_match_phase_changed)
	_marker = _make_marker()
	add_child(_marker)
	_show_overlay(match_controller.state)
	_enter(step)


## O jogador venceu o bot (ou nao): [param winner] e o peer vencedor da partida.
func report_match_ended(winner: int) -> void:
	if not is_bound():
		return
	progress.won = winner == _hero.peer_id
	if progress.won:
		_advance_while_complete()


func _process(delta: float) -> void:
	if not is_bound():
		return
	_track()
	_advance_while_complete()
	_update_marker(delta)


## Quadro a quadro: anda, gira, recargas. So o passo atual aproveita o que viu.
func _track() -> void:
	var position := _hero.global_position
	var yaw := _camera.global_rotation.y
	var cooldowns := Vector3i(_hero.q_cooldown, _hero.e_cooldown, _hero.r_cooldown)
	if _match.state < MatchState.State.PHASE1:  # cinematica: a camera voa sozinha, nao conta
		_last_position = position
		_last_yaw = yaw
		_last_cooldowns = cooldowns
		return
	match step:
		TutorialRules.Step.MOVE_CAMERA:
			var walked := Vector2(position.x - _last_position.x, position.z - _last_position.z)
			if walked.length() < MAX_STEP_DISTANCE:
				progress.moved += walked.length()
			progress.orbited += absf(angle_difference(_last_yaw, yaw))
		TutorialRules.Step.TARGET_ATTACK:
			progress.targeted = progress.targeted or _hero.target_id != TargetRules.NONE
		TutorialRules.Step.SKILLS:
			progress.used_q = progress.used_q or _fired(_last_cooldowns.x, cooldowns.x)
			progress.used_e = progress.used_e or _fired(_last_cooldowns.y, cooldowns.y)
			progress.used_r = progress.used_r or _fired(_last_cooldowns.z, cooldowns.z)
		TutorialRules.Step.MONSTER_XP:
			var level := XpTable.level_for_xp(_hero.xp_curve, _hero.xp)
			progress.leveled = progress.leveled or level > _level_at_entry
			progress.point_spent = progress.point_spent or _ranks_total() > _points_at_entry
		TutorialRules.Step.CHEST_SHEET:
			_track_chest()
	_last_position = position
	_last_yaw = yaw
	_last_cooldowns = cooldowns


## Habilidade usada = a recarga saiu de zero.
func _fired(before: int, now: int) -> bool:
	return before == 0 and now > 0


func _track_chest() -> void:
	var chest := _focus as Chest
	if chest != null and chest.opened and chest.opener == _hero.peer_id:
		progress.chest_opened = true
		# Item levado = o menu de escolha esvaziou (bau de cura nao tem menu).
		progress.item_taken = chest.choices.is_empty()
	if _bestiary.visible and _bestiary.is_hero_tab():
		progress.sheet_opened = progress.chest_opened


func _advance_while_complete() -> void:
	while TutorialRules.is_complete(step, progress):
		step = TutorialRules.next(step)
		_enter(step)


func _enter(new_step: TutorialRules.Step) -> void:
	_focus = null
	_refresh_left = 0.0
	print("[tutorial] passo %s" % TutorialRules.Step.keys()[new_step])
	_overlay.show_step(new_step)
	match new_step:
		TutorialRules.Step.MONSTER_XP:
			_level_at_entry = XpTable.level_for_xp(_hero.xp_curve, _hero.xp)
			_points_at_entry = _ranks_total()
			_top_up_xp()
		TutorialRules.Step.PHASE2:
			_clock.jump_to_phase1_end(NetworkTime.tick)
	_pick_focus()
	step_changed.emit(new_step)


## Servidor: completa o XP do heroi ate faltar 1 para o nivel seguinte; o abate fecha o nivel.
func _top_up_xp() -> void:
	var extra := TutorialRules.xp_top_up(_hero.xp_curve, _hero.xp)
	if extra <= 0:
		return
	var effect := HitEffect.new()
	effect.xp = extra
	var source := HitLedger.source_key(XP_SOURCE_ID, HitLedger.Slot.REWARD)
	_hero.receive_hit(NetworkTime.tick + 1, source, effect)


func _ranks_total() -> int:
	return _hero.ranks.x + _hero.ranks.y + _hero.ranks.z


# --- alvo e marcador -------------------------------------------------------------------------


func _update_marker(delta: float) -> void:
	_refresh_left -= delta
	if not _focus_valid() or _refresh_left <= 0.0:
		_pick_focus()
	_marker.visible = _focus != null
	if _focus != null:
		var bob := sin(Time.get_ticks_msec() * 0.001 * MARKER_BOB_SPEED) * MARKER_BOB
		_marker.global_position = _focus.global_position + Vector3.UP * (MARKER_HEIGHT + bob)


func _focus_valid() -> bool:
	if _focus == null or not is_instance_valid(_focus):
		return false
	var monster := _focus as Monster
	if monster != null:
		return monster.is_alive()
	var chest := _focus as Chest
	return chest == null or not chest.opened or step != TutorialRules.Step.CHEST_SHEET


func _pick_focus() -> void:
	_refresh_left = REFRESH_SECONDS
	match step:
		TutorialRules.Step.TARGET_ATTACK, TutorialRules.Step.SKILLS, TutorialRules.Step.MONSTER_XP:
			_focus = _nearest_monster()
		TutorialRules.Step.CHEST_SHEET:
			# O bau aberto continua marcado ate o jogador levar o item.
			if not (_focus is Chest and (_focus as Chest).opened):
				_focus = _nearest_chest()
		_:
			_focus = null


## Monstro vivo, que nao e o boss, no lado do heroi ou no neutro: o mais perto dele.
func _nearest_monster() -> Monster:
	var best: Monster = null
	var best_distance := INF
	for node: Node in _spawns.get_children():
		var monster := node as Monster
		if monster == null or monster.name == SpawnDirector.BOSS_NAME or not monster.is_alive():
			continue
		if not _is_reachable_side(monster.home_team):
			continue
		var distance := _hero.global_position.distance_to(monster.global_position)
		if distance < best_distance:
			best = monster
			best_distance = distance
	return best


## Bau fechado, com menu de itens, no lado do heroi ou no neutro: o mais perto dele. Sem nenhum com
## itens, o mais perto de qualquer tipo.
func _nearest_chest() -> Chest:
	var best: Chest = null
	var best_distance := INF
	var any: Chest = null
	var any_distance := INF
	for node: Node in get_tree().get_nodes_in_group(Chest.GROUP):
		var chest := node as Chest
		if chest.opened or not _is_reachable_side(chest.home_team):
			continue
		var distance := _hero.global_position.distance_to(chest.global_position)
		if distance < any_distance:
			any = chest
			any_distance = distance
		var has_menu := chest.drops != PackedInt32Array([ChestRules.HEAL])
		if has_menu and distance < best_distance:
			best = chest
			best_distance = distance
	return best if best != null else any


func _is_reachable_side(home_team: int) -> bool:
	return home_team == _hero.team or home_team == GateRules.TEAM_NEUTRAL


func _make_marker() -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.0
	mesh.bottom_radius = MARKER_RADIUS
	mesh.height = MARKER_SIZE
	var material := StandardMaterial3D.new()
	material.albedo_color = MARKER_COLOR
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.no_depth_test = true
	mesh.material = material
	var marker := MeshInstance3D.new()
	marker.name = "TutorialMarker"
	marker.mesh = mesh
	marker.rotation_degrees.x = 180.0  # ponta para baixo, no alvo
	marker.top_level = true
	marker.visible = false
	return marker


# --- sinais ----------------------------------------------------------------------------------


func _on_hero_struck(_target: Combatant, _slot: HitLedger.Slot, _tick: int) -> void:
	if step == TutorialRules.Step.TARGET_ATTACK:
		progress.struck = true


func _on_camera_distance_changed(_distance: float) -> void:
	if step == TutorialRules.Step.MOVE_CAMERA:
		progress.zoomed = true


func _on_spawns_monster_killed(peer: int, _tick: int) -> void:
	if step == TutorialRules.Step.MONSTER_XP and peer == _hero.peer_id:
		progress.monster_killed = true


func _on_match_phase_changed(_from: int, to: int, _tick: int) -> void:
	_show_overlay(to as MatchState.State)
	if to == MatchState.State.PHASE2 and _bot != null:
		_bot.paused = false  # o bot so entra em acao na fase 2 (passo 6)


## A instrucao aparece do inicio da fase 1 ate o fim da partida; na cinematica e na selecao nao.
func _show_overlay(state: MatchState.State) -> void:
	_overlay.visible = state >= MatchState.State.PHASE1 and state != MatchState.State.ENDED
