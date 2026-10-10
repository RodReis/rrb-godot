extends GutTest
## Integracao headless: arena + SpawnDirector + ArenaNav + bot (time B) + heroi parado (time A).
## O bot so recebe think(tick); os monstros e o heroi rodam o proprio tick. Base primeiro
## (PI 2026-10-09): limpa a propria metade, base B + 2 campos laterais (535 XP -> nivel 4,
## GDB §5.2, F36), e passa a saquear.

const ARENA: String = "res://scenes/arena/ilha_arcana.tscn"
const KNIGHT: String = "res://scenes/heroes/knight.tscn"
const DT: float = 1.0 / 30.0
## Teto de ticks para limpar a base (~3 min de jogo).
const MAX_TICKS: int = 5400
const MAP_FRAMES: int = 30
## XP do ultimo abate entra pelo ledger no tick seguinte.
const SETTLE_TICKS: int = 5

var _arena: Node3D
var _director: SpawnDirector
var _nav: ArenaNav
var _bot: Hero
var _player: Hero
var _tick: int = 0


func before_each() -> void:
	_arena = (load(ARENA) as PackedScene).instantiate() as Node3D
	add_child_autofree(_arena)
	_director = SpawnDirector.new()
	_director.loot_seed = 37
	add_child_autofree(_director)
	_nav = ArenaNav.new()
	add_child_autofree(_nav)
	_nav.bake(_arena, GateRules.gate_layer(GateRules.TEAM_A))
	_player = _spawn(1, GateRules.TEAM_A, false)
	_bot = _spawn(2, GateRules.TEAM_B, true)
	await _await_path(_bot.global_position, Vector3.ZERO)


## O mapa de navegacao fica pronto depois de algumas iteracoes assincronas.
func _await_path(from: Vector3, to: Vector3) -> void:
	var map := _bot.get_world_3d().navigation_map
	for i: int in MAP_FRAMES:
		await wait_physics_frames(1)
		if NavigationServer3D.map_get_iteration_id(map) == 0:
			continue
		var path := NavigationServer3D.map_get_path(map, from, to, true)
		if not path.is_empty() and path[path.size() - 1].distance_to(to) < 1.0:
			return


func _spawn(id: int, team: int, bot: bool) -> Hero:
	var hero := (load(KNIGHT) as PackedScene).instantiate() as Hero
	hero.name = str(id)
	hero.team = team
	hero.is_bot = bot
	hero.collision_mask = GateRules.hero_mask(team)
	if bot:
		hero.get_node("Input").set_script(BotInput)
	for node: Node in get_tree().get_nodes_in_group(SpawnMarker.GROUP):
		var marker := node as SpawnMarker
		if marker.kind == SpawnMarker.Kind.HERO and marker.team == team:
			hero.transform = marker.global_transform
	add_child_autofree(hero)
	return hero


func _brain() -> BotInput:
	return _bot.input as BotInput


func _base_monsters_alive() -> int:
	var alive := 0
	for node: Node in get_tree().get_nodes_in_group(Monster.GROUP):
		var monster := node as Monster
		if monster.home_team == GateRules.TEAM_B and monster.is_alive():
			alive += 1
	return alive


func _step() -> void:
	_tick += 1
	_brain().think(_tick)
	for node: Node in get_tree().get_nodes_in_group(Monster.GROUP):
		(node as Monster)._on_network_tick(DT, _tick)
	_bot._rollback_tick(DT, _tick, true)


func test_input_do_bot_e_do_servidor() -> void:
	assert_true(_bot.input is BotInput)
	assert_eq(_bot.input.get_multiplayer_authority(), 1)
	assert_eq(_player.input.get_multiplayer_authority(), 1)


func test_navmesh_tem_caminho_da_base_ao_centro() -> void:
	var map := _bot.get_world_3d().navigation_map
	var path := NavigationServer3D.map_get_path(map, _bot.global_position, Vector3.ZERO, true)
	assert_gt(path.size(), 1)
	assert_lt(path[path.size() - 1].length(), 1.0)


func test_jogador_atras_do_portao_inimigo_nao_faz_o_bot_empurrar_o_portao() -> void:
	# Jogador no patio da base A, bot do lado de fora do portao A: o navmesh do bot tem o
	# portao A como parede, entao ele para no ponto alcancavel em vez de andar reto.
	var gate_a: Gate = null
	for node: Node in get_tree().get_nodes_in_group(Gate.GROUP):
		if (node as Gate).team == GateRules.TEAM_A:
			gate_a = node as Gate
	var inward := (_home_a() - gate_a.global_position).normalized()
	_player.global_position = gate_a.global_position + inward * 3.0
	_bot.global_position = gate_a.global_position - inward * 1.5
	_bot.level = 5
	_bot.xp = 740
	_brain().think(1)
	assert_eq(_brain().state, BotRules.State.FIGHT)
	assert_true(_bot.input.movement.is_zero_approx())


func _home_a() -> Vector3:
	for node: Node in get_tree().get_nodes_in_group(SpawnMarker.GROUP):
		var marker := node as SpawnMarker
		if marker.kind == SpawnMarker.Kind.HERO and marker.team == GateRules.TEAM_A:
			return marker.global_position
	return Vector3.ZERO


## F36: o T1 da base renasce a ~5 u da fonte (aggro 6 u). Recuando ate ela, o bot revida o
## monstro colado nele em vez de apanhar parado ate morrer (rodada offline de 5:00).
func test_recuando_revida_o_monstro_no_alcance() -> void:
	var monster: Monster = null
	for node: Node in get_tree().get_nodes_in_group(Monster.GROUP):
		if (node as Monster).home_team == GateRules.TEAM_B:
			monster = node as Monster
	_bot.global_position = monster.global_position + Vector3(1.0, 0.0, 0.0)
	_bot.hp = roundi(_bot.attributes.max_hp * 0.2)
	_brain().state = BotRules.State.RETREAT
	_brain().think(1)
	assert_eq(_brain().state, BotRules.State.RETREAT)
	assert_true(_bot.input.attack)
	var to := monster.global_position - _bot.global_position
	assert_almost_eq(_bot.input.aim, to.normalized(), Vector3.ONE * 0.01)


## F36: monstro parado (sem aggro) a ate 8 u da fonte nao e perigo; contava como perigo e o
## bot ficava em RETREAT ate 5:00 com HP 92 % (rodada offline).
func test_monstro_parado_perto_nao_prende_o_recuo() -> void:
	var monster: Monster = null
	for node: Node in get_tree().get_nodes_in_group(Monster.GROUP):
		if (node as Monster).home_team == GateRules.TEAM_B:
			monster = node as Monster
	_bot.global_position = monster.global_position + Vector3(7.0, 0.0, 0.0)
	_bot.hp = roundi(_bot.attributes.max_hp * 0.5)
	_brain().state = BotRules.State.RETREAT
	_brain().think(1)
	var safe := SkillRules.seconds_to_ticks(BotInput.PROFILE.safe_seconds, NetworkTime.tickrate)
	_brain().think(2 + safe)
	assert_ne(_brain().state, BotRules.State.RETREAT)


func test_recuando_sem_monstro_perto_nao_ataca() -> void:
	_bot.hp = roundi(_bot.attributes.max_hp * 0.2)
	_brain().state = BotRules.State.RETREAT
	_brain().think(1)
	assert_false(_bot.input.attack)


func test_comeca_farmando_e_anda_ate_o_monstro_da_base() -> void:
	var start := _bot.global_position
	for i: int in 30:
		_step()
	assert_eq(_brain().state, BotRules.State.FARM)
	assert_gt(_bot.global_position.distance_to(start), 1.0)


## Propria metade = base + 2 campos laterais (F36): 535 XP -> nivel 4 (GDB §5.2), 10 baus.
func test_limpa_a_propria_metade_chega_ao_nivel_4_e_saqueia() -> void:
	while _tick < MAX_TICKS and _base_monsters_alive() > 0:
		_step()
	for i: int in SETTLE_TICKS:
		_step()
	gut.p(
		"metade limpa no tick %d (%.0f s): Nv %d, %d XP" % [_tick, _tick * DT, _bot.level, _bot.xp]
	)
	assert_eq(_base_monsters_alive(), 0)
	assert_gte(_bot.xp, 535)
	assert_gte(_bot.level, 4)
	assert_eq(_brain().state, BotRules.State.LOOT)
	var limit := _tick + MAX_TICKS
	while _tick < limit and _opened_base_chests() < 10:
		_step()
	gut.p("baus da metade abertos no tick %d" % _tick)
	assert_eq(_opened_base_chests(), 10)
	_step()
	assert_ne(_brain().state, BotRules.State.LOOT)


## Campos laterais das duas metades alcancaveis pelo navmesh do bot (portao A como parede).
func test_navmesh_alcanca_os_campos_laterais() -> void:
	var map := _bot.get_world_3d().navigation_map
	var checked := 0
	for node: Node in get_tree().get_nodes_in_group(SpawnMarker.GROUP):
		var marker := node as SpawnMarker
		var spawn := (
			Vector3(-24, 0, -24) if marker.team == GateRules.TEAM_A else Vector3(24, 0, -24)
		)
		var content := marker.kind != SpawnMarker.Kind.HERO and marker.kind != SpawnMarker.Kind.BOSS
		if marker.team == GateRules.TEAM_NEUTRAL or not content:
			continue
		if marker.global_position.distance_to(spawn) <= 12.7:
			continue
		var path := NavigationServer3D.map_get_path(
			map, _bot.global_position, marker.global_position, true
		)
		assert_false(path.is_empty(), marker.name)
		if not path.is_empty():
			var gap := path[path.size() - 1].distance_to(marker.global_position)
			assert_lt(gap, 1.0, "%s fora do navmesh (%.1f u)" % [marker.name, gap])
		checked += 1
	assert_eq(checked, 20)


func _opened_base_chests() -> int:
	var opened := 0
	for node: Node in get_tree().get_nodes_in_group(Chest.GROUP):
		var chest := node as Chest
		if chest.home_team == GateRules.TEAM_B and chest.opened:
			opened += 1
	return opened


## Mata os monstros (menos os da base [param keep]) e abre todos os baus.
func _clear(keep: int = -1) -> void:
	for node: Node in get_tree().get_nodes_in_group(Monster.GROUP):
		var monster := node as Monster
		if monster.home_team != keep:
			monster.hp = 0
	for node: Node in get_tree().get_nodes_in_group(Chest.GROUP):
		(node as Chest).opened = true


## 5:00 no servidor (main.gd): portoes caem e o navmesh do bot e refeito sem eles.
func _fall_gates() -> void:
	for node: Node in get_tree().get_nodes_in_group(Gate.GROUP):
		(node as Gate).fall()
	_nav.bake(_arena)
	await _await_path(_center(), _home_a())


func _center() -> Vector3:
	for node: Node in get_tree().get_nodes_in_group(SpawnMarker.GROUP):
		var marker := node as SpawnMarker
		if marker.kind == SpawnMarker.Kind.BOSS:
			return marker.global_position
	return Vector3.ZERO


func _nearest_alive_distance(team: int) -> float:
	var best := INF
	for node: Node in get_tree().get_nodes_in_group(Monster.GROUP):
		var monster := node as Monster
		if monster.home_team == team and monster.is_alive():
			best = minf(best, _bot.global_position.distance_to(monster.global_position))
	return best


func test_sem_alvo_no_centro_o_bot_para_e_nao_gira() -> void:
	# #52: boss morto, sem monstro nem bau do lado do bot; ja no ponto de espera ele para.
	_clear()
	_bot.global_position = _center() + Vector3(0.2, 0.0, 0.1)
	for i: int in 10:
		_step()
		assert_true(_bot.input.movement.is_zero_approx(), "tick %d: %s" % [i, _bot.input.movement])


func test_portoes_caidos_sem_alvo_proprio_farma_a_base_do_jogador() -> void:
	# PI 2026-10-09 (#52): depois dos 5:00 o bot vem farmar o que sobrou na base do jogador.
	_clear(GateRules.TEAM_A)
	await _fall_gates()
	_bot.global_position = _center()
	var start := _nearest_alive_distance(GateRules.TEAM_A)
	for i: int in 150:
		_step()
	assert_eq(_brain().state, BotRules.State.FARM)
	assert_lt(_nearest_alive_distance(GateRules.TEAM_A), start - 5.0)


func test_portoes_caidos_sem_monstro_vai_ate_o_jogador() -> void:
	_clear()
	await _fall_gates()
	_bot.global_position = _center()
	var start := _bot.global_position.distance_to(_player.global_position)
	for i: int in 150:
		_step()
	assert_lt(_bot.global_position.distance_to(_player.global_position), start - 5.0)


## Neblina (F37): o bot so enxerga o que o filtro entregaria ao peer dele (raio de 12 u).
func test_nao_enxerga_o_jogador_fora_da_visao() -> void:
	_brain()._hero = _bot
	_bot.global_position = _center()
	var away := _open_direction()
	_player.global_position = _center() + away * 12.5
	assert_null(_brain()._enemy_hero())
	_player.global_position = _center() + away * 11.5
	assert_eq(_brain()._enemy_hero(), _player)


func test_nao_persegue_o_jogador_que_saiu_da_visao() -> void:
	_bot.global_position = _center()
	_bot.level = 6
	_bot.xp = 1200
	_player.global_position = _center() + _open_direction() * 6.0
	_brain().think(1)
	assert_eq(_brain().state, BotRules.State.FIGHT)
	_player.global_position = _center() + _open_direction() * 20.0
	_brain().think(2)
	assert_ne(_brain().state, BotRules.State.FIGHT, "sem ver, nao luta")


func test_monstro_morto_fora_da_visao_segue_vivo_ate_o_bot_ver() -> void:
	var monster := _far_base_monster()
	_brain().think(1)
	monster.hp = 0  # o jogador matou longe do bot
	_brain().think(2)
	assert_true(_brain()._alive_monsters(GateRules.TEAM_B).has(monster), "o bot nao sabe")
	_bot.global_position = monster.global_position + Vector3(3.0, 0.0, 0.0)
	_brain().think(3)
	assert_false(_brain()._alive_monsters(GateRules.TEAM_B).has(monster), "viu: morto")


func test_bau_aberto_fora_da_visao_segue_fechado_ate_o_bot_ver() -> void:
	var chest := _far_base_chest()
	_brain().think(1)
	chest.opened = true
	_brain().think(2)
	assert_false(_brain()._known_opened(chest), "o bot ainda conta com ele")
	_bot.global_position = chest.global_position + Vector3(2.0, 0.0, 0.0)
	_brain().think(3)
	assert_true(_brain()._known_opened(chest), "viu: aberto")


## Direcao a partir do centro sem moita entre 5 e 21 u (o mato decide sozinho no F32).
func _open_direction() -> Vector3:
	for i: int in 16:
		var dir := Vector3.FORWARD.rotated(Vector3.UP, TAU * i / 16.0)
		var clear := true
		for d: float in [6.0, 11.5, 12.5, 20.0]:
			_player.global_position = _center() + dir * d
			clear = clear and not _player.hidden_from(_bot)
		if clear:
			return dir
	return Vector3.FORWARD


## Monstro da base B a mais de 12 u do bot (no spawn).
func _far_base_monster() -> Monster:
	for node: Node in get_tree().get_nodes_in_group(Monster.GROUP):
		var monster := node as Monster
		var far := monster.global_position.distance_to(_bot.global_position) > 14.0
		if monster.home_team == GateRules.TEAM_B and far:
			return monster
	return null


func _far_base_chest() -> Chest:
	for node: Node in get_tree().get_nodes_in_group(Chest.GROUP):
		var chest := node as Chest
		var far := chest.global_position.distance_to(_bot.global_position) > 14.0
		if chest.home_team == GateRules.TEAM_B and far:
			return chest
	return null


func test_portoes_caidos_com_o_jogador_morto_nao_vai_ate_ele() -> void:
	_clear()
	await _fall_gates()
	_bot.global_position = _center()
	_player.hp = 0
	var start := _bot.global_position.distance_to(_player.global_position)
	for i: int in 150:
		_step()
	assert_gt(_bot.global_position.distance_to(_player.global_position), start - 1.0)
