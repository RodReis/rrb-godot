// Estrela de 5 pontas do atordoado (StatusIndicator, PI 2026-10-22): quad de frente para a camera,
// mascara da estrela em UV (fora dela, discard), centro mais claro.
shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled;

uniform vec4 color : source_color = vec4(1.0, 0.85, 0.3, 1.0);

void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
		INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]
	);
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float angle = atan(p.x, -p.y);
	float sector = TAU / 5.0;
	// Raio da borda: 1 nas pontas, 0,45 nos vales.
	float t = abs(mod(angle, sector) - sector * 0.5) / (sector * 0.5);
	float edge = mix(0.45, 1.0, t);
	float r = length(p);
	if (r > edge) {
		discard;
	}
	ALBEDO = mix(color.rgb, vec3(1.0), 0.55 * (1.0 - r / edge));
}
