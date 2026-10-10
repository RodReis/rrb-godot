class_name HudPhase2
extends CanvasLayer
## HUD da fase 2 (DV tela 4, ARCHITECTURE-GAME §3.6), da TRANSITION (5:00) ao fim: relogio ate o
## colapso, placar de kills (ScoreBanner), painel da zona (raio, dano fora, proximo fechamento),
## minimapa com o ZoneRadar por cima, estado do respawn (ativo ate a morte subita, desligado
## depois), aviso dos portoes na transicao, aviso da morte subita e vinheta vermelha quando o
## heroi local esta fora da zona. So consome sinais (phase_changed, kill_scored, zone_updated) e
## estado replicado (heroi, relogio); tempos e numeros vem de MatchRules. A base de combate e a
## mesma da fase 1 (HeroPlate). Escondida ate o HudController ativar. No match_ended para e sai
## da tela: a tela de fim (MatchEnd, F18) assume.

## Aviso de fase some sozinho (PATTERNS P7); a transicao fica os 5 s dela.
const BANNER_SECONDS: float = 3.0
## Entrada do aviso dos portoes: desce estes px com fade.
const BANNER_DROP: float = 40.0
## Tremida da camera na queda dos portoes (u) e quantos passos de DUR_FAST/2.
const SHAKE_AMPLITUDE: float = 0.3
const SHAKE_STEPS: int = 8
## Opacidade minima do pisca da morte subita.
const STROBE_ALPHA: float = 0.25
const PERCENT: float = 100.0

var _hero: Hero
var _clock: MatchClock
var _spawns: SpawnDirector
var _players: Node
var _match: MatchController
var _rules: MatchRules
var _kills: Dictionary = {}  # peer -> kills na fase 2 (kill_scored)
## Ultimo zone_updated: dano fora (fracao do HP max/s).
var _damage_pct: float = 0.0
var _fade_ticks: int = 0
var _radar_positions: PackedVector3Array = PackedVector3Array()
var _radar_colors: PackedColorArray = PackedColorArray()
var _transition_tween: Tween
var _sudden_tween: Tween
var _shake_tween: Tween
## Partida encerrada: a HUD fica parada na tela.
var _ended: bool = false

@onready var _vignette: ColorRect = %ZoneVignette
@onready var _phase_title: Label = %PhaseTitle
@onready var _phase_timer: TimerLabel = %PhaseTimer
@onready var _score: ScoreBanner = %ScoreBanner
@onready var _zone_radius: Label = %ZoneRadius
@onready var _zone_damage: Label = %ZoneDamage
@onready var _zone_timer: TimerLabel = %ZoneTimer
@onready var _minimap: Minimap = %Minimap
@onready var _radar: ZoneRadar = %ZoneRadar
@onready var _respawn_state: Label = %RespawnState
@onready var _respawn_hint: Label = %RespawnHint
@onready var _respawn_timer: TimerLabel = %RespawnTimer
@onready var _transition: PanelCard = %TransitionBanner
@onready var _transition_timer: TimerLabel = %TransitionTimer
@onready var _transition_sound: AudioStreamPlayer = %TransitionSound
@onready var _sudden: PanelCard = %SuddenDeathBanner
@onready var _sudden_text: Label = %SuddenDeathText
@onready var _sudden_sound: AudioStreamPlayer = %SuddenDeathSound
@onready var _respawn: PanelCard = %Respawn
@onready var _respawn_title: Label = %RespawnTitle
@onready var _respawn_text: Label = %RespawnText
@onready var _plate: HeroPlate = %HeroPlate


func _ready() -> void:
	visible = false
	set_process(false)
	var shader := _vignette.material as ShaderMaterial
	shader.set_shader_parameter(&"color", UiTokens.RED)
	shader.set_shader_parameter(&"pulse_period", UiTokens.PULSE_ZONE)
	_vignette.visible = false


## Liga a HUD ao heroi local, ao mundo e aos sinais da partida. [param players] = pai dos herois.
func bind(
	hero: Hero,
	clock: MatchClock,
	spawns: SpawnDirector,
	players: Node,
	match_controller: MatchController,
	zone: ZoneController
) -> void:
	_hero = hero
	_clock = clock
	_spawns = spawns
	_players = players
	_match = match_controller
	_rules = clock.rules
	_fade_ticks = SkillRules.seconds_to_ticks(Hero.ZONE_FADE_SECONDS, NetworkTime.tickrate)
	_minimap.bind(hero)
	_radar.world_extent = _minimap.world_extent
	_radar.full_radius = _rules.zone_radius[0]
	if not zone.zone_updated.is_connected(_on_zone_updated):
		zone.zone_updated.connect(_on_zone_updated)
		match_controller.kill_scored.connect(_on_match_kill_scored)
		match_controller.phase_changed.connect(_on_match_phase_changed)
		match_controller.match_ended.connect(_on_match_ended)


## Mostra e atualiza (ou esconde e para). Ao aparecer, a base, o placar e os baus sao relidos.
func set_active(active: bool) -> void:
	if active and not visible:
		_plate.bind(_hero)
		_plate.set_chests(_chests())
		_refresh_score()
	visible = active
	set_process(active and not _ended)


func _process(_delta: float) -> void:
	if not is_instance_valid(_hero):
		visible = false
		set_process(false)
		return
	var elapsed := maxf(_clock.elapsed(NetworkTime.tick), 0.0)
	_update_clock(elapsed)
	_update_respawn_state(elapsed)
	_plate.update()
	_update_vignette()
	_update_map()
	_update_respawn()


func _update_clock(elapsed: float) -> void:
	var sudden := _match.state == MatchState.State.SUDDEN_DEATH
	_phase_timer.set_seconds(HudMath.until(_rules.max_match_duration, elapsed))
	_phase_timer.set_state(TimerLabel.State.DANGER if sudden else TimerLabel.State.NORMAL)
	if _match.state == MatchState.State.TRANSITION:
		_phase_title.text = tr("OS PORTÕES CAÍRAM")
	elif sudden:
		_phase_title.text = tr("MORTE SÚBITA")
	else:
		_phase_title.text = tr("FASE 2: CONFRONTO")
	_transition_timer.set_seconds(
		HudMath.until(_rules.phase1_duration + _rules.transition_duration, elapsed)
	)


## Respawn ativo ate a morte subita (9:00); depois desligado, contando ate o colapso (10:00).
func _update_respawn_state(elapsed: float) -> void:
	if _match.state == MatchState.State.SUDDEN_DEATH:
		_respawn_state.text = tr("RESPAWN DESLIGADO")
		_respawn_hint.text = tr("Colapso total em")
		_respawn_timer.set_seconds(HudMath.until(_rules.max_match_duration, elapsed))
		_respawn_timer.set_state(TimerLabel.State.DANGER)
		return
	_respawn_state.text = tr("RESPAWN ATIVO: %s s") % HudMath.decimal(_rules.respawn_phase2)
	_respawn_hint.text = tr("Morte súbita em")
	var sudden_at := _rules.phase1_duration + _rules.respawn_off_at
	var left := HudMath.until(sudden_at, elapsed)
	_respawn_timer.set_seconds(left)
	_respawn_timer.set_state(
		TimerLabel.State.WARNING if HudMath.is_warning(left) else TimerLabel.State.NORMAL
	)


## Fora da zona = flag do servidor no heroi local (Hero.zone_ticks), nunca a posicao (P8).
func _update_vignette() -> void:
	var intensity := HudMath.zone_vignette(_rules, _damage_pct, _hero.zone_ticks, _fade_ticks)
	_vignette.visible = intensity > 0.0
	if _vignette.visible:
		(_vignette.material as ShaderMaterial).set_shader_parameter(&"intensity", intensity)


## Herois no radar (verde = eu, vermelho = adversario); o minimapa so gira junto.
func _update_map() -> void:
	var camera := get_viewport().get_camera_3d()
	if camera != null:
		_minimap.set_yaw(camera.global_rotation.y)
		_radar.set_yaw(camera.global_rotation.y)
	_radar_positions.clear()
	_radar_colors.clear()
	for node: Node in _players.get_children():
		var hero := node as Hero
		if hero != null and hero.is_alive():
			_radar_positions.append(hero.global_position)
			_radar_colors.append(UiTokens.GREEN if hero == _hero else UiTokens.RED)
	_radar.set_players(_radar_positions, _radar_colors)


## Morto: segundos ate renascer (respawn_ticks replicado); na morte subita nao renasce.
func _update_respawn() -> void:
	_respawn.visible = not _hero.is_alive()
	if not _respawn.visible:
		return
	if _match.state == MatchState.State.SUDDEN_DEATH:
		_respawn_title.text = tr("ELIMINADO!")
		_respawn_text.text = tr("Respawn desligado na morte súbita")
		return
	_respawn_title.text = tr("VOCÊ FOI ABATIDO!")
	var seconds := ceili(float(_hero.respawn_ticks) / NetworkTime.tickrate)
	_respawn_text.text = tr("Renascendo na base em %d s") % seconds


func _refresh_score() -> void:
	var me := ScoreBanner.PlayerScore.new(
		_hero.hero_data.display_name.to_upper(), _kills.get(_hero.peer_id, 0), true
	)
	var them := ScoreBanner.PlayerScore.new(tr("OPONENTE"), 0, false)
	for node: Node in _players.get_children():
		var other := node as Hero
		if other != null and other != _hero:
			them.name = other.hero_data.display_name.to_upper()
			them.kills = _kills.get(other.peer_id, 0)
	_score.bind(me, them, _rules.kill_goal)


func _chests() -> Array[Chest]:
	var result: Array[Chest] = []
	for node: Node in _spawns.get_children():
		if node is Chest:
			result.append(node as Chest)
	return result


## Portoes caem (5:00): aviso central desce com fade e fica a transicao toda, camera treme, som.
func _show_transition() -> void:
	_transition.visible = true
	_transition.modulate.a = 0.0
	var rest := _transition.position.y
	_transition.position.y = rest - BANNER_DROP
	if _transition_tween != null:
		_transition_tween.kill()
	_transition_tween = create_tween()
	_transition_tween.set_parallel()
	_transition_tween.tween_property(_transition, ^"modulate:a", 1.0, UiTokens.DUR_SLOW)
	_transition_tween.tween_property(_transition, ^"position:y", rest, UiTokens.DUR_SLOW).set_trans(
		Tween.TRANS_CUBIC
	)
	_transition_tween.set_parallel(false)
	_transition_tween.tween_interval(_rules.transition_duration - UiTokens.DUR_SLOW * 2.0)
	_transition_tween.tween_property(_transition, ^"modulate:a", 0.0, UiTokens.DUR_SLOW)
	_transition_tween.tween_callback(_transition.hide)
	_transition_sound.play()
	_shake()


## Tremida curta da camera pelos offsets (o follow_camera nao usa h/v_offset).
func _shake() -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	if _shake_tween != null:
		_shake_tween.kill()
	_shake_tween = create_tween()
	var step := UiTokens.DUR_FAST / 2.0
	for i: int in SHAKE_STEPS:
		var fade := 1.0 - float(i) / SHAKE_STEPS
		var amount := SHAKE_AMPLITUDE * fade * (1.0 if i % 2 == 0 else -1.0)
		_shake_tween.tween_property(camera, ^"h_offset", amount, step)
		_shake_tween.parallel().tween_property(camera, ^"v_offset", -amount / 2.0, step)
	_shake_tween.tween_property(camera, ^"h_offset", 0.0, step)
	_shake_tween.parallel().tween_property(camera, ^"v_offset", 0.0, step)


## 9:00: aviso vermelho piscando (estroboscopico), some em BANNER_SECONDS; som.
func _show_sudden_death() -> void:
	var collapse := TimerLabel.format_seconds(_rules.max_match_duration, TimerLabel.Format.MM_SS)
	_sudden_text.text = tr("Respawn desligado · colapso total da zona aos %s") % collapse
	_sudden.visible = true
	_sudden.modulate.a = 1.0
	if _sudden_tween != null:
		_sudden_tween.kill()
	_sudden_tween = create_tween()
	var flashes := floori(BANNER_SECONDS / (UiTokens.DUR_FAST * 2.0))
	for i: int in flashes:
		_sudden_tween.tween_property(_sudden, ^"modulate:a", STROBE_ALPHA, UiTokens.DUR_FAST)
		_sudden_tween.tween_property(_sudden, ^"modulate:a", 1.0, UiTokens.DUR_FAST)
	_sudden_tween.tween_property(_sudden, ^"modulate:a", 0.0, UiTokens.DUR_SLOW)
	_sudden_tween.tween_callback(_sudden.hide)
	_sudden_sound.play()


func _on_match_phase_changed(_from: int, to: int, _tick: int) -> void:
	if to == MatchState.State.TRANSITION:
		_show_transition()
	elif to == MatchState.State.SUDDEN_DEATH:
		_show_sudden_death()


## Fim (meta, eliminacao, colapso): para tudo, tira respawn e avisos e sai da tela.
func _on_match_ended(_winner: int, _reason: StringName, _stats: MatchStats, _tick: int) -> void:
	_ended = true
	set_process(false)
	for node: Control in [_respawn, _transition, _sudden]:
		node.hide()
	_vignette.hide()
	visible = false


func _on_match_kill_scored(peer: int, total: int, _tick: int) -> void:
	_kills[peer] = total
	_refresh_score()


func _on_zone_updated(
	radius: float, next_radius: float, damage_pct: float, t_next: float, _tick: int
) -> void:
	_damage_pct = damage_pct
	var fraction := HudMath.zone_fraction(_rules, radius)
	_zone_radius.text = (
		tr("Raio %d%% · %s u") % [roundi(fraction * PERCENT), HudMath.decimal(radius)]
	)
	_zone_damage.text = tr("Dano fora: %s%% do HP/s") % HudMath.decimal(damage_pct * PERCENT)
	_zone_timer.set_seconds(t_next)
	_radar.set_zone(fraction, HudMath.zone_fraction(_rules, next_radius), t_next)
