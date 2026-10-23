class_name SetBonus
extends RefCounted
## Bonus de conjunto ativo pelas pecas equipadas (GDB §6.1).


static func count_pieces(items: Array[ItemData], set_id: StringName) -> int:
	var count := 0
	for item: ItemData in items:
		if item.set_id == set_id:
			count += 1
	return count


static func active(items: Array[ItemData], bonuses: Array[SetBonusData]) -> Array[SetBonusData]:
	var result: Array[SetBonusData] = []
	for bonus: SetBonusData in bonuses:
		if count_pieces(items, bonus.set_id) >= bonus.pieces_required:
			result.append(bonus)
	return result


## Nome unico do conjunto ativo (telemetria, F29); vazio se nenhum ou mais de um esta ativo.
static func active_set_id(items: Array[ItemData], bonuses: Array[SetBonusData]) -> StringName:
	var complete := active(items, bonuses)
	return complete[0].set_id if complete.size() == 1 else &""
