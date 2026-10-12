class_name FireWizard
extends ProjectileHero
## Bruxo de Fogo (GDB §4.4, F54): basico Bola de Fogo (projetil que para no 1o alvo); Q Explosao
## de Chamas (projetil que explode no 1o alvo, na Muralha, no muro ou no fim do alcance e fere em
## area); E Anel de Fogo (area em volta do Bruxo que fere e empurra para fora; o alvo desliza pelo
## proprio move_and_slide, entao para no muro e no rio); R Meteoro (marca a area no cursor ate
## cast_range e cai duration depois, dano unico em quem esta na area naquele tick). Sem queimadura
## (PI 2026-10-11). Numeros de fire_wizard.tres; dano e empurrao pelo ledger do alvo (Hero._hit).

# Estado de rollback.
## Ticks ate o Meteoro cair (0 = nenhum marcado); o centro fica onde foi marcado.
var meteor_ticks: int = 0
var meteor_center: Vector3 = Vector3.ZERO

@onready var _meteor_area: Node3D = $MeteorArea


func _ready() -> void:
	super()
	var radius := hero_data.skill_r.radius  # malha da area tem raio 1
	_meteor_area.scale = Vector3(radius, 1.0, radius)


func _process(delta: float) -> void:
	super(delta)
	_meteor_area.visible = meteor_ticks > 0
	if _meteor_area.visible:
		_meteor_area.global_position = meteor_center


func _extra_state_properties() -> Array[String]:
	var props := super()
	props.append_array([":meteor_ticks", ":meteor_center"])
	return props


func _use_skills(tick: int) -> void:
	var rate := NetworkTime.tickrate
	var data := hero_data
	if input.skill_q and q_cooldown == 0 and SkillRules.can_use(data.skill_q, ranks.x, level):
		q_cooldown = SkillRules.cooldown_ticks(data.skill_q, ranks.x, attributes.intelligence, rate)
		var damage := roundi(SkillRules.amount(data.skill_q, ranks.x, attributes))
		_shoot(Arrow.Kind.EXPLODE, data.skill_q.attack_range, damage)
	if input.skill_e and e_cooldown == 0 and SkillRules.can_use(data.skill_e, ranks.y, level):
		e_cooldown = SkillRules.cooldown_ticks(data.skill_e, ranks.y, attributes.intelligence, rate)
		_ring(tick)
	if input.skill_r and r_cooldown == 0 and SkillRules.can_use(data.skill_r, ranks.z, level):
		r_cooldown = SkillRules.cooldown_ticks(data.skill_r, ranks.z, attributes.intelligence, rate)
		_mark_meteor()
	if input.attack and basic_cooldown == 0:
		basic_cooldown = SkillRules.seconds_to_ticks(attributes.attack_interval, rate)
		var basic := data.basic_attack
		_shoot(
			Arrow.Kind.BASIC, basic.attack_range, roundi(SkillRules.amount(basic, 1, attributes))
		)


func _simulate_effects(tick: int) -> void:
	var flying := _arrows_flying()
	if not flying and meteor_ticks == 0:
		return
	_enemies_into(_targets)
	if flying:
		_advance_arrows(tick)
	if meteor_ticks > 0:
		meteor_ticks -= 1
		if meteor_ticks == 0 and multiplayer.is_server():
			var r := hero_data.skill_r
			var damage := roundi(SkillRules.amount(r, ranks.z, attributes))
			_area_hit(tick, HitLedger.Slot.R, meteor_center, r.radius, damage, 0.0)


## As duas bolas param no 1o toque: a do basico fere quem tocou; a do Q explode onde parou.
func _arrow_struck(arrow: Arrow, other: Combatant, at: Vector3, tick: int) -> bool:
	if arrow.kind == Arrow.Kind.BASIC and multiplayer.is_server():
		_struck_basic.append(other)
		_hit(other, tick, HitLedger.Slot.BASIC, HitEffect.new(arrow.damage, at))
	return true


func _arrow_stopped(arrow: Arrow, tick: int) -> void:
	if arrow.kind != Arrow.Kind.EXPLODE or not multiplayer.is_server():
		return
	var radius := hero_data.skill_q.radius
	for other: Combatant in _targets:
		if CombatRules.in_radius(arrow.origin, other.global_position, radius):
			_struck_q.append(other)
			_hit(other, tick, HitLedger.Slot.Q, HitEffect.new(arrow.damage, arrow.origin))


## Anel de Fogo: fere em volta e empurra cada atingido para longe do Bruxo.
func _ring(tick: int) -> void:
	if not multiplayer.is_server():
		return
	var e := hero_data.skill_e
	var damage := roundi(SkillRules.amount(e, ranks.y, attributes))
	_enemies_into(_targets)
	_area_hit(tick, HitLedger.Slot.E, global_position, e.radius, damage, e.knockback)


func _mark_meteor() -> void:
	var r := hero_data.skill_r
	var distance := InputRules.sanitize_distance(input.aim_distance, r.cast_range)
	meteor_center = RangerRules.rain_center(global_position, forward(), distance, r.cast_range)
	var delay := SkillData.at_rank(r.duration, ranks.z)
	meteor_ticks = SkillRules.seconds_to_ticks(delay, NetworkTime.tickrate)


## Servidor: fere os _targets a ate [param radius] de [param center]; [param knockback] > 0 empurra
## para longe do centro (alvo no centro exato nao e empurrado).
func _area_hit(
	tick: int, slot: HitLedger.Slot, center: Vector3, radius: float, damage: int, knockback: float
) -> void:
	for other: Combatant in _targets:
		if CombatRules.in_radius(center, other.global_position, radius):
			var push := CombatRules.push_vector(other.global_position - center, knockback)
			_hit(other, tick, slot, HitEffect.new(damage, center, push))
		else:
			_miss(other, tick, slot)
