extends GutTest
## SkillButton com skill sem rank aprendivel (Ocultista ate o F78, COMPONENTS.md regra 2).

const SKILL_BUTTON: PackedScene = preload("res://shared/ui/components/skill_button.tscn")


## R sem ponto aprendivel (max_rank 0, Ocultista ate o F78): travado sem "Nv" que nunca chega.
func test_skill_without_learnable_rank_shows_unavailable_not_a_level() -> void:
	var button: SkillButton = add_child_autofree(SKILL_BUTTON.instantiate())
	var occultist := load("res://shared/data/heroes/occultist.tres") as HeroData
	button.bind(occultist.skill_r, 0)
	button.set_locked(true)
	var label := button.get_node("%Cooldown") as Label
	assert_eq(label.text, SkillButton.UNAVAILABLE_TEXT)
	assert_true(button.tooltip_text.contains("em breve"))
	button.set_upgradable(false)
	assert_eq(label.text, SkillButton.UNAVAILABLE_TEXT)
