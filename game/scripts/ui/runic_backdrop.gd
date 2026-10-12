class_name RunicBackdrop
extends ColorRect
## Retangulo com o shader runic_backdrop (F51): passa o proprio tamanho ao shader, que desenha a
## grade de pontos e os cantos em px. Cada instancia tem o seu ShaderMaterial; nao recebe clique.


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	resized.connect(_on_resized)
	_on_resized()


func _on_resized() -> void:
	(material as ShaderMaterial).set_shader_parameter(&"rect_size", size)
