class_name PickRules
extends RefCounted
## Selecao de herois (CONVENTION §3, R-PEND-04): padrao do slot e heroi aceito no lock-in.
## Espelho permitido: nada aqui olha a escolha do outro jogador.


## Heroi de quem nao confirmou: o padrao do [param slot] (0 = P1) se disponivel, senao o
## primeiro disponivel; &"" se nenhum.
## [param shown]: heroi em destaque na tela de quem nao confirmou (PI 2026-10-22); vale se
## disponivel, antes do padrao do slot.
static func default_hero(
	defaults: Array[StringName], slot: int, available: Array[StringName], shown: StringName = &""
) -> StringName:
	if available.has(shown):
		return shown
	if slot >= 0 and slot < defaults.size() and available.has(defaults[slot]):
		return defaults[slot]
	return available[0] if not available.is_empty() else &""


static func can_pick(hero: StringName, available: Array[StringName]) -> bool:
	return available.has(hero)
