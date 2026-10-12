class_name ItemVisuals
extends Resource
## Visual dos itens para um heroi (SPEC-048): peca 3D e icone por id de item. A arma muda por
## heroi; a armadura e a mesma peca em todos (o rig e o mesmo). So cliente: o servidor headless
## nunca chama for_hero(), entao nao carrega peca nem icone.
## Item sem peca (elmo do Barbaro, ADR-0011 item 3): o slot nao mostra nada e a peca do pack fica;
## o atributo do item vale do mesmo jeito.
## Peca: cena cujos filhos se chamam "<peca>__<osso>" (osso com "_" no lugar de "."), modelados no
## espaco do modelo do heroi em pose de repouso (art/heroes/equipment/build_equipment.py).

const PATH: String = "res://shared/data/items/visuals/%s_items.tres"
## Separa a peca do osso no nome do no da peca.
const BONE_SEPARATOR: String = "__"

## Peca do pack escondida enquanto o slot tem peca (indice = ItemData.Slot; vazio = nenhuma).
@export var pack_parts: Array[StringName] = [&"", &"", &"", &""]
@export var pieces: Dictionary[StringName, PackedScene] = {}
@export var icons: Dictionary[StringName, Texture2D] = {}


## Nulo se o heroi nao tem visual de itens.
static func for_hero(hero_id: StringName) -> ItemVisuals:
	var path := PATH % hero_id
	if not ResourceLoader.exists(path):
		return null
	return load(path) as ItemVisuals


## Osso do rig a que o no [param piece_node] da peca se prende ("x__foot_l" -> "foot.l").
static func bone_of(piece_node: StringName) -> String:
	return String(piece_node).get_slice(BONE_SEPARATOR, 1).replace("_", ".")


## Nulo se o item nao tem icone.
func icon(item: ItemData) -> Texture2D:
	return icons.get(item.id) as Texture2D
