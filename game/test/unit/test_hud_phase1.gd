extends GutTest
## HUD da fase 1 ligada a um Cavaleiro de verdade: so mostra o estado do heroi e do mundo.

const HUD: PackedScene = preload("res://scenes/ui/hud_phase1.tscn")
const KNIGHT: PackedScene = preload("res://scenes/heroes/knight.tscn")
const CHEST: PackedScene = preload("res://scenes/world/chest.tscn")
const RULES: MatchRules = preload("res://shared/data/rules/match_pacing.tres")
const GUARD_HELM: ItemData = preload("res://shared/data/items/guard_set/guard_helm_t1.tres")
const TICKRATE: int = 30

var _players: Node3D
var _hero: Hero
var _clock: MatchClock
var _spawns: SpawnDirector
var _hud: HudPhase1


func before_each() -> void:
	_players = add_child_autofree(Node3D.new())
	_hero = _spawn_hero("1", 1)
	_clock = MatchClock.new()
	_clock.rules = RULES
	add_child_autofree(_clock)
	_spawns = add_child_autofree(SpawnDirector.new())
	_hud = add_child_autofree(HUD.instantiate())


func _spawn_hero(peer: String, level: int) -> Hero:
	var hero := KNIGHT.instantiate() as Hero
	hero.name = peer
	hero.level = level
	_players.add_child(hero)
	return hero


func _bind_and_wait() -> void:
	_hud.bind(_hero, _clock, _spawns, _players)
	await wait_process_frames(2)


func _node(path: String) -> Node:
	return _hud.get_node(path)


func test_hidden_until_bound() -> void:
	assert_false(_hud.visible)
	await _bind_and_wait()
	assert_true(_hud.visible)


func test_plate_shows_name_level_and_hp() -> void:
	await _bind_and_wait()
	assert_eq((_node("%HeroName") as Label).text, "CAVALEIRO")
	assert_eq((_node("%HeroLevel") as Label).text, "NÍVEL 1")
	var hp := "%d / %d" % [_hero.hp, _hero.attributes.max_hp]
	assert_eq((_node("%HpBar").get_node("%Numbers") as Label).text, hp)


func test_r_locked_and_q_ready_at_level_1() -> void:
	await _bind_and_wait()
	assert_eq((_node("%SkillR") as SkillButton).state, SkillButton.State.LOCKED)
	assert_eq((_node("%SkillQ") as SkillButton).state, SkillButton.State.READY)


func test_cooldown_from_hero_state() -> void:
	await _bind_and_wait()
	_hero.q_cooldown = 30
	await wait_process_frames(1)
	assert_eq((_node("%SkillQ") as SkillButton).state, SkillButton.State.COOLING)


func test_new_item_fills_slot_notifies_and_counts_set() -> void:
	await _bind_and_wait()
	_hero.equipment = Inventory.equip(_hero.equipment, GUARD_HELM)
	await wait_process_frames(1)
	assert_false((_node("%Helm") as SlotItem).is_empty())
	var toast := _node("%Toast") as Toast
	assert_true(toast.visible)
	assert_string_contains((toast.get_child(0) as Label).text, GUARD_HELM.display_name)
	assert_string_contains((_node("%SetText") as Label).text, "Guarda 1/3")


func test_catch_up_when_two_levels_behind() -> void:
	_spawn_hero("2", 5)
	await _bind_and_wait()
	assert_true((_node("%CatchUp") as Control).visible)


func test_no_catch_up_alone() -> void:
	await _bind_and_wait()
	assert_false((_node("%CatchUp") as Control).visible)


func test_offer_when_chest_in_reach_holds_an_item() -> void:
	var chest := CHEST.instantiate() as Chest
	_spawns.add_child(chest)
	chest.opened = true
	chest.item = Ids.to_int(GUARD_HELM.id)
	await _bind_and_wait()
	var offer := _node("%Offer") as Control
	assert_true(offer.visible)
	assert_string_contains((_node("%OfferText") as Label).text, GUARD_HELM.display_name)
	_hero.global_position = Vector3(50.0, 0.0, 0.0)
	await wait_process_frames(1)
	assert_false(offer.visible)


func test_boss_warning_shows_banner_with_time_from_rules() -> void:
	await _bind_and_wait()
	_clock._begin(0, TICKRATE)
	_clock.boss_warning.emit(roundi(RULES.boss_warning_time * TICKRATE))
	var banner := _node("%BossBanner") as Control
	assert_true(banner.visible)
	var seconds := roundi(RULES.boss_spawn_time - RULES.boss_warning_time)
	assert_string_contains((_node("%BossBannerText") as Label).text, "%d s" % seconds)


func test_late_join_after_boss_spawn_gets_no_banner() -> void:
	await _bind_and_wait()
	_clock._begin(0, TICKRATE)
	_clock.boss_warning.emit(roundi((RULES.boss_spawn_time + 10.0) * TICKRATE))
	assert_false((_node("%BossBanner") as Control).visible)
