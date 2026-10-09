class_name Ids
extends RefCounted
## IDs estaveis de herois, itens e monstros: StringName no codigo, int na rede
## (ARCHITECTURE-GAME.md §5). So acrescente no fim; reordenar quebra a compatibilidade.

## Numero de "nenhum id" (slot vazio, id inexistente).
const NONE: int = -1

const ALL: Array[StringName] = [
	&"knight",
	&"ranger",
	&"sword_t1",
	&"sword_t2",
	&"sword_t3_epic",
	&"guard_helm_t1",
	&"guard_helm_t2",
	&"guard_helm_t3",
	&"guard_chest_t1",
	&"guard_chest_t2",
	&"guard_chest_t3",
	&"guard_boots_t1",
	&"guard_boots_t2",
	&"guard_boots_t3",
	&"hunter_helm_t1",
	&"hunter_helm_t2",
	&"hunter_helm_t3",
	&"hunter_chest_t1",
	&"hunter_chest_t2",
	&"hunter_chest_t3",
	&"hunter_boots_t1",
	&"hunter_boots_t2",
	&"hunter_boots_t3",
	&"skeleton_t1",
	&"skeleton_warrior_t2",
	&"skeleton_mage_t2",
	&"golem_t3",
	&"skeleton_king_boss",
]


## NONE se o id nao existe.
static func to_int(id: StringName) -> int:
	return ALL.find(id)


## &"" se o numero nao existe.
static func to_name(number: int) -> StringName:
	if number < 0 or number >= ALL.size():
		return &""
	return ALL[number]
