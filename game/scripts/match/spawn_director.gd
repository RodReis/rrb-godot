class_name SpawnDirector
extends Node3D
## Um monstro por marcador MONSTER da arena (SPEC-007 §4), no servidor e nos clientes, na
## mesma ordem: nome e uid batem dos dois lados sem MultiplayerSpawner. A quantidade de
## GDB §5.1 vem dos marcadores. Monstros nao respawnam (GDB §5). Cena por id em SCENE_PATH.

const SCENE_PATH: String = "res://scenes/monsters/%s.tscn"


func _ready() -> void:
	var index := 0
	for node: Node in get_tree().get_nodes_in_group(SpawnMarker.GROUP):
		var marker := node as SpawnMarker
		if marker.kind != SpawnMarker.Kind.MONSTER:
			continue
		var path := SCENE_PATH % marker.monster_id
		if not ResourceLoader.exists(path):
			push_error("[spawn] sem cena para o monstro %s" % marker.monster_id)
			continue
		index += 1
		var monster := (load(path) as PackedScene).instantiate() as Monster
		monster.name = "Monster%d" % index
		monster.uid = -index
		monster.transform = global_transform.affine_inverse() * marker.global_transform
		add_child(monster)
