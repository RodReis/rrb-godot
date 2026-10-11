class_name VfxPool
extends Node
## Pool dos efeitos de uma vez (F41; CLAUDE.md regra 5: pooling so do que e frequente — impacto,
## poeira, pulso). Instancia sob demanda e reusa o que terminou; nada e liberado na partida.
## Persistente (Muralha, rastros, saraivada) nao passa por aqui: mora no HeroVfx. So cliente.

var _free: Dictionary = {}  # PackedScene -> Array[VfxOneShot] (terminados, prontos para reuso)


## Toca [param scene] em [param at] ([param radius] > 0 = efeito de area dimensionado).
func spawn(scene: PackedScene, at: Transform3D, radius: float = 0.0) -> VfxOneShot:
	var effect: VfxOneShot = null
	if _free.has(scene):
		var ready_list: Array[VfxOneShot] = _free[scene]
		effect = ready_list.pop_back()
	if effect == null:
		effect = scene.instantiate() as VfxOneShot
		add_child(effect)
		effect.finished.connect(_on_effect_finished.bind(scene))
	effect.play(at, radius)
	return effect


func _on_effect_finished(effect: VfxOneShot, scene: PackedScene) -> void:
	if not _free.has(scene):
		var list: Array[VfxOneShot] = []
		_free[scene] = list
	(_free[scene] as Array[VfxOneShot]).append(effect)
