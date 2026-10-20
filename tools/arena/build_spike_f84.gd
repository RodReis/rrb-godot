extends SceneTree
## Gera game/scenes/arena/spike_f84.tscn (F84, SPEC-084): cena herdada da ilha_arcana.tscn com o
## visual da base A (canto SO) e do patio trocado pelo kit do spike (art/spike/f84/
## build_spike_f84.py). So visual: cada peca antiga do castelo e do patio no SO fica escondida e a
## nova entra no grupo SpikeF84 com o mesmo transform (a colisao e do builder da arena, em outro
## node, e nao muda); o portao A e a fonte A trocam so o modelo; praca, props e luzes das
## lanternas sao novos. A base B, a colisao, os marcadores e o resto da arena ficam como na oficial.
## Luz: o LightmapGI da variante usa spike_f84.lmbake (tools/bake-lightmap.ps1 -Scene
## res://scenes/arena/spike_f84.tscn -Builder tools/arena/build_spike_f84.gd); sem ele, nenhum.
## Uso (na raiz do repo; rode de novo depois de regerar a arena oficial ou o kit):
##   godot --headless --path game -s <repo>/tools/arena/build_spike_f84.gd

const BASE: String = "res://scenes/arena/ilha_arcana.tscn"
const OUT: String = "res://scenes/arena/spike_f84.tscn"
const LIGHTMAP_DATA: String = "res://scenes/arena/spike_f84.lmbake"
const KIT: String = "res://shared/assets/rrb/spike/f84/"
const GROUP: String = "SpikeF84"
## Peca da arena oficial (nome do .glb) -> peca do spike, mesma origem e escala.
const SWAP: Dictionary[String, String] = {
	"castle_wall_a": "spike_wall",
	"castle_tower_a": "spike_tower",
	"castle_gate_a": "spike_gate",
	"castle_keep_a": "spike_keep",
	"stone_house": "spike_house_stone",
	"megakit_house_long": "spike_house_long",
	"megakit_house_small": "spike_house_small",
	"megakit_yard_corner": "spike_yard",
}
const SWAP_GROUPS: Array[String] = ["Castle", "Village"]
## Os 3 muros curtos de dentro da base usam a mureta baixa (sem ameias): nao tapam o portao.
const INNER_WALL: String = "spike_wall_low"
const SPAWN_A: Vector2 = Vector2(-24, 24)
## Props sem colisao, rente a muro e casa, fora do spawn, dos baus, dos monstros e da fonte:
## [asset, (x, z) do mundo, yaw em graus; NAN = virado para o spawn A].
const PROPS: Array[Array] = [
	["spike_banner", Vector2(-18.66, 13.58), NAN],
	["spike_banner", Vector2(-13.58, 18.66), NAN],
	["spike_lantern", Vector2(-26.87, 12.73), NAN],
	["spike_lantern", Vector2(-12.73, 26.87), NAN],
	["spike_lantern", Vector2(-26.30, 21.78), NAN],
	["spike_lantern", Vector2(-21.78, 26.30), NAN],
	["spike_rack", Vector2(-29.13, 25.45), NAN],
	["spike_rack", Vector2(-25.45, 29.13), NAN],
	["spike_barrel", Vector2(-32.94, 18.37), 0.0],
	["spike_barrel", Vector2(-33.60, 19.10), 40.0],
	["spike_crate", Vector2(-32.70, 17.30), 15.0],
	["spike_barrel", Vector2(-18.37, 32.94), 0.0],
	["spike_crate", Vector2(-17.30, 32.70), -20.0],
	["spike_crate", Vector2(-19.20, 33.70), 35.0],
	["spike_cart", Vector2(-33.20, 32.60), 120.0],
	["spike_banner", Vector2(-29.20, 30.20), NAN],
	["spike_barrel", Vector2(-34.70, 29.00), 10.0],
	["spike_crate", Vector2(-29.00, 34.60), 5.0],
]
## Casa do spike -> plantas das floreiras dela (.glb proprio: folhagem com vento, sem lightmap),
## postas no mesmo transform da casa.
const PLANTS: Dictionary[String, String] = {
	"spike_house_stone": "spike_house_stone_plants",
	"spike_house_long": "spike_house_long_plants",
	"spike_house_small": "spike_house_small_plants",
}
## Folhagem rente ao arco por dentro: raio e azimute em graus a partir da direcao spawn -> centro
## (-80 e a fonte), alternando moita e arbusto alto.
const RING_RADIUS: float = 11.6
const RING_DEG: Array[float] = [-46.0, -24.0, 24.0, 46.0, 80.0]
const RING_ASSETS: Array[String] = ["spike_bush", "spike_shrub"]
## Folhagem solta, fora das casas, dos baus e do spawn: [asset, (x, z) do mundo].
const FOLIAGE: Array[Array] = [
	["spike_shrub", Vector2(-39.0, 21.5)],
	["spike_shrub", Vector2(-21.5, 39.0)],
	["spike_bush", Vector2(-34.0, 34.0)],
	["spike_bush", Vector2(-38.0, 28.5)],
	["spike_bush", Vector2(-28.5, 38.0)],
	["spike_flowers", Vector2(-34.8, 24.3)],
	["spike_flowers", Vector2(-34.9, 30.2)],
	["spike_flowers", Vector2(-31.0, 34.8)],
	["spike_flowers", Vector2(-24.3, 34.8)],
]
## Touceiras floridas da base em (s, l) da base A: ao lado da fonte e dos postes do spawn.
const FLOWERS_BASE: Array[Vector2] = [Vector2(33.5, 12.0), Vector2(34.5, 4.2), Vector2(34.5, -4.2)]
## Escala-base por asset (a touceira florida baixa sumia na camera do jogo; PI 2026-10-20).
const FOLIAGE_SCALE: Dictionary[String, float] = {"spike_flowers": 1.4}
const AXIS_A: Vector2 = Vector2(-0.70710678, 0.70710678)
const LATERAL_A: Vector2 = Vector2(-0.70710678, -0.70710678)
const LANTERN_LIGHT_RANGE: float = 5.5
const LANTERN_LIGHT_ENERGY: float = 1.0
const LANTERN_LIGHT_COLOR: Color = Color(1.0, 0.66, 0.34)
## Vidro da lanterna no espaco do prop (art/spike/f84/build_spike_f84.py, build_props).
const LANTERN_GLASS: Vector3 = Vector3(0.55, 2.18, 0.0)

var _root: Node3D


func _initialize() -> void:
	var base := load(BASE) as PackedScene
	_root = base.instantiate(PackedScene.GEN_EDIT_STATE_MAIN_INHERITED) as Node3D
	var group := Node3D.new()
	group.name = GROUP
	_add(_root, group)
	var swapped := _swap_pieces(group)
	_swap_gate()
	_swap_fountain()
	_add_kit(group, "spike_plaza", "SpikePlaza", Transform3D.IDENTITY)
	_place_props(group)
	_link_lightmap()
	var packed := PackedScene.new()
	var err := packed.pack(_root)
	if err == OK:
		err = ResourceSaver.save(packed, OUT)
	print("[spike] %d pecas trocadas; %s -> %s" % [swapped, OUT, error_string(err)])
	_root.free()
	quit(0 if err == OK and swapped > 0 else 1)


## Esconde cada peca do castelo/patio no canto SO (x < 0, z > 0: so a base A) e poe a do spike
## no mesmo transform. Devolve quantas trocou.
func _swap_pieces(group: Node3D) -> int:
	var count := 0
	for group_name: String in SWAP_GROUPS:
		for node: Node in _root.get_node(group_name).get_children():
			var piece := node as Node3D
			var asset := piece.scene_file_path.get_file().get_basename()
			if not SWAP.has(asset) or piece.position.x >= 0.0 or piece.position.z <= 0.0:
				continue
			piece.visible = false
			var kit: String = SWAP[asset]
			if _is_inner_wall(piece.name):
				kit = INNER_WALL
			_add_kit(group, kit, "Spike" + piece.name, piece.transform)
			if PLANTS.has(kit):
				_add_kit(group, PLANTS[kit], "Spike%sPlants" % piece.name, piece.transform)
			count += 1
	return count


## Muros curtos de dentro da base (BASE_WALLS do builder: "WA<i>" ou "WA<i>_<k>").
func _is_inner_wall(label: String) -> bool:
	return label.begins_with("WA") and label.substr(2, 1).is_valid_int()


## Folhas do portao A: o gate.gd gira Door/LeafL e LeafR, entao a folha nova vira filha delas e o
## modelo antigo de dentro fica escondido.
func _swap_gate() -> void:
	var gate := _root.get_node("Gates/GateA")
	_root.set_editable_instance(gate, true)
	for side: String in ["L", "R"]:
		var leaf := gate.get_node("Door/Leaf" + side) as Node3D
		_root.set_editable_instance(leaf, true)
		for child: Node in leaf.get_children():
			(child as Node3D).visible = false
		_add_kit(leaf, "spike_door_" + side.to_lower(), "SpikeDoor", Transform3D.IDENTITY)


func _swap_fountain() -> void:
	var fountain := _root.get_node("Fountains/FountainA")
	_root.set_editable_instance(fountain, true)
	(fountain.get_node("Model") as Node3D).visible = false
	_add_kit(fountain, "spike_fountain", "SpikeModel", Transform3D.IDENTITY)


func _place_props(group: Node3D) -> void:
	var ambience := _root.get_node("Ambience")
	for i: int in range(PROPS.size()):
		var spec: Array = PROPS[i]
		var asset: String = spec[0]
		var at: Vector2 = spec[1]
		var yaw: float = spec[2]
		var basis := Basis(Vector3.UP, _yaw_to_spawn(at) if is_nan(yaw) else deg_to_rad(yaw))
		var where := Transform3D(basis, Vector3(at.x, 0, at.y))
		_add_kit(group, asset, "Spike%s%d" % [asset.trim_prefix("spike_").capitalize(), i], where)
		if asset == "spike_lantern":
			var light := OmniLight3D.new()
			light.name = "SpikeLantern%d" % i
			light.position = where * LANTERN_GLASS
			light.light_color = LANTERN_LIGHT_COLOR
			light.light_energy = LANTERN_LIGHT_ENERGY
			light.omni_range = LANTERN_LIGHT_RANGE
			_add(ambience, light)
	_place_foliage(group)


## Folhagem: anel do arco, pontos soltos do patio e touceiras floridas da base, com giro e
## tamanho variando pela posicao (a mesma moita nao se repete igual).
func _place_foliage(group: Node3D) -> void:
	var spots: Array[Array] = FOLIAGE.duplicate()
	var to_center := (-SPAWN_A).normalized()
	for i: int in range(RING_DEG.size()):
		var at := SPAWN_A + to_center.rotated(deg_to_rad(RING_DEG[i])) * RING_RADIUS
		spots.append([RING_ASSETS[i % RING_ASSETS.size()], at])
	for local: Vector2 in FLOWERS_BASE:
		spots.append(["spike_flowers", AXIS_A * local.x + LATERAL_A * local.y])
	for i: int in range(spots.size()):
		var asset: String = spots[i][0]
		var at: Vector2 = spots[i][1]
		var size := 0.85 + 0.35 * fposmod(at.x * 0.37 + at.y * 0.61, 1.0)
		size *= FOLIAGE_SCALE.get(asset, 1.0)
		var basis := Basis(Vector3.UP, at.x * 1.3 + at.y * 0.7).scaled(Vector3.ONE * size)
		var label := "Spike%s%d" % [asset.trim_prefix("spike_").capitalize(), i]
		_add_kit(group, asset, label, Transform3D(basis, Vector3(at.x, 0, at.y)))


## Yaw que vira o +x do prop (braco da lanterna, frente do estandarte) para o spawn A.
func _yaw_to_spawn(at: Vector2) -> float:
	var dir := SPAWN_A - at
	return atan2(-dir.y, dir.x)


func _link_lightmap() -> void:
	var lightmap := _root.get_node("LightmapGI") as LightmapGI
	if ResourceLoader.exists(LIGHTMAP_DATA):
		lightmap.light_data = load(LIGHTMAP_DATA)
	else:
		lightmap.light_data = null  # nunca o .lmbake da oficial: o bake da variante o regravaria
		push_warning("[spike] sem %s: rode tools/bake-lightmap.ps1 para a variante" % LIGHTMAP_DATA)


func _add_kit(parent: Node, asset: String, label: String, where: Transform3D) -> Node3D:
	var node := (load(KIT + asset + ".glb") as PackedScene).instantiate() as Node3D
	node.name = label
	node.transform = where
	_add(parent, node)
	return node


func _add(parent: Node, child: Node) -> void:
	parent.add_child(child)
	child.owner = _root
