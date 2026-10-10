extends Control
## Galeria do design system (COMPONENTS.md, regra 1): cada componente em cada variante/estado,
## lado a lado. E o que o PI olha na verificacao visual. Dados de exemplo saem de shared/data.
## Cada exemplo entra na arvore antes do bind (os @onready dos componentes precisam disso).

const STAT_BAR: PackedScene = preload("res://shared/ui/components/stat_bar.tscn")
const SKILL_BUTTON: PackedScene = preload("res://shared/ui/components/skill_button.tscn")
const SLOT_ITEM: PackedScene = preload("res://shared/ui/components/slot_item.tscn")
const PREVIEW: PackedScene = preload("res://shared/ui/components/monster_preview_3d.tscn")
const SKELETON_MODEL: PackedScene = preload(
	"res://shared/assets/kaykit/skeletons/Skeleton_Minion.glb"
)
const MONSTERS: Array[MonsterData] = [
	preload("res://shared/data/monsters/skeleton_t1.tres"),
	preload("res://shared/data/monsters/skeleton_king_boss.tres"),
]
const KNIGHT: HeroData = preload("res://shared/data/heroes/knight.tres")
const RANGER: HeroData = preload("res://shared/data/heroes/ranger.tres")
const RULES: MatchRules = preload("res://shared/data/rules/match_pacing.tres")
const ITEMS: Array[ItemData] = [
	preload("res://shared/data/items/guard_set/guard_helm_t1.tres"),
	preload("res://shared/data/items/guard_set/guard_chest_t2.tres"),
	preload("res://shared/data/items/weapons/sword_t3_epic.tres"),
]
## Toast da galeria fica na tela.
const TOAST_FOREVER: float = 3600.0
const CARD_SIZE: Vector2 = Vector2(180, 72)
const RADAR_SIZE: Vector2 = Vector2(160, 160)

## Secoes na coluna esquerda; as seguintes vao para a direita.
const LEFT_SECTIONS: int = 5

var _sections: int = 0

@onready var _left: VBoxContainer = %Left
@onready var _right: VBoxContainer = %Right


func _ready() -> void:
	_typography()
	_buttons()
	_panels()
	_badges()
	_stat_bars()
	_timers()
	_skills()
	_slots()
	_toasts()
	_catalog()
	_scores()
	_radars()


func _typography() -> void:
	var row := _row("Tipografia")
	for type: StringName in [
		&"LabelVictory",
		&"LabelH1",
		&"LabelH2",
		&"LabelBody",
		&"LabelCounter",
		&"LabelBadge",
		&"LabelMuted",
	]:
		var label := Label.new()
		label.theme_type_variation = type
		label.text = "03:42" if type == &"LabelCounter" else "Rei Esqueleto"
		_add(row, label, type)


func _buttons() -> void:
	var row := _row("Botões (Tab mostra o foco)")
	for type: StringName in [&"Button", &"ButtonPrimary", &"ButtonDanger"]:
		var button := Button.new()
		button.theme_type_variation = type if type != &"Button" else &""
		button.text = "Jogar"
		_add(row, button, type)
	var disabled := Button.new()
	disabled.text = "Jogar"
	disabled.disabled = true
	_add(row, disabled, "disabled")


func _panels() -> void:
	var row := _row("PanelCard")
	for variant: int in PanelCard.Surface.values():
		_add(row, _card(variant, PanelCard.Accent.NONE), _name(PanelCard.Surface, variant))
	for accent: int in PanelCard.Accent.values():
		if accent != PanelCard.Accent.NONE:
			var caption := "PANEL + %s" % _name(PanelCard.Accent, accent)
			_add(row, _card(PanelCard.Surface.PANEL, accent), caption)


func _badges() -> void:
	var row := _row("HotkeyBadge")
	for key: String in ["Q", "F", "B"]:
		var badge := HotkeyBadge.new()
		badge.key = key
		_add(row, badge, "SM")
	var md := HotkeyBadge.new()
	md.size_variant = HotkeyBadge.Size.MD
	md.key = "Q"
	_add(row, md, "MD")


func _stat_bars() -> void:
	var row := _row("StatBar")
	var samples: Array[Array] = [
		["HP", 735.0, 735.0, StatBar.Kind.HP, true],
		["HP", 240.0, 600.0, StatBar.Kind.HP_ENEMY, true],
		["XP", 180.0, 300.0, StatBar.Kind.XP, true],
		["ATK", 45.0, 100.0, StatBar.Kind.STAT, false],
	]
	for sample: Array in samples:
		var bar := STAT_BAR.instantiate() as StatBar
		var variant: StatBar.Kind = sample[3]
		_add(row, bar, _name(StatBar.Kind, variant))
		bar.show_numbers = sample[4]
		bar.bind(sample[0], sample[1], sample[2], variant)


func _timers() -> void:
	var row := _row("TimerLabel")
	var samples: Array[Array] = [
		[222.0, TimerLabel.State.NORMAL, TimerLabel.Format.MM_SS],
		[285.0, TimerLabel.State.WARNING, TimerLabel.Format.MM_SS],
		[12.0, TimerLabel.State.DANGER, TimerLabel.Format.MM_SS],
		[7.0, TimerLabel.State.NORMAL, TimerLabel.Format.SS],
	]
	for sample: Array in samples:
		var timer := TimerLabel.new()
		var state: TimerLabel.State = sample[1]
		timer.format = sample[2]
		_add(row, timer, _name(TimerLabel.State, state))
		timer.set_seconds(sample[0])
		timer.set_state(state)


func _skills() -> void:
	var row := _row("SkillButton")
	# skill, tecla, rank, recarga restante (s), bloqueada, ponto livre, legenda
	var samples: Array[Array] = [
		[KNIGHT.skill_q, "Q", 2, 0.0, false, false, "READY"],
		[KNIGHT.skill_e, "E", 2, 3.4, false, false, "COOLING"],
		[KNIGHT.basic_attack, "LMB", 1, 0.6, false, false, "COOLING < 1 s"],
		[KNIGHT.skill_q, "Q", 1, 0.0, false, true, "upgradable"],
		[KNIGHT.skill_r, "R", 0, 0.0, true, false, "LOCKED"],
		[KNIGHT.skill_r, "R", 0, 0.0, true, true, "LOCKED + upgradable"],
	]
	for sample: Array in samples:
		var button := SKILL_BUTTON.instantiate() as SkillButton
		var skill: SkillData = sample[0]
		var rank: int = sample[2]
		button.hotkey = sample[1]
		_add(row, button, sample[6])
		button.bind(skill, rank)
		button.set_cooldown(sample[3], SkillData.at_rank(skill.cooldown, maxi(rank, 1)))
		button.set_locked(sample[4])
		button.set_upgradable(sample[5])


func _slots() -> void:
	var row := _row("SlotItem (passe o mouse: tooltip)")
	var empty := SLOT_ITEM.instantiate() as SlotItem
	empty.slot = ItemData.Slot.BOOTS
	_add(row, empty, "vazio")
	for item: ItemData in ITEMS:
		var slot := SLOT_ITEM.instantiate() as SlotItem
		slot.slot = item.slot
		_add(row, slot, ItemData.RARITY_NAMES[item.rarity])
		slot.bind(item)
	var tooltip := ItemTooltip.new()
	_add(row, tooltip, "ItemTooltip")
	tooltip.bind(ITEMS[ITEMS.size() - 1])


func _toasts() -> void:
	var row := _row("Toast")
	var samples: Array[String] = [
		"Baú comum aberto: +100 HP",
		"Elmo da Guarda equipado",
		"O Rei Esqueleto desperta em 0:30",
		"Conexão perdida",
	]
	for kind: int in Toast.Kind.values():
		var toast := Toast.new()
		toast.custom_minimum_size = CARD_SIZE
		_add(row, toast, _name(Toast.Kind, kind))
		toast.show_message(samples[kind], kind, TOAST_FOREVER)


func _catalog() -> void:
	var row := _row("CatalogList + DetailCard + MonsterPreview3D (setas)")
	var list := CatalogList.new()
	_add(row, list, "CatalogList")
	var detail := DetailCard.new()
	detail.custom_minimum_size = CARD_SIZE * 2.0
	_add(row, detail, "DetailCard")
	var preview := PREVIEW.instantiate() as MonsterPreview3D
	preview.custom_minimum_size = CARD_SIZE * 1.5
	_add(row, preview, "MonsterPreview3D")
	preview.show_model(SKELETON_MODEL.instantiate() as Node3D)
	list.selected.connect(
		func(id: StringName) -> void:
			for monster: MonsterData in MONSTERS:
				if monster.id == id:
					detail.bind(monster)
	)
	var entries: Array[CatalogEntry] = []
	for monster: MonsterData in MONSTERS:
		entries.append(CatalogEntry.new(monster.id, monster.display_name))
	list.bind(entries)


func _scores() -> void:
	var row := _row("ScoreBanner")
	# kills de quem joga, do adversario, legenda
	var samples: Array[Array] = [[3, 2, "líder: você"], [1, 4, "líder: oponente"], [2, 2, "empate"]]
	for sample: Array in samples:
		var banner := ScoreBanner.new()
		_add(row, banner, sample[2])
		banner.bind(
			ScoreBanner.PlayerScore.new(KNIGHT.display_name.to_upper(), sample[0], true),
			ScoreBanner.PlayerScore.new(RANGER.display_name.to_upper(), sample[1], false),
			RULES.kill_goal
		)


func _radars() -> void:
	var row := _row("ZoneRadar (por cima do Minimap na HUD F2)")
	# fracao do raio, fracao do proximo, segundos ate ele, legenda
	var samples: Array[Array] = [
		[1.0, 0.75, 60.0, "5:00 (arena toda)"],
		[0.5, 0.25, 45.0, "7:15"],
		[0.1, 0.0, 0.0, "morte súbita"],
	]
	var players := PackedVector3Array([Vector3(0.2, 0.0, 0.3), Vector3(-0.6, 0.0, -0.5)])
	var colors := PackedColorArray([UiTokens.GREEN, UiTokens.RED])
	for sample: Array in samples:
		var card := PanelCard.new()
		card.variant = PanelCard.Surface.SURFACE
		var radar := ZoneRadar.new()
		radar.custom_minimum_size = RADAR_SIZE
		card.add_child(radar)
		_add(row, card, sample[3])
		radar.set_zone(sample[0], sample[1], sample[2])
		radar.set_players(players, colors)


func _card(variant: PanelCard.Surface, accent: PanelCard.Accent) -> PanelCard:
	var card := PanelCard.new()
	card.variant = variant
	card.accent = accent
	card.custom_minimum_size = CARD_SIZE
	var label := Label.new()
	label.text = "Card"
	card.add_child(label)
	return card


## Linha com titulo, ja na arvore.
func _row(title: String) -> HFlowContainer:
	var column := _left if _sections < LEFT_SECTIONS else _right
	_sections += 1
	var label := Label.new()
	label.theme_type_variation = &"LabelH2"
	label.text = title
	column.add_child(label)
	var row := HFlowContainer.new()
	column.add_child(row)
	column.add_child(HSeparator.new())
	return row


## Exemplo com a legenda embaixo.
func _add(row: HFlowContainer, control: Control, caption: String) -> void:
	var box := VBoxContainer.new()
	control.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	box.add_child(control)
	var label := Label.new()
	label.theme_type_variation = &"LabelBadge"
	label.text = caption
	box.add_child(label)
	row.add_child(box)


func _name(values: Dictionary, value: int) -> String:
	return values.find_key(value)
