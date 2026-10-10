class_name ArenaAmbience
extends Node3D
## Ambientacao da arena (F40): luzes locais e particulas (cascatas de mana, brasas do magma).
## So visual: no servidor headless o node se remove, para nada de VFX existir fora do cliente
## (bloco visual, regra 1). Nenhum estado de jogo depende destes filhos.


func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		queue_free()
