extends Node3D
## Vitrine do equipamento (SPEC-048 §6 item 5; regra de alinhamento do PRD §11): os herois
## com os dois conjuntos nas tres raridades (elmo, peito e bota do conjunto + a arma da mesma
## raridade), ou seja, os 21 itens em cada heroi. Fora da partida; so para a verificacao visual.
## Teclas: 1 = camera do jogo (14 u, 45°), 2 = de perto, W/S = linha em foco, Espaco = gira os
## herois, A = alterna parado/correndo (confere o clipping na animacao).
## Argumentos (depois de --): --close e --row=N abrem de perto na linha N (captura de tela).

const HEROES: Array[String] = [
	"res://scenes/heroes/knight.tscn",
	"res://scenes/heroes/ranger.tscn",
	"res://scenes/heroes/barbarian.tscn",
]
const SETS: Array[String] = ["guard", "hunter"]
const SLOTS: Array[String] = ["helm", "chest", "boots"]
## Indice = raridade.
const WEAPONS: Array[StringName] = [&"sword_t1", &"sword_t2", &"sword_t3_epic"]
const SET_NAMES: Array[String] = ["Guarda", "Caçador"]
const COLUMN_STEP: float = 3.0
const ROW_STEP: float = 7.5
const GAME_PITCH: float = 45.0
const GAME_DISTANCE: float = 14.0
const CLOSE_PITCH: float = 15.0
const CLOSE_DISTANCE: float = 5.0
const TURN_SPEED: float = 0.6  # rad/s
## Velocidade fingida para o HeroVisual tocar a corrida (acima de moving_speed).
const RUN_SPEED: float = 5.0
const LABEL_SIZE: int = 28
const LABEL_OFFSET: Vector3 = Vector3(0.0, 0.15, 1.1)
const LOCAL_PEER: String = "1"
## Uma linha por heroi e conjunto.
const ROWS: int = 6

var _heroes: Array[Hero] = []
var _turning: bool = false
var _running: bool = false
var _row: int = 0
var _close: bool = false

@onready var _camera: Camera3D = $Camera


func _ready() -> void:
	var row := 0
	for scene: String in HEROES:
		for set_index: int in SETS.size():
			for rarity: int in WEAPONS.size():
				var position_xz := Vector3((rarity - 1) * COLUMN_STEP, 0.0, _row_z(row))
				_spawn(scene, set_index, rarity, position_xz)
			row += 1
	for arg: String in OS.get_cmdline_user_args():
		if arg == "--close":
			_close = true
		elif arg.begins_with("--row="):
			_row = clampi(arg.get_slice("=", 1).to_int(), 0, ROWS - 1)
	_aim()


func _process(delta: float) -> void:
	for hero: Hero in _heroes:
		if _turning:
			hero.rotate_y(TURN_SPEED * delta)
		hero.velocity = Vector3.FORWARD * RUN_SPEED if _running else Vector3.ZERO


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	match key.keycode:
		KEY_1:
			_close = false
		KEY_2:
			_close = true
		KEY_W:
			_row = maxi(_row - 1, 0)
		KEY_S:
			_row = mini(_row + 1, ROWS - 1)
		KEY_SPACE:
			_turning = not _turning
		KEY_A:
			_running = not _running
	_aim()


## Cada heroi e o jogador local (peer 1, sob um pai proprio): heroi de outro peer nasce
## escondido pela neblina.
func _spawn(scene: String, set_index: int, rarity: int, at: Vector3) -> void:
	var holder := Node3D.new()
	holder.position = at
	add_child(holder)
	var hero := (load(scene) as PackedScene).instantiate() as Hero
	hero.name = LOCAL_PEER
	hero.rotation.y = PI  # de frente para a camera
	holder.add_child(hero)
	var equipment := Inventory.NONE
	var ids: Array[StringName] = [WEAPONS[rarity]]
	for slot: String in SLOTS:
		ids.append(StringName("%s_%s_t%d" % [SETS[set_index], slot, rarity + 1]))
	for id: StringName in ids:
		equipment = Inventory.equip(equipment, hero.item_catalog.find(Ids.to_int(id)))
	hero.equipment = equipment
	var label := Label3D.new()
	label.text = "%s · %s" % [SET_NAMES[set_index], ItemData.RARITY_NAMES[rarity]]
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = LABEL_SIZE
	label.pixel_size = 0.01
	label.position = at + LABEL_OFFSET
	add_child(label)
	_heroes.append(hero)


func _row_z(row: int) -> float:
	return (row - (ROWS - 1) * 0.5) * ROW_STEP


## Camera do jogo sobre a grade inteira ou de perto na linha em foco.
func _aim() -> void:
	var target := Vector3(0.0, 0.0, _row_z(_row)) if _close else Vector3.ZERO
	var pitch := CLOSE_PITCH if _close else GAME_PITCH
	var distance := CLOSE_DISTANCE if _close else GAME_DISTANCE
	_camera.position = target + CameraRig.offset(0.0, pitch, distance)
	_camera.look_at(target + Vector3.UP, Vector3.UP)
