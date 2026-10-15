class_name MonsterSpecies
extends RefCounted
## Um card do Bestiario: a especie e as variantes dela (MonsterData.species). O lider e o
## membro cujo id e o da especie; os numeros do card saem dele, a contagem soma todos.

var id: StringName
var members: Array[MonsterData] = []


func _init(species_id: StringName) -> void:
	id = species_id


func add(monster: MonsterData) -> void:
	members.append(monster)


## Membro de id igual ao da especie (o primeiro, se nenhum).
func lead() -> MonsterData:
	for monster: MonsterData in members:
		if monster.id == id:
			return monster
	return members[0]


## Quantos da especie existem por partida (todas as variantes somadas).
func total_count() -> int:
	var total := 0
	for monster: MonsterData in members:
		total += monster.count
	return total
