extends Node3D
## Arena provisoria do M0, gerada em codigo para ser identica em servidor e cliente.

const SIZE: float = 40.0
const GROUND_COLOR: Color = Color(0.55, 0.75, 0.35)
const WALL_COLOR: Color = Color(0.5, 0.5, 0.55)


func _ready() -> void:
	_add_box(Vector3(SIZE, 1.0, SIZE), Vector3(0, -0.5, 0), GROUND_COLOR)
	_add_box(Vector3(2, 2, 2), Vector3(4, 1, -4), WALL_COLOR)
	_add_box(Vector3(2, 2, 6), Vector3(-5, 1, 4), WALL_COLOR)


func _add_box(size: Vector3, pos: Vector3, color: Color) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	mesh.material = material
	mesh_instance.mesh = mesh
	body.add_child(shape)
	body.add_child(mesh_instance)
	add_child(body)
