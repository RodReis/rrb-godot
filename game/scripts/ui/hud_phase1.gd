class_name HudPhase1
extends CanvasLayer
## HUD da fase 1 (DV tela 3, ARCHITECTURE-GAME §3.6): relogio, portao, boss, minimapa,
## catch-up, loot e o aviso de respawn enquanto o heroi local esta morto (F15); HP/XP, slots,
## skills e a oferta do bau ficam na base comum (HeroPlate). So le estado replicado (heroi
## local, relogio, nos do mundo) e nunca decide regra; tempos e limiares vem de
## MatchRules/XpCurve. Fica escondida ate bind() com o heroi local; o HudController a troca pela
## da fase 2 (set_active).

const PERCENT: float = 100.0
## Banner de alerta de fase some sozinho (PATTERNS P7).
const BANNER_SECONDS: float = 3.0

var _hero: Hero
var _clock: MatchClock
var _spawns: SpawnDirector
var _players: Node
var _rules: MatchRules
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
@onready var _boss_banner: PanelCard = %BossBanner
@onready var _boss_banner_text: Label = %BossBannerText
@onready var _boss_sound: AudioStreamPlayer = %BossSound
@onready var _respawn: PanelCard = %Respawn
@onready var _respawn_text: Label = %RespawnText
@onready var _plate: HeroPlate = %HeroPlate


func _ready() -> void:
	visible = false
	set_process(false)


## Liga a HUD ao heroi local e ao mundo da partida. [param players] = pai dos herois.
func bind(hero: Hero, clock: MatchClock, spawns: SpawnDirector, players: Node) -> void:
	_hero = hero
	_clock = clock
	_spawns = spawns
	_players = players
	_rules = clock.rules
	_minimap.bind(hero)
	_collect_world()
	if not spawns.boss_killed.is_connected(_on_spawns_boss_killed):
		spawns.boss_killed.connect(_on_spawns_boss_killed)
		clock.boss_spawned.connect(_on_clock_boss_spawned)
		clock.boss_warning.connect(_on_clock_boss_warning)
	visible = false  # set_active religa a base
	set_active(true)


## Mostra e atualiza (ou esconde e para); ao voltar, a base redesenha sem avisos atrasados.
func set_active(active: bool) -> void:
	if active and not visible:
		_plate.bind(_hero)
	visible = active
	set_process(active)


func _process(_delta: float) -> void:
	if not is_instance_valid(_hero):
		visible = false
		set_process(false)
		return
	var elapsed := maxf(_clock.elapsed(NetworkTime.tick), 0.0)  # cliente ainda sincronizando
	_update_clock(elapsed)
	_plate.update()
	_update_catch_up()
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
	var boss := _spawns.get_node_or_null(SpawnDirector.BOSS_NAME) as Monster
	if _spawns.has_node(SpawnDirector.BOSS_CHEST_NAME):
		_boss_status.text = tr("DERROTADO")
	elif boss_left > 0.0:
		_boss_status.text = tr("surge no centro")
	elif gates_open and boss != null and not boss.present:
		_boss_status.text = tr("SAIU DO MAPA")  # vivo aos 5:00 (R-PEND-06)
	else:
		_boss_status.text = tr("NO CENTRO")


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
	_plate.set_chests(_chests)


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
