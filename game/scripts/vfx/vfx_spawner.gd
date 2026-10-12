class_name VfxSpawner
extends Node
## Cliente (F41): cria os efeitos de cada heroi que entra em Players (HeroVfx da cena do heroi,
## por HeroData.id) e entrega o impacto confirmado pelo servidor (ImpactRelay) ao efeito do
## atacante. Nunca existe no servidor headless (bloco visual regra 1): a main so o cria quando
## wanted(). O heroi nao ganha filho: os efeitos ficam aqui e o seguem.

const NODE_NAME: StringName = &"Vfx"
## Efeitos por HeroData.id; heroi sem entrada fica sem VFX.
const DRIVERS: Dictionary = {
	&"knight": preload("res://scenes/vfx/knight_vfx.tscn"),
	&"ranger": preload("res://scenes/vfx/ranger_vfx.tscn"),
	&"barbarian": preload("res://scenes/vfx/barbarian_vfx.tscn"),
}

## Pai dos herois (Main/Players) e o relay de impactos; definidos antes de entrar na arvore.
var players: Node
var relay: ImpactRelay

var _pool: VfxPool
var _drivers: Dictionary = {}  # peer_id (int) -> HeroVfx


## Este processo desenha (cliente ou host com janela); servidor headless nao.
static func wanted() -> bool:
	return DisplayServer.get_name() != "headless"


func _ready() -> void:
	_pool = VfxPool.new()
	_pool.name = "Pool"
	add_child(_pool)
	players.child_entered_tree.connect(_on_players_child_entered_tree)
	relay.impacted.connect(_on_relay_impacted)
	for node: Node in players.get_children():
		_on_players_child_entered_tree(node)


## Depois do _ready do heroi (peer_id e HeroData prontos).
func _attach(hero: Hero) -> void:
	if not is_instance_valid(hero) or not DRIVERS.has(hero.hero_data.id):
		return
	var driver := (DRIVERS[hero.hero_data.id] as PackedScene).instantiate() as HeroVfx
	add_child(driver)
	driver.bind(hero, _pool)
	_drivers[hero.peer_id] = driver


func _on_players_child_entered_tree(node: Node) -> void:
	var hero := node as Hero
	if hero != null:
		_attach.call_deferred(hero)


func _on_relay_impacted(attacker_id: int, slot: int, at: Vector3) -> void:
	var driver: Object = _drivers.get(attacker_id)
	if is_instance_valid(driver):
		(driver as HeroVfx).impact(slot as HitLedger.Slot, at)
