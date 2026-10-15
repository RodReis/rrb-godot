class_name CompendiumArt
extends RefCounted
## Imagens do Compendio (FRONTEND-LAUNCHER §8.3 regra 3: renders dos assets reais no lugar das
## imagens geradas do prototipo). Carrega pelo id do dado; null se o arquivo nao existe.

const MONSTERS_DIR: String = "res://shared/assets/ui/monsters/"
const ITEMS_DIR: String = "res://shared/ui/icons/items/"


## Render do monstro (tools/ui/render_monster_cards.gd).
static func monster(monster_id: StringName) -> Texture2D:
	return _load("%s%s.png" % [MONSTERS_DIR, monster_id])


## Icone do item. Arma muda com o heroi (espada, arco, machado: <heroi>_<item>.png); armadura e a
## mesma para todos (<item>.png).
static func item(data: ItemData, hero_id: StringName = &"") -> Texture2D:
	if data.slot == ItemData.Slot.WEAPON and not hero_id.is_empty():
		return _load("%s%s_%s.png" % [ITEMS_DIR, hero_id, data.id])
	return _load("%s%s.png" % [ITEMS_DIR, data.id])


static func _load(path: String) -> Texture2D:
	return load(path) as Texture2D if ResourceLoader.exists(path) else null
