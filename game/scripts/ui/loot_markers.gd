class_name LootMarkers
extends RefCounted
## Baus e monstros no minimapa das duas HUDs (F57, decisao do PI 2026-10-12): bau fechado sempre
## (posicao fixa do mapa), monstro vivo so quando o jogador o ve (neblina, F37). Menores que os
## herois, que vem depois e ficam por cima. O boss tem marcador proprio (roxo) na HUD.

const CHEST_COLOR: Color = UiTokens.BLUE
const MONSTER_COLOR: Color = UiTokens.RED
## Raio do marcador (px): herois no padrao do Minimap; baus e monstros menores.
const HERO_RADIUS: float = 6.0
const LOOT_RADIUS: float = 3.5


## Acrescenta os marcadores nos arrays da HUD (reusados a cada quadro: nada alocado aqui).
static func append(
	chests: Array[Chest],
	monsters: Array[Monster],
	positions: PackedVector3Array,
	colors: PackedColorArray,
	radii: PackedFloat32Array
) -> void:
	for chest: Chest in chests:
		if not chest.shown_opened:
			positions.append(chest.global_position)
			colors.append(CHEST_COLOR)
			radii.append(LOOT_RADIUS)
	for monster: Monster in monsters:
		if monster.name == SpawnDirector.BOSS_NAME:
			continue
		if monster.is_alive() and monster.is_shown():
			positions.append(monster.global_position)
			colors.append(MONSTER_COLOR)
			radii.append(LOOT_RADIUS)
