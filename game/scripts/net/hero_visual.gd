class_name HeroVisual
extends Node
## Visual do heroi: esconde as pecas do pack que o heroi nao usa, escolhe a animacao pelo
## estado do Hero (replicado/previsto) e mostra o equipamento (SPEC-048): cada item equipado
## vira pecas presas aos ossos por BoneAttachment3D (ItemVisuals). So le estado; nunca o altera.
## Morto: cai uma vez e fica. Servidor headless nao carrega peca nenhuma.
## Silhueta no mato alto (F72, ADR-0015 item 10): so no cliente de quem controla o heroi, dentro de
## moita ou fumaca, as malhas ganham um passe translucido sem teste de profundidade e a moita abre
## em volta. Le a regra (Hero.zones_at); nao toca em VisibilityRules, estado nem replicacao.

## Raio da abertura da moita em volta do heroi (u) e alpha da silhueta.
const REVEAL_RADIUS: float = 2.5
const SILHOUETTE_ALPHA: float = 0.35
## Por cima de tudo o que e transparente (a moita fica em -10, as barras em 0).
const SILHOUETTE_PRIORITY: int = 100
## Material unico das moitas (o glTF aponta para ele): o mesmo recurso em todas as malhas.
const GRASS: ShaderMaterial = preload("res://shared/resources/materials/tall_grass.tres")

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
var _tracks_cover: bool = false
var _covered: bool = false
var _silhouette: StandardMaterial3D
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
		use_cover_silhouette(_controlled_here())


func _exit_tree() -> void:
	_set_covered(false)  # a moita e um recurso global: sem isto sobra a abertura na ultima posicao


func _process(_delta: float) -> void:
	if _tracks_cover:
		_set_covered(_hero.is_alive() and _hero.zones_at(_hero.global_position) != Hero.NO_ZONES)
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


## Liga (ou desliga) a silhueta no mato alto. O jogo liga so para o heroi controlado neste cliente;
## o runner headless liga a mao.
func use_cover_silhouette(enabled: bool) -> void:
	_tracks_cover = enabled
	if not enabled:
		_set_covered(false)


func _show_equipment(equipment: Vector4i) -> void:
	for slot: int in Inventory.SLOTS:
		if equipment[slot] != _shown_equipment[slot]:
			_show_slot(slot, Inventory.item_at(equipment, slot, _hero.item_catalog))
	_shown_equipment = equipment
	if _covered:
		_apply_silhouette(_silhouette)  # peca nova tambem entra na silhueta


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


## O heroi e de quem joga neste processo: o dono do peer, fora o bot do treino.
func _controlled_here() -> bool:
	return not _hero.is_bot and _hero.name.to_int() == multiplayer.get_unique_id()


## Entra ou sai do mato: liga ou desliga a silhueta e a abertura. Dentro, a abertura segue o heroi.
func _set_covered(covered: bool) -> void:
	if covered:
		GRASS.set_shader_parameter(&"hero_pos", _hero.global_position)
	if covered == _covered:
		return
	_covered = covered
	GRASS.set_shader_parameter(&"reveal_radius", REVEAL_RADIUS if covered else 0.0)
	if _silhouette == null:
		_silhouette = StandardMaterial3D.new()
		_silhouette.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_silhouette.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_silhouette.no_depth_test = true
		_silhouette.disable_receive_shadows = true
		_silhouette.render_priority = SILHOUETTE_PRIORITY
		_silhouette.albedo_color = Color(UiTokens.BLUE, SILHOUETTE_ALPHA)
	_apply_silhouette(_silhouette if covered else null)


## Passe de silhueta em todas as malhas do heroi, pecas de equipamento incluidas.
func _apply_silhouette(material: Material) -> void:
	for mesh: Node in model.find_children("*", "MeshInstance3D", true, false):
		(mesh as MeshInstance3D).material_overlay = material


func _loop(animation: StringName, speed: float = 1.0) -> void:
	_one_shot = false
	if _player.current_animation != animation:
		_player.play(animation, -1.0, speed)


func _once(animation: StringName, speed: float = 1.0) -> void:
	_one_shot = true
	_player.play(animation, -1.0, speed)


func _on_player_animation_finished(_animation: StringName) -> void:
	_one_shot = false
