class_name Chest
extends Node3D
## Bau de loot (GDB §6.2). O reforcado do campo de canto (SPEC-055) troca corpo e tampa pelos
## modelos com cantoneiras; colisao e area de interacao iguais. Os drops sao sorteados pelo
## SpawnDirector com a seed da partida; so os do servidor valem. F61 (ADR-0014, supera a
## SPEC-047): o toque em F abre o bau uma vez e o reserva a quem abriu (opener), que ve os 3 itens
## (choices) num menu da HUD (ChestChoiceMenu) e leva 1 com o clique (input chest_pick ->
## pick); o bau fecha. Pode ser pior que o equipado; o item antigo some (PI 2026-10-09). Cura vai
## pelo ledger na abertura, sem menu. Clientes recebem aberto + opener por RPC confiavel; so o
## opener recebe os choices.
## Neblina de guerra (F37): o estado so vai a quem tem o bau no raio de visao (seen_by,
## Concealment); quem passa a ver recebe o estado atual. Fora da visao o bau continua no mapa com
## o ultimo estado visto (shown_opened; no host, o do jogador local).

## Servidor apenas: aberto pela primeira vez por [param peer] (evento chest_opened, F15).
signal first_opened(peer: int, chest_uid: int, tick: int)

const GROUP: StringName = &"chests"
const LID_OPEN_DEGREES: float = -110.0
const NOT_OPENED: int = -1
## Superficie das cintas de ferro no .glb (art/arena/build_island.py): recebe a cor da raridade.
const TRIM_MATERIAL: String = "chest_trim"

@export var rules: MatchRules
@export var catalog: ItemCatalog
@export var common_material: Material
@export var rare_material: Material
@export var epic_material: Material
@export var reinforced_material: Material
## Corpo e tampa do bau reforcado (art/arena/build_island.py).
@export var reinforced_body: PackedScene
@export var reinforced_lid: PackedScene

## Definidos pelo SpawnDirector antes de entrar na arvore.
var kind: ChestRules.Kind = ChestRules.Kind.COMMON
## Bau que o Rei Esqueleto deixa ao morrer (F11).
var epic: bool = false
## Base onde fica (GateRules.TEAM_*; NEUTRAL = centro), do marcador.
var home_team: int = GateRules.TEAM_NEUTRAL
## Negativo e unico entre baus e monstros (chave do ledger).
var uid: int = 0
## So no servidor: numeros de Ids sorteados (ChestRules.roll_choices) ou [ChestRules.HEAL].
var drops: PackedInt32Array = PackedInt32Array()

var opened: bool = false
## Tick do servidor em que abriu (NOT_OPENED = fechado), igual nos dois lados (NetProbe, F20).
var opened_tick: int = NOT_OPENED
## Peer que abriu e a quem o bau fica reservado (0 = ninguem).
var opener: int = 0
## Itens do menu, so no servidor e no opener; vazio = nada a escolher (cura, ou ja escolhido).
var choices: PackedInt32Array = PackedInt32Array()
## Aberto como o jogador deste processo o viu por ultimo (tampa e HUD); no cliente = opened.
var shown_opened: bool = false

var _concealment: Concealment

@onready var _body: Node3D = $Body
@onready var _lid: Node3D = $Lid
@onready var _lid_mesh: Node3D = $Lid/Mesh


func _ready() -> void:
	add_to_group(GROUP)
	var material := common_material
	if epic:
		material = epic_material
	elif kind == ChestRules.Kind.RARE:
		material = rare_material
	elif kind == ChestRules.Kind.REINFORCED:
		material = reinforced_material
		_body = _swap(_body, reinforced_body)
		_lid_mesh = _swap(_lid_mesh, reinforced_lid)
	_paint_trim(_body, material)
	_paint_trim(_lid_mesh, material)
	_concealment = Concealment.guard(self, seen_by)
	_concealment.sight_changed.connect(_on_concealment_sight_changed)
	_refresh_visual()


## Troca o modelo [param old] pela cena [param scene] no mesmo lugar (mesmo nome).
func _swap(old: Node3D, scene: PackedScene) -> Node3D:
	var fresh := scene.instantiate() as Node3D
	fresh.name = old.name
	fresh.transform = old.transform
	var parent := old.get_parent()
	parent.remove_child(old)
	old.free()
	parent.add_child(fresh)
	return fresh


## Cor da raridade so nas cintas (superficie TRIM_MATERIAL); a madeira fica no atlas.
func _paint_trim(root: Node3D, material: Material) -> void:
	for node: Node in root.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		for i: int in range(mi.get_surface_override_material_count()):
			var active := mi.get_active_material(i)
			if active != null and active.resource_name == TRIM_MATERIAL:
				mi.set_surface_override_material(i, material)


func in_reach(point: Vector3) -> bool:
	return CombatRules.in_radius(global_position, point, rules.chest_interact_range)


## Neblina (F37): o heroi [param observer] (null = ninguem) tem o bau no raio de visao.
func seen_by(observer: Hero) -> bool:
	return (
		observer != null
		and VisionRules.in_sight(
			observer.global_position, global_position, observer.match_rules.vision_radius
		)
	)


## Servidor apenas: toque em F do [param hero] ao alcance. Abre uma vez; aberto, nao faz nada
## (o menu reabre so no cliente do opener).
# ponytail: abrir/escolher e irreversivel e vale pela ordem de chegada no servidor; ressimulacao
# que tire o heroi do alcance depois nao desfaz. Raro (input atrasado); servidor segue autoritativo.
func interact(hero: Hero, tick: int) -> void:
	if opened:
		return
	_open(hero, tick)
	_broadcast(tick)


## Servidor apenas: clique no item [param index] do menu (input do cliente, validado aqui).
func pick(hero: Hero, tick: int, index: int) -> void:
	var valid := index >= 0 and index < choices.size()
	if not valid or hero.peer_id != opener or not in_reach(hero.global_position):
		return
	var item := choices[index]
	print("[chest] %s leva %s" % [hero.name, catalog.find(item).display_name])
	var effect := HitEffect.new()
	effect.item = item
	_reward(hero, tick, effect)
	choices = PackedInt32Array()
	_broadcast(tick)


func _open(hero: Hero, tick: int) -> void:
	opened = true
	opened_tick = tick
	opener = hero.peer_id
	first_opened.emit(hero.peer_id, uid, tick)
	if drops == PackedInt32Array([ChestRules.HEAL]):
		var effect := HitEffect.new()
		effect.heal = roundi(rules.heal_amount)
		_reward(hero, tick, effect)
	else:
		choices = drops


## Estado atual a cada peer que ve o bau (Concealment); os itens so ao opener.
func _broadcast(tick: int) -> void:
	_refresh_visual()
	for peer: int in multiplayer.get_peers():
		if _concealment.shown_to(peer):
			_send(peer, tick)


func _send(peer: int, tick: int) -> void:
	var items := choices if peer == opener else PackedInt32Array()
	_show.rpc_id(peer, tick, opened, opener, items)


## O heroi aplica no proprio _rollback_tick de tick+1 (ARCHITECTURE-GAME §3.2).
func _reward(hero: Hero, tick: int, effect: HitEffect) -> void:
	hero.receive_hit(tick + 1, HitLedger.source_key(uid, HitLedger.Slot.REWARD), effect)


## No host, so com o bau na visao do jogador local: fora dela fica o ultimo estado visto.
func _refresh_visual() -> void:
	if not _concealment.is_shown():
		return
	shown_opened = opened
	_lid.rotation_degrees.x = LID_OPEN_DEGREES if opened else 0.0


## [param tick] do evento (ARCHITECTURE-GAME §3.2). So cliente: o servidor ja tem o estado.
@rpc("authority", "call_remote", "reliable")
func _show(tick: int, p_opened: bool, p_opener: int, p_choices: PackedInt32Array) -> void:
	if p_opened and opened_tick == NOT_OPENED:
		opened_tick = tick
	opened = p_opened
	opener = p_opener
	choices = p_choices
	_refresh_visual()


## Servidor: quem passa a ver recebe o estado atual (RPC so a peer conectado); o jogador do host
## atualiza a tampa.
func _on_concealment_sight_changed(peer: int, shown: bool, _tick: int) -> void:
	if not shown:
		return
	if peer == multiplayer.get_unique_id():
		_refresh_visual()
	elif multiplayer.get_peers().has(peer):
		_send(peer, opened_tick)
