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
## Neblina de guerra (F37): o adversario so ve o heroi no raio de visao dele e fora do mato
## (seen_by, VisionRules); o VisionDirector decide por tick e o Concealment filtra.
## Fumaca da Ladina (F58, ADR-0013): a nuvem vale como moita (zones_at); quem solta fumaca se
## registra em _smoke_casters, e o indice dele e o bit da nuvem.
## VFX (F41): cada golpe registrado no ledger do alvo sai em struck (servidor); o ImpactRelay
## anuncia uma vez aos clientes. O heroi nao tem no de VFX: o cliente cria os efeitos (VfxSpawner).
## Controle v2 (F66, SPEC-066): o heroi encara a direcao em que anda (FacingRules); ao disparar o
## basico ou uma skill pronta vira para a mira e a mantem por facing_hold_time. Alvo travado
## (target_id, TargetRules): o pedido do input so vale se o alvo existe, e adversario, esta vivo e o
## heroi o ve; com ele em alcance do basico, o basico sai sozinho na direcao dele (attack_now).

## Servidor: golpe de [param slot] registrado em [param target] no [param tick] (pode repetir na
## ressimulacao do atacante; o ImpactRelay filtra).
signal struck(target: Combatant, slot: HitLedger.Slot, tick: int)

const GROUP: StringName = &"heroes"
## respawn_off_tick enquanto o respawn vale.
const RESPAWN_ALWAYS: int = 9223372036854775807
## Cena de cada heroi pelo id do HeroData.
const SCENE_PATH: String = "res://scenes/heroes/%s.tscn"
## Flag de fora da zona: dura um intervalo entre pulsos (1 s) mais a folga, para nao piscar entre
## pulsos nem com estado atrasado; nos ultimos ZONE_FADE_SECONDS a vinheta some aos poucos.
const ZONE_FLAG_SECONDS: float = 1.5
const ZONE_FADE_SECONDS: float = 0.5
## Fora de toda moita e de toda nuvem.
const NO_ZONES: Vector2i = Vector2i(VisibilityRules.NO_GRASS, VisibilityRules.NO_SMOKE)

## Herois que soltam fumaca (Ladina) na arvore; o indice e o bit da nuvem (VisibilityRules).
static var _smoke_casters: Array[Hero] = []

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
## Servidor: cinematica de abertura (INTRO, F69): nenhum input e aplicado e o heroi fica no spawn.
## Definido pelo MatchController; o cliente ja manda input zerado (PlayerInput.cinematic).
var input_locked: bool = false
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
## Alvo travado (F66): combat_id do heroi adversario ou monstro; TargetRules.NONE = nenhum.
var target_id: int = TargetRules.NONE
## Ticks que restam da janela de encarar depois de um disparo (F66, FacingRules).
var face_ticks: int = 0
## Ticks imune a controle (Ragnarok do Berserker, F75): lentidao, raiz, atordoamento, empurrao e
## puxao que chegam pelo ledger nao se aplicam.
var cc_immune_ticks: int = 0
## Maldição do Ocultista (F77, GDB §2.2-F): marcas (0..3), ticks até caírem todas juntas e a DEF
## efetiva que sai delas (_defense). Valem para todo herói; o VFX mostra as marcas.
var curse_stacks: int = 0
var curse_ticks: int = 0
## Praga do Ocultista (F77): ticks que faltam, dano bruto que ainda falta (dividido pelos pulsos
## restantes), ticks entre pulsos e o peer_id de quem a pôs (o dano e o abate contam para ele).
var dot_ticks: int = 0
var dot_left: int = 0
var dot_interval: int = 0
var dot_source: int = 0

## O basico dispara neste tick: botao segurado ou auto-ataque do alvo travado em alcance. Derivado
## do input a cada tick (fora do estado de rollback); as subclasses leem aqui, nao em input.attack.
var attack_now: bool = false

var _rollback: RollbackSynchronizer
var _target_cache: Combatant
## Alvo travado ja validado neste tick (null = nenhum).
var _target_node: Combatant
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
	ranks.z = mini(ranks.z, hero_data.skill_r.max_rank)  # rank tipico nunca passa do maximo
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
		":target_id",
		":face_ticks",
		":cc_immune_ticks",
		":curse_stacks",
		":curse_ticks",
		":dot_ticks",
		":dot_left",
		":dot_interval",
		":dot_source",
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
		"Input:chest_pick",
		"Input:target_id",
		"Input:target_clear",
	]
	_rollback.enable_input_broadcast = false
	add_child(_rollback)
	var ack := SpawnAck.guard(self, [_rollback.visibility_filter])
	_concealment = Concealment.guard(self, seen_by, _rollback, ack, peer_id)

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
		if not _hits.is_empty() or dot_ticks > 0:
			_apply_hits(tick)
	_refresh_attributes()
	hp = mini(hp, attributes.max_hp)  # troca para item com menos HP
	_tick_timers()  # recarga corre tambem morto
	if multiplayer.is_server():
		_drink(tick)
	_simulate_effects(tick)  # o que ja foi lancado segue mesmo com o heroi morto
	_refresh_body()
	if not is_alive() or input_locked:
		velocity = Vector3.ZERO
		return
	_learn()
	_interact(tick)

	# Input vem do cliente: nunca confiar no valor recebido.
	var movement := InputRules.sanitize_direction(input.movement)
	var aim := _plan_attack(InputRules.sanitize_direction(input.aim))
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
		_face(movement, aim)
		var slow := slow_pct if slow_ticks > 0 else 0.0
		velocity = movement * CombatRules.slowed(_move_speed(), slow)
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
	if VisibilityRules.acted(cooldowns, _cooldowns(), _reveals_on_e()):
		reveal_ticks = VisibilityRules.reveal_ticks(match_rules, NetworkTime.tickrate)


func _process(_delta: float) -> void:
	_refresh_attributes()
	_refresh_body()
	visible = _concealment.is_shown()
	var plate := is_alive() and not PlayerInput.cinematic  # sem placas na cinematica (F69)
	hp_label.visible = plate
	hp_bar.visible = plate
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
	var seen_from := NO_ZONES
	if observer != null:
		seen_from = zones_at(observer.global_position)
	return VisibilityRules.is_hidden_in(zones_at(global_position), seen_from, reveal_ticks)


## Moita (x, VisibilityRules.grass_at) e nuvens de fumaca (bits em y) que cobrem [param point].
func zones_at(point: Vector3) -> Vector2i:
	var smoke := VisibilityRules.NO_SMOKE
	for i: int in _smoke_casters.size():
		if _smoke_casters[i].smoke_covers(point):
			smoke |= VisibilityRules.smoke_bit(i)
	return Vector2i(VisibilityRules.grass_at(point, _grass), smoke)


## A nuvem de fumaca deste heroi cobre [param _point] (so a Ladina solta fumaca).
func smoke_covers(_point: Vector3) -> bool:
	return false


## Golpe no fim do avanco (Emboscada da Ladina): ticks restantes do golpe (sobe ao acertar), para o
## HeroVisual e o VFX; 0 = nenhum.
func dash_strike_ticks() -> int:
	return 0


## O jogador deste processo ve o heroi (neblina e mato; HUD e minimapa).
func is_shown() -> bool:
	return _concealment.is_shown()


## Neblina (F37): o heroi [param observer] (null = ninguem) ve este heroi — o proprio e o time
## sempre; o adversario so no raio de visao dele e fora do mato.
func seen_by(observer: Hero) -> bool:
	if observer == null:
		return false
	if observer == self or observer.team == team:
		return true
	var near := VisionRules.in_sight(
		observer.global_position, global_position, observer.match_rules.vision_radius
	)
	return VisionRules.hero_shown(near, hidden_from(observer))


func forward() -> Vector3:
	return -global_transform.basis.z


func combat_id() -> int:
	return peer_id


## Alvo travado (F66) ou null: a HUD mostra a moldura e o anel dele. Sai do estado replicado, nao
## do tick, entao vale tambem no cliente entre dois ticks.
func target() -> Combatant:
	return _lookup_target(target_id)


func missing_hp() -> int:
	return maxi(attributes.max_hp - hp, 0)


## Dano que [param raw] faria agora: depois da DEF, nada se invulneravel, no maximo o HP restante
## (roubo de vida do Berserker). A Muralha frontal fica de fora.
func effective_damage(raw: int) -> int:
	if invuln_ticks > 0 or not is_alive():
		return 0
	return mini(_scaled(CombatRules.mitigated(raw, _defense()), _taken_factor(true)), hp)


## DEF do momento: atributos + bonus temporario da subclasse (Grito de Guerra), menos a Maldicao
## (F77): o desconto vem depois dos bonus.
func _defense() -> float:
	return OccultistRules.effective_defense(attributes.defense + _defense_bonus(), curse_stacks)


## Velocidade de movimento do momento (u/s): atributos + bonus temporario da subclasse.
func _move_speed() -> float:
	return attributes.move_speed * (1.0 + _move_speed_bonus())


## Habilidade canalizada em curso (Rodopio do Barbaro): o HeroVisual mostra a animacao dela.
func is_channeling() -> bool:
	return false


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
	target_id = TargetRules.NONE
	face_ticks = 0
	shield_ticks = 0
	shield_hp = 0
	slow_ticks = 0
	invuln_ticks = 0
	interact_ticks = 0
	zone_ticks = 0
	cc_immune_ticks = 0
	curse_stacks = 0
	curse_ticks = 0
	dot_ticks = 0
	dot_left = 0
	dot_interval = 0
	dot_source = 0


## Gasta um ponto no slot pedido pelo input (Ctrl+Q/E/R). Valor do cliente: validado aqui.
func _learn() -> void:
	var slot := input.learn
	if slot < SkillRules.SLOT_Q or slot > SkillRules.SLOT_R:
		return
	var skills: Array[SkillData] = [hero_data.skill_q, hero_data.skill_e, hero_data.skill_r]
	ranks = SkillRules.learn(ranks, slot, skills[slot], level)


## F: o toque abre o bau ao alcance; o clique no menu (input chest_pick) leva o item escolhido
## (F61). Servidor apenas; o saque volta pelo ledger. Baus ficam a >= 3 u um do outro (SPEC-007):
## no maximo um ao alcance.
func _interact(tick: int) -> void:
	interact_ticks = interact_ticks + 1 if input.interact_hold else 0
	var pick := input.chest_pick
	var tapped := interact_ticks == 1
	if not multiplayer.is_server() or (not tapped and pick == PlayerInput.PICK_NONE):
		return
	for node: Node in get_tree().get_nodes_in_group(Chest.GROUP):
		var chest := node as Chest
		if chest.in_reach(global_position):
			if tapped:
				chest.interact(self, tick)
			if pick != PlayerInput.PICK_NONE:
				chest.pick(self, tick, pick)
			return


## Alvo do tick (F66): trava, mantem ou solta o alvo pelo pedido do input (TargetRules.resolve) e
## deixa em _target_node o alvo valido (null = nenhum). Quem pede alvo invisivel, aliado ou morto
## fica sem alvo: o servidor nunca confia no id (invariante de honestidade, CONVENTION §4.6).
func _lock_target() -> void:
	var asked := _valid_target(input.target_id)
	var held := _valid_target(target_id)
	target_id = TargetRules.resolve(
		target_id, input.target_id, input.target_clear, asked != null, held != null
	)
	if target_id == TargetRules.NONE:
		_target_node = null
	else:
		_target_node = asked if target_id == input.target_id else held


## Decide o ataque do tick e devolve a mira do disparo: botao segurado dispara na mira do cursor;
## sem ele, o alvo travado em alcance do basico dispara sozinho, na direcao dele. Skill pronta no
## mesmo tick manda a mira do cursor (Q, E e R miram nele). Nao anda ate o alvo.
func _plan_attack(aim: Vector3) -> Vector3:
	_lock_target()
	attack_now = input.attack
	# Empurrado, o heroi nao vira (_face so roda andando): o auto-ataque sairia na direcao antiga.
	if input.attack or _target_node == null or knockback_ticks > 0:
		return aim
	var reach := hero_data.basic_attack.attack_range
	if not TargetRules.can_attack(true, global_position, _target_node.global_position, reach):
		return aim
	attack_now = true
	if _skill_fires():
		return aim
	return TargetRules.aim_to(global_position, _target_node.global_position)


## O heroi dispara neste tick: basico pronto ou skill apertada, aprendida e fora de recarga.
func _fires() -> bool:
	return (attack_now and basic_cooldown == 0) or _skill_fires()


func _skill_fires() -> bool:
	var data := hero_data
	return (
		(input.skill_q and q_cooldown == 0 and SkillRules.can_use(data.skill_q, ranks.x, level))
		or (input.skill_e and e_cooldown == 0 and SkillRules.can_use(data.skill_e, ranks.y, level))
		or (input.skill_r and r_cooldown == 0 and SkillRules.can_use(data.skill_r, ranks.z, level))
	)


## Orientacao do tick (F66, FacingRules): movimento, ou a mira se dispara agora (abre a janela).
func _face(movement: Vector3, aim: Vector3) -> void:
	var firing := _fires()
	var toward := FacingRules.direction(movement, aim, firing, face_ticks)
	if not toward.is_zero_approx():
		look_at(global_position + toward, Vector3.UP)
	if firing:
		face_ticks = SkillRules.seconds_to_ticks(match_rules.facing_hold_time, NetworkTime.tickrate)


## [param id] como alvo valido de quem trava: existe, e adversario, esta vivo e este heroi o ve.
func _valid_target(id: int) -> Combatant:
	var other := _lookup_target(id)
	if other == null:
		return null
	var enemy := other != self and other.team != team
	return (
		other if TargetRules.is_valid(true, enemy, other.is_alive(), other.seen_by(self)) else null
	)


# ponytail: percorre o grupo so quando o alvo muda; cacheia o ultimo achado.
func _lookup_target(id: int) -> Combatant:
	if id == TargetRules.NONE:
		return null
	if is_instance_valid(_target_cache) and _target_cache.combat_id() == id:
		return _target_cache
	for node: Node in get_tree().get_nodes_in_group(TARGETS_GROUP):
		var other := node as Combatant
		if other.combat_id() == id:
			_target_cache = other
			return other
	return null


func _tick_timers() -> void:
	face_ticks = maxi(face_ticks - 1, 0)
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
	cc_immune_ticks = maxi(cc_immune_ticks - 1, 0)
	dot_ticks = maxi(dot_ticks - 1, 0)
	curse_ticks = maxi(curse_ticks - 1, 0)
	if curse_ticks == 0:
		curse_stacks = 0  # as marcas caem todas juntas
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


## Efeitos ja lancados que seguem a cada tick, inclusive morto (projeteis, Chuva, Meteoro).
func _simulate_effects(_tick: int) -> void:
	pass


## Usar o E revela no mato (VisibilityRules.acted); a Bomba de Fumaca da Ladina nao (ADR-0013).
func _reveals_on_e() -> bool:
	return true


## Propriedades de estado de rollback alem das do Hero (caminhos relativos a este node).
func _extra_state_properties() -> Array[String]:
	return []


## O basico em arco e golpe direto (Retribuicao do Paladino, F76); o Bacamarte do Engenheiro e tiro
## de arma de fogo e nao e (decisao do PI em 2026-10-19).
func _basic_is_direct() -> bool:
	return true


## DEF somada agora (Grito de Guerra do Berserker); sai do estado de rollback da subclasse.
func _defense_bonus() -> float:
	return 0.0


## Fracao de velocidade de movimento somada agora (Grito de Guerra e Ragnarok do Berserker).
func _move_speed_bonus() -> float:
	return 0.0


## Fator do dano tomado depois da DEF (Couraca e Penitencia do Carrasco, F98); [param _hero_basic] =
## o golpe e ataque basico de heroi. Sai do estado de rollback da subclasse.
func _taken_factor(_hero_basic: bool) -> float:
	return 1.0


## [param damage] vezes [param factor], arredondado; fator 1 devolve o mesmo valor.
static func _scaled(damage: int, factor: float) -> int:
	if factor == 1.0:
		return damage
	return maxi(roundi(damage * factor), 0)


## Basico corpo a corpo (Cavaleiro, Barbaro): golpeia quem esta no arco do basic_attack.
func _melee(tick: int) -> void:
	if not multiplayer.is_server():
		return
	var basic := hero_data.basic_attack
	var damage := roundi(SkillRules.amount(basic, 1, attributes))
	for other: Combatant in _enemies():
		var half_arc := basic.arc_degrees / 2.0
		if CombatRules.is_in_melee_arc(
			global_position, forward(), other.global_position, basic.attack_range, half_arc
		):
			var effect := HitEffect.new(damage, global_position)
			if _basic_is_direct():
				_direct(effect)
			_hit(other, tick, HitLedger.Slot.BASIC, effect)
		else:
			_miss(other, tick, HitLedger.Slot.BASIC)


## O chefe (Raizes Vivas e Golpe Consagrado so o ferem; o bot o caca, F74/F76).
static func _is_boss(other: Combatant) -> bool:
	var monster := other as Monster
	return monster != null and monster.data.tier == MonsterData.Tier.BOSS


## Marca [param effect] como golpe direto deste heroi (Retribuicao do Paladino, F76).
func _direct(effect: HitEffect) -> HitEffect:
	effect.striker_id = combat_id()
	return effect


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
	effect.hero_basic = slot == HitLedger.Slot.BASIC
	other.receive_hit(tick + 1, HitLedger.source_key(peer_id, slot), effect)
	# Forca ressimular o alvo a partir de tick+1 se ele ja foi simulado.
	NetworkRollback.mutate(other, tick + 1)
	struck.emit(other, slot, tick)


func _miss(other: Combatant, tick: int, slot: HitLedger.Slot) -> void:
	other.cancel_hit(tick + 1, HitLedger.source_key(peer_id, slot))


## DEF reduz primeiro; a Muralha absorve o que sobrou se o golpe veio pela frente
## (PI 2026-10-09); o resto vai ao HP. Invulneravel (Rolamento) nao toma dano mas sofre o resto
## (GDB §4.2: invulnerabilidade a dano). A zona (true_damage) ignora DEF e Muralha, nao a
## invulnerabilidade. Dano de heroi fica registrado por atacante (_hero_damage). XP so soma
## (I7). Saque: cura ate o HP max e item equipado no slot dele (a decisao de trocar ja foi do
## Chest). Morto recebe XP e item, nada mais. Couraca/Penitencia (F98) escalam o dano depois da DEF
## (_taken_factor); a execucao das Correntes zera o HP de quem ficou abaixo do limiar.
func _apply_hits(tick: int) -> void:
	var heal := 0
	# Pulso da Praga antes do ledger: sai so do estado do alvo, entao a ressimulacao o repete igual.
	if OccultistRules.is_dot_pulse(dot_ticks, dot_interval):
		heal += _apply_effect(_dot_pulse(), tick, false)
	for effect: HitEffect in _hits.effects_at(tick):
		heal += _apply_effect(effect, tick)
	# Cura do tick (saque, roubo de vida) depois de todo o dano: o resultado nao depende da ordem dos
	# efeitos no ledger (golpe fatal mata mesmo com cura no mesmo tick).
	if heal > 0 and is_alive():
		hp = mini(hp + heal, attributes.max_hp)
	_hits.trim_before(tick - NetworkRollback.history_limit)


## Aplica um efeito do tick e devolve a cura que ele traz (somada por quem chama).
func _apply_effect(effect: HitEffect, tick: int, blockable: bool = true) -> int:
	xp += maxi(effect.xp, 0)
	var item := item_catalog.find(effect.item)
	if item != null:
		equipment = Inventory.equip(equipment, item)
	if not is_alive():
		return 0
	var heal := maxi(effect.heal, 0)
	if effect.true_damage > 0:
		zone_ticks = SkillRules.seconds_to_ticks(ZONE_FLAG_SECONDS, NetworkTime.tickrate)
	var damage := _scaled(
		CombatRules.mitigated(effect.damage, _defense()), _taken_factor(effect.hero_basic)
	)
	if invuln_ticks > 0:
		damage = 0
	if (
		blockable
		and shield_ticks > 0
		and CombatRules.is_frontal(global_position, forward(), effect.source)
	):
		var split := CombatRules.absorb(damage, shield_hp)
		damage = split.x
		shield_hp = split.y
	if (
		effect.execute_below > 0.0
		and CarrascoRules.executes(
			hp - damage, attributes.max_hp, effect.execute_below, invuln_ticks > 0
		)
	):
		damage = hp  # Correntes do Julgamento: executa, ignora DEF (F98)
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
		return heal
	_apply_curse_and_dot(effect)
	if cc_immune_ticks > 0:
		return heal  # Ragnarok: empurrao, puxao, atordoamento, lentidao e raiz nao se aplicam
	if not effect.push.is_zero_approx():
		knockback_ticks = (
			effect.push_ticks
			if effect.push_ticks > 0
			else CombatRules.knockback_ticks(NetworkTime.tickrate)
		)
		knockback_velocity = effect.push * NetworkTime.tickrate / knockback_ticks
	stun_ticks = maxi(stun_ticks, effect.stun_ticks)
	if effect.slow_ticks > 0:
		if CombatRules.slow_applies(slow_pct, slow_ticks, effect.slow):
			slow_pct = effect.slow
			slow_ticks = maxi(slow_ticks, effect.slow_ticks)
	return heal


## Marcas da Maldicao (a nova renova todas) e Praga (reaplicar renova e troca o dano, nao acumula).
## Nao sao controle: valem tambem durante o Ragnarok.
func _apply_curse_and_dot(effect: HitEffect) -> void:
	if effect.curse > 0:
		curse_stacks = OccultistRules.add_stacks(curse_stacks, effect.curse)
		curse_ticks = effect.curse_ticks
	if effect.dot_pulses > 0:
		dot_interval = effect.dot_interval_ticks
		dot_ticks = OccultistRules.dot_duration_ticks(effect.dot_pulses, dot_interval)
		dot_left = effect.dot_total
		dot_source = effect.attacker_id


## Um pulso da Praga como golpe de quem a pos: passa pela DEF (com Maldicao) e pelo abate, nao pela
## Muralha (a Praga ja esta no alvo; a Muralha so bloqueia o projetil).
func _dot_pulse() -> HitEffect:
	var damage := OccultistRules.pulse_damage(dot_left, dot_ticks, dot_interval)
	dot_left -= damage
	var pulse := HitEffect.new(damage, global_position)
	pulse.attacker_id = dot_source
	return pulse


func _record_hero_damage(tick: int, attacker_id: int, amount: int) -> void:
	if not _hero_damage.has(tick):
		_hero_damage[tick] = {}
	var by_attacker: Dictionary = _hero_damage[tick]
	by_attacker[attacker_id] = by_attacker.get(attacker_id, 0) + amount
