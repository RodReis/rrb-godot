// Barra de HP sobre a cabeca (WorldHealthBar): quad sempre de frente para a camera,
// preenchido da esquerda ate ratio. Proporcao e cor por instancia: um material para todas.
shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled;

instance uniform float ratio : hint_range(0.0, 1.0) = 1.0;
instance uniform vec4 fill_color : source_color = vec4(1.0);
uniform vec4 back_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
		INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]
	);
}

void fragment() {
	vec4 color = UV.x < ratio ? fill_color : back_color;
	ALBEDO = color.rgb;
}
