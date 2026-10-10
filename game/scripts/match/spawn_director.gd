class_name SpawnDirector
extends Node3D
## Um monstro por marcador MONSTER e um bau por marcador CHEST da arena (SPEC-007 §4), no
## servidor e nos clientes, na mesma ordem: nome e uid batem dos dois lados sem
## MultiplayerSpawner. Quantidades de GDB §5.1 e §6.2 vem dos marcadores. Nada respawna (GDB §5,
## §6.2). Drops dos baus sorteados na criacao com a seed da partida (ARCHITECTURE-GAME §3.3);
## so os do servidor valem. Cena do monstro por id em SCENE_PATH. O Rei Esqueleto nasce no
## marcador BOSS quando o MatchClock da boss_spawned (3:30, nos dois lados); ao morrer vira um
## bau epico no lugar (PI 2026-10-09), avisado aos clientes por RPC confiavel.

## Para a HUD (F13). [param peer] = quem deu o golpe final.
signal boss_killed(peer: int)

const SCENE_PATH: String = "res://scenes/monsters/%s.tscn"
const CHEST_SCENE: String = "res://scenes/world/chest.tscn"
const BOSS_NAME: String = "Boss"
const BOSS_CHEST_NAME: String = "BossChest"
const BOSS_PORTAL_NAME: String = "BossPortal"

## Seed dos drops; NO_SEED = --seed da linha de comando ou sorteada. Definida antes de entrar
## na arvore; depois guarda a usada (log do servidor, auditoria).
var loot_seed: int = LaunchArgs.NO_SEED

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _chest_scene: PackedScene = preload(CHEST_SCENE)
## Ultimo numero usado em nome/uid; o boss e o bau dele continuam a contagem.
var _last_number: int = 0
var _boss_killer: int = 0


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
				spawned = _monster(marker, _last_number + 1)
			SpawnMarker.Kind.CHEST:
				spawned = _chest(marker, _last_number + 1)
		if spawned == null:
			continue
		_last_number += 1
		spawned.transform = global_transform.affine_inverse() * marker.global_transform
		add_child(spawned)


## Servidor e clientes (boss_warning do MatchClock, 3:00): pista visual no marcador BOSS ate o
## boss surgir. Repetir, ou boss ja vivo/morto, e ignorado.
func warn_boss(_tick: int = 0) -> void:
	if has_node(BOSS_PORTAL_NAME) or has_node(BOSS_NAME) or has_node(BOSS_CHEST_NAME):
		return
	var marker := _boss_marker()
	if marker == null:
		return
	var portal := BossPortal.new()
	portal.name = BOSS_PORTAL_NAME
	portal.transform = global_transform.affine_inverse() * marker.global_transform
	add_child(portal)


## Servidor e clientes (boss_spawned do MatchClock). Repetir, ou boss ja morto (cliente que
## entrou depois), e ignorado.
func spawn_boss(_tick: int = 0) -> void:
	var portal := get_node_or_null(BOSS_PORTAL_NAME)
	if portal != null:
		portal.free()
	if has_node(BOSS_NAME) or has_node(BOSS_CHEST_NAME):
		return
	var marker := _boss_marker()
	if marker == null:
		return
	var boss := _monster(marker, _last_number + 1)
	if boss == null:
		return
	_last_number += 1
	boss.name = BOSS_NAME
	boss.transform = global_transform.affine_inverse() * marker.global_transform
	boss.died.connect(_on_boss_died)
	add_child(boss)


## Servidor apenas: cria o bau do boss no peer que acabou de conectar (o estado do bau vai
## depois, com os outros baus).
func send_state(peer: int) -> void:
	var chest := get_node_or_null(BOSS_CHEST_NAME) as Chest
	if chest != null:
		_boss_defeated.rpc_id(peer, NetworkTime.tick, _boss_killer, chest.uid, chest.position)


func _boss_marker() -> SpawnMarker:
	for node: Node in get_tree().get_nodes_in_group(SpawnMarker.GROUP):
		var marker := node as SpawnMarker
		if marker.kind == SpawnMarker.Kind.BOSS:
			return marker
	push_error("[spawn] sem marcador BOSS")
	return null


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
	return chest


## Nos dois lados; o uid vem do servidor. O drop so vale no servidor.
@rpc("authority", "call_local", "reliable")
func _boss_defeated(_tick: int, killer_id: int, chest_uid: int, where: Vector3) -> void:
	if has_node(BOSS_CHEST_NAME):
		return
	_boss_killer = killer_id
	var chest := _chest_scene.instantiate() as Chest
	chest.name = BOSS_CHEST_NAME
	chest.uid = chest_uid
	chest.epic = true
	if multiplayer.is_server():
		chest.drop = ChestRules.boss_drop(chest.catalog.items, _rng)
	chest.position = where
	add_child(chest)
	boss_killed.emit(killer_id)


## Servidor apenas (Monster.died).
func _on_boss_died(killer_id: int) -> void:
	_last_number += 1
	var where := (get_node(BOSS_NAME) as Node3D).position
	_boss_defeated.rpc(NetworkTime.tick, killer_id, -_last_number, where)
