class_name HeroVisual
extends Node
## Visual do heroi: esconde as pecas do pack que o heroi nao usa, escolhe a animacao pelo
## estado do Hero (replicado/previsto) e mostra o equipamento (SPEC-048): cada item equipado
## vira pecas presas aos ossos por BoneAttachment3D (ItemVisuals). So le estado; nunca o altera.
## Morto: cai uma vez e fica. Servidor headless nao carrega peca nenhuma.

@export var model: Node3D
@export var hidden_parts: Array[StringName] = []
@export var idle: StringName = &"Idle"
@export var run: StringName = &"Running_A"
@export var dash: StringName = &"Running_B"
## Velocidade da animacao de avanco (o Salto do Barbaro cabe a animacao de pulo em 0,45 s).
@export var dash_play_speed: float = 1.0
@export var block: StringName = &"Blocking"
@export var stunned: StringName = &"Hit_B"
@export var basic_attack: StringName = &"1H_Melee_Attack_Slice_Horizontal"
## Vazio = o Q nao tem animacao propria (Investida usa a de avanco).
@export var skill_q: StringName = &""
## Velocidade da animacao do Q (a Rajada da Ladina cabe a 1H_Ranged_Shooting na janela do disparo).
@export var skill_q_speed: float = 1.0
## Vazio = o E nao tem animacao propria (Muralha usa a de bloqueio; Rolamento, a de avanco).
@export var skill_e: StringName = &""
## Vazio = o R nao tem animacao propria (Emboscada usa a de avanco e depois a de strike).
@export var skill_r: StringName = &"1H_Melee_Attack_Chop"
## Golpe no fim do avanco (Hero.dash_strike_ticks: Emboscada da Ladina); vazio = nenhum.
@export var strike: StringName = &""
## Laco enquanto o heroi canaliza (Hero.is_channeling: Rodopio do Barbaro).
@export var channel: StringName = &""
@export var death: StringName = &"Death_A"
## Velocidade abaixo da qual o heroi esta parado (u/s).
@export var moving_speed: float = 0.1

var _hero: Hero
var _player: AnimationPlayer
var _one_shot: bool = false
var _last_basic: int = 0
var _last_q: int = 0
var _last_e: int = 0
var _last_r: int = 0
var _last_strike: int = 0
var _fallen: bool = false
var _items: ItemVisuals
var _skeleton: Skeleton3D
var _shown_equipment: Vector4i = Inventory.NONE
var _attachments: Array[Array] = [[], [], [], []]  # indice = ItemData.Slot -> BoneAttachment3D


func _ready() -> void:
	_hero = get_parent() as Hero
	for part: StringName in hidden_parts:
		var node := model.find_child(part) as Node3D
		if node:
			node.hide()
	_player = model.find_child("AnimationPlayer") as AnimationPlayer
	for looping: StringName in [idle, run, dash, block, channel]:
		if _player.has_animation(looping):
			_player.get_animation(looping).loop_mode = Animation.LOOP_LINEAR
	_player.animation_finished.connect(_on_player_animation_finished)
	_skeleton = model.find_child("Skeleton3D") as Skeleton3D
	if DisplayServer.get_name() != "headless":  # so quem desenha carrega pecas e icones
		use_items(ItemVisuals.for_hero(_hero.hero_data.id))


func _process(_delta: float) -> void:
	if _items != null and _hero.equipment != _shown_equipment:
		_show_equipment(_hero.equipment)
	if not _hero.is_alive():
		if not _fallen:
			_fallen = true
			_once(death)
		return
	_fallen = false
	var started_basic := _hero.basic_cooldown > _last_basic
	var started_r := _hero.r_cooldown > _last_r and skill_r != &""
	var strike_ticks := _hero.dash_strike_ticks()
	var struck := strike_ticks > _last_strike and strike != &""
	_last_strike = strike_ticks
	var started_q := _hero.q_cooldown > _last_q and skill_q != &""
	var started_e := _hero.e_cooldown > _last_e and skill_e != &""
	_last_basic = _hero.basic_cooldown
	_last_q = _hero.q_cooldown
	_last_e = _hero.e_cooldown
	_last_r = _hero.r_cooldown
	if _hero.stun_ticks > 0 or _hero.knockback_ticks > 0:  # atordoado, empurrado ou puxado (F59)
		_loop(stunned)
	elif struck:
		_once(strike)
	elif _hero.dash_ticks > 0:
		_loop(dash, dash_play_speed)
	elif started_r:
		_once(skill_r)
	elif _hero.is_channeling() and _player.current_animation != skill_r:
		_loop(channel)
	elif started_q:
		_once(skill_q, skill_q_speed)
	elif started_e:
		_once(skill_e)
	elif started_basic:
		_once(basic_attack)
	elif _one_shot:
		return
	elif _hero.shield_ticks > 0:
		_loop(block)
	elif _hero.velocity.length() > moving_speed:
		_loop(run)
	else:
		_loop(idle)


## Liga o visual dos itens (nulo desliga) e mostra o equipamento atual.
func use_items(items: ItemVisuals) -> void:
	_show_equipment(Inventory.NONE)  # tira as pecas e devolve as do pack com o visual anterior
	_items = items
	if _items != null:
		_show_equipment(_hero.equipment)


func _show_equipment(equipment: Vector4i) -> void:
	for slot: int in Inventory.SLOTS:
		if equipment[slot] != _shown_equipment[slot]:
			_show_slot(slot, Inventory.item_at(equipment, slot, _hero.item_catalog))
	_shown_equipment = equipment


## Troca as pecas do slot pelas de [param item] (nulo = vazio) e esconde a peca do pack que elas
## substituem. Cada no da peca e modelado no espaco do modelo em repouso: dentro do
## BoneAttachment3D ele recebe o inverso da pose de repouso do osso.
func _show_slot(slot: int, item: ItemData) -> void:
	for attachment: Node in _attachments[slot]:
		attachment.free()
	_attachments[slot].clear()
	var piece: PackedScene = null
	if item != null and _items != null:
		piece = _items.pieces.get(item.id) as PackedScene
	var pack_part: Node3D = null
	if _items != null and _items.pack_parts[slot] != &"":
		pack_part = model.find_child(_items.pack_parts[slot]) as Node3D
	if pack_part != null:
		pack_part.visible = piece == null
	if piece == null:
		return
	var root := piece.instantiate()
	for node: Node in root.get_children():
		var bone := ItemVisuals.bone_of(node.name)
		var index := _skeleton.find_bone(bone)
		if index < 0:
			push_warning("[equipamento] osso %s nao existe (%s)" % [bone, node.name])
			continue
		var mesh := node as Node3D
		var attachment := BoneAttachment3D.new()
		attachment.bone_name = bone
		_skeleton.add_child(attachment)
		root.remove_child(mesh)
		mesh.owner = null
		attachment.add_child(mesh)
		mesh.transform = _skeleton.get_bone_global_rest(index).affine_inverse() * mesh.transform
		_attachments[slot].append(attachment)
	root.free()


func _loop(animation: StringName, speed: float = 1.0) -> void:
	_one_shot = false
	if _player.current_animation != animation:
		_player.play(animation, -1.0, speed)


func _once(animation: StringName, speed: float = 1.0) -> void:
	_one_shot = true
	_player.play(animation, -1.0, speed)


func _on_player_animation_finished(_animation: StringName) -> void:
	_one_shot = false
