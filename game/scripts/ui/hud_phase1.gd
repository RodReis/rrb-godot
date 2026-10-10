class_name HudPhase1
extends CanvasLayer
## HUD da fase 1 (DV tela 3, ARCHITECTURE-GAME §3.6): relogio, portao, boss, minimapa, HP/XP,
## 4 slots com conjuntos, skills com recarga e pontos livres, catch-up, loot, oferta do bau e o
## aviso de respawn enquanto o heroi local esta morto (F15).
## So le estado replicado (heroi local, relogio, nos do mundo) e nunca decide regra; tempos
## e limiares vem de MatchRules/XpCurve. Fica escondida ate bind() com o heroi local.

## Indice = slot do SkillButton: basico, Q, E, R.
const SKILL_KEYS: Array[String] = ["LMB", "Q", "E", "R"]
const LEARN_KEYS: Array[String] = ["Ctrl+Q", "Ctrl+E", "Ctrl+R"]
const PERCENT: float = 100.0
## Banner de alerta de fase some sozinho (PATTERNS P7).
const BANNER_SECONDS: float = 3.0

var _hero: Hero
var _clock: MatchClock
var _spawns: SpawnDirector
var _players: Node
var _rules: MatchRules
var _skills: Array[SkillData] = []
var _buttons: Array[SkillButton] = []
var _learn_badges: Array[HotkeyBadge] = []
var _slots: Array[SlotItem] = []
## Ultimo estado mostrado: so redesenha o que mudou.
var _shown_hp: Vector2i = -Vector2i.ONE
var _shown_xp: int = -1
var _shown_ranks: Vector3i = -Vector3i.ONE
var _shown_equipment: Vector4i = Inventory.NONE
## Maior recarga vista desde que zerou, por botao (ticks): total da volta radial.
var _cooldown_totals: PackedInt32Array = PackedInt32Array([0, 0, 0, 0])
var _cooldowns: PackedInt32Array = PackedInt32Array([0, 0, 0, 0])
var _chests: Array[Chest] = []
var _monsters: Array[Monster] = []
var _marker_positions: PackedVector3Array = PackedVector3Array()
var _marker_colors: PackedColorArray = PackedColorArray()
var _banner_tween: Tween

@onready var _gate_text: Label = %GateText
@onready var _phase_title: Label = %PhaseTitle
@onready var _phase_timer: TimerLabel = %PhaseTimer
@onready var _boss_timer: TimerLabel = %BossTimer
@onready var _boss_status: Label = %BossStatus
@onready var _minimap: Minimap = %Minimap
@onready var _loot_text: Label = %LootText
@onready var _catch_up: PanelCard = %CatchUp
@onready var _catch_up_text: Label = %CatchUpText
@onready var _catch_up_hint: Label = %CatchUpHint
@onready var _toast: Toast = %Toast
@onready var _offer: PanelCard = %Offer
@onready var _offer_text: Label = %OfferText
@onready var _hero_name: Label = %HeroName
@onready var _hero_level: Label = %HeroLevel
@onready var _hp_bar: StatBar = %HpBar
@onready var _xp_bar: StatBar = %XpBar
@onready var _set_text: Label = %SetText
@onready var _points: HBoxContainer = %Points
@onready var _boss_banner: PanelCard = %BossBanner
@onready var _boss_banner_text: Label = %BossBannerText
@onready var _boss_sound: AudioStreamPlayer = %BossSound
@onready var _respawn: PanelCard = %Respawn
@onready var _respawn_text: Label = %RespawnText


func _ready() -> void:
	visible = false
	set_process(false)
	_buttons = [%Basic, %SkillQ, %SkillE, %SkillR]
	_learn_badges = [%LearnQ, %LearnE, %LearnR]
	_slots = [%Weapon, %Helm, %Chest, %Boots]
	for i: int in _buttons.size():
		_buttons[i].hotkey = SKILL_KEYS[i]
	for i: int in _learn_badges.size():
		_learn_badges[i].key = LEARN_KEYS[i]


## Liga a HUD ao heroi local e ao mundo da partida. [param players] = pai dos herois.
func bind(hero: Hero, clock: MatchClock, spawns: SpawnDirector, players: Node) -> void:
	_hero = hero
	_shown_hp = -Vector2i.ONE
	_shown_xp = -1
	_shown_ranks = -Vector3i.ONE
	_cooldown_totals.fill(0)
	_clock = clock
	_spawns = spawns
	_players = players
	_rules = clock.rules
	var data := hero.hero_data
	_skills = [data.basic_attack, data.skill_q, data.skill_e, data.skill_r]
	_hero_name.text = data.display_name.to_upper()
	_minimap.bind(hero)
	_collect_world()
	if not spawns.boss_killed.is_connected(_on_spawns_boss_killed):
		spawns.boss_killed.connect(_on_spawns_boss_killed)
		clock.boss_spawned.connect(_on_clock_boss_spawned)
		clock.boss_warning.connect(_on_clock_boss_warning)
	_shown_equipment = hero.equipment  # o que ja estava equipado nao vira notificacao
	_refresh_equipment()
	visible = true
	set_process(true)


func _process(_delta: float) -> void:
	if not is_instance_valid(_hero):
		visible = false
		set_process(false)
		return
	var elapsed := maxf(_clock.elapsed(NetworkTime.tick), 0.0)  # cliente ainda sincronizando
	_update_clock(elapsed)
	_update_plate()
	_update_skills()
	if _hero.equipment != _shown_equipment:
		_notify_equipped()
		_refresh_equipment()
	_update_catch_up()
	_update_offer()
	_update_loot_text()
	_update_minimap()
	_update_respawn()


func _update_clock(elapsed: float) -> void:
	var phase_left := HudMath.until(_rules.phase1_duration, elapsed)
	_phase_timer.set_seconds(phase_left)
	_phase_timer.set_state(
		TimerLabel.State.WARNING if HudMath.is_warning(phase_left) else TimerLabel.State.NORMAL
	)
	var gates_open := elapsed >= _rules.phase1_duration
	_gate_text.text = tr("PORTÕES ABERTOS") if gates_open else tr("PORTÃO DA BASE: SEGURO")
	_phase_title.text = tr("FASE 1 ENCERRADA") if gates_open else tr("FASE 1: PREPARAÇÃO")
	var boss_left := HudMath.until(_rules.boss_spawn_time, elapsed)
	_boss_timer.visible = boss_left > 0.0
	_boss_timer.set_seconds(boss_left)
	_boss_timer.set_state(
		TimerLabel.State.WARNING if HudMath.is_warning(boss_left) else TimerLabel.State.NORMAL
	)
	if _spawns.has_node(SpawnDirector.BOSS_CHEST_NAME):
		_boss_status.text = tr("DERROTADO")
	elif boss_left > 0.0:
		_boss_status.text = tr("surge no centro")
	else:
		_boss_status.text = tr("NO CENTRO")


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


func _update_catch_up() -> void:
	var bonus := 0.0
	for node: Node in _players.get_children():
		var other := node as Hero
		if other != null and other != _hero:
			bonus = maxf(bonus, HudMath.catch_up_bonus(_hero.xp_curve, _hero.level, other.level))
	_catch_up.visible = bonus > 0.0
	if _catch_up.visible:
		_catch_up_text.text = tr("CATCH-UP +%d%% XP") % roundi(bonus * PERCENT)
		var gap := _hero.xp_curve.catch_up_level_gap
		_catch_up_hint.text = tr("%d+ níveis atrás do adversário") % gap


## Morto: segundos ate renascer, do estado replicado do heroi (respawn_ticks).
func _update_respawn() -> void:
	_respawn.visible = not _hero.is_alive()
	if _respawn.visible:
		var seconds := ceili(float(_hero.respawn_ticks) / NetworkTime.tickrate)
		_respawn_text.text = tr("Renascendo na base em %d s") % seconds


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


func _update_loot_text() -> void:
	var opened := 0
	for chest: Chest in _chests:
		if chest.opened:
			opened += 1
	var alive := 0
	for monster: Monster in _monsters:
		if monster.is_alive():
			alive += 1
	_loot_text.text = tr("Baús abertos %d/%d · Monstros %d") % [opened, _chests.size(), alive]


## Herois (verde = eu, vermelho = adversario) e o boss vivo (roxo).
func _update_minimap() -> void:
	var camera := get_viewport().get_camera_3d()
	if camera != null:
		_minimap.set_yaw(camera.global_rotation.y)
	_marker_positions.clear()
	_marker_colors.clear()
	for node: Node in _players.get_children():
		var hero := node as Hero
		if hero == null:
			continue
		_marker_positions.append(hero.global_position)
		_marker_colors.append(UiTokens.GREEN if hero == _hero else UiTokens.RED)
	var boss := _spawns.get_node_or_null(SpawnDirector.BOSS_NAME) as Monster
	if boss != null and boss.is_alive():
		_marker_positions.append(boss.global_position)
		_marker_colors.append(UiTokens.PURPLE)
	_minimap.set_markers(_marker_positions, _marker_colors)


## Baus e monstros sao filhos do SpawnDirector; o boss e o bau dele chegam depois.
func _collect_world() -> void:
	_chests.clear()
	_monsters.clear()
	for node: Node in _spawns.get_children():
		if node is Chest:
			_chests.append(node as Chest)
		elif node is Monster:
			_monsters.append(node as Monster)


## Aviso global do boss (3:00, PI 2026-10-09): banner central, som e, no mundo, o BossPortal.
## Quem entra depois recebe os eventos atrasados de uma vez: com o boss ja vivo, nada.
func _on_clock_boss_warning(tick: int) -> void:
	var left := _rules.boss_spawn_time - _clock.elapsed(tick)
	if left <= 0.0:
		return
	_boss_banner_text.text = tr("O REI ESQUELETO DESPERTA EM %d s") % roundi(left)
	_boss_banner.visible = true
	_boss_banner.modulate.a = 0.0
	if _banner_tween != null:
		_banner_tween.kill()
	_banner_tween = create_tween()
	_banner_tween.tween_property(_boss_banner, ^"modulate:a", 1.0, UiTokens.DUR_SLOW)
	_banner_tween.tween_interval(BANNER_SECONDS)
	_banner_tween.tween_property(_boss_banner, ^"modulate:a", 0.0, UiTokens.DUR_SLOW)
	_banner_tween.tween_callback(_boss_banner.hide)
	_boss_sound.play()


## Depois do SpawnDirector.spawn_boss, ligado antes no main.
func _on_clock_boss_spawned(_tick: int) -> void:
	_collect_world()


func _on_spawns_boss_killed(_peer: int) -> void:
	_collect_world()
