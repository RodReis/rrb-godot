class_name Hero
extends Combatant
## Heroi autoritativo no servidor, generico: atributos e habilidades vem de HeroData
## (GDB §4) e do nivel; nenhum numero de balanceamento aqui. O node se chama str(peer_id).
## Efeito sobre outro heroi (dano, empurrao, atordoamento, XP de abate) vai para o ledger do
## alvo, que o aplica no proprio _rollback_tick (ARCHITECTURE-GAME §3.2); monstro aplica o
## golpe na hora (Monster). Nivel = XP pela curva (GDB §3.2); pontos gastos por input (F9).
## As habilidades ficam na subclasse (Knight F8, Ranger F14: _use_skills, _while_dashing,
## _simulate_effects); aqui fica o que vale para todos: avanco, escudo, lentidao (R da Arqueira) e
## invulnerabilidade (Rolamento). Equipamento (F10) e
## estado de rollback: atributos saem dele pelo Inventory; F abre e troca no Chest, e o saque
## chega pelo ledger. Morte (F15): HP 0 deixa o heroi inerte e fora de alcance por
## respawn_seconds (o MatchController ajusta pela fase, KillRules) e ele renasce em home com HP
## cheio, sem perder itens (GDB §3.3). Jogador que cai: o servidor passa a dar input vazio ao
## heroi (mark_disconnected), senao o netfox para de simula-lo (ARCHITECTURE-GAME §6).
## Fonte da base (#74): no servidor, perto da fonte do proprio time e com fountain_open (fase 1),
## cura a cada segundo; tomar dano pausa a cura (heal_pause_ticks, estado de rollback).
## Fase 2 (F16): a zona chega pelo ledger como true_damage; da morte subita (respawn_off_tick)
## em diante o morto fica morto; o dano tomado de cada heroi fica registrado por tick para o
## desempate (KillTracker), assim como o dano sofrido de toda fonte, para a tela de fim (F18).
## Cada pulso da zona liga zone_ticks, o flag de "fora da zona" que a vinheta da HUD le (F17,
## PATTERNS P8).
## Mato alto (F32): dentro de uma moita o heroi some para quem esta fora (hidden_from,
## VisibilityRules); atacar ou usar skill liga reveal_ticks. Quem filtra a replicacao e o
## Concealment; no cliente o heroi escondido fica invisivel e sem colisao.

const GROUP: StringName = &"heroes"
## respawn_off_tick enquanto o respawn vale.
const RESPAWN_ALWAYS: int = 9223372036854775807
## Cena de cada heroi pelo id do HeroData.
const SCENE_PATH: String = "res://scenes/heroes/%s.tscn"
## Flag de fora da zona: dura um intervalo entre pulsos (1 s) mais a folga, para nao piscar entre
## pulsos nem com estado atrasado; nos ultimos ZONE_FADE_SECONDS a vinheta some aos poucos.
const ZONE_FLAG_SECONDS: float = 1.5
const ZONE_FADE_SECONDS: float = 0.5

@export var hero_data: HeroData
@export var xp_curve: XpCurve
@export var item_catalog: ItemCatalog
@export var match_rules: MatchRules

## Definido por quem spawna, antes de entrar na arvore (MultiplayerSpawner). Nivel inicial
## (--level de dev); depois o nivel sai do XP.
var level: int = LaunchArgs.DEFAULT_LEVEL
var peer_id: int = 0
## Heroi do bot (F12): o Input e um BotInput e o dono dele e o servidor (peer 1).
var is_bot: bool = false
## Onde renasce: o transform com que entrou na arvore (marcador HERO do time).
var home: Transform3D = Transform3D.IDENTITY
## Servidor: tempo de respawn da fase atual (KillRules), definido pelo MatchController.
var respawn_seconds: float = 0.0
## Servidor: peer_id de quem deu o golpe final na ultima morte (0 = monstro).
var killer_id: int = 0
## Servidor: a fonte da base cura (so na fase 1), definido pelo MatchController.
var fountain_open: bool = false
## Servidor: tick da morte subita (KillRules.respawns), definido pelo MatchController. Por tick,
## nao flag: ressimular um tick de antes dele ainda renasce.
var respawn_off_tick: int = RESPAWN_ALWAYS
var attributes: HeroAttributes

# Estado de rollback.
var xp: int = 0
## Ranks de Q, E e R (indice SkillRules.SLOT_*).
var ranks: Vector3i = Vector3i.ZERO
var hp: int = 0
var shield_hp: int = 0
var shield_ticks: int = 0
var stun_ticks: int = 0
var dash_ticks: int = 0
var dash_direction: Vector3 = Vector3.ZERO
var dash_speed: float = 0.0
## Lentidao recebida (R da Arqueira): fracao e ticks restantes.
var slow_ticks: int = 0
var slow_pct: float = 0.0
## Ticks sem tomar dano (Rolamento da Arqueira).
var invuln_ticks: int = 0
## Empurrao recebido (Investida, golpe do boss): desliza knockback_ticks a knockback_velocity.
var knockback_ticks: int = 0
var knockback_velocity: Vector3 = Vector3.ZERO
var basic_cooldown: int = 0
var q_cooldown: int = 0
var e_cooldown: int = 0
var r_cooldown: int = 0
## Numero de Ids por ItemData.Slot (Inventory).
var equipment: Vector4i = Inventory.NONE
## Ticks seguidos com F (0 = solto).
var interact_ticks: int = 0
## Ticks ate renascer; so vale com hp 0 (morto).
var respawn_ticks: int = 0
## Ticks em que a fonte nao cura depois de um dano.
var heal_pause_ticks: int = 0
## Ticks ate deixar de contar como fora da zona (> 0 = o ultimo pulso da zona pegou o heroi).
var zone_ticks: int = 0
## Ticks em que o heroi fica visivel mesmo na moita (> 0 = atacou ou usou skill ha pouco).
var reveal_ticks: int = 0

var _rollback: RollbackSynchronizer
var _concealment: Concealment
## Moitas da arena (VisibilityRules.grass_box), lidas no _ready: a arena nao muda na partida.
var _grass: Array[Transform3D] = []
var _attributes_equipment: Vector4i = Inventory.NONE
var _hits: HitLedger = HitLedger.new()  # so no servidor; fora do estado de rollback
## Servidor: dano tomado de herois, tick -> {peer_id do atacante -> dano}. Refeito a cada
## simulacao do tick, entao ressimular nao conta duas vezes.
var _hero_damage: Dictionary = {}
## Servidor: dano sofrido de toda fonte (heroi, monstro, zona), tick -> dano; refeito como acima.
var _damage_taken: Dictionary = {}
var _alive_layer: int = 0

@onready var input: PlayerInput = $Input
@onready var hp_label: Label3D = $HpLabel
@onready var hp_bar: WorldHealthBar = $HpBar
## Volume da Muralha (so o Cavaleiro tem).
@onready var _shield_blocker: Area3D = get_node_or_null("ShieldBlocker") as Area3D


func _ready() -> void:
	peer_id = name.to_int()
	home = transform
	_alive_layer = collision_layer
	add_to_group(GROUP)
	level = clampi(level, LaunchArgs.DEFAULT_LEVEL, XpTable.max_level(xp_curve))
	xp = XpTable.xp_for_level(xp_curve, level)
	attributes = Inventory.attributes(hero_data, level, equipment, item_catalog)
	_attributes_equipment = equipment
	ranks = XpTable.typical_ranks(xp_curve, level)
	hp = attributes.max_hp
	set_multiplayer_authority(1)
	input.set_multiplayer_authority(1 if is_bot else peer_id)
	hp_bar.set_friendly(peer_id == multiplayer.get_unique_id())
	_grass = _collect_grass()

	# Heroi planar (#41): perto de muro a despenetracao mexia no y e o encaixe no chao do
	# move_and_slide() passava a depender de is_on_floor() do tick anterior, que fica fora do
	# rollback; servidor e cliente divergiam. Com y travado o encaixe nao tem o que mover.
	axis_lock_linear_y = true

	_rollback = RollbackSynchronizer.new()
	_rollback.name = "RollbackSynchronizer"
	_rollback.root = self
	_rollback.state_properties = [
		":transform",
		":xp",
		":ranks",
		":velocity",
		":hp",
		":shield_hp",
		":shield_ticks",
		":stun_ticks",
		":dash_ticks",
		":dash_direction",
		":dash_speed",
		":slow_ticks",
		":slow_pct",
		":invuln_ticks",
		":knockback_ticks",
		":knockback_velocity",
		":basic_cooldown",
		":q_cooldown",
		":e_cooldown",
		":r_cooldown",
		":equipment",
		":interact_ticks",
		":respawn_ticks",
		":heal_pause_ticks",
		":zone_ticks",
		":reveal_ticks",
	]
	_rollback.state_properties.append_array(_extra_state_properties())
	_rollback.input_properties = [
		"Input:movement",
		"Input:aim",
		"Input:aim_distance",
		"Input:attack",
		"Input:skill_q",
		"Input:skill_e",
		"Input:skill_r",
		"Input:learn",
		"Input:interact_hold",
	]
	_rollback.enable_input_broadcast = false
	add_child(_rollback)
	var ack := SpawnAck.guard(self, [_rollback.visibility_filter])
	_concealment = Concealment.guard(self, _rollback, ack)

	var interpolator := TickInterpolator.new()
	interpolator.name = "TickInterpolator"
	interpolator.root = self
	interpolator.properties = [":transform"]
	add_child(interpolator)

	_rollback.process_settings()


func _rollback_tick(_delta: float, tick: int, _is_fresh: bool) -> void:
	# Ressimulacao restaura xp/equipment mas nao attributes: recalcula antes de usar DEF/HP max.
	_refresh_attributes()
	if not is_alive():
		_count_respawn(tick)
	if multiplayer.is_server():
		_hero_damage.erase(tick)
		_damage_taken.erase(tick)
		if not _hits.is_empty():
			_apply_hits(tick)
	_refresh_attributes()
	hp = mini(hp, attributes.max_hp)  # troca para item com menos HP
	_tick_timers()  # recarga corre tambem morto
	if multiplayer.is_server():
		_drink(tick)
	_simulate_effects(tick)  # o que ja foi lancado segue mesmo com o heroi morto
	_refresh_body()
	if not is_alive():
		velocity = Vector3.ZERO
		return
	_learn()
	_interact(tick)

	# Input vem do cliente: nunca confiar no valor recebido.
	var movement := InputRules.sanitize_direction(input.movement)
	var aim := InputRules.sanitize_direction(input.aim)
	if knockback_ticks > 0 or stun_ticks > 0:
		dash_ticks = 0  # empurrao e atordoamento interrompem o avanco
	if knockback_ticks > 0:
		velocity = knockback_velocity
		knockback_ticks -= 1
	elif stun_ticks > 0:
		velocity = Vector3.ZERO
	elif dash_ticks > 0:
		velocity = dash_direction * dash_speed
	else:
		if not aim.is_zero_approx():
			look_at(global_position + aim, Vector3.UP)
		var slow := slow_pct if slow_ticks > 0 else 0.0
		velocity = movement * CombatRules.slowed(attributes.move_speed, slow)
	velocity *= NetworkTime.physics_factor
	move_and_slide()
	velocity /= NetworkTime.physics_factor

	if stun_ticks > 0:
		return
	# Conta o avanco depois de andar: dash_ticks ticks de movimento, distancia cravada (Rolamento).
	if dash_ticks > 0:
		dash_ticks -= 1
		_while_dashing(tick)
		return
	var cooldowns := _cooldowns()
	_use_skills(tick)
	if VisibilityRules.acted(cooldowns, _cooldowns()):
		reveal_ticks = VisibilityRules.reveal_ticks(match_rules, NetworkTime.tickrate)


func _process(_delta: float) -> void:
	_refresh_attributes()
	_refresh_body()
	visible = _concealment.is_shown()
	hp_label.visible = is_alive()
	hp_bar.visible = is_alive()
	var status := " +%d" % shield_hp if shield_ticks > 0 else ""
	if stun_ticks > 0:
		status += " (atordoado)"
	elif slow_ticks > 0:
		status += " (lento)"
	hp_label.text = "Nv %d%s" % [level, status]
	hp_bar.set_ratio(float(hp) / attributes.max_hp)


func is_alive() -> bool:
	return hp > 0


## Servidor: o jogador caiu. O input passa ao servidor e fica vazio (PlayerInput.disconnected);
## process_authority faz o RollbackSynchronizer gravar esse input e seguir simulando o heroi.
func mark_disconnected() -> void:
	input.disconnected = true
	input.set_multiplayer_authority(1)
	_rollback.process_authority()


func receive_hit(tick: int, source: int, effect: HitEffect) -> void:
	_hits.set_hit(tick, source, effect)


func cancel_hit(tick: int, source: int) -> void:
	_hits.clear_hit(tick, source)


## Servidor: dano que o heroi [param attacker_id] causou neste heroi na partida.
func hero_damage_from(attacker_id: int) -> int:
	var total := 0
	for by_attacker: Dictionary in _hero_damage.values():
		total += by_attacker.get(attacker_id, 0)
	return total


## Servidor: XP somado ao que ja esta no ledger para [param tick] e ainda nao foi aplicado
## (recompensa do abate que encerrou a partida, F18).
func xp_with_pending(tick: int) -> int:
	var total := xp
	for effect: HitEffect in _hits.effects_at(tick):
		total += maxi(effect.xp, 0)
	return total


## Servidor: dano sofrido na partida, de toda fonte.
func damage_taken() -> int:
	var total := 0
	for amount: int in _damage_taken.values():
		total += amount
	return total


## Escondido no mato de [param observer] (heroi, monstro ou bot; null = sem observador, conta
## como fora de toda moita). O proprio heroi e o time dele sempre o veem: so some do adversario.
func hidden_from(observer: Node3D) -> bool:
	if observer == self or (observer is Hero and (observer as Hero).team == team):
		return false
	var seen_from := VisibilityRules.NO_GRASS
	if observer != null:
		seen_from = VisibilityRules.grass_at(observer.global_position, _grass)
	var grass := VisibilityRules.grass_at(global_position, _grass)
	return VisibilityRules.is_hidden(grass, seen_from, reveal_ticks)


func forward() -> Vector3:
	return -global_transform.basis.z


func combat_id() -> int:
	return peer_id


## Fracao do segmento [param p0]-[param p1] em que a Muralha ativa bloqueia um projetil, ou
## CombatRules.NO_HIT (sem Muralha). A largura sai da forma do ShieldBlocker na cena.
func projectile_block_fraction(p0: Vector3, p1: Vector3) -> float:
	if shield_ticks <= 0 or _shield_blocker == null:
		return CombatRules.NO_HIT
	var shape := _shield_blocker.get_child(0) as CollisionShape3D
	var half := (shape.shape as BoxShape3D).size.x / 2.0
	var xf := shape.global_transform
	return CombatRules.segment_cross_fraction(
		p0, p1, xf * Vector3(-half, 0.0, 0.0), xf * Vector3(half, 0.0, 0.0)
	)


## Nivel e atributos seguem o XP e o equipamento do estado (inclusive quando o rollback volta).
func _refresh_attributes() -> void:
	var new_level := XpTable.level_for_xp(xp_curve, xp)
	if new_level == level and equipment == _attributes_equipment:
		return
	level = new_level
	_attributes_equipment = equipment
	attributes = Inventory.attributes(hero_data, level, equipment, item_catalog)


## Colisao que sai do estado (vale tambem para o heroi remoto no cliente): morto nao bloqueia
## ninguem; a Muralha bloqueia so enquanto dura. No cliente, heroi escondido no mato nao bloqueia:
## o node dele parou onde sumiu, e o servidor segue autoritativo.
func _refresh_body() -> void:
	var solid := is_alive() and (multiplayer.is_server() or _concealment.is_shown())
	var layer := _alive_layer if solid else 0
	if collision_layer != layer:
		collision_layer = layer
	if _shield_blocker != null:
		_shield_blocker.collision_layer = PhysicsLayers.SHIELD if shield_ticks > 0 else 0


## Servidor: um pulso de cura por segundo na fonte do proprio time (#74).
func _drink(tick: int) -> void:
	if tick % NetworkTime.tickrate != 0:
		return
	var in_area := false
	for node: Node in get_tree().get_nodes_in_group(Fountain.GROUP):
		in_area = in_area or (node as Fountain).heals(global_position, team)
	if FountainRules.can_heal(fountain_open, is_alive(), heal_pause_ticks, in_area):
		var amount := FountainRules.heal_amount(attributes.max_hp, match_rules.fountain_heal_pct)
		hp = mini(hp + amount, attributes.max_hp)


## Morto: conta o respawn; no fim renasce em home com HP cheio (itens ficam, GDB §3.3). Da morte
## subita em diante fica morto.
func _count_respawn(tick: int) -> void:
	if tick >= respawn_off_tick:
		return
	respawn_ticks = maxi(respawn_ticks - 1, 0)
	if respawn_ticks > 0:
		return
	hp = attributes.max_hp
	transform = home
	velocity = Vector3.ZERO


## Golpe final: zera o que estava em curso e marca o tempo de respawn.
func _die(effect: HitEffect) -> void:
	hp = 0
	killer_id = effect.attacker_id
	respawn_ticks = SkillRules.seconds_to_ticks(respawn_seconds, NetworkTime.tickrate)
	knockback_ticks = 0
	stun_ticks = 0
	dash_ticks = 0
	shield_ticks = 0
	shield_hp = 0
	slow_ticks = 0
	invuln_ticks = 0
	interact_ticks = 0
	zone_ticks = 0


## Gasta um ponto no slot pedido pelo input (Ctrl+Q/E/R). Valor do cliente: validado aqui.
func _learn() -> void:
	var slot := input.learn
	if slot < SkillRules.SLOT_Q or slot > SkillRules.SLOT_R:
		return
	var skills: Array[SkillData] = [hero_data.skill_q, hero_data.skill_e, hero_data.skill_r]
	ranks = SkillRules.learn(ranks, slot, skills[slot], level)


## F: o bau ao alcance decide pelo tempo segurado (toque abre, segurar troca). Servidor apenas;
## o saque volta pelo ledger. Baus ficam a >= 3 u um do outro (SPEC-007): no maximo um ao alcance.
func _interact(tick: int) -> void:
	interact_ticks = interact_ticks + 1 if input.interact_hold else 0
	if interact_ticks == 0 or not multiplayer.is_server():
		return
	for node: Node in get_tree().get_nodes_in_group(Chest.GROUP):
		var chest := node as Chest
		if chest.in_reach(global_position):
			chest.interact(self, tick, interact_ticks)
			return


func _tick_timers() -> void:
	basic_cooldown = maxi(basic_cooldown - 1, 0)
	q_cooldown = maxi(q_cooldown - 1, 0)
	e_cooldown = maxi(e_cooldown - 1, 0)
	r_cooldown = maxi(r_cooldown - 1, 0)
	stun_ticks = maxi(stun_ticks - 1, 0)
	heal_pause_ticks = maxi(heal_pause_ticks - 1, 0)
	zone_ticks = maxi(zone_ticks - 1, 0)
	slow_ticks = maxi(slow_ticks - 1, 0)
	reveal_ticks = maxi(reveal_ticks - 1, 0)
	invuln_ticks = maxi(invuln_ticks - 1, 0)
	shield_ticks = maxi(shield_ticks - 1, 0)
	if shield_ticks == 0:
		shield_hp = 0


func _cooldowns() -> Vector4i:
	return Vector4i(basic_cooldown, q_cooldown, e_cooldown, r_cooldown)


## Moitas da arena na arvore (VisibilityRules.GROUP): Area3D com um CollisionShape3D de caixa.
func _collect_grass() -> Array[Transform3D]:
	var boxes: Array[Transform3D] = []
	for node: Node in get_tree().get_nodes_in_group(VisibilityRules.GROUP):
		for child: Node in node.get_children():
			var shape := child as CollisionShape3D
			if shape != null and shape.shape is BoxShape3D:
				var size := (shape.shape as BoxShape3D).size
				boxes.append(VisibilityRules.grass_box(shape.global_transform, size))
	return boxes


## Habilidades neste tick (subclasse): vivo, sem atordoamento e fora do avanco.
func _use_skills(_tick: int) -> void:
	pass


## Durante o avanco (dash_ticks > 0), no lugar de _use_skills: contato da Investida (Knight).
func _while_dashing(_tick: int) -> void:
	pass


## Efeitos ja lancados que seguem a cada tick, inclusive morto (flechas e Chuva da Ranger).
func _simulate_effects(_tick: int) -> void:
	pass


## Propriedades de estado de rollback alem das do Hero (caminhos relativos a este node).
func _extra_state_properties() -> Array[String]:
	return []


## Heroi do outro time e monstro vivo.
func _enemies() -> Array[Combatant]:
	var result: Array[Combatant] = []
	_enemies_into(result)
	return result


## Como _enemies, reusando [param out] (efeito que roda todo tick: flechas, Chuva).
# ponytail: get_nodes_in_group ainda aloca a lista do grupo; cachear se o profiler apontar.
func _enemies_into(out: Array[Combatant]) -> void:
	out.clear()
	for node: Node in get_tree().get_nodes_in_group(TARGETS_GROUP):
		var other := node as Combatant
		if other != self and other.team != team and other.is_alive():
			out.append(other)


## O alvo aplica no proprio _rollback_tick de tick+1, lendo o ledger; ressimular o alvo
## (input dele atrasado) nao apaga o efeito. Servidor apenas: o cliente nunca altera HP.
func _hit(other: Combatant, tick: int, slot: HitLedger.Slot, effect: HitEffect) -> void:
	effect.attacker_id = peer_id
	other.receive_hit(tick + 1, HitLedger.source_key(peer_id, slot), effect)
	# Forca ressimular o alvo a partir de tick+1 se ele ja foi simulado.
	NetworkRollback.mutate(other, tick + 1)


func _miss(other: Combatant, tick: int, slot: HitLedger.Slot) -> void:
	other.cancel_hit(tick + 1, HitLedger.source_key(peer_id, slot))


## DEF reduz primeiro; a Muralha absorve o que sobrou se o golpe veio pela frente
## (PI 2026-10-09); o resto vai ao HP. Invulneravel (Rolamento) nao toma dano mas sofre o resto
## (GDB §4.2: invulnerabilidade a dano). A zona (true_damage) ignora DEF e Muralha, nao a
## invulnerabilidade. Dano de heroi fica registrado por atacante (_hero_damage). XP so soma
## (I7). Saque: cura ate o HP max e item equipado no slot dele (a decisao de trocar ja foi do
## Chest). Morto recebe XP e item, nada mais.
func _apply_hits(tick: int) -> void:
	for effect: HitEffect in _hits.effects_at(tick):
		xp += maxi(effect.xp, 0)
		var item := item_catalog.find(effect.item)
		if item != null:
			equipment = Inventory.equip(equipment, item)
		if not is_alive():
			continue
		hp = mini(hp + maxi(effect.heal, 0), attributes.max_hp)
		if effect.true_damage > 0:
			zone_ticks = SkillRules.seconds_to_ticks(ZONE_FLAG_SECONDS, NetworkTime.tickrate)
		var damage := CombatRules.mitigated(effect.damage, attributes.defense)
		if invuln_ticks > 0:
			damage = 0
		if shield_ticks > 0 and CombatRules.is_frontal(global_position, forward(), effect.source):
			var split := CombatRules.absorb(damage, shield_hp)
			damage = split.x
			shield_hp = split.y
		if invuln_ticks == 0:
			damage += maxi(effect.true_damage, 0)
		if damage > 0:
			_damage_taken[tick] = _damage_taken.get(tick, 0) + mini(damage, hp)
		if effect.attacker_id != 0 and damage > 0:
			_record_hero_damage(tick, effect.attacker_id, mini(damage, hp))
		hp = maxi(hp - damage, 0)
		if damage > 0:
			var pause := match_rules.fountain_damage_pause
			heal_pause_ticks = SkillRules.seconds_to_ticks(pause, NetworkTime.tickrate)
		if hp == 0:
			_die(effect)
			continue
		if not effect.push.is_zero_approx():
			knockback_ticks = CombatRules.knockback_ticks(NetworkTime.tickrate)
			knockback_velocity = effect.push * NetworkTime.tickrate / knockback_ticks
		stun_ticks = maxi(stun_ticks, effect.stun_ticks)
		if effect.slow_ticks > 0:
			slow_pct = maxf(slow_pct, effect.slow) if slow_ticks > 0 else effect.slow
			slow_ticks = maxi(slow_ticks, effect.slow_ticks)
	_hits.trim_before(tick - NetworkRollback.history_limit)


func _record_hero_damage(tick: int, attacker_id: int, amount: int) -> void:
	if not _hero_damage.has(tick):
		_hero_damage[tick] = {}
	var by_attacker: Dictionary = _hero_damage[tick]
	by_attacker[attacker_id] = by_attacker.get(attacker_id, 0) + amount
