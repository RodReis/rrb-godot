extends Control
## Galeria do design system (COMPONENTS.md, regra 1): cada componente em cada variante/estado,
## lado a lado. E o que o PI olha na verificacao visual. Dados de exemplo saem de shared/data.
## Cada exemplo entra na arvore antes do bind (os @onready dos componentes precisam disso).

const STAT_BAR: PackedScene = preload("res://shared/ui/components/stat_bar.tscn")
const SKILL_BUTTON: PackedScene = preload("res://shared/ui/components/skill_button.tscn")
const SLOT_ITEM: PackedScene = preload("res://shared/ui/components/slot_item.tscn")
const TARGET_FRAME: PackedScene = preload("res://shared/ui/components/target_frame.tscn")
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
## Demo da ghost bar: um golpe a cada [constant GHOST_PERIOD] s; cura cheia ao zerar.
const GHOST_PERIOD: float = 1.5
const GHOST_HIT: float = 0.2
const GHOST_MAX_HP: float = 600.0

## Secoes na coluna esquerda; as seguintes vao para a direita.
const LEFT_SECTIONS: int = 5
## Launcher (F24): tamanho de cada exemplo de StateBox e largura dos blocos de tela.
const STATE_SIZE: Vector2 = Vector2(200, 120)
const SCREEN_BLOCK_WIDTH: float = 760.0

var _sections: int = 0
## Bloco do topo: tipos Ln* e componentes do Launcher (F24).
var _launcher: VBoxContainer = VBoxContainer.new()

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
	_target_frames()
	# Launcher no topo, largura cheia; as duas colunas da HUD embaixo.
	var columns := _left.get_parent()
	var margin := columns.get_parent()
	margin.remove_child(columns)
	var stack := VBoxContainer.new()
	margin.add_child(stack)
	stack.add_child(_launcher)
	stack.add_child(columns)
	_launcher_typography()
	_launcher_buttons()
	_launcher_controls()
	_launcher_panels()
	_launcher_chrome()
	_launcher_states()


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
	var ghost := STAT_BAR.instantiate() as StatBar
	_add(row, ghost, "ghost (dano a cada %.1f s)" % GHOST_PERIOD)
	ghost.bind("HP", GHOST_MAX_HP, GHOST_MAX_HP, StatBar.Kind.HP_ENEMY)
	var timer := Timer.new()
	timer.wait_time = GHOST_PERIOD
	timer.autostart = true
	ghost.add_child(timer)
	timer.timeout.connect(
		func() -> void:
			var hp := (ghost.get_node("%Bar") as ProgressBar).value - GHOST_MAX_HP * GHOST_HIT
			ghost.animate_to(hp if hp > 0.0 else GHOST_MAX_HP)
	)


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
		[KNIGHT.basic_attack, "RMB", 1, 0.6, false, false, "COOLING < 1 s"],
		[KNIGHT.skill_q, "Q", 1, 0.0, false, true, "upgradable"],
		[KNIGHT.skill_r, "R", 0, 0.0, true, false, "LOCKED"],
		[KNIGHT.skill_r, "R", 0, 0.0, true, true, "LOCKED + upgradable"],
		[RANGER.basic_attack, "RMB", 1, 0.0, false, false, "Arqueira"],
		[RANGER.skill_q, "Q", 1, 0.0, false, false, "Arqueira"],
		[RANGER.skill_e, "E", 1, 2.2, false, false, "Arqueira"],
		[RANGER.skill_r, "R", 1, 0.0, false, false, "Arqueira"],
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
		slot.bind(item, ItemVisuals.for_hero(&"knight").icon(item))
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


func _target_frames() -> void:
	var row := _row("TargetFrame (alvo travado, F66)")
	# nome, etiqueta, HP, HP max, legenda
	var samples: Array[Array] = [
		["Cavaleiro", "Nv 3", 240, 600, "herói inimigo"],
		["Esqueleto", "T1", 100, 100, "monstro"],
		["Rei Esqueleto", "CHEFE", 2400, 3000, "boss"],
	]
	for sample: Array in samples:
		var frame := TARGET_FRAME.instantiate() as TargetFrame
		_add(row, frame, sample[4])
		frame.bind(sample[0], sample[1], sample[2], sample[3])


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


func _launcher_typography() -> void:
	var row := _row("Launcher · tipografia (Space Grotesk, Outfit, JetBrains Mono)", _launcher)
	for type: StringName in LauncherTheme.LABELS:
		if String(type).begins_with("LnIcon"):
			continue
		var label := Label.new()
		label.theme_type_variation = type
		label.text = "1920 x 1080" if String(type).begins_with("LnNum") else "Configurações"
		_add(row, label, type)
	var icons := _row("Launcher · ícones (Material Symbols, UiIcons)", _launcher)
	var glyphs := (UiIcons as Script).get_script_constant_map()
	for constant: String in glyphs:
		var glyph := Label.new()
		glyph.theme_type_variation = &"LnIconTitle"
		glyph.text = glyphs[constant]
		_add(icons, glyph, constant.to_lower())


func _launcher_buttons() -> void:
	var row := _row("Launcher · botões (Tab mostra o foco)", _launcher)
	var samples: Array[Array] = [
		[&"LnTab", "AJUSTES", false],
		[&"LnTab", "ATIVA", true],
		[&"LnButton", "%s  RESTAURAR PADRÕES" % UiIcons.RESTART_ALT, false],
		[&"LnButtonPrimary", "%s  SALVAR & APLICAR" % UiIcons.SAVE, false],
		[&"LnButtonDanger", "SAIR DO JOGO", false],
		[&"LnIconButton", UiIcons.SETTINGS, false],
		[&"LnIconButtonDanger", UiIcons.POWER_SETTINGS_NEW, false],
		[&"LnSegment", "144", true],
		[&"LnSegment", "60", false],
		[&"LnKey", "W", false],
		[&"LnKey", "…", true],
		[&"LnKeyCyan", "ESPAÇO", false],
		[&"LnKeyUltimate", "R", false],
	]
	for sample: Array in samples:
		var button := Button.new()
		button.theme_type_variation = sample[0]
		button.text = sample[1]
		button.toggle_mode = sample[2]
		button.button_pressed = sample[2]
		_add(row, button, sample[0])
	var disabled := Button.new()
	disabled.theme_type_variation = &"LnButton"
	disabled.text = "DESABILITADO"
	disabled.disabled = true
	_add(row, disabled, "LnButton disabled")
	var key := Label.new()
	key.theme_type_variation = &"LnKeyLabel"
	key.text = "M2 (DIR)"
	_add(row, key, "LnKeyLabel")


func _launcher_controls() -> void:
	var row := _row("Launcher · switch, slider, lista", _launcher)
	for sample: Array in [[true, false], [false, false], [true, true]]:
		var toggle := CheckButton.new()
		toggle.theme_type_variation = &"LnSwitch"
		toggle.button_pressed = sample[0]
		toggle.disabled = sample[1]
		_add(row, toggle, "LnSwitch%s" % (" disabled" if sample[1] else ""))
	var slider := HSlider.new()
	slider.theme_type_variation = &"LnSlider"
	slider.custom_minimum_size.x = CARD_SIZE.x
	slider.value = 45.0
	_add(row, slider, "LnSlider")
	var picker := OptionButton.new()
	picker.theme_type_variation = &"LnOption"
	picker.get_popup().theme_type_variation = &"LnPopup"
	for text: String in ["1280 x 720", "1920 x 1080"]:
		picker.add_item(text)
	_add(row, picker, "LnOption + LnPopup")


func _launcher_panels() -> void:
	var row := _row("Launcher · painéis", _launcher)
	for type: StringName in [
		&"LnCard", &"LnCardRaised", &"LnRibbon", &"LnRow", &"LnRowHover", &"LnWell", &"LnModal"
	]:
		var panel := PanelContainer.new()
		panel.theme_type_variation = type
		panel.custom_minimum_size = CARD_SIZE
		var label := Label.new()
		label.theme_type_variation = &"LnBody"
		label.text = "Card"
		panel.add_child(label)
		_add(row, panel, type)
	var chip := PanelContainer.new()
	chip.theme_type_variation = &"LnChip"
	var chip_text := Label.new()
	chip_text.theme_type_variation = &"LnNumCyan"
	chip_text.text = "FORWARD+"
	chip.add_child(chip_text)
	_add(row, chip, "LnChip")
	var box := PanelContainer.new()
	box.theme_type_variation = &"LnIconBox"
	var glyph := Label.new()
	glyph.theme_type_variation = &"LnIconGold"
	glyph.text = UiIcons.SPORTS_ESPORTS
	box.add_child(glyph)
	_add(row, box, "LnIconBox")


func _launcher_chrome() -> void:
	var row := _row("ScreenHeader · ScreenFooter · FormRow · ModalDialog", _launcher)
	var header := ScreenHeader.new()
	header.custom_minimum_size.x = SCREEN_BLOCK_WIDTH
	_add(row, header, "ScreenHeader (com voltar)")
	header.bind("Configurações do jogo", true, "Painel técnico", UiIcons.TUNE, "Descrição curta.")
	var tab := Button.new()
	tab.theme_type_variation = &"LnTab"
	tab.text = "ABA"
	header.right_slot.add_child(tab)
	var footer := ScreenFooter.new()
	footer.custom_minimum_size.x = SCREEN_BLOCK_WIDTH
	_add(row, footer, "ScreenFooter")
	var hints: Array[HotkeyHint] = [HotkeyHint.make("ESC", "Voltar")]
	footer.bind(hints, "status", "ARENA 1V1")
	for error: String in ["", "E-mail inválido"]:
		var form := FormRow.new()
		form.custom_minimum_size.x = CARD_SIZE.x * 1.5
		form.bind("E-mail")
		form.add_child(LineEdit.new())
		if not error.is_empty():
			form.set_error(error)
		_add(row, form, "FormRow %s" % ("error" if form.has_error() else "normal"))
	var open := Button.new()
	open.theme_type_variation = &"LnButton"
	open.text = "ABRIR MODAL"
	_add(row, open, "ModalDialog")
	var dialog := ModalDialog.new()
	add_child(dialog)
	var actions: Array[DialogAction] = [
		DialogAction.make("CANCELAR"), DialogAction.make("SAIR", DialogAction.Kind.DANGER)
	]
	open.pressed.connect(func() -> void: dialog.open("Sair do jogo?", "Exemplo.", actions))


func _launcher_states() -> void:
	var row := _row("StateBox (5 estados)", _launcher)
	var messages: Array[String] = ["", "", "", "Nenhuma partida ainda", "Servidor fora do ar"]
	for state: int in StateBox.State.values():
		var panel := PanelContainer.new()
		panel.theme_type_variation = &"LnCard"
		var box := StateBox.new()
		box.custom_minimum_size = STATE_SIZE
		var content := Label.new()
		content.theme_type_variation = &"LnBody"
		content.text = "Conteúdo pronto"
		box.add_child(content)
		panel.add_child(box)
		_add(row, panel, _name(StateBox.State, state))
		box.set_state(state, messages[state])


func _card(variant: PanelCard.Surface, accent: PanelCard.Accent) -> PanelCard:
	var card := PanelCard.new()
	card.variant = variant
	card.accent = accent
	card.custom_minimum_size = CARD_SIZE
	var label := Label.new()
	label.text = "Card"
	card.add_child(label)
	return card


## Linha com titulo, ja na arvore; sem coluna, a esquerda ate LEFT_SECTIONS e depois a direita.
func _row(title: String, target: VBoxContainer = null) -> HFlowContainer:
	var column := target
	if column == null:
		column = _left if _sections < LEFT_SECTIONS else _right
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
