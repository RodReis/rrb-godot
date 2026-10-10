class_name SpawnDirector
extends Node3D
## Um monstro por marcador MONSTER e um bau por marcador CHEST da arena (SPEC-007 §4), no
## servidor e nos clientes, na mesma ordem: nome e uid batem dos dois lados sem
## MultiplayerSpawner. Quantidades de GDB §5.1 e §6.2 vem dos marcadores. Monstro nao-boss morto
## na fase 1 renasce no mesmo node apos MatchRules.monster_respawn_phase1 (GDB §5, F36); na
## transicao (5:00) os pendentes sao cancelados. Bau e boss nao voltam (GDB §6.2, §7.1).
## Drops dos baus sorteados na criacao com a seed da partida (ARCHITECTURE-GAME §3.3);
## so os do servidor valem. Cena do monstro por id em SCENE_PATH. O Rei Esqueleto existe desde o
## inicio no marcador BOSS, fora do mapa (Monster.present), e o servidor o traz quando o MatchClock
## da boss_spawned (3:30); vivo aos 5:00, sai sem drop (R-PEND-06). Assim nenhum monstro nasce
## no meio da partida e o estado dele nunca chega antes do node (F20). Ao morrer vira um bau
## epico no lugar (PI 2026-10-09), avisado aos clientes por RPC confiavel.

## Para a HUD (F13). [param peer] = quem deu o golpe final.
signal boss_killed(peer: int)
## Servidor apenas: bau (inclusive o do boss) aberto pela primeira vez por [param peer].
signal chest_opened(peer: int, chest_uid: int, tick: int)
## Servidor apenas: monstro nao-boss abatido por [param peer] (estatisticas, F18).
signal monster_killed(peer: int, tick: int)

const SCENE_PATH: String = "res://scenes/monsters/%s.tscn"
const CHEST_SCENE: String = "res://scenes/world/chest.tscn"
const BOSS_NAME: String = "Boss"
const BOSS_CHEST_NAME: String = "BossChest"
const BOSS_PORTAL_NAME: String = "BossPortal"
const NO_RESPAWN: int = 9223372036854775807

@export var rules: MatchRules = preload("res://shared/data/rules/match_pacing.tres")

## Seed dos drops; NO_SEED = --seed da linha de comando ou sorteada. Definida antes de entrar
## na arvore; depois guarda a usada (log do servidor, auditoria).
var loot_seed: int = LaunchArgs.NO_SEED

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _chest_scene: PackedScene = preload(CHEST_SCENE)
## Ultimo numero usado em nome/uid; o boss e o bau dele continuam a contagem.
var _last_number: int = 0
## Servidor: monstro morto -> tick em que renasce. Fechado (e vazio) a partir da transicao.
var _respawn_at: Dictionary[Monster, int] = {}
var _respawn_open: bool = true
## Menor tick pendente: update() so percorre o dicionario quando ele chega.
var _next_respawn: int = NO_RESPAWN
## O MatchClock ja deu boss_spawned (3:30).
var _boss_spawned: bool = false


func _ready() -> void:
	if loot_seed == LaunchArgs.NO_SEED:
		loot_seed = LaunchArgs.parse(OS.get_cmdline_user_args())["seed"]
	if loot_seed == LaunchArgs.NO_SEED:
		loot_seed = randi()
	_rng.seed = loot_seed
	print("[spawn] seed dos baus %d" % loot_seed)
	for node: Node in get_tree().get_nodes_in_group(SpawnMarker.GROUP):
		var marker := node as SpawnMarker
		var spawned: Node3D
		match marker.kind:
			SpawnMarker.Kind.MONSTER:
				var monster := _monster(marker, _last_number + 1)
				if monster != null:
					monster.died.connect(_on_monster_died.bind(monster, marker.name))
				spawned = monster
			SpawnMarker.Kind.CHEST:
				spawned = _chest(marker, _last_number + 1)
		if spawned == null:
			continue
		_last_number += 1
		spawned.transform = global_transform.affine_inverse() * marker.global_transform
		add_child(spawned)
	_add_boss()
	NetworkTime.on_tick.connect(_on_network_tick)


## Servidor (a cada tick; o teste chama direto com o proprio relogio): renasce quem ja cumpriu
## o tempo de respawn.
func update(tick: int) -> void:
	if tick < _next_respawn:
		return
	_next_respawn = NO_RESPAWN
	for monster: Monster in _respawn_at.keys():
		var due: int = _respawn_at[monster]
		if tick >= due:
			_respawn_at.erase(monster)
			monster.revive()
		else:
			_next_respawn = mini(_next_respawn, due)


## Servidor e clientes (MatchClock.phase1_ended: 5:00, entrada na TRANSITION): cancela os
## respawns pendentes e ninguem mais renasce; os vivos ficam (GDB §5, §7.1).
func stop_respawns(_tick: int = 0) -> void:
	_respawn_open = false
	_respawn_at.clear()
	_next_respawn = NO_RESPAWN


## Servidor e clientes (boss_warning do MatchClock, 3:00): pista visual no marcador BOSS ate o
## boss surgir. Repetir, ou boss ja surgido, e ignorado.
func warn_boss(_tick: int = 0) -> void:
	if has_node(BOSS_PORTAL_NAME) or _boss_spawned:
		return
	var marker := _boss_marker()
	if marker == null:
		return
	var portal := BossPortal.new()
	portal.name = BOSS_PORTAL_NAME
	portal.transform = global_transform.affine_inverse() * marker.global_transform
	add_child(portal)


## Servidor e clientes (boss_spawned do MatchClock): tira o portal; o servidor traz o boss, que
## chega aos clientes pelo estado replicado. Repetir, ou boss ja morto, e ignorado.
func spawn_boss(_tick: int = 0) -> void:
	var portal := get_node_or_null(BOSS_PORTAL_NAME)
	if portal != null:
		portal.free()
	if _boss_spawned or has_node(BOSS_CHEST_NAME):
		return
	_boss_spawned = true
	var boss := get_node_or_null(BOSS_NAME) as Monster
	if boss != null and multiplayer.is_server():
		boss.revive()


## Servidor e clientes (MatchClock.phase1_ended, 5:00): o boss vivo sai do mapa sem drop nem XP
## (R-PEND-06, PI 2026-10-10); morto, o bau dele fica.
func dismiss_boss(tick: int = 0) -> void:
	var boss := get_node_or_null(BOSS_NAME) as Monster
	if boss == null or not boss.is_alive() or not multiplayer.is_server():
		return
	boss.leave()
	print("[spawn] Rei Esqueleto vivo aos 5:00 sai do mapa sem drop, tick %d" % tick)


## Servidor e clientes, no _ready: o boss fora do mapa, na mesma ordem de nome e uid dos dois lados.
func _add_boss() -> void:
	var marker := _boss_marker()
	if marker == null:
		return
	var boss := _monster(marker, _last_number + 1)
	if boss == null:
		return
	_last_number += 1
	boss.name = BOSS_NAME
	boss.present = false
	boss.transform = global_transform.affine_inverse() * marker.global_transform
	boss.died.connect(_on_boss_died)
	add_child(boss)


func _boss_marker() -> SpawnMarker:
	for node: Node in get_tree().get_nodes_in_group(SpawnMarker.GROUP):
		var marker := node as SpawnMarker
		if marker.kind == SpawnMarker.Kind.BOSS:
			return marker
	return null  # arena de teste sem centro


func _monster(marker: SpawnMarker, number: int) -> Monster:
	var path := SCENE_PATH % marker.monster_id
	if not ResourceLoader.exists(path):
		push_error("[spawn] sem cena para o monstro %s" % marker.monster_id)
		return null
	var monster := (load(path) as PackedScene).instantiate() as Monster
	monster.name = "Monster%d" % number
	monster.uid = -number
	monster.home_team = marker.team
	return monster


func _chest(marker: SpawnMarker, number: int) -> Chest:
	var chest := _chest_scene.instantiate() as Chest
	chest.name = "Chest%d" % number
	chest.uid = -number
	chest.rare = marker.chest_kind == SpawnMarker.ChestKind.RARE
	chest.home_team = marker.team
	chest.drop = ChestRules.roll(chest.rare, chest.rules, chest.catalog.items, _rng)
	chest.first_opened.connect(chest_opened.emit)
	return chest


## Nos dois lados; o uid vem do servidor. O drop so vale no servidor.
@rpc("authority", "call_local", "reliable")
func _boss_defeated(_tick: int, killer_id: int, chest_uid: int, where: Vector3) -> void:
	if has_node(BOSS_CHEST_NAME):
		return
	var chest := _chest_scene.instantiate() as Chest
	chest.name = BOSS_CHEST_NAME
	chest.uid = chest_uid
	chest.epic = true
	if multiplayer.is_server():
		chest.drop = ChestRules.boss_drop(chest.catalog.items, _rng)
	chest.position = where
	chest.first_opened.connect(chest_opened.emit)
	add_child(chest)
	boss_killed.emit(killer_id)


## Servidor apenas (Monster.died), monstros nao-boss. [param marker] so para o log (ordem de
## limpeza dos campos, F36).
func _on_monster_died(killer_id: int, tick: int, monster: Monster, marker: StringName) -> void:
	monster_killed.emit(killer_id, tick)
	if not _respawn_open:
		print("[spawn] %s morto por %d no tick %d, sem respawn" % [marker, killer_id, tick])
		return
	var due := (
		tick + SkillRules.seconds_to_ticks(rules.monster_respawn_phase1, NetworkTime.tickrate)
	)
	_respawn_at[monster] = due
	_next_respawn = mini(_next_respawn, due)
	print("[spawn] %s morto por %d no tick %d, renasce no %d" % [marker, killer_id, tick, due])


func _on_network_tick(_delta: float, tick: int) -> void:
	update(tick)


## Servidor apenas (Monster.died).
func _on_boss_died(killer_id: int, _tick: int) -> void:
	_last_number += 1
	var where := (get_node(BOSS_NAME) as Node3D).position
	_boss_defeated.rpc(NetworkTime.tick, killer_id, -_last_number, where)
