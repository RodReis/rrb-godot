class_name FogOfWar
extends MeshInstance3D
## Neblina de guerra no cliente (F37, CONVENTION §4.9): area nunca vista fica escura, area ja vista
## em cinza (a cena como esta: o que o servidor parou de mandar fica com o ultimo estado visto) e o
## raio de visao do heroi local fica intacto. Quad de tela com fog_of_war.gdshader, o primeiro
## transparente desenhado (RENDER_PRIORITY): a parede da zona e as barras vem depois, por cima — a
## zona e sempre visivel. O minimapa (SubViewport no mesmo World3D) desenha o mesmo quad. A mascara
## de explorado sai so da posicao do proprio heroi (VisionRules.explore): nao vaza nada. So visual;
## quem esconde de verdade e o servidor (VisionDirector).

const SHADER: Shader = preload("res://scenes/world/fog_of_war.gdshader")
const RENDER_PRIORITY: int = Material.RENDER_PRIORITY_MIN
## Meia largura da area da mascara (u; a arena cabe em +-37) e lado da celula (u).
const MAP_EXTENT: float = 40.0
const CELL: float = 0.5
## O quad e desenhado em qualquer camera: nunca sai do frustum.
const CULL_MARGIN: float = 16384.0
const NO_CELL: Vector2i = Vector2i(-1000000, -1000000)

var _hero: Hero
var _radius: float = 0.0
var _side: int = 0
var _mask: PackedByteArray = PackedByteArray()
var _image: Image
var _texture: ImageTexture
var _material: ShaderMaterial
## Celula do heroi na ultima atualizacao da mascara (so refaz ao mudar de celula).
var _cell: Vector2i = NO_CELL


func _ready() -> void:
	var quad := QuadMesh.new()
	quad.size = Vector2(2.0, 2.0)
	mesh = quad
	extra_cull_margin = CULL_MARGIN
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_material = ShaderMaterial.new()
	_material.shader = SHADER
	_material.render_priority = RENDER_PRIORITY
	material_override = _material
	_side = VisionRules.mask_side(MAP_EXTENT, CELL)
	_mask = VisionRules.new_mask(MAP_EXTENT, CELL)
	_image = Image.create_from_data(_side, _side, false, Image.FORMAT_R8, _mask)
	_texture = ImageTexture.create_from_image(_image)
	_material.set_shader_parameter(&"explored_mask", _texture)
	_material.set_shader_parameter(&"map_extent", MAP_EXTENT)
	set_process(false)


## Passa a seguir [param hero] (o heroi do jogador deste processo).
func bind(hero: Hero) -> void:
	_hero = hero
	_radius = hero.match_rules.vision_radius
	_material.set_shader_parameter(&"vision_radius", _radius)
	set_process(true)


func is_explored(point: Vector3) -> bool:
	var cell := VisionRules.cell_of(point, MAP_EXTENT, CELL)
	var inside := cell.x >= 0 and cell.y >= 0 and cell.x < _side and cell.y < _side
	return inside and _mask[cell.y * _side + cell.x] == VisionRules.SEEN


func shader_material() -> ShaderMaterial:
	return _material


func _process(_delta: float) -> void:
	if not is_instance_valid(_hero):
		set_process(false)
		return
	var at := _hero.global_position
	_material.set_shader_parameter(&"viewer_xz", Vector2(at.x, at.z))
	var cell := VisionRules.cell_of(at, MAP_EXTENT, CELL)
	if cell == _cell:
		return
	_cell = cell
	_mask = VisionRules.explore(_mask, MAP_EXTENT, CELL, at, _radius)
	_image.set_data(_side, _side, false, Image.FORMAT_R8, _mask)
	_texture.update(_image)
