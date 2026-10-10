// Parede da zona da fase 2 (ZoneRing): forte no chao e sumindo para cima, com faixas subindo.
// appear (0-1) faz a zona surgir na transicao; cor de UiTokens pelo script.
shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled, depth_draw_never;

uniform vec4 color : source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform float appear : hint_range(0.0, 1.0) = 1.0;
// Meia altura da malha (o cilindro e centrado na origem dele).
uniform float half_height = 1.5;
uniform float max_alpha = 0.6;
uniform float bands = 5.0;
uniform float band_speed = 0.5;
uniform float band_depth = 0.35;

varying float height01;

void vertex() {
	height01 = (VERTEX.y + half_height) / (2.0 * half_height);
}

void fragment() {
	float fade = pow(1.0 - clamp(height01, 0.0, 1.0), 1.5);
	float band = 1.0 - band_depth * (0.5 + 0.5 * sin((height01 * bands - TIME * band_speed) * TAU));
	ALBEDO = color.rgb;
	ALPHA = fade * band * max_alpha * appear;
}
