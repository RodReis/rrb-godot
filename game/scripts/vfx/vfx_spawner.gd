class_name VfxSpawner
extends Node
## Cliente (F41): cria os efeitos de cada heroi que entra em Players (HeroVfx da cena do heroi,
## por HeroData.id) e entrega o impacto confirmado pelo servidor (ImpactRelay) ao efeito do
## atacante, a nuvem da Ladina (F58) ao efeito dela e a Torreta e a caixa do Engenheiro (F59) ao
## dele, a Pocao Verde e o Pantano do Protetor da Selva (F74) ao dele e o Circulo Profano do
## Ocultista (F77) ao dele; as marcas e a Praga sobre o alvo sao do CurseMarks. Nunca existe
## no servidor headless (bloco visual regra 1): a main so o cria quando wanted().
## O heroi nao ganha filho: os efeitos ficam aqui e o seguem.

const NODE_NAME: StringName = &"Vfx"
## Efeitos por HeroData.id; heroi sem entrada fica sem VFX.
const DRIVERS: Dictionary = {
	&"knight": preload("res://scenes/vfx/knight_vfx.tscn"),
	&"ranger": preload("res://scenes/vfx/ranger_vfx.tscn"),
	&"barbarian": preload("res://scenes/vfx/barbarian_vfx.tscn"),
	&"fire_wizard": preload("res://scenes/vfx/fire_wizard_vfx.tscn"),
	&"rogue": preload("res://scenes/vfx/rogue_vfx.tscn"),
	&"engineer": preload("res://scenes/vfx/engineer_vfx.tscn"),
	&"druid": preload("res://scenes/vfx/druid_vfx.tscn"),
	&"berserker": preload("res://scenes/vfx/berserker_vfx.tscn"),
	&"occultist": preload("res://scenes/vfx/occultist_vfx.tscn"),
	&"paladin": preload("res://scenes/vfx/paladin_vfx.tscn"),
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
	var curses := CurseMarks.new()
	curses.name = "Curses"
	add_child(curses)
	players.child_entered_tree.connect(_on_players_child_entered_tree)
	relay.impacted.connect(_on_relay_impacted)
	relay.smoke_shown.connect(_on_relay_smoke_shown)
	relay.deploy_shown.connect(_on_relay_deploy_shown)
	relay.turret_shot_shown.connect(_on_relay_turret_shot_shown)
	relay.zone_shown.connect(_on_relay_zone_shown)
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


func _on_relay_smoke_shown(caster_id: int, center: Vector3, tick: int) -> void:
	var driver: Object = _drivers.get(caster_id)
	if is_instance_valid(driver) and driver is RogueVfx:
		(driver as RogueVfx).smoke(center, tick)


func _on_relay_deploy_shown(caster_id: int, kind: int, center: Vector3, tick: int) -> void:
	var driver: Object = _drivers.get(caster_id)
	if is_instance_valid(driver) and driver is EngineerVfx:
		(driver as EngineerVfx).deployed(kind, center, tick)


func _on_relay_turret_shot_shown(
	caster_id: int, from: Vector3, at: Vector3, ticks_left: int
) -> void:
	var driver: Object = _drivers.get(caster_id)
	if is_instance_valid(driver) and driver is EngineerVfx:
		(driver as EngineerVfx).turret_shot(from, at, ticks_left)


func _on_relay_zone_shown(caster_id: int, kind: int, center: Vector3, tick: int) -> void:
	var driver: Object = _drivers.get(caster_id)
	if is_instance_valid(driver) and driver is DruidVfx:
		(driver as DruidVfx).zone(kind, center, tick)
	elif is_instance_valid(driver) and driver is OccultistVfx:
		(driver as OccultistVfx).zone(kind, center, tick)
