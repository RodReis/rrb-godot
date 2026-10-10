extends GutTest
## Logica dos componentes de shared/ui/components (COMPONENTS.md, regra 2).

const STAT_BAR: PackedScene = preload("res://shared/ui/components/stat_bar.tscn")
const SKILL_BUTTON: PackedScene = preload("res://shared/ui/components/skill_button.tscn")
const SLOT_ITEM: PackedScene = preload("res://shared/ui/components/slot_item.tscn")
const KNIGHT: HeroData = preload("res://shared/data/heroes/knight.tres")
const EPIC_SWORD: ItemData = preload("res://shared/data/items/weapons/sword_t3_epic.tres")
const GUARD_BOOTS: ItemData = preload("res://shared/data/items/guard_set/guard_boots_t2.tres")


func test_timer_formats_minutes_and_seconds() -> void:
	assert_eq(TimerLabel.format_seconds(222.9, TimerLabel.Format.MM_SS), "03:42")
	assert_eq(TimerLabel.format_seconds(-3.0, TimerLabel.Format.MM_SS), "00:00")
	assert_eq(TimerLabel.format_seconds(7.9, TimerLabel.Format.SS), "07")


func test_timer_state_changes_variation_and_stops_blinking() -> void:
	var timer: TimerLabel = add_child_autofree(TimerLabel.new())
	timer.set_state(TimerLabel.State.WARNING)
	assert_eq(timer.theme_type_variation, &"LabelCounterWarning")
	timer.set_state(TimerLabel.State.DANGER)
	assert_eq(timer.theme_type_variation, &"LabelCounterDanger")
	assert_eq(timer.modulate.a, 1.0)


func test_stat_bar_bind_sets_variant_and_numbers() -> void:
	var bar: StatBar = add_child_autofree(STAT_BAR.instantiate())
	bar.bind("HP", 300.0, 735.0, StatBar.Kind.HP_ENEMY)
	var progress := bar.get_node("%Bar") as ProgressBar
	assert_eq(progress.max_value, 735.0)
	assert_eq(progress.value, 300.0)
	assert_eq(progress.theme_type_variation, &"ProgressEnemy")
	assert_eq((bar.get_node("%Numbers") as Label).text, "300 / 735")


func test_stat_bar_animates_bar_but_updates_numbers_now() -> void:
	var bar: StatBar = add_child_autofree(STAT_BAR.instantiate())
	bar.bind("XP", 100.0, 300.0, StatBar.Kind.XP)
	bar.animate_to(250.0, UiTokens.DUR_FAST)
	assert_eq((bar.get_node("%Numbers") as Label).text, "250 / 300")
	await wait_seconds(UiTokens.DUR_FAST * 2.0)
	assert_almost_eq((bar.get_node("%Bar") as ProgressBar).value, 250.0, 0.01)


func test_skill_cooldown_text() -> void:
	assert_eq(SkillButton.cooldown_text(3.2), "4")
	assert_eq(SkillButton.cooldown_text(1.0), "1")
	assert_eq(SkillButton.cooldown_text(0.44), "0.4")


func test_skill_states() -> void:
	var button: SkillButton = add_child_autofree(SKILL_BUTTON.instantiate())
	button.bind(KNIGHT.skill_e, 2)
	assert_eq(button.state, SkillButton.State.READY)
	button.set_cooldown(3.0, 8.0)
	assert_eq(button.state, SkillButton.State.COOLING)
	assert_almost_eq(button.value, 0.375, 0.001)
	assert_eq((button.get_node("%Cooldown") as Label).text, "3")
	button.set_cooldown(0.0, 8.0)
	assert_eq(button.state, SkillButton.State.READY)
	button.set_locked(true)
	assert_eq(button.state, SkillButton.State.LOCKED)


func test_skill_locked_shows_required_level_and_upgradable_frame() -> void:
	var button: SkillButton = add_child_autofree(SKILL_BUTTON.instantiate())
	button.bind(KNIGHT.skill_r, 0)
	button.set_locked(true)
	var required := KNIGHT.skill_r.required_hero_level[0]
	assert_eq((button.get_node("%Cooldown") as Label).text, "Nv%d" % required)
	button.set_upgradable(true)
	assert_eq((button.get_node("%Frame") as Panel).theme_type_variation, &"SkillFrameUpgradable")


func test_slot_empty_then_bound_by_rarity() -> void:
	var slot: SlotItem = add_child_autofree(SLOT_ITEM.instantiate())
	assert_true(slot.is_empty())
	assert_eq((slot.get_node("%Frame") as Panel).theme_type_variation, &"FrameEmpty")
	slot.bind(EPIC_SWORD)
	assert_false(slot.is_empty())
	assert_eq((slot.get_node("%Frame") as Panel).theme_type_variation, &"FrameEpic")
	assert_eq((slot.get_node("%Rarity") as Label).text, "Épico")
	slot.clear()
	assert_true(slot.is_empty())


func test_slot_press_emits_slot() -> void:
	var slot: SlotItem = add_child_autofree(SLOT_ITEM.instantiate())
	slot.slot = ItemData.Slot.HELM
	watch_signals(slot)
	slot.pressed.emit()
	assert_signal_emitted_with_parameters(slot, "pressed_slot", [ItemData.Slot.HELM])


func test_item_tooltip_lines() -> void:
	var sword := ItemTooltip.bonus_lines(EPIC_SWORD)
	assert_has(sword, "+%d ATK" % roundi(EPIC_SWORD.attack))
	assert_has(sword, "Passiva: Fúria (%d%%)" % roundi(EPIC_SWORD.passive_value * 100.0))
	var boots := ItemTooltip.bonus_lines(GUARD_BOOTS)
	assert_has(boots, "+%d%% AGI" % roundi(GUARD_BOOTS.agility_pct * 100.0))
	assert_has(boots, "+%d DEF" % roundi(GUARD_BOOTS.defense))


func test_toast_kind_sets_accent_and_text() -> void:
	var toast: Toast = add_child_autofree(Toast.new())
	toast.show_message("Conexão perdida", Toast.Kind.ERROR)
	assert_true(toast.visible)
	assert_eq(toast.accent, PanelCard.Accent.RED)
	assert_eq((toast.get_child(0) as Label).text, "Conexão perdida")


func test_panel_card_variant_and_hotkey_badge() -> void:
	var card := PanelCard.new()
	card.variant = PanelCard.Surface.INNER
	assert_eq(card.theme_type_variation, &"PanelCardInner")
	card.free()
	var badge := HotkeyBadge.new()
	badge.key = "B"
	assert_eq(badge.text, "[B]")
	badge.size_variant = HotkeyBadge.Size.MD
	assert_eq(badge.text, "B")
	badge.free()
