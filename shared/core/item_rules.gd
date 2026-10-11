class_name ItemRules
extends RefCounted
## Oferta de troca de equipamento no mesmo slot (GDB §6.2, SPEC-047): o F so aparece para item
## melhor. Nada e automatico; quem decide e o servidor, por heroi.


## O heroi pode trocar [param current] por [param incoming] segurando F? [param current] nulo =
## slot vazio. Os dois itens sao do mesmo slot. Vazio, raridade maior ou escolha lateral (mesma
## raridade, outro conjunto): sim. Menor ou identico: nao.
static func offer(current: ItemData, incoming: ItemData) -> bool:
	if is_upgrade(current, incoming):
		return true
	return incoming.rarity == current.rarity and incoming.set_id != current.set_id


## Slot vazio ou raridade maior: a parte de offer() que o bot aceita (ignora a lateral).
static func is_upgrade(current: ItemData, incoming: ItemData) -> bool:
	return current == null or incoming.rarity > current.rarity
