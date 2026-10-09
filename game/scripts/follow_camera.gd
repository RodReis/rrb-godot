extends Camera3D
## Segue o player local (node com nome = peer id deste cliente).

const OFFSET: Vector3 = Vector3(0, 12, 9)

func _ready() -> void:
	global_position = OFFSET
	look_at(Vector3.ZERO, Vector3.UP)

func _process(_delta: float) -> void:
	if multiplayer.is_server():
		return
	var me := get_node_or_null("../Players/%d" % multiplayer.get_unique_id()) as Node3D
	if me == null:
		return
	global_position = me.global_position + OFFSET
	look_at(me.global_position, Vector3.UP)
