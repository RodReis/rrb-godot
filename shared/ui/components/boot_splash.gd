class_name BootSplash
extends TextureRect
## Splash "ARENA 1V1" do Launcher (F68, SPEC-068): o boot splash do motor fica sem imagem (so a cor
## de fundo, sem o logo do Godot) e este controle cobre a janela ate o Launcher estar pronto.
## Imagem gerada por tools/ui/render_loading.gd. [method dismiss] some com fade e se liberta;
## chamar de novo nao faz nada.

const IMAGE: String = "res://shared/assets/ui/loading/splash.png"
const FADE_SECONDS: float = 0.35

var _dismissed: bool = false


func _init() -> void:
	texture = load(IMAGE) as Texture2D
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)


func is_dismissed() -> bool:
	return _dismissed


func dismiss() -> void:
	if _dismissed:
		return
	_dismissed = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not is_inside_tree():
		queue_free()
		return
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, FADE_SECONDS)
	tween.finished.connect(queue_free)
