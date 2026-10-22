class_name StatusMark
extends Node3D
## Animacao do controle sobre a cabeca de UM alvo (PI 2026-10-22), so cliente: estrelas girando
## (atordoado), anel de correntes (preso) e setas azuis descendo (lento). O CurseMarks le
## Combatant.status() e chama apply; aqui so se desenha. Ocioso: set_process desligado e oculto.

const STAR_SHADER: Shader = preload("res://scenes/vfx/status_star.gdshader")
## Altura (u) sobre a barra de HP; a Maldicao fica acima (CurseIndicator.MARK_LIFT).
const LIFT: float = 0.5
## Atordoado: estrelas na roda (raio u, lado u, voltas/s, balanco u).
const STAR_COUNT: int = 3
const STAR_RADIUS: float = 0.42
const STAR_SIZE: float = 0.26
const STAR_SPIN: float = 0.9
const STAR_BOB: float = 0.06
## Preso: elos na roda (raio u, voltas/s, raio do elo u).
const LINK_COUNT: int = 10
const LINK_RADIUS: float = 0.45
const LINK_SPIN: float = 0.15
const LINK_SIZE: float = 0.07
## Lento: setas que descem DROP u por ciclo, CYCLE_SPEED ciclos/s, defasadas.
const ARROW_COUNT: int = 3
const ARROW_SIZE: float = 0.22
const ARROW_DROP: float = 0.45
const ARROW_SPACING: float = 0.28
const CYCLE_SPEED: float = 1.1
const STAR_COLOR: Color = Color(1.0, 0.82, 0.25)
const LINK_COLOR: Color = Color(0.72, 0.75, 0.8)
const ARROW_COLOR: Color = Color(0.4, 0.7, 1.0)

var _status: StatusRules.Status = StatusRules.Status.NONE
var _time: float = 0.0
var _stars: Node3D = Node3D.new()
var _links: Node3D = Node3D.new()
var _arrows: Node3D = Node3D.new()


func _ready() -> void:
	var star_material := ShaderMaterial.new()
	star_material.shader = STAR_SHADER
	star_material.set_shader_parameter(&"color", STAR_COLOR)
	var star_mesh := QuadMesh.new()
	star_mesh.size = Vector2.ONE * STAR_SIZE
	for i: int in STAR_COUNT:
		_stars.add_child(_part(star_mesh, star_material))
	var link_mesh := TorusMesh.new()
	link_mesh.inner_radius = LINK_SIZE * 0.55
	link_mesh.outer_radius = LINK_SIZE
	link_mesh.rings = 12
	link_mesh.ring_segments = 6
	for i: int in LINK_COUNT:
		var link := _part(link_mesh, _flat(LINK_COLOR, false))
		var angle := TAU * i / LINK_COUNT
		link.position = Vector3(cos(angle), 0.0, sin(angle)) * LINK_RADIUS
		# Elos alternados de pe e deitados, tangentes a roda: le como corrente.
		link.rotation = Vector3(PI / 2.0 if i % 2 == 0 else 0.0, -angle, 0.0)
		_links.add_child(link)
	var arrow_mesh := PrismMesh.new()
	arrow_mesh.size = Vector3(ARROW_SIZE, ARROW_SIZE * 0.8, 0.02)
	for i: int in ARROW_COUNT:
		_arrows.add_child(_part(arrow_mesh, _flat(ARROW_COLOR, true)))
	for group: Node3D in [_stars, _links, _arrows]:
		group.visible = false
		add_child(group)
	visible = false
	set_process(false)


## Liga a altura: [param bar_height] = altura (u) da barra de HP do alvo.
func bind(bar_height: float) -> void:
	position = Vector3(0.0, bar_height + LIFT, 0.0)


func apply(status: StatusRules.Status, shown: bool) -> void:
	var on := shown and status != StatusRules.Status.NONE
	visible = on
	set_process(on)
	if status == _status:
		return
	_status = status
	_time = 0.0
	_stars.visible = status == StatusRules.Status.STUN
	_links.visible = status == StatusRules.Status.ROOT
	_arrows.visible = status == StatusRules.Status.SLOW


func shown_status() -> StatusRules.Status:
	return _status if visible else StatusRules.Status.NONE


func _process(delta: float) -> void:
	_time += delta
	match _status:
		StatusRules.Status.STUN:
			for i: int in STAR_COUNT:
				var angle := TAU * (STAR_SPIN * _time + float(i) / STAR_COUNT)
				var bob := sin(_time * 6.0 + i * 2.1) * STAR_BOB
				(_stars.get_child(i) as Node3D).position = Vector3(
					cos(angle) * STAR_RADIUS, bob, sin(angle) * STAR_RADIUS
				)
		StatusRules.Status.ROOT:
			_links.rotation.y = TAU * LINK_SPIN * _time
		StatusRules.Status.SLOW:
			for i: int in ARROW_COUNT:
				var cycle := fmod(_time * CYCLE_SPEED + float(i) / ARROW_COUNT, 1.0)
				var arrow := _arrows.get_child(i) as Node3D
				var x := (i - (ARROW_COUNT - 1) * 0.5) * ARROW_SPACING
				arrow.position = Vector3(x, ARROW_DROP * (0.5 - cycle), 0.0)
				# Billboard ignora a rotacao: Y negativo poe a ponta para baixo; nasce e some pequena.
				var size := sin(cycle * PI)
				arrow.scale = Vector3(size, -size, size)


func _part(mesh: Mesh, material: Material) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.material_override = material
	part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return part


static func _flat(color: Color, billboard: bool) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	if billboard:
		material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		material.billboard_keep_scale = true
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material
