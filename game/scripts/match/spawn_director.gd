class_name SpawnDirector
extends Node3D
## Um monstro por marcador MONSTER e um bau por marcador CHEST da arena (SPEC-007 §4), no
## servidor e nos clientes, na mesma ordem: nome e uid batem dos dois lados sem
## MultiplayerSpawner. Quantidades de GDB §5.1 e §6.2 vem dos marcadores. Nada respawna (GDB §5,
## §6.2). Drops dos baus sorteados na criacao com a seed da partida (ARCHITECTURE-GAME §3.3);
## so os do servidor valem. Cena do monstro por id em SCENE_PATH.

const SCENE_PATH: String = "res://scenes/monsters/%s.tscn"
const CHEST_SCENE: String = "res://scenes/world/chest.tscn"

## Seed dos drops; NO_SEED = --seed da linha de comando ou sorteada. Definida antes de entrar
## na arvore; depois guarda a usada (log do servidor, auditoria).
var loot_seed: int = LaunchArgs.NO_SEED

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _chest_scene: PackedScene = preload(CHEST_SCENE)


func _ready() -> void:
	if loot_seed == LaunchArgs.NO_SEED:
		loot_seed = LaunchArgs.parse(OS.get_cmdline_user_args())["seed"]
	if loot_seed == LaunchArgs.NO_SEED:
		loot_seed = randi()
	_rng.seed = loot_seed
	print("[spawn] seed dos baus %d" % loot_seed)
	var index := 0
	for node: Node in get_tree().get_nodes_in_group(SpawnMarker.GROUP):
		var marker := node as SpawnMarker
		var spawned: Node3D
		match marker.kind:
			SpawnMarker.Kind.MONSTER:
				spawned = _monster(marker, index + 1)
			SpawnMarker.Kind.CHEST:
				spawned = _chest(marker, index + 1)
		if spawned == null:
			continue
		index += 1
		spawned.transform = global_transform.affine_inverse() * marker.global_transform
		add_child(spawned)


func _monster(marker: SpawnMarker, number: int) -> Monster:
	var path := SCENE_PATH % marker.monster_id
	if not ResourceLoader.exists(path):
		push_error("[spawn] sem cena para o monstro %s" % marker.monster_id)
		return null
	var monster := (load(path) as PackedScene).instantiate() as Monster
	monster.name = "Monster%d" % number
	monster.uid = -number
	return monster


func _chest(marker: SpawnMarker, number: int) -> Chest:
	var chest := _chest_scene.instantiate() as Chest
	chest.name = "Chest%d" % number
	chest.uid = -number
	chest.rare = marker.chest_kind == SpawnMarker.ChestKind.RARE
	chest.drop = ChestRules.roll(chest.rare, chest.rules, chest.catalog.items, _rng)
	return chest
