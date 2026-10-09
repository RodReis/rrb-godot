class_name Chest
extends Node3D
## Bau de loot (GDB §6.2). O drop e sorteado pelo SpawnDirector com a seed da partida; so o do
## servidor vale. Abre uma vez com toque em F; o item vai ao heroi pelo ledger dele se a troca
## for automatica (ItemRules), senao fica no bau ate alguem segurar F swap_hold_time, e o item
## antigo some (PI 2026-10-09). Cura vai pelo ledger. Clientes recebem aberto + item (numero de
## Ids) por RPC confiavel.

const GROUP: StringName = &"chests"
const LID_OPEN_DEGREES: float = -110.0
const RARITY_NAMES: Array[String] = ["Comum", "Raro", "Épico"]

@export var rules: MatchRules
@export var catalog: ItemCatalog
@export var common_material: Material
@export var rare_material: Material

## Definidos pelo SpawnDirector antes de entrar na arvore.
var rare: bool = false
## Negativo e unico entre baus e monstros (chave do ledger).
var uid: int = 0
## So no servidor: numero de Ids ou ChestRules.HEAL.
var drop: int = Ids.NONE

var opened: bool = false
## Item esperando troca no bau aberto; Ids.NONE = vazio.
var item: int = Ids.NONE

## So no servidor: tick em que abriu. A troca so conta de um F apertado depois (confirmacao).
var _opened_tick: int = 0

@onready var _body: MeshInstance3D = $Body
@onready var _lid: Node3D = $Lid
@onready var _lid_mesh: MeshInstance3D = $Lid/Mesh
@onready var _label: Label3D = $Label


func _ready() -> void:
	add_to_group(GROUP)
	var material := rare_material if rare else common_material
	_body.material_override = material
	_lid_mesh.material_override = material
	_refresh_visual()


func in_reach(point: Vector3) -> bool:
	return CombatRules.in_radius(global_position, point, rules.chest_interact_range)


## Servidor apenas. [param held_ticks] = ticks seguidos com F (1 = toque) do [param hero].
# ponytail: abrir/trocar e irreversivel e vale pela ordem de chegada no servidor; ressimulacao
# que tire o heroi do alcance depois nao desfaz. Raro (input atrasado); servidor segue autoritativo.
func interact(hero: Hero, tick: int, held_ticks: int) -> void:
	var pressed_tick := tick - held_ticks + 1
	if held_ticks == 1 and not opened:
		_open(hero, tick)
	elif item != Ids.NONE and held_ticks == _hold_ticks() and pressed_tick > _opened_tick:
		_give(hero, tick)
	else:
		return
	_show.rpc(tick, opened, item)


## Servidor apenas: estado atual ao peer que acabou de conectar (baus abertos antes dele).
func send_state(peer: int) -> void:
	if opened:
		_show.rpc_id(peer, NetworkTime.tick, opened, item)


func _hold_ticks() -> int:
	return SkillRules.seconds_to_ticks(rules.swap_hold_time, NetworkTime.tickrate)


func _open(hero: Hero, tick: int) -> void:
	opened = true
	_opened_tick = tick
	if drop == ChestRules.HEAL:
		var effect := HitEffect.new()
		effect.heal = roundi(rules.heal_amount)
		_reward(hero, tick, effect)
	else:
		item = drop
		var auto := ItemRules.Swap.AUTO
		if Inventory.swap_mode(hero.equipment, catalog.find(item), catalog) == auto:
			_give(hero, tick)


func _give(hero: Hero, tick: int) -> void:
	var effect := HitEffect.new()
	effect.item = item
	_reward(hero, tick, effect)
	item = Ids.NONE


## O heroi aplica no proprio _rollback_tick de tick+1 (ARCHITECTURE-GAME §3.2).
func _reward(hero: Hero, tick: int, effect: HitEffect) -> void:
	hero.receive_hit(tick + 1, HitLedger.source_key(uid, HitLedger.Slot.REWARD), effect)


func _refresh_visual() -> void:
	_lid.rotation_degrees.x = LID_OPEN_DEGREES if opened else 0.0
	var offer := catalog.find(item)
	_label.visible = offer != null
	if offer != null:
		_label.text = (
			"%s (%s)\nsegure F para trocar" % [offer.display_name, RARITY_NAMES[offer.rarity]]
		)


## [param _tick] do evento (ARCHITECTURE-GAME §3.2); a UI do F13 usa.
@rpc("authority", "call_local", "reliable")
func _show(_tick: int, p_opened: bool, p_item: int) -> void:
	opened = p_opened
	item = p_item
	_refresh_visual()
