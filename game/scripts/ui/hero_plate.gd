class_name HeroPlate
extends Control
## Base de combate das duas HUDs (DV telas 3 e 4; dock do prototipo HUD Moderno, F57): icone,
## nome, conjuntos, atributos, nivel, HP e XP, 4 slots, skills com recarga e pontos livres,
## comandos, aviso de item equipado, o menu do bau (ChestChoiceMenu, F61) e a
## engrenagem (Bestiario e switches de som da sessao). So le o estado replicado do heroi local e
## nunca decide regra; a HUD dona chama update() no proprio _process.

## Indice = slot do SkillButton: basico, Q, E, R.
const SKILL_KEYS: Array[String] = ["RMB", "Q", "E", "R"]
const LEARN_KEYS: Array[String] = ["Ctrl+Q", "Ctrl+E", "Ctrl+R"]
## Switches da engrenagem (decisao do PI 2026-10-12): tudo, ou so o jingle do chefao (barramento
## do default_bus_layout.tres). Valem so na sessao (FORA-DE-ESCOPO: gravar no settings.cfg).
const BUS_GAME: StringName = &"Master"
const BUS_BOSS: StringName = &"Boss"

var _hero: Hero
var _skills: Array[SkillData] = []
var _buttons: Array[SkillButton] = []
var _learn_badges: Array[HotkeyBadge] = []
var _slots: Array[SlotItem] = []
var _items: ItemVisuals  # icones dos itens deste heroi
## Ultimo estado mostrado: so redesenha o que mudou.
var _shown_hp: Vector2i = -Vector2i.ONE
var _shown_xp: int = -1
## Nivel do ultimo aviso: subir com ponto livre avisa (F57); -1 = recem-ligada, nao avisa.
var _shown_level: int = -1
var _shown_ranks: Vector3i = -Vector3i.ONE
var _shown_equipment: Vector4i = Inventory.NONE
## O heroi troca o objeto ao recalcular (nivel, item): referencia diferente = redesenhar.
var _shown_attributes: HeroAttributes
## Maior recarga vista desde que zerou, por botao (ticks): total da volta radial.
var _cooldown_totals: PackedInt32Array = PackedInt32Array([0, 0, 0, 0])
var _cooldowns: PackedInt32Array = PackedInt32Array([0, 0, 0, 0])

@onready var _toast: Toast = %Toast
@onready var _choice_menu: ChestChoiceMenu = %ChoiceMenu
@onready var _hero_name: Label = %HeroName
@onready var _hero_level: Label = %HeroLevel
@onready var _hp_bar: StatBar = %HpBar
@onready var _xp_bar: StatBar = %XpBar
@onready var _set_text: Label = %SetText
@onready var _points: HBoxContainer = %Points
@onready var _hero_icon: TextureRect = %HeroIcon
@onready var _equip_count: Label = %EquipCount
@onready var _attr_attack: Label = %AttrAttack
@onready var _attr_defense: Label = %AttrDefense
@onready var _attr_intelligence: Label = %AttrIntelligence
@onready var _attr_agility: Label = %AttrAgility
@onready var _attr_speed: Label = %AttrSpeed
@onready var _attr_cdr: Label = %AttrCdr
@onready var _gear_button: Button = %GearButton
@onready var _gear_menu: Control = %GearMenu
@onready var _bestiary_button: Button = %BestiaryButton
@onready var _sound_game: CheckButton = %SoundGame
@onready var _sound_boss: CheckButton = %SoundBoss


func _ready() -> void:
	_buttons = [%Basic, %SkillQ, %SkillE, %SkillR]
	_learn_badges = [%LearnQ, %LearnE, %LearnR]
	_slots = [%Weapon, %Helm, %Chest, %Boots]
	for i: int in _buttons.size():
		_buttons[i].hotkey = SKILL_KEYS[i]
	for i: int in _learn_badges.size():
		_learn_badges[i].key = LEARN_KEYS[i]
		_buttons[i + 1].learn_key = LEARN_KEYS[i]
	_gear_menu.visible = false
	_gear_button.pressed.connect(_on_gear_button_pressed)
	_bestiary_button.pressed.connect(_on_bestiary_button_pressed)
	_sound_game.toggled.connect(_on_sound_game_toggled)
	_sound_boss.toggled.connect(_on_sound_boss_toggled)


## Liga ao heroi local e redesenha tudo; o que ja esta equipado nao vira aviso.
func bind(hero: Hero) -> void:
	_hero = hero
	_items = ItemVisuals.for_hero(hero.hero_data.id)
	_choice_menu.bind(hero)
	_shown_hp = -Vector2i.ONE
	_shown_xp = -1
	_shown_level = -1
	_shown_ranks = -Vector3i.ONE
	_cooldown_totals.fill(0)
	_shown_attributes = null
	var data := hero.hero_data
	_skills = [data.basic_attack, data.skill_q, data.skill_e, data.skill_r]
	_hero_name.text = data.display_name.to_upper()
	_hero_icon.texture = data.basic_attack.icon
	_refresh_equipment()


## Baus da partida, para o menu do bau (a HUD dona recolhe do SpawnDirector).
func set_chests(chests: Array[Chest]) -> void:
	_choice_menu.set_chests(chests)


func update() -> void:
	_update_plate()
	_update_skills()
	if _hero.equipment != _shown_equipment:
		_notify_equipped()
		_refresh_equipment()
	if _hero.attributes != _shown_attributes:
		_refresh_attributes()
	_choice_menu.update()


## Pecas de cada conjunto equipado ("Guarda 2/3"), um texto por conjunto; vazio sem peca de
## conjunto. Tambem na tela de fim (F18, F52).
static func set_pieces(equipment: Vector4i, catalog: ItemCatalog) -> PackedStringArray:
	var items := Inventory.items(equipment, catalog)
	var parts := PackedStringArray()
	for bonus: SetBonusData in catalog.set_bonuses:
		var pieces := SetBonus.count_pieces(items, bonus.set_id)
		if pieces > 0:
			parts.append("%s %d/%d" % [bonus.display_name, pieces, bonus.pieces_required])
	return parts


## [method set_pieces] numa linha, ou "Sem conjunto".
static func set_text(equipment: Vector4i, catalog: ItemCatalog) -> String:
	var parts := set_pieces(equipment, catalog)
	if parts.is_empty():
		return TranslationServer.translate("Sem conjunto")
	return " · ".join(parts)


func _update_plate() -> void:
	var hp := Vector2i(_hero.hp, _hero.attributes.max_hp)
	if hp.y != _shown_hp.y:
		_hp_bar.bind(tr("HP"), hp.x, hp.y, StatBar.Kind.HP)
	elif hp.x != _shown_hp.x:
		_hp_bar.animate_to(hp.x)
	_shown_hp = hp
	if _hero.xp != _shown_xp:
		_shown_xp = _hero.xp
		var progress := HudMath.xp_progress(_hero.xp_curve, _hero.xp)
		_xp_bar.bind(tr("XP"), progress.x, progress.y, StatBar.Kind.XP)
		_hero_level.text = tr("NÍVEL %d") % _hero.level
		if _shown_level >= 0 and _hero.level > _shown_level:
			_notify_free_point()
		_shown_level = _hero.level


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


## Ponto de habilidade para gastar: o aviso diz o atalho (E e R comecam travados, GDB §3.1).
func _notify_free_point() -> void:
	if SkillRules.free_points(_hero.level, _hero.ranks) <= 0:
		return
	var text := tr("NÍVEL %d! Ponto de habilidade: aprenda com Ctrl+Q/E/R") % _hero.level
	_toast.show_message(text, Toast.Kind.INFO)


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
			_slots[slot].bind(item, _items.icon(item) if _items != null else null)
	_set_text.text = set_text(_shown_equipment, catalog)
	var equipped := 0
	for slot: int in Inventory.SLOTS:
		if Inventory.item_at(_shown_equipment, slot, catalog) != null:
			equipped += 1
	_equip_count.text = "%d / %d" % [equipped, Inventory.SLOTS]


## Grade de atributos (F57): os 6 finais do heroi (nivel + itens + conjuntos, Stats).
func _refresh_attributes() -> void:
	var attributes := _hero.attributes
	_shown_attributes = attributes
	_attr_attack.text = tr("ATQ %d") % roundi(attributes.attack)
	_attr_defense.text = tr("DEF %d") % roundi(attributes.defense)
	_attr_intelligence.text = tr("INT %d") % roundi(attributes.intelligence)
	_attr_agility.text = tr("AGI %d") % roundi(attributes.agility)
	_attr_speed.text = tr("VEL %s") % HudMath.decimal(attributes.move_speed)
	_attr_cdr.text = tr("RCG %d%%") % roundi(attributes.cdr_percent)


## Barramento ligado (nao mutado)? Sem o barramento (layout ausente): ligado.
static func _bus_on(bus_name: StringName) -> bool:
	var index := AudioServer.get_bus_index(bus_name)
	return index < 0 or not AudioServer.is_bus_mute(index)


static func _set_bus_on(bus_name: StringName, on: bool) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index < 0:
		push_warning("[hud] sem barramento de audio %s" % bus_name)
		return
	AudioServer.set_bus_mute(index, not on)


## Ao abrir, os switches leem o barramento: a outra HUD pode ter mudado.
func _on_gear_button_pressed() -> void:
	_gear_menu.visible = not _gear_menu.visible
	if _gear_menu.visible:
		_sound_game.set_pressed_no_signal(_bus_on(BUS_GAME))
		_sound_boss.set_pressed_no_signal(_bus_on(BUS_BOSS))


## Mesmo caminho da tecla B: o Bestiario (no main) nao e referenciado pela HUD.
func _on_bestiary_button_pressed() -> void:
	_gear_menu.visible = false
	var event := InputEventAction.new()
	event.action = InputActions.OPEN_BESTIARY
	event.pressed = true
	Input.parse_input_event(event)
	var release := event.duplicate() as InputEventAction  # mesmo objeto 2x no quadro: inseguro
	release.pressed = false  # solta: a acao nao fica "segurada" no Input
	Input.parse_input_event(release)


func _on_sound_game_toggled(on: bool) -> void:
	_set_bus_on(BUS_GAME, on)


func _on_sound_boss_toggled(on: bool) -> void:
	_set_bus_on(BUS_BOSS, on)
