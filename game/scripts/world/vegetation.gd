class_name Vegetation
extends MultiMeshInstance3D
## Grama decorativa da arena (F42): os tufos vem como dado do builder
## (tools/arena/arena_vegetation.gd, em scenes/arena/vegetation.tscn) e o MultiMesh (1 draw call)
## e montado aqui. O builder roda headless, e o servidor de renderizacao headless nao guarda buffer
## de MultiMesh nem malha: a cena nao tem como salvar o MultiMesh pronto. So visual: no servidor
## headless ou com graphics.grass desligado no settings.cfg (ADR-0006 item 8) o node sai da arvore
## no _ready, sem alocar nada.

# Tufo: TUFT_BLADES folhas em leque, cada uma 3 triangulos (base, meio, ponta).
const TUFT_BLADES: int = 7
const TUFT_HEIGHT: float = 0.5
const TUFT_RADIUS: float = 0.16
const BLADE_WIDTH: float = 0.065
## Inclinacao da ponta para fora (fracao da altura).
const BLADE_LEAN: float = 0.35
## Altura do meio da folha (fracao) e largura ali (fracao da base).
const BLADE_MID: float = 0.55
const BLADE_MID_WIDTH: float = 0.7

## Um tufo por item: (x, z, yaw em rad, escala uniforme), no chao (y = 0).
@export var tufts: PackedVector4Array = PackedVector4Array()


func _ready() -> void:
	if not wanted(DisplayServer.get_name(), GraphicsSettings.load_file()):
		queue_free()
		return
	multimesh = build_multimesh(tufts)


static func wanted(display: String, flags: Dictionary) -> bool:
	return display != "headless" and flags[GraphicsSettings.GRASS]


static func build_multimesh(data: PackedVector4Array) -> MultiMesh:
	var result := MultiMesh.new()
	result.transform_format = MultiMesh.TRANSFORM_3D
	result.mesh = tuft_mesh()
	result.instance_count = data.size()
	for i: int in range(data.size()):
		var t := data[i]
		var tuft_basis := Basis(Vector3.UP, t.z).scaled(Vector3.ONE * t.w)
		result.set_instance_transform(i, Transform3D(tuft_basis, Vector3(t.x, 0, t.y)))
	return result


## Leque de folhas finas afinando ate a ponta, sem textura (sem alpha: barato e sem ordenacao).
## Normal para cima em tudo: a folha acende como o chao, sem lado escuro. UV.y = altura (0..1),
## lida pelo grass_wind.gdshader (curva do vento e cor).
static func tuft_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_normal(Vector3.UP)
	for b: int in range(TUFT_BLADES):
		var key := Vector2(b, b * 1.7)
		var angle := TAU * (b + _hash(key)) / TUFT_BLADES
		var out := Vector3(cos(angle), 0, sin(angle))
		var side := Vector3(-out.z, 0, out.x) * BLADE_WIDTH / 2
		var root := out * TUFT_RADIUS * _hash(key + Vector2(2, 0))
		var height := TUFT_HEIGHT * lerpf(0.7, 1.0, _hash(key + Vector2(0, 3)))
		var lean := out * height * BLADE_LEAN
		var mid := root + lean * 0.4 + Vector3.UP * height * BLADE_MID
		var ml := mid - side * BLADE_MID_WIDTH
		var mr := mid + side * BLADE_MID_WIDTH
		var top := root + lean + Vector3.UP * height
		_vertex(st, root - side, 0.0)
		_vertex(st, root + side, 0.0)
		_vertex(st, ml, BLADE_MID)
		_vertex(st, root + side, 0.0)
		_vertex(st, mr, BLADE_MID)
		_vertex(st, ml, BLADE_MID)
		_vertex(st, ml, BLADE_MID)
		_vertex(st, mr, BLADE_MID)
		_vertex(st, top, 1.0)
	return st.commit()


static func _vertex(st: SurfaceTool, at: Vector3, height_frac: float) -> void:
	st.set_uv(Vector2(0.5, height_frac))
	st.add_vertex(at)


static func _hash(p: Vector2) -> float:
	return fposmod(sin(p.x * 12.9898 + p.y * 78.233) * 43758.5453, 1.0)
