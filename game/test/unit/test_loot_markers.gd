extends GutTest
## Baus e monstros no minimapa (F57, decisao do PI 2026-10-12): bau fechado sempre (posicao fixa
## do mapa), monstro vivo so quando o jogador o ve (neblina, F37).

const ARENA: PackedScene = preload("res://scenes/arena/ilha_arcana.tscn")
const SEEN: int = 3

var _chests: Array[Chest] = []
var _monsters: Array[Monster] = []
var _positions: PackedVector3Array = PackedVector3Array()
var _colors: PackedColorArray = PackedColorArray()
var _radii: PackedFloat32Array = PackedFloat32Array()


func before_each() -> void:
	add_child_autofree(ARENA.instantiate())
	var spawns := add_child_autofree(SpawnDirector.new()) as SpawnDirector
	await wait_process_frames(1)
	_chests.clear()
	_monsters.clear()
	for node: Node in spawns.get_children():
		if node is Chest:
			_chests.append(node as Chest)
		elif node is Monster:
			_monsters.append(node as Monster)


func _count(color: Color) -> int:
	_positions.clear()
	_colors.clear()
	_radii.clear()
	LootMarkers.append(_chests, _monsters, _positions, _colors, _radii)
	assert_eq(_positions.size(), _colors.size())
	assert_eq(_positions.size(), _radii.size())
	var total := 0
	for c: Color in _colors:
		if c == color:
			total += 1
	return total


func test_closed_chests_always_on_the_map() -> void:
	assert_eq(_count(LootMarkers.CHEST_COLOR), _chests.size())
	_chests[0].shown_opened = true
	assert_eq(_count(LootMarkers.CHEST_COLOR), _chests.size() - 1)


## Monstro sem dono nasce escondido do jogador (Concealment): 3 passam a ser vistos como se o
## servidor decidisse (o teste roda como host, peer offline).
func test_only_living_monsters_the_player_sees() -> void:
	assert_eq(_count(LootMarkers.MONSTER_COLOR), 0, "neblina esconde todos")
	for i: int in SEEN:
		_monsters[i]._concealment._shown[multiplayer.get_unique_id()] = true
	assert_eq(_count(LootMarkers.MONSTER_COLOR), SEEN)
	_monsters[0].hp = 0
	assert_eq(_count(LootMarkers.MONSTER_COLOR), SEEN - 1)


func test_loot_is_smaller_than_heroes() -> void:
	_count(LootMarkers.CHEST_COLOR)
	for radius: float in _radii:
		assert_lt(radius, LootMarkers.HERO_RADIUS)
