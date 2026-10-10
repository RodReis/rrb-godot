class_name Chest
extends Node3D
## Bau de loot (GDB §6.2). O drop e sorteado pelo SpawnDirector com a seed da partida; so o do
## servidor vale. Abre uma vez com toque em F; o item vai ao heroi pelo ledger dele se a troca
## for automatica (ItemRules), senao fica no bau ate alguem segurar F swap_hold_time, e o item
## antigo some (PI 2026-10-09). Cura vai pelo ledger. Clientes recebem aberto + item (numero de
## Ids) por RPC confiavel. A oferta de troca aparece na HUD (F13), nao no bau.

## Servidor apenas: aberto pela primeira vez por [param peer] (evento chest_opened, F15).
signal first_opened(peer: int, chest_uid: int, tick: int)

const GROUP: StringName = &"chests"
const LID_OPEN_DEGREES: float = -110.0
const NOT_OPENED: int = -1

@export var rules: MatchRules
@export var catalog: ItemCatalog
@export var common_material: Material
@export var rare_material: Material
@export var epic_material: Material

## Definidos pelo SpawnDirector antes de entrar na arvore.
var rare: bool = false
## Bau que o Rei Esqueleto deixa ao morrer (F11).
var epic: bool = false
## Base onde fica (GateRules.TEAM_*; NEUTRAL = centro), do marcador.
var home_team: int = GateRules.TEAM_NEUTRAL
## Negativo e unico entre baus e monstros (chave do ledger).
var uid: int = 0
## So no servidor: numero de Ids ou ChestRules.HEAL.
var drop: int = Ids.NONE

var opened: bool = false
## Tick do servidor em que abriu (NOT_OPENED = fechado), igual nos dois lados (NetProbe, F20).
var opened_tick: int = NOT_OPENED
## Item esperando troca no bau aberto; Ids.NONE = vazio.
var item: int = Ids.NONE

## So no servidor: tick em que abriu. A troca so conta de um F apertado depois (confirmacao).
var _opened_tick: int = 0

@onready var _body: MeshInstance3D = $Body
@onready var _lid: Node3D = $Lid
@onready var _lid_mesh: MeshInstance3D = $Lid/Mesh


func _ready() -> void:
	add_to_group(GROUP)
	var material := common_material
	if epic:
		material = epic_material
	elif rare:
		material = rare_material
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


func _hold_ticks() -> int:
	return SkillRules.seconds_to_ticks(rules.swap_hold_time, NetworkTime.tickrate)


func _open(hero: Hero, tick: int) -> void:
	opened = true
	_opened_tick = tick
	first_opened.emit(hero.peer_id, uid, tick)
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


## [param tick] do evento (ARCHITECTURE-GAME §3.2).
@rpc("authority", "call_local", "reliable")
func _show(tick: int, p_opened: bool, p_item: int) -> void:
	if p_opened and opened_tick == NOT_OPENED:
		opened_tick = tick
	opened = p_opened
	item = p_item
	_refresh_visual()
