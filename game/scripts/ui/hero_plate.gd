class_name HeroPlate
extends Control
## Base de combate das duas HUDs (DV telas 3 e 4): nome, nivel, HP e XP, 4 slots com conjuntos,
## skills com recarga e pontos livres, controles, aviso de item equipado e a oferta de troca do
## bau ao alcance. So le o estado replicado do heroi local e nunca decide regra; a HUD dona chama
## update() no proprio _process.

## Indice = slot do SkillButton: basico, Q, E, R.
const SKILL_KEYS: Array[String] = ["LMB", "Q", "E", "R"]
const LEARN_KEYS: Array[String] = ["Ctrl+Q", "Ctrl+E", "Ctrl+R"]

var _hero: Hero
var _skills: Array[SkillData] = []
var _buttons: Array[SkillButton] = []
var _learn_badges: Array[HotkeyBadge] = []
var _slots: Array[SlotItem] = []
var _chests: Array[Chest] = []
## Ultimo estado mostrado: so redesenha o que mudou.
var _shown_hp: Vector2i = -Vector2i.ONE
var _shown_xp: int = -1
var _shown_ranks: Vector3i = -Vector3i.ONE
var _shown_equipment: Vector4i = Inventory.NONE
## Maior recarga vista desde que zerou, por botao (ticks): total da volta radial.
var _cooldown_totals: PackedInt32Array = PackedInt32Array([0, 0, 0, 0])
var _cooldowns: PackedInt32Array = PackedInt32Array([0, 0, 0, 0])

@onready var _toast: Toast = %Toast
@onready var _offer: PanelCard = %Offer
@onready var _offer_text: Label = %OfferText
@onready var _hero_name: Label = %HeroName
@onready var _hero_level: Label = %HeroLevel
@onready var _hp_bar: StatBar = %HpBar
@onready var _xp_bar: StatBar = %XpBar
@onready var _set_text: Label = %SetText
@onready var _points: HBoxContainer = %Points


func _ready() -> void:
	_buttons = [%Basic, %SkillQ, %SkillE, %SkillR]
	_learn_badges = [%LearnQ, %LearnE, %LearnR]
	_slots = [%Weapon, %Helm, %Chest, %Boots]
	for i: int in _buttons.size():
		_buttons[i].hotkey = SKILL_KEYS[i]
	for i: int in _learn_badges.size():
		_learn_badges[i].key = LEARN_KEYS[i]


## Liga ao heroi local e redesenha tudo; o que ja esta equipado nao vira aviso.
func bind(hero: Hero) -> void:
	_hero = hero
	_shown_hp = -Vector2i.ONE
	_shown_xp = -1
	_shown_ranks = -Vector3i.ONE
	_cooldown_totals.fill(0)
	var data := hero.hero_data
	_skills = [data.basic_attack, data.skill_q, data.skill_e, data.skill_r]
	_hero_name.text = data.display_name.to_upper()
	_refresh_equipment()


## Baus da partida, para a oferta de troca (a HUD dona recolhe do SpawnDirector).
func set_chests(chests: Array[Chest]) -> void:
	_chests = chests


func update() -> void:
	_update_plate()
	_update_skills()
	if _hero.equipment != _shown_equipment:
		_notify_equipped()
		_refresh_equipment()
	_update_offer()


func _update_plate() -> void:
	var hp := Vector2i(_hero.hp, _hero.attributes.max_hp)
	if hp.y != _shown_hp.y:
		_hp_bar.bind(tr("HP"), hp.x, hp.y, StatBar.Kind.HP)
	elif hp.x != _shown_hp.x:
		_hp_bar.animate_to(hp.x, UiTokens.DUR_FAST)
	_shown_hp = hp
	if _hero.xp != _shown_xp:
		_shown_xp = _hero.xp
		var progress := HudMath.xp_progress(_hero.xp_curve, _hero.xp)
		_xp_bar.bind(tr("XP"), progress.x, progress.y, StatBar.Kind.XP)
		_hero_level.text = tr("NÍVEL %d") % _hero.level


func _update_skills() -> void:
	var ranks := _hero.ranks
	if ranks != _shown_ranks:
		_shown_ranks = ranks
		_buttons[0].bind(_skills[0], 1)
		for slot: int in SkillRules.SLOT_R + 1:
			_buttons[slot + 1].bind(_skills[slot + 1], ranks[slot])
	_cooldowns[0] = _hero.basic_cooldown
	_cooldowns[1] = _hero.q_cooldown
	_cooldowns[2] = _hero.e_cooldown
	_cooldowns[3] = _hero.r_cooldown
	var rate := float(NetworkTime.tickrate)
	var free := SkillRules.free_points(_hero.level, ranks)
	for i: int in _buttons.size():
		var remaining := _cooldowns[i]
		_cooldown_totals[i] = maxi(_cooldown_totals[i], remaining) if remaining > 0 else 0
		_buttons[i].set_cooldown(remaining / rate, _cooldown_totals[i] / rate)
		if i == 0:
			continue
		var rank := ranks[i - 1]
		_buttons[i].set_locked(rank == 0)
		var learnable := free > 0 and SkillRules.can_use(_skills[i], rank + 1, _hero.level)
		_buttons[i].set_upgradable(learnable)
		_learn_badges[i - 1].visible = learnable
	_points.visible = free > 0


func _notify_equipped() -> void:
	var catalog := _hero.item_catalog
	for slot: int in Inventory.SLOTS:
		if _hero.equipment[slot] == _shown_equipment[slot]:
			continue
		var item := Inventory.item_at(_hero.equipment, slot, catalog)
		if item != null:
			var rarity := ItemData.RARITY_NAMES[item.rarity]
			var text := tr("%s (%s) equipado") % [item.display_name, rarity]
			_toast.show_message(text, Toast.Kind.SUCCESS)


func _refresh_equipment() -> void:
	_shown_equipment = _hero.equipment
	var catalog := _hero.item_catalog
	for slot: int in Inventory.SLOTS:
		var item := Inventory.item_at(_shown_equipment, slot, catalog)
		if item == null:
			_slots[slot].clear()
		else:
			_slots[slot].bind(item)
	var items := Inventory.items(_shown_equipment, catalog)
	var parts := PackedStringArray()
	for bonus: SetBonusData in catalog.set_bonuses:
		var pieces := SetBonus.count_pieces(items, bonus.set_id)
		if pieces > 0:
			parts.append("%s %d/%d" % [bonus.display_name, pieces, bonus.pieces_required])
	_set_text.text = " · ".join(parts) if not parts.is_empty() else tr("Sem conjunto")


## Bau aberto ao alcance com item esperando troca: segurar F troca (Chest).
func _update_offer() -> void:
	for chest: Chest in _chests:
		if chest.item != Ids.NONE and chest.in_reach(_hero.global_position):
			var offer := chest.catalog.find(chest.item)
			if offer == null:
				continue
			var rarity := ItemData.RARITY_NAMES[offer.rarity]
			_offer_text.text = tr("Segure para trocar: %s (%s)") % [offer.display_name, rarity]
			_offer.visible = true
			return
	_offer.visible = false
