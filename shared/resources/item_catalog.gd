class_name ItemCatalog
extends Resource
## Todos os itens e bonus de conjunto da partida (GDB §6.1). Item vai na rede como o numero de
## Ids; find() devolve o ItemData.

@export var items: Array[ItemData]
@export var set_bonuses: Array[SetBonusData]

var _by_number: Dictionary = {}  # Ids (int) -> ItemData, montado no primeiro find()


## Nulo se o numero nao e item do catalogo.
func find(number: int) -> ItemData:
	if _by_number.is_empty():
		for item: ItemData in items:
			_by_number[Ids.to_int(item.id)] = item
	return _by_number.get(number) as ItemData
