extends GutTest
## HUD da fase 2 (F17, DV tela 4) e a troca pelo HudController: reage aos sinais phase_changed,
## kill_scored e zone_updated e ao estado replicado do heroi local, sem chamar regra
## (ARCHITECTURE-GAME §3.6). Os sinais sao emitidos direto, como chegariam do servidor.

const HUD: PackedScene = preload("res://scenes/ui/hud.tscn")
const KNIGHT: PackedScene = preload("res://scenes/heroes/knight.tscn")
const RANGER: PackedScene = preload("res://scenes/heroes/ranger.tscn")
const RULES: MatchRules = preload("res://shared/data/rules/match_pacing.tres")
const TICKRATE: int = 30
const ME: int = 1
const THEM: int = 2

var _players: Node3D
var _hero: Hero
var _clock: MatchClock
var _spawns: SpawnDirector
var _match: MatchController
var _zone: ZoneController
var _hud: HudController
var _phase2: HudPhase2


func before_each() -> void:
	_players = add_child_autofree(Node3D.new())
	_hero = _spawn(KNIGHT, ME, Vector3(1, 0, 1))
	_spawn(RANGER, THEM, Vector3(-1, 0, -1))
	_clock = MatchClock.new()
	_clock.rules = RULES
	add_child_autofree(_clock)
	_spawns = add_child_autofree(SpawnDirector.new())
	_match = MatchController.new()
	_match.rules = RULES
	add_child_autofree(_match)
	_zone = ZoneController.new()
	_zone.rules = RULES
	_zone.clock = _clock
	add_child_autofree(_zone)
	_hud = add_child_autofree(HUD.instantiate())
	_phase2 = _hud.get_node("HudPhase2") as HudPhase2


func _spawn(scene: PackedScene, peer: int, where: Vector3) -> Hero:
	var hero := scene.instantiate() as Hero
	hero.name = str(peer)
	hero.transform = Transform3D(Basis(), where)
	_players.add_child(hero)
	return hero


func _bind() -> void:
	_hud.bind(_hero, _clock, _spawns, _players, _match, _zone)
	_clock._begin(0, TICKRATE)


func _phase(to: MatchState.State) -> void:
	var from := _match.state
	_match.state = to
	_match.phase_changed.emit(from, to, roundi(RULES.phase1_duration * TICKRATE))


func _node(path: String) -> Node:
	return _phase2.get_node(path)


func _texts(root: Node) -> Array[String]:
	var result: Array[String] = []
	for label: Node in root.find_children("*", "Label", true, false):
		result.append((label as Label).text)
	return result


func test_fase_1_mostra_a_hud_1_e_a_transicao_troca_para_a_2() -> void:
	_bind()
	var phase1 := _hud.get_node("HudPhase1") as HudPhase1
	assert_true(phase1.visible)
	assert_false(_phase2.visible)
	_phase(MatchState.State.PHASE1)
	assert_true(phase1.visible)
	_phase(MatchState.State.TRANSITION)
	assert_false(phase1.visible)
	assert_false(phase1.is_processing())
	assert_true(_phase2.visible)
	assert_true(_phase2.is_processing())


func test_bind_no_meio_da_fase_2_ja_mostra_a_hud_2() -> void:
	_match.state = MatchState.State.PHASE2
	_bind()
	assert_true(_phase2.visible)
	assert_true(_hud.is_bound())


func test_transicao_mostra_o_aviso_dos_portoes() -> void:
	_bind()
	_phase(MatchState.State.TRANSITION)
	var banner := _node("%TransitionBanner") as Control
	assert_true(banner.visible)
	assert_has(_texts(banner), "OS PORTÕES DA ARENA CAÍRAM!")


func test_morte_subita_mostra_o_aviso_e_desliga_o_respawn() -> void:
	_bind()
	_phase(MatchState.State.TRANSITION)
	_phase(MatchState.State.PHASE2)
	assert_false((_node("%SuddenDeathBanner") as Control).visible)
	assert_string_contains((_node("%RespawnState") as Label).text, "ATIVO")
	_phase(MatchState.State.SUDDEN_DEATH)
	assert_true((_node("%SuddenDeathBanner") as Control).visible)
	_phase2._process(0.0)
	assert_eq((_node("%RespawnState") as Label).text, "RESPAWN DESLIGADO")


func test_kill_scored_atualiza_o_placar() -> void:
	_bind()
	_phase(MatchState.State.TRANSITION)
	_match.kill_scored.emit(ME, 1, 100)
	_match.kill_scored.emit(THEM, 1, 110)
	_match.kill_scored.emit(ME, 2, 120)
	var banner := _node("%ScoreBanner") as ScoreBanner
	var texts := _texts(banner)
	assert_has(texts, "CAVALEIRO (VOCÊ)")
	assert_has(texts, "ARQUEIRA (OPONENTE)")
	assert_has(texts, "2")
	assert_has(texts, "1")
	assert_has(texts, "META: %d KILLS" % RULES.kill_goal)


func test_zone_updated_atualiza_painel_e_radar() -> void:
	_bind()
	_phase(MatchState.State.TRANSITION)
	_zone.zone_updated.emit(17.5, 8.75, 0.03, 45.0, 100)
	assert_eq((_node("%ZoneRadius") as Label).text, "Raio 50% · 17,5 u")
	assert_eq((_node("%ZoneDamage") as Label).text, "Dano fora: 3,0% do HP/s")
	assert_eq((_node("%ZoneTimer") as TimerLabel).text, "00:45")
	var radar := _node("%ZoneRadar") as ZoneRadar
	assert_almost_eq(radar.radius_pct, 0.5, 0.0001)
	assert_almost_eq(radar.next_radius_pct, 0.25, 0.0001)


## Vinheta (PATTERNS P8): pelo flag do servidor no heroi, nunca pela posicao.
func test_vinheta_so_com_o_flag_do_servidor_e_pelo_dano() -> void:
	_bind()
	_phase(MatchState.State.TRANSITION)
	_zone.zone_updated.emit(35.0, 26.0, 0.05, 60.0, 100)
	var vignette := _node("%ZoneVignette") as ColorRect
	_hero.global_position = Vector3(100, 0, 0)  # longe: o cliente nao decide pela posicao
	_phase2._process(0.0)
	assert_false(vignette.visible)
	_hero.zone_ticks = 45
	_phase2._process(0.0)
	assert_true(vignette.visible)
	var shader := vignette.material as ShaderMaterial
	assert_almost_eq(shader.get_shader_parameter(&"intensity") as float, 1.0, 0.0001)
	_zone.zone_updated.emit(35.0, 26.0, 0.01, 60.0, 130)
	_phase2._process(0.0)
	assert_almost_eq(shader.get_shader_parameter(&"intensity") as float, 0.2, 0.0001)


func test_morto_na_fase_2_mostra_o_respawn() -> void:
	_bind()
	_phase(MatchState.State.PHASE2)
	_hero.hp = 0
	_hero.respawn_ticks = 3 * TICKRATE
	_phase2._process(0.0)
	assert_true((_node("%Respawn") as Control).visible)
	assert_eq((_node("%RespawnText") as Label).text, "Renascendo na base em 3 s")


## Fim da partida: a HUD para, some o respawn e ela sai da tela; a tela de fim (F18, MatchEnd)
## assume com o resultado.
func test_fim_da_partida_para_e_esconde_a_hud() -> void:
	_bind()
	_phase(MatchState.State.PHASE2)
	_hero.hp = 0
	_hero.respawn_ticks = 6 * TICKRATE
	_phase2._process(0.0)
	_phase(MatchState.State.ENDED)
	_match.match_ended.emit(THEM, VictoryRules.KILL_GOAL, MatchStats.new(), 200)
	assert_false(_phase2.is_processing())
	assert_false((_node("%Respawn") as Control).visible)
	assert_false(_phase2.visible)
	_phase2.set_active(true)
	assert_false(_phase2.is_processing(), "religar depois do fim nao volta a correr")


func test_bind_so_com_heroi_ligado() -> void:
	assert_false(_hud.is_bound(), "sem heroi ainda")
	_bind()
	assert_true(_hud.is_bound())
